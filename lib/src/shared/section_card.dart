import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.backgroundColor,
    this.gradient,
    this.shadows,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surface,
        gradient: gradient,
        border: Border.all(color: borderColor ?? colors.outline, width: 1),
        borderRadius: BorderRadius.circular(AppRadii.surface),
        boxShadow:
            shadows ??
            (colors.brightness == Brightness.dark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0D17313A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
