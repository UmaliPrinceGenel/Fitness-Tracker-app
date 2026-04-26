import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart' as llama;

import 'fitness_chat_context_service.dart';
import 'local_llm_runtime_service.dart';
import 'model_storage_service.dart';
import 'remote_fitness_chat_service.dart';
import 'web_llm_runtime_bridge.dart';

const String _fitnessSystemPrompt = '''
You are a knowledgeable fitness and wellness assistant for the Rockies Fitness Gym Tracker app.

SCOPE — you can help with:
• Workouts, exercise form, training programs and routines
• Nutrition, meal plans, diet plans, calorie counting, macros
• Supplements, hydration, pre/post-workout nutrition
• Weight management, body composition, BMI
• Recovery, sleep optimization, stretching, mobility
• Goal setting, progress tracking, motivation
• General health and wellness related to fitness

RULES:
1. Give complete, actionable answers. Include specific exercises, sets/reps, meal suggestions, or calorie targets when relevant.
2. Do NOT ask unnecessary follow-up questions. Provide your best answer with the available context. Only ask for clarification when truly essential information is missing.
3. Use the supplied user context when referring to personal data. Do not invent user data.
4. If the requested personal data is not in the supplied context, clearly say it is not available.
5. Politely decline topics completely unrelated to fitness and wellness (e.g., coding, politics, history, entertainment, schoolwork).
6. Do not give medical diagnoses or prescribe medication.
7. Keep answers practical, well-structured, and easy to follow. Use bullet points or numbered lists for plans.
''';
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

  bool get isHostedChatEnabled => _remoteWebChatService.isConfigured;

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

    // Mobile: try local model first.
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
    if (userMessage.trim().isEmpty) {
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

    // Mobile: try local model first, fall back to remote.
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

    // Fallback to remote if local model unavailable or failed.
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
$_fitnessSystemPrompt

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

    final recentHistory = trimmedHistory.length <= 10
        ? trimmedHistory
        : trimmedHistory.sublist(trimmedHistory.length - 10);

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



  String get genericChatFailureReply => _genericChatFailureReply;
}
