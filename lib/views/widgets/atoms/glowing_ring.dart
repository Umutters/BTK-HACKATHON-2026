import 'package:flutter/material.dart';

class GlowingRing extends StatelessWidget {
  final double size;
  final Color glowColor;
  final double strokeWidth;
  final Widget? child;

  const GlowingRing({
    super.key,
    required this.size,
    required this.glowColor,
    this.strokeWidth = 1.5,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Color.fromARGB(
            128,
            glowColor.r.toInt(),
            glowColor.g.toInt(),
            glowColor.b.toInt(),
          ),
          width: strokeWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(
              38,
              glowColor.r.toInt(),
              glowColor.g.toInt(),
              glowColor.b.toInt(),
            ),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: child,
    );
  }
}
