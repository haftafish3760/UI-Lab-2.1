import '../../../l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/storage/draft_recovery_query.dart';

/// Explicit recovery access, separate from opening a fresh client form.
class UnfinishedClientForms extends StatefulWidget {
  const UnfinishedClientForms({required this.onResume, super.key});

  final Future<void> Function(String) onResume;

  @override
  State<UnfinishedClientForms> createState() => _UnfinishedClientFormsState();
}

class _UnfinishedClientFormsState extends State<UnfinishedClientForms> {
  Future<List<DraftRecoveryChoice>>? _choices;
  bool _opening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _choices ??= _load();
  }

  Future<List<DraftRecoveryChoice>> _load() async {
    final directory = PrototypeOperationsScope.of(context).directorySession;
    if (directory == null) return const [];
    return directory.customerDraftRecovery.list();
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<DraftRecoveryChoice>>(
        future: _choices,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return TextButton(
              onPressed: () => setState(() => _choices = _load()),
              child: Text(context.l10n.clientRecoveryRetry),
            );
          }
          final choices = snapshot.data ?? const [];
          if (choices.isEmpty) return const SizedBox.shrink();
          return ExpansionTile(
            title: Text(context.l10n.clientUnfinished),
            subtitle: Text(context.l10n.clientContinueHint),
            children: [
              for (final choice in choices)
                ListTile(
                  title: Text(
                    choice.label == 'Unnamed client'
                        ? context.l10n.clientNameMissing
                        : choice.label,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_opening && !choice.unreadable,
                  onTap: () async {
                    setState(() => _opening = true);
                    await widget.onResume(choice.draftId);
                    if (mounted) setState(() => _opening = false);
                  },
                ),
            ],
          );
        },
      );
}
