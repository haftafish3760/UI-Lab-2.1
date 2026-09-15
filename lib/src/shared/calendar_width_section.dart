import 'package:flutter/material.dart';
import '../layout/app_layout_engine.dart';

/// Calendar sibling of the padded record workspace, with real hit-test bounds.
/// Place directly in the safe scrolling viewport, not inside a record lane.
class CalendarWidthSection extends StatelessWidget {
  const CalendarWidthSection({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppLayoutEngine.calendarMaximum),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}
