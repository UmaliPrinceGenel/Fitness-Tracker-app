import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

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
  final bridge = await _waitForBridge();
  if (bridge == null) {
    return const WebLlmSupportState(
      isSupported: false,
      reason: 'Browser model bridge failed to load.',
    );
  }

  final supported = await _awaitJsPromise<bool>(
    bridge.callMethod('isSupported'),
  );
  if (supported) {
    return const WebLlmSupportState(isSupported: true);
  }

  final reason = await _awaitJsPromise<String>(
    bridge.callMethod('getUnsupportedReason'),
  );
  return WebLlmSupportState(
    isSupported: false,
    reason: reason,
  );
}

Future<WebLlmSupportState> ensureWebLlmReady() async {
  final bridge = await _waitForBridge();
  if (bridge == null) {
    return const WebLlmSupportState(
      isSupported: false,
      reason: 'Browser model bridge failed to load.',
    );
  }

  try {
    final modelId = await _awaitJsPromise<String>(
      bridge.callMethod('ensureInitialized'),
    );
    return WebLlmSupportState(
      isSupported: true,
      modelId: modelId,
    );
  } catch (error) {
    return WebLlmSupportState(
      isSupported: false,
      reason: error.toString(),
    );
  }
}

Future<String> generateWebLlmReply(String messagesJson) async {
  final bridge = await _waitForBridge();
  if (bridge == null) {
    throw StateError('Browser model bridge failed to load.');
  }

  return _awaitJsPromise<String>(
    bridge.callMethod('generateReply', [messagesJson]),
  );
}

Future<js.JsObject?> _waitForBridge() async {
  for (var attempt = 0; attempt < 40; attempt++) {
    final bridge = js.context['fitnessWebLlm'];
    if (bridge is js.JsObject) {
      return bridge;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return null;
}

Future<T> _awaitJsPromise<T>(dynamic jsPromise) {
  if (jsPromise is! js.JsObject) {
    if (jsPromise is T) {
      return Future<T>.value(jsPromise);
    }
    return Future<T>.error(
      StateError('Expected a JavaScript Promise but got ${jsPromise.runtimeType}.'),
    );
  }

  final completer = Completer<T>();

  jsPromise.callMethod('then', [
    js_util.allowInterop((dynamic value) {
      if (completer.isCompleted) {
        return;
      }
      completer.complete(value as T);
    }),
    js_util.allowInterop((dynamic error) {
      if (completer.isCompleted) {
        return;
      }
      completer.completeError(
        StateError(error?.toString() ?? 'Unknown JavaScript error.'),
      );
    }),
  ]);

  return completer.future;
}
