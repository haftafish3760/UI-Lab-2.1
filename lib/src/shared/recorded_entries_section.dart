import 'package:flutter/material.dart';

import '../theme/operational_card_palette.dart';
import 'operational_card_color_scope.dart';
import 'section_card.dart';

/// Shared presentation for recorded activity, irrespective of module or person.
/// Modules retain their own records, permissions, expansion and destinations.
/// Builders must use this scope's row colors, not invent section backgrounds.
class RecordedEntriesSection extends StatelessWidget {
  const RecordedEntriesSection({
    required this.builder,
    this.gradient,
    super.key,
  });

  final WidgetBuilder builder;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => OperationalCardColorScope(
    tone: OperationalCardPalette.entries,
    builder: (context) => SectionCard(
      padding: EdgeInsets.zero,
      backgroundColor: OperationalCardPalette.entries.start,
      gradient: gradient,
      borderColor: OperationalCardPalette.entries.start,
      child: builder(context),
    ),
  );
}
