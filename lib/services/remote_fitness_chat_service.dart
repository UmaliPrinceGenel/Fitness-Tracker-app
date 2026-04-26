import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemoteFitnessChatResult {
  const RemoteFitnessChatResult({
    required this.isConfigured,
    this.reply,
    this.reason,
  });

  final bool isConfigured;
  final String? reply;
  final String? reason;

  bool get hasReply => reply != null && reply!.trim().isNotEmpty;
}

class RemoteFitnessChatService {
  static const bool _useHostedChat = bool.fromEnvironment(
    'FITNESS_CHAT_USE_REMOTE',
    defaultValue: bool.fromEnvironment(
      'FITNESS_CHAT_USE_REMOTE_WEB',
      defaultValue: true,
    ),
  );
  static const bool _enableWebFallback = bool.fromEnvironment(
    'FITNESS_CHAT_ENABLE_WEB_FALLBACK',
    defaultValue: false,
  );
  static const String _functionName = String.fromEnvironment(
    'FITNESS_CHAT_FUNCTION_NAME',
    defaultValue: 'fitness-chat',
  );
  static const String _functionRegion = String.fromEnvironment(
    'FITNESS_CHAT_FUNCTION_REGION',
    defaultValue: '',
  );

  bool get isConfigured => _useHostedChat && _functionName.trim().isNotEmpty;

  bool get shouldUseWebFallback => kIsWeb && _enableWebFallback;

  Future<RemoteFitnessChatResult> generateReply({
    required List<Map<String, String>> messages,
  }) async {
    if (!isConfigured) {
      return const RemoteFitnessChatResult(
        isConfigured: false,
        reason: 'Hosted chat is not configured.',
      );
    }

    try {
      final response = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: <String, dynamic>{
          'messages': messages,
        },
        region: _functionRegion.trim().isEmpty ? null : _functionRegion.trim(),
      );

      final reply = _extractReply(response.data);
      if (reply != null && reply.trim().isNotEmpty) {
        return RemoteFitnessChatResult(
          isConfigured: true,
          reply: reply.trim(),
        );
      }

      return const RemoteFitnessChatResult(
        isConfigured: true,
        reason: 'Hosted chat returned an empty reply.',
      );
    } catch (error) {
      return RemoteFitnessChatResult(
        isConfigured: true,
        reason: 'Hosted chat request failed: $error',
      );
    }
  }

  String? _extractReply(dynamic data) {
    if (data is String) {
      return data;
    }

    if (data is Map) {
      final reply = data['reply'];
      if (reply is String) {
        return reply;
      }

      final nestedData = data['data'];
      if (nestedData is Map) {
        final nestedReply = nestedData['reply'];
        if (nestedReply is String) {
          return nestedReply;
        }
      }
    }

    return null;
  }
}
