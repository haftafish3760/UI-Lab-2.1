import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_extension.dart';

class WorkSelectedDateBar extends StatelessWidget {
  const WorkSelectedDateBar({
    required this.selectedDay,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final DateTime selectedDay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = MaterialLocalizations.of(context).formatFullDate(selectedDay);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        border: Border.all(color: colors.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.operationalPreviousDay,
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              date,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            tooltip: context.l10n.operationalNextDay,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
