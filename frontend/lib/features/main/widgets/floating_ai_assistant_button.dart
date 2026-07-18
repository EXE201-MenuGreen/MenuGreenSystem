import 'package:flutter/material.dart';

class FloatingAiAssistantButton extends StatelessWidget {
  const FloatingAiAssistantButton({
    super.key,
    required this.isVip,
    required this.onTap,
    required this.onPanUpdate,
  });

  final bool isVip;
  final VoidCallback onTap;
  final ValueChanged<DragUpdateDetails> onPanUpdate;

  @override
  Widget build(BuildContext context) {
    final gradient = isVip
        ? const [
            Color(0xFFFFF3B0),
            Color(0xFFFFD166),
            Color(0xFFE0A106),
          ]
        : const [
            Color(0xFF2D5A45),
            Color(0xFF1B4332),
          ];

    final glowColor = isVip
        ? const Color(0xFFFFD166).withValues(alpha: 0.45)
        : const Color(0xFF1B4332).withValues(alpha: 0.28);

    final foreground = isVip ? const Color(0xFF654300) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: isVip ? 72 : 64,
        height: isVip ? 72 : 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: isVip ? 20 : 14,
              spreadRadius: isVip ? 2 : 0,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isVip
                ? Colors.white.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.2),
            width: isVip ? 2 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: foreground,
              size: isVip ? 30 : 28,
            ),
            if (isVip)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8C5A00),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'VIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
