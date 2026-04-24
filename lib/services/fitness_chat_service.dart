import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart' as llama;

import 'fitness_chat_context_service.dart';
import 'local_llm_runtime_service.dart';
import 'model_storage_service.dart';
import 'remote_fitness_chat_service.dart';
import 'web_llm_runtime_bridge.dart';

const String _fitnessOnlySystemPrompt = '''
You are a fitness-only assistant for this workout tracking app.
Only answer topics related to fitness, workouts, calories, recovery, sleep, mobility, and user progress.
If the user asks about anything unrelated to fitness, politely refuse and redirect them back to fitness topics.
Use only the supplied user context when referring to personal data.
Do not invent user data.
If the user asks about their own stats, nutrition, diet plan, profile, goals, workouts, streaks, calories, weight, BMI, sleep, or progress, answer only from the supplied app context.
If the requested personal data is not present in the supplied context, clearly say that the data is not available in the app context.
Do not answer coding, politics, history, entertainment, schoolwork, general trivia, or other non-fitness topics.
Do not give medical diagnosis.
Keep answers concise and practical.
''';

const Set<String> _allowedFitnessKeywords = {
  'fitness',
  'fit',
  'workout',
  'workouts',
  'exercise',
  'exercises',
  'train',
  'training',
  'gym',
  'strength',
  'cardio',
  'calories',
  'calorie',
  'weight',
  'bmi',
  'diet',
  'height',
  'steps',
  'sleep',
  'recovery',
  'mobility',
  'stretch',
  'stretching',
  'protein',
  'nutrition',
  'meal',
  'meals',
  'macro',
  'macros',
  'hydrate',
  'hydration',
  'water',
  'fat',
  'muscle',
  'goal',
  'goals',
  'progress',
  'streak',
  'reps',
  'sets',
  'bench',
  'squat',
  'deadlift',
  'run',
  'running',
  'walk',
  'walking',
  'jog',
  'jogging',
  'bodyweight',
  'routine',
  'plan',
};

const Set<String> _allowedGreetingMessages = {
  'hi',
  'hello',
  'hey',
  'yo',
  'good morning',
  'good afternoon',
  'good evening',
};

const String _offTopicReply =
    'I can only help with fitness topics and your app-based fitness data, such as workouts, calories, weight, BMI, sleep, goals, streaks, and progress.';
const String _genericChatFailureReply =
    'Unable to generate a fitness reply right now. Please try again in a moment.';
const String _webRuntimeFailureReply =
    'The browser chatbot could not start. Refresh the page and try again. If it keeps failing, use a recent Chrome or Edge browser with WebGPU enabled.';
const String _hostedChatFailurePrefix =
    'The hosted chatbot is currently unavailable.';

enum FitnessChatRole {
  user,
  assistant,
}

class FitnessChatTurn {
  const FitnessChatTurn({
    required this.role,
    required this.content,
  });

  final FitnessChatRole role;
  final String content;
}

class FitnessChatService {
  FitnessChatService({
    ModelStorageService? modelStorageService,
    FitnessChatContextService? contextService,
    LocalLlmRuntimeService? runtimeService,
  }) : _modelStorageService = modelStorageService ?? ModelStorageService(),
       _contextService = contextService ?? FitnessChatContextService(),
       _runtimeService = runtimeService ?? LocalLlmRuntimeService.instance,
       _remoteWebChatService = RemoteFitnessChatService();

  final ModelStorageService _modelStorageService;
  final FitnessChatContextService _contextService;
  final LocalLlmRuntimeService _runtimeService;
  final RemoteFitnessChatService _remoteWebChatService;

  ValueNotifier<LocalLlmRuntimeStatus> get runtimeStatus =>
      _runtimeService.status;

  bool get isHostedChatEnabled => kIsWeb && _remoteWebChatService.isConfigured;

  Future<ModelLocationState> getModelLocation() {
    return _modelStorageService.getModelLocation();
  }

  Future<ModelLocationState> prepareModel() async {
    if (kIsWeb && _remoteWebChatService.isConfigured) {
      return const ModelLocationState(
        exists: true,
        source: ModelPathSource.remoteHostedModel,
        path: 'remote://fitness-chat',
        suggestedPath: null,
      );
    }

    if (kIsWeb) {
      final supportState = await getWebLlmSupportState();
      return ModelLocationState(
        exists: supportState.isSupported,
        source: supportState.isSupported
            ? ModelPathSource.bundledDefaultModel
            : ModelPathSource.missing,
        path: supportState.isSupported
            ? 'browser://${supportState.modelId ?? 'fitness-context-assistant'}'
            : null,
        suggestedPath: supportState.reason,
      );
    }

    final location = await _modelStorageService.getModelLocation();
    final modelPath = location.path;
    if (location.exists && modelPath != null) {
      await _runtimeService.ensureModelLoaded(modelPath);
    } else {
      await _runtimeService.unloadModel();
    }

    return location;
  }

  Future<ModelLocationState> pickModelFile() async {
    await _modelStorageService.pickModelFile();
    return prepareModel();
  }

  Future<ModelLocationState> clearSavedModelPath() async {
    await _modelStorageService.clearModelPath();
    return prepareModel();
  }

  Future<void> stopGeneration() {
    return _runtimeService.stopGeneration();
  }

  Stream<String> streamMessage({
    required String userMessage,
    required List<FitnessChatTurn> history,
  }) async* {
    if (!_isAllowedFitnessMessage(userMessage)) {
      yield _offTopicReply;
      return;
    }

    final context = await _contextService.buildContext();
    final chatMessages = _buildChatMessages(
      context: context,
      userMessage: userMessage,
      history: history,
    );

    if (kIsWeb) {
      final failureReasons = <String>[];
      if (_remoteWebChatService.isConfigured) {
        final remoteResult = await _remoteWebChatService.generateReply(
          messages: chatMessages,
        );
        if (remoteResult.hasReply) {
          yield remoteResult.reply!;
          return;
        }
        if (remoteResult.reason != null &&
            remoteResult.reason!.trim().isNotEmpty) {
          failureReasons.add(remoteResult.reason!.trim());
        }
      }

      try {
        if (!_remoteWebChatService.shouldUseWebFallback) {
          yield _buildHostedChatFailureReply(failureReasons);
          return;
        }

        final supportState = await ensureWebLlmReady();
        if (!supportState.isSupported) {
          failureReasons.add(
            _buildWebRuntimeFailureReply(reason: supportState.reason),
          );
          yield _buildHostedChatFailureReply(failureReasons);
          return;
        }

        final reply = await generateWebLlmReply(
          jsonEncode(chatMessages),
        );
        yield reply.trim().isEmpty
            ? 'The browser assistant returned an empty reply.'
            : reply.trim();
      } catch (error, stackTrace) {
        debugPrint('Web chat generation failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        failureReasons.add(
          _buildWebRuntimeFailureReply(reason: error.toString()),
        );
        yield _buildHostedChatFailureReply(failureReasons);
      }
      return;
    }

    final modelLocation = await _modelStorageService.getModelLocation();
    final modelPath = modelLocation.path;
    if (modelLocation.exists && modelPath != null) {
      final messages = chatMessages
          .map(
            (message) => llama.ChatMessage(
              role: message['role'] ?? 'user',
              content: message['content'] ?? '',
            ),
          )
          .toList(growable: false);

      try {
        yield* _runtimeService.generateChat(
          modelPath: modelPath,
          messages: messages,
        );
        return;
      } catch (error, stackTrace) {
        debugPrint('Mobile local chat failed: $error');
        debugPrintStack(stackTrace: stackTrace);

        if (!_remoteWebChatService.isConfigured) {
          yield 'The local mobile model could not respond. Restart the app and try again.';
          return;
        }
      }
    }

    if (_remoteWebChatService.isConfigured) {
      final remoteResult = await _remoteWebChatService.generateReply(
        messages: chatMessages,
      );
      if (remoteResult.hasReply) {
        yield remoteResult.reply!;
        return;
      }

      final reason = remoteResult.reason?.trim();
      if (reason != null && reason.isNotEmpty) {
        yield _buildHostedChatFailureReply([reason]);
        return;
      }
      yield _hostedChatFailurePrefix;
      return;
    }

    final suggestedPath = modelLocation.suggestedPath;
    yield suggestedPath == null
        ? 'No GGUF model is selected yet. Open chat settings and choose your model file.'
        : 'No GGUF model is selected yet. Open chat settings and pick your model file.\n\nSuggested path:\n$suggestedPath';
  }

  String _buildSystemPrompt(FitnessChatContext context) {
    return '''
$_fitnessOnlySystemPrompt

${context.toPromptBlock()}
'''.trim();
  }

  List<Map<String, String>> _buildChatMessages({
    required FitnessChatContext context,
    required String userMessage,
    required List<FitnessChatTurn> history,
  }) {
    final trimmedHistory = history
        .where((turn) => turn.content.trim().isNotEmpty)
        .toList(growable: false);

    final recentHistory = trimmedHistory.length <= 6
        ? trimmedHistory
        : trimmedHistory.sublist(trimmedHistory.length - 6);

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': _buildSystemPrompt(context),
      },
      ...recentHistory.map(
        (turn) => <String, String>{
          'role': turn.role == FitnessChatRole.user ? 'user' : 'assistant',
          'content': turn.content,
        },
      ),
    ];

    if (userMessage.trim().isNotEmpty) {
      messages.add({
        'role': 'user',
        'content': userMessage,
      });
    }

    return messages;
  }

  String _buildWebRuntimeFailureReply({String? reason}) {
    if (reason == null || reason.trim().isEmpty) {
      return _webRuntimeFailureReply;
    }
    return '$_webRuntimeFailureReply\n\nDetails: ${reason.trim()}';
  }

  String _buildHostedChatFailureReply(List<String> reasons) {
    final normalizedReasons = reasons
        .map((reason) => reason.trim())
        .where((reason) => reason.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedReasons.isEmpty) {
      return _hostedChatFailurePrefix;
    }

    return '$_hostedChatFailurePrefix\n\n${normalizedReasons.join('\n\n')}';
  }

  bool _isAllowedFitnessMessage(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    if (_allowedGreetingMessages.contains(normalized)) {
      return true;
    }

    for (final keyword in _allowedFitnessKeywords) {
      if (normalized.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  String get genericChatFailureReply => _genericChatFailureReply;
}
