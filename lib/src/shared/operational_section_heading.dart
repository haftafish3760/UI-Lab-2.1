import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One title-row rhythm for Plan and recorded-entry sections. Reserve the
/// action's normal height even when Show all is absent; allow text to grow.
class OperationalSectionHeading extends StatelessWidget {
  const OperationalSectionHeading({
    required this.background,
    required this.foreground,
    required this.child,
    this.headerKey,
    this.dividerColor,
    super.key,
  });

  final Color background;
  final Color foreground;
  final Widget child;
  final Key? headerKey;
  final Color? dividerColor;

  @override
  Widget build(BuildContext context) => Container(
    key: headerKey,
    decoration: BoxDecoration(
      color: background,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadii.surface - 1),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 2),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              heightFactor: 1,
              child: child,
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: dividerColor ?? foreground.withValues(alpha: .35),
        ),
      ],
    ),
  );
}
