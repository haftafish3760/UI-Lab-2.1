part of 'job_workspace_screen.dart';

enum _CustomerContactAction { call, message }

extension _CustomerContactSheet on _JobWorkspaceScreenState {
  Future<void> _openCustomerContact(_CustomerContactAction action) async {
    final colors = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                action == _CustomerContactAction.call
                    ? 'Call ${_job.customerName}'
                    : 'Message ${_job.customerName}',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                action == _CustomerContactAction.call
                    ? 'Use the phone number with this device or a connected phone.'
                    : 'Use the phone number for a text message, or use the email address below.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              _ContactValue(
                label: 'Phone number',
                value: _job.customerPhone,
                copyLabel: 'Copy phone number',
              ),
              const SizedBox(height: 10),
              _ContactValue(
                label: 'Email address',
                value: _job.customerEmail,
                copyLabel: 'Copy email address',
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactValue extends StatelessWidget {
  const _ContactValue({
    required this.label,
    required this.value,
    required this.copyLabel,
  });

  final String label;
  final String value;
  final String copyLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 2),
            SelectableText(value, key: ValueKey('job-contact-value-$label')),
          ],
        );
        final copy = TextButton.icon(
          key: ValueKey('job-contact-copy-$label'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$label copied.')));
          },
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: Text(copyLabel),
        );
        if (AppLayoutEngine.stackFormFieldsFor(
          constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
        )) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              details,
              const SizedBox(height: 6),
              Align(alignment: AlignmentDirectional.centerStart, child: copy),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: details),
            const SizedBox(width: 8),
            copy,
          ],
        );
      },
    ),
  );
}
