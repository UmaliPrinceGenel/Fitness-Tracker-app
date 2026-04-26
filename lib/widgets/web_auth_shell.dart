import 'package:flutter/material.dart';

class WebAuthShell extends StatelessWidget {
  const WebAuthShell({
    super.key,
    required this.leftTitle,
    required this.leftSubtitle,
    required this.rightChild,
  });

  final String leftTitle;
  final String leftSubtitle;
  final Widget rightChild;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool compact = width < 760;
          final bool narrow = width < 480;
          final double horizontalPadding = narrow ? 14 : (compact ? 18 : 28);
          final double verticalPadding = narrow ? 16 : 32;
          final double borderRadius = compact ? 30 : 42;
          final double panelMinHeight = compact ? 0 : 560;

          return Stack(
            children: [
              const _WebAuthBackdrop(),
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.28),
                            blurRadius: 28,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: compact
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLeftPanel(
                                  borderRadius: borderRadius,
                                  minHeight: panelMinHeight,
                                  compact: compact,
                                ),
                                _buildRightPanel(
                                  borderRadius: borderRadius,
                                  minHeight: panelMinHeight,
                                  compact: compact,
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: _buildLeftPanel(
                                    borderRadius: borderRadius,
                                    minHeight: panelMinHeight,
                                    compact: compact,
                                  ),
                                ),
                                Expanded(
                                  flex: 13,
                                  child: _buildRightPanel(
                                    borderRadius: borderRadius,
                                    minHeight: panelMinHeight,
                                    compact: compact,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftPanel({
    required double borderRadius,
    required double minHeight,
    required bool compact,
  }) {
    return Container(
      constraints: minHeight > 0 ? BoxConstraints(minHeight: minHeight) : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 22 : 36,
        vertical: compact ? 28 : 44,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0EF),
        borderRadius: compact
            ? BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              )
            : BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                bottomLeft: Radius.circular(borderRadius),
              ),
      ),
      child: _LeftPanel(
        title: leftTitle,
        subtitle: leftSubtitle,
        compact: compact,
      ),
    );
  }

  Widget _buildRightPanel({
    required double borderRadius,
    required double minHeight,
    required bool compact,
  }) {
    return Container(
      constraints: minHeight > 0 ? BoxConstraints(minHeight: minHeight) : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 46,
        vertical: compact ? 26 : 44,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4F2),
        borderRadius: compact
            ? BorderRadius.only(
                bottomLeft: Radius.circular(borderRadius),
                bottomRight: Radius.circular(borderRadius),
              )
            : BorderRadius.only(
                topRight: Radius.circular(borderRadius),
                bottomRight: Radius.circular(borderRadius),
              ),
      ),
      child: rightChild,
    );
  }
}

class _WebAuthBackdrop extends StatelessWidget {
  const _WebAuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A1A), Color(0xFF0B0B0B)],
              ),
            ),
          ),
          Center(
            child: Opacity(
              opacity: 0.12,
              child: Transform.scale(
                scale: 2.6,
                child: Image.asset('assets/logo.jpg'),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double titleSize = compact ? 34 : 46;
    final double logoSize = compact ? 164 : 220;
    final double subtitleSize = compact ? 15 : 17;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF121212),
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),
        SizedBox(height: compact ? 20 : 28),
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
          ),
        ),
        SizedBox(height: compact ? 20 : 26),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF525252),
            fontSize: subtitleSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
