class WebLlmSupportState {
  const WebLlmSupportState({
    required this.isSupported,
    this.reason,
    this.modelId,
  });

  final bool isSupported;
  final String? reason;
  final String? modelId;
}

Future<WebLlmSupportState> getWebLlmSupportState() async {
  return const WebLlmSupportState(
    isSupported: false,
    reason: 'Browser local model runtime is only available on the web build.',
  );
}

Future<WebLlmSupportState> ensureWebLlmReady() async {
  return getWebLlmSupportState();
}

Future<String> generateWebLlmReply(String messagesJson) {
  throw UnsupportedError(
    'Browser local model runtime is only available on the web build.',
  );
}
