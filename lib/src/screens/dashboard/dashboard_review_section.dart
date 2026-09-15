import 'package:flutter/material.dart';

import '../../shared/operational_card_color_scope.dart';
import '../../shared/operational_section_heading.dart';
import '../../shared/section_card.dart';
import '../../theme/operational_card_palette.dart';

/// Admin review uses the same whole-card hierarchy as Plan and Entries.
class DashboardReviewSection extends StatelessWidget {
  const DashboardReviewSection({
    required this.title,
    required this.icon,
    required this.children,
    this.tone = OperationalCardPalette.entries,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final OperationalCardTone tone;

  @override
  Widget build(BuildContext context) => OperationalCardColorScope(
    tone: tone,
    builder: (context) => SectionCard(
      padding: EdgeInsets.zero,
      backgroundColor: tone.end,
      borderColor: tone.start,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OperationalSectionHeading(
            background: tone.start,
            foreground: tone.foreground,
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    ),
  );
}
