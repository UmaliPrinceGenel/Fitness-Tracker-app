import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart' as llama;

enum LocalLlmRuntimePhase {
  unsupported,
  idle,
  loading,
  ready,
  generating,
  error,
}

class LocalLlmRuntimeStatus {
  const LocalLlmRuntimeStatus({
    required this.phase,
    this.modelPath,
    this.message,
  });

  final LocalLlmRuntimePhase phase;
  final String? modelPath;
  final String? message;

  bool get isReady => phase == LocalLlmRuntimePhase.ready;
  bool get isGenerating => phase == LocalLlmRuntimePhase.generating;

  LocalLlmRuntimeStatus copyWith({
    LocalLlmRuntimePhase? phase,
    String? modelPath,
    String? message,
  }) {
    return LocalLlmRuntimeStatus(
      phase: phase ?? this.phase,
      modelPath: modelPath ?? this.modelPath,
      message: message ?? this.message,
    );
  }
}

class LocalLlmRuntimeService {
  LocalLlmRuntimeService._();

  static final LocalLlmRuntimeService instance = LocalLlmRuntimeService._();

  llama.LlamaController? _controller;
  String? _loadedModelPath;
  StreamSubscription<String>? _activeGenerationSubscription;

  final ValueNotifier<LocalLlmRuntimeStatus> status =
      ValueNotifier<LocalLlmRuntimeStatus>(
        const LocalLlmRuntimeStatus(
          phase: LocalLlmRuntimePhase.idle,
          message: 'No local model loaded.',
        ),
      );

  bool get _isSupportedPlatform => !kIsWeb && Platform.isAndroid;

  Future<LocalLlmRuntimeStatus> ensureModelLoaded(String modelPath) async {
    if (!_isSupportedPlatform) {
      return _updateStatus(
        LocalLlmRuntimeStatus(
          phase: LocalLlmRuntimePhase.unsupported,
          modelPath: modelPath,
          message: 'Local GGUF runtime is enabled only on Android builds.',
        ),
      );
    }

    final modelFile = File(modelPath);
    if (!await modelFile.exists()) {
      return _updateStatus(
        LocalLlmRuntimeStatus(
          phase: LocalLlmRuntimePhase.error,
          modelPath: modelPath,
          message: 'Model file not found at the saved path.',
        ),
      );
    }

    if (_loadedModelPath == modelPath &&
        _controller != null &&
        await _controller!.isModelLoaded()) {
      return _updateStatus(
        LocalLlmRuntimeStatus(
          phase: LocalLlmRuntimePhase.ready,
          modelPath: modelPath,
          message: 'Local model is ready.',
        ),
      );
    }

    await unloadModel();
    _controller = llama.LlamaController();
    _updateStatus(
      LocalLlmRuntimeStatus(
        phase: LocalLlmRuntimePhase.loading,
        modelPath: modelPath,
        message: 'Loading local GGUF model...',
      ),
    );

    try {
      final gpuInfo = await _controller!.detectGpu();
      await _controller!.loadModel(
        modelPath: modelPath,
        threads: _recommendedThreads(),
        contextSize: 2048,
        gpuLayers: _recommendedGpuLayers(gpuInfo),
      );
      _loadedModelPath = modelPath;
      return _updateStatus(
        LocalLlmRuntimeStatus(
          phase: LocalLlmRuntimePhase.ready,
          modelPath: modelPath,
          message: 'Local model is ready.',
        ),
      );
    } catch (error) {
      return _updateStatus(
        LocalLlmRuntimeStatus(
          phase: LocalLlmRuntimePhase.error,
          modelPath: modelPath,
          message: 'Failed to load local model: $error',
        ),
      );
    }
  }

  Stream<String> generateChat({
    required String modelPath,
    required List<llama.ChatMessage> messages,
  }) async* {
    final loadStatus = await ensureModelLoaded(modelPath);
    if (!loadStatus.isReady) {
      if (loadStatus.message != null) {
        yield loadStatus.message!;
      }
      return;
    }

    final controller = _controller;
    if (controller == null) {
      yield 'Local model controller is unavailable.';
      return;
    }

    _updateStatus(
      LocalLlmRuntimeStatus(
        phase: LocalLlmRuntimePhase.generating,
        modelPath: modelPath,
        message: 'Generating response...',
      ),
    );

    final outputController = StreamController<String>();
    _activeGenerationSubscription?.cancel();
    _activeGenerationSubscription = controller
        .generateChat(
          messages: messages,
          template: 'chatml',
          maxTokens: 320,
          temperature: 0.65,
          topP: 0.9,
          topK: 40,
          minP: 0.05,
          repeatPenalty: 1.15,
          presencePenalty: 0.05,
          frequencyPenalty: 0.05,
          repeatLastN: 96,
        )
        .listen(
          outputController.add,
          onError: (Object error, StackTrace stackTrace) {
            if (!outputController.isClosed) {
              outputController.addError(error, stackTrace);
            }
          },
          onDone: () {
            if (!outputController.isClosed) {
              outputController.close();
            }
          },
          cancelOnError: true,
        );

    try {
      yield* outputController.stream;
      _updateStatus(
        LocalLlmRuntimeStatus(
          phase: LocalLlmRuntimePhase.ready,
          modelPath: modelPath,
          message: 'Local model is ready.',
        ),
      );
    } catch (error) {
      _updateStatus(
        LocalLlmRuntimeStatus(
          phase: LocalLlmRuntimePhase.error,
          modelPath: modelPath,
          message: 'Generation failed: $error',
        ),
      );
      rethrow;
    } finally {
      await _activeGenerationSubscription?.cancel();
      _activeGenerationSubscription = null;
      if (!outputController.isClosed) {
        await outputController.close();
      }
      if (status.value.phase != LocalLlmRuntimePhase.error) {
        _updateStatus(
          LocalLlmRuntimeStatus(
            phase: LocalLlmRuntimePhase.ready,
            modelPath: modelPath,
            message: 'Local model is ready.',
          ),
        );
      }
    }
  }

  Future<void> stopGeneration() async {
    if (!_isSupportedPlatform) {
      return;
    }

    await _activeGenerationSubscription?.cancel();
    _activeGenerationSubscription = null;
    await _controller?.stop();
    if (_loadedModelPath != null) {
      _updateStatus(
        LocalLlmRuntimeStatus(
          phase: LocalLlmRuntimePhase.ready,
          modelPath: _loadedModelPath,
          message: 'Generation stopped.',
        ),
      );
    }
  }

  Future<void> unloadModel() async {
    await _activeGenerationSubscription?.cancel();
    _activeGenerationSubscription = null;
    await _controller?.dispose();
    _controller = null;
    _loadedModelPath = null;
    _updateStatus(
      const LocalLlmRuntimeStatus(
        phase: LocalLlmRuntimePhase.idle,
        message: 'No local model loaded.',
      ),
    );
  }

  int _recommendedThreads() {
    final availableCores = Platform.numberOfProcessors;
    return math.max(2, math.min(availableCores - 1, 4));
  }

  int _recommendedGpuLayers(llama.GpuInfo gpuInfo) {
    final recommended = gpuInfo.recommendedGpuLayers;
    if (recommended < 0) {
      return 0;
    }
    return recommended;
  }

  LocalLlmRuntimeStatus _updateStatus(LocalLlmRuntimeStatus nextStatus) {
    status.value = nextStatus;
    return nextStatus;
  }
}
