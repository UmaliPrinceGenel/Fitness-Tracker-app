import 'package:flutter/material.dart';

const double _chatbotButtonSize = 56;
const double _chatbotEdgeInset = 12;
const double _chatbotSideSwitchThreshold = 36;

class ChatbotLauncher extends StatefulWidget {
  const ChatbotLauncher({
    super.key,
    this.title = 'Fitness Chat',
    this.initialLeft = 16,
    this.initialBottom = 20,
  });

  final String title;
  final double initialLeft;
  final double initialBottom;

  @override
  State<ChatbotLauncher> createState() => _ChatbotLauncherState();
}

class _ChatbotLauncherState extends State<ChatbotLauncher> {
  double _horizontalDrag = 0;

  void _openChatbot(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChatbotSheet(title: widget.title),
    );
  }

  double _maxTravel(BoxConstraints constraints) {
    return (constraints.maxHeight - _chatbotButtonSize)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  _ChatbotDockPosition _initialPosition(BoxConstraints constraints) {
    final maxTravel = _maxTravel(constraints);
    final bottomOffset =
        widget.initialBottom.clamp(0.0, maxTravel).toDouble();
    final side = widget.initialLeft <= constraints.maxWidth / 2
        ? _ChatbotSide.left
        : _ChatbotSide.right;

    return _ChatbotDockPosition(
      side: side,
      bottomOffset: bottomOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final safeConstraints = BoxConstraints(
          maxWidth: constraints.hasBoundedWidth
              ? constraints.maxWidth
              : mediaSize.width,
          maxHeight: constraints.hasBoundedHeight
              ? constraints.maxHeight
              : mediaSize.height,
        );

        _SharedChatbotDock.position.value ??= _initialPosition(safeConstraints);

        return ValueListenableBuilder<_ChatbotDockPosition?>(
          valueListenable: _SharedChatbotDock.position,
          builder: (context, sharedPosition, _) {
            final position = sharedPosition ?? _initialPosition(safeConstraints);
            final maxTravel = _maxTravel(safeConstraints);
            final bottomOffset =
                position.bottomOffset.clamp(0.0, maxTravel).toDouble();
            final top = (safeConstraints.maxHeight -
                    _chatbotButtonSize -
                    bottomOffset)
                .clamp(0.0, maxTravel)
                .toDouble();
            final left = position.side == _ChatbotSide.left
                ? _chatbotEdgeInset
                : (safeConstraints.maxWidth -
                        _chatbotButtonSize -
                        _chatbotEdgeInset)
                    .clamp(0.0, double.infinity)
                    .toDouble();

            return Stack(
              children: [
                Positioned(
                  left: 0,
                  top: top,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: left),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedLeft, child) {
                      return Transform.translate(
                        offset: Offset(animatedLeft, 0),
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onPanStart: (_) {
                        _horizontalDrag = 0;
                      },
                      onPanUpdate: (details) {
                        final nextBottomOffset =
                            (bottomOffset - details.delta.dy)
                                .clamp(0.0, maxTravel)
                                .toDouble();
                        var nextSide = position.side;

                        _horizontalDrag += details.delta.dx;
                        if (_horizontalDrag >= _chatbotSideSwitchThreshold) {
                          nextSide = _ChatbotSide.right;
                          _horizontalDrag = 0;
                        } else if (_horizontalDrag <=
                            -_chatbotSideSwitchThreshold) {
                          nextSide = _ChatbotSide.left;
                          _horizontalDrag = 0;
                        }

                        _SharedChatbotDock.position.value = position.copyWith(
                          side: nextSide,
                          bottomOffset: nextBottomOffset,
                        );
                      },
                      onPanEnd: (_) {
                        _horizontalDrag = 0;
                      },
                      onPanCancel: () {
                        _horizontalDrag = 0;
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openChatbot(context),
                          borderRadius: BorderRadius.circular(18),
                          child: Ink(
                            width: _chatbotButtonSize,
                            height: _chatbotButtonSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7A00),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SharedChatbotDock {
  static final ValueNotifier<_ChatbotDockPosition?> position =
      ValueNotifier<_ChatbotDockPosition?>(null);
}

enum _ChatbotSide { left, right }

class _ChatbotDockPosition {
  const _ChatbotDockPosition({
    required this.side,
    required this.bottomOffset,
  });

  final _ChatbotSide side;
  final double bottomOffset;

  _ChatbotDockPosition copyWith({
    _ChatbotSide? side,
    double? bottomOffset,
  }) {
    return _ChatbotDockPosition(
      side: side ?? this.side,
      bottomOffset: bottomOffset ?? this.bottomOffset,
    );
  }
}

class _ChatbotSheet extends StatefulWidget {
  const _ChatbotSheet({
    required this.title,
  });

  final String title;

  @override
  State<_ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<_ChatbotSheet> {
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = const [
    _ChatMessage(
      text:
          'Hi! I am your fitness assistant. Ask about workouts, calories, or progress.',
      isUser: false,
    ),
  ].toList();

  bool _isReplying = false;
  ScrollController? _activeScrollController;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _activeScrollController;
      if (controller == null || !controller.hasClients) {
        return;
      }

      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messageController.clear();
      _isReplying = true;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            text: _buildPlaceholderReply(text),
            isUser: false,
          ),
        );
        _isReplying = false;
      });
      _scrollToBottom();
    });
  }

  String _buildPlaceholderReply(String text) {
    final message = text.toLowerCase();

    if (message.contains('workout')) {
      return 'This chat UI is ready. Connect it to your workout chatbot logic to return real plans and guidance.';
    }

    if (message.contains('calorie') || message.contains('nutrition')) {
      return 'You can hook this message panel to your nutrition assistant and return calorie or meal suggestions here.';
    }

    if (message.contains('progress')) {
      return 'This is a placeholder response. Connect your chatbot service to answer using user progress data.';
    }

    return 'The messaging UI is working. Replace this placeholder reply with your chatbot backend response.';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.52,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, sheetController) {
            _activeScrollController = sheetController;
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF101010),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 12, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7A00),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Ask anything about your fitness journey',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: sheetController,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      itemCount: _messages.length + (_isReplying ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isReplying && index == _messages.length) {
                          return const _TypingBubble();
                        }

                        final message = _messages[index];
                        return _MessageBubble(message: message);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF151515),
                      border: Border(
                        top: BorderSide(color: Colors.white12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 4,
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF222222),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _sendMessage,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7A00),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
  });

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor =
        message.isUser ? const Color(0xFFFF7A00) : const Color(0xFF1F1F1F);
    final textColor = message.isUser ? Colors.black : Colors.white;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
            border: message.isUser
                ? null
                : Border.all(color: Colors.white10),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'Typing...',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;
}
