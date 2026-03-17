import 'package:flutter/material.dart';

class ClayContainer extends StatelessWidget {
  final Widget? child;
  final double borderRadius;
  final Color color;
  final double depth;
  final double spread;
  final bool emboss;
  final EdgeInsetsGeometry? padding;

  const ClayContainer({
    super.key,
    this.child,
    this.borderRadius = 30,
    required this.color,
    this.depth = 12,
    this.spread = 5,
    this.emboss = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final Color lightColor = hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor();
    final Color darkColor = hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: emboss
            ? [
                BoxShadow(
                  color: darkColor,
                  offset: Offset(depth, depth),
                  blurRadius: spread,
                  spreadRadius: -spread / 2,
                ),
                BoxShadow(
                  color: lightColor,
                  offset: Offset(-depth, -depth),
                  blurRadius: spread,
                  spreadRadius: -spread / 2,
                ),
              ]
            : [
                BoxShadow(
                  color: darkColor.withOpacity(0.5),
                  offset: Offset(depth, depth),
                  blurRadius: spread * 2,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.7),
                  offset: Offset(-depth, -depth),
                  blurRadius: spread * 2,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}
