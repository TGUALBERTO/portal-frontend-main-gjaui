import 'package:gjamobile/src/imports/core_imports.dart';

class HomeAppButton extends StatefulWidget {
  const HomeAppButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<HomeAppButton> createState() => _HomeAppButtonState();
}

class _HomeAppButtonState extends State<HomeAppButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final backgroundColor = colorScheme.primary;
    final hoverBackgroundColor = colorScheme.primaryContainer;
    final foregroundColor = colorScheme.onPrimary;
    final hoverForegroundColor = colorScheme.onPrimaryContainer;
    final shadowColor = colorScheme.shadow.withValues(alpha: 0.18);
    final currentBackgroundColor = _isHovered ? hoverBackgroundColor : backgroundColor;
    final currentForegroundColor = _isHovered ? hoverForegroundColor : foregroundColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : (_isHovered ? 1.02 : 1),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: currentBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    if (_isHovered)
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: currentForegroundColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        widget.icon,
                        color: currentForegroundColor,
                        size: 48,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
