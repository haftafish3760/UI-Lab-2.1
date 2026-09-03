import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<void> showDashboardActionDirectory(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _ActionDirectory(),
    );

Future<void> showStartWorkdayConfirmation(
  BuildContext context,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Start workday?'),
    content: const Text(
      'Confirm Alex Morgan and Transit 12 before starting the workday record.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Confirm start'),
      ),
    ],
  ),
);

Future<void> showDashboardSettings(
  BuildContext context,
  VoidCallback onToggleTheme,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dashboard settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            leading: const Icon(Icons.contrast_rounded),
            title: const Text('Switch light or dark mode'),
            subtitle: const Text(
              'Only appearance changes in this review build',
            ),
            onTap: () {
              Navigator.pop(context);
              onToggleTheme();
            },
          ),
        ],
      ),
    ),
  ),
);

Future<void> showDashboardBusinessMenu(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Business menu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const ListTile(
                leading: Icon(Icons.business_outlined),
                title: Text('Thompson Home Services'),
                subtitle: Text('Solo owner-technician review profile'),
              ),
              const ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Dashboard is the active review screen'),
                subtitle: Text(
                  'Other business screens remain intentionally frozen',
                ),
              ),
            ],
          ),
        ),
      ),
    );

class _ActionDirectory extends StatelessWidget {
  const _ActionDirectory();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    const actions = [
      (Icons.event_available_outlined, 'Schedule work'),
      (Icons.work_outline_rounded, 'Create job'),
      (Icons.request_quote_outlined, 'Create estimate'),
      (Icons.description_outlined, 'Create invoice'),
      (Icons.receipt_long_outlined, 'Record expense'),
      (Icons.add_a_photo_outlined, 'Add receipt'),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add a record', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Choose what you are recording.',
              style: TextStyle(color: colors.inkMuted),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisExtent: 64,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) => OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(actions[index].$1),
                label: Text(actions[index].$2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
