import '../../../l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/invoice_approval_content.dart';
import '../../data/work/work_persistence_session.dart';
import 'work_models.dart';

class InvoiceApprovalActions extends StatelessWidget {
  const InvoiceApprovalActions({required this.record, super.key});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) {
    final session = PrototypeOperationsScope.of(context).workSession;
    if (session == null ||
        record.status != WorkRecordStatus.draft ||
        !session.permissions.canEdit(record)) {
      return const SizedBox.shrink();
    }
    final approved = invoiceHasCurrentApproval(record);
    final last = record.invoiceApprovalHistory.lastOrNull;
    final pending =
        last?.decision == InvoiceApprovalDecision.submitted &&
        last?.contentFingerprint == invoiceApprovalFingerprint(record);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (record.requiresInvoiceApproval)
          Text(
            approved
                ? context.l10n.workStatusApproved
                : context.l10n.invoiceNeedsApproval,
          ),
        if (last?.decision == InvoiceApprovalDecision.changesRequested &&
            last!.note.isNotEmpty)
          Text(last.note),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (!approved && !pending)
              TextButton.icon(
                key: const ValueKey('invoice-submit-approval'),
                onPressed: session.isSaving
                    ? null
                    : () => _save(context, InvoiceApprovalDecision.submitted),
                icon: const Icon(Icons.forward_to_inbox_outlined),
                label: Text(context.l10n.invoiceRequestApproval),
              ),
            if (pending && session.permissions.canApproveInvoices)
              TextButton.icon(
                key: const ValueKey('invoice-approve'),
                onPressed: session.isSaving
                    ? null
                    : () => _save(context, InvoiceApprovalDecision.approved),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(context.l10n.invoiceApprove),
              ),
            if (pending && session.permissions.canApproveInvoices)
              TextButton.icon(
                key: const ValueKey('invoice-request-changes'),
                onPressed: session.isSaving
                    ? null
                    : () => _requestChanges(context),
                icon: const Icon(Icons.edit_note_outlined),
                label: Text(context.l10n.invoiceRequestChanges),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _requestChanges(BuildContext context) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => const _InvoiceChangesDialog(),
    );
    if (note == null || !context.mounted) return;
    await _save(context, InvoiceApprovalDecision.changesRequested, note: note);
  }

  Future<void> _save(
    BuildContext context,
    InvoiceApprovalDecision decision, {
    String note = '',
  }) async {
    final session = PrototypeOperationsScope.of(context).workSession;
    if (session == null) return;
    final saved = await session.recordInvoiceApproval(
      record,
      decision,
      note: note,
    );
    if (!context.mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            session.failureMessage ?? context.l10n.invoiceApprovalSaveFailed,
          ),
        ),
      );
    }
  }
}

class _InvoiceChangesDialog extends StatefulWidget {
  const _InvoiceChangesDialog();
  @override
  State<_InvoiceChangesDialog> createState() => _InvoiceChangesDialogState();
}

class _InvoiceChangesDialogState extends State<_InvoiceChangesDialog> {
  final _note = TextEditingController();
  bool _missing = false;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.invoiceRequestChanges),
    content: TextField(
      key: const ValueKey('invoice-changes-reason'),
      controller: _note,
      minLines: 2,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: context.l10n.invoiceChangesReason,
        errorText: _missing ? context.l10n.invoiceChangesReasonRequired : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      TextButton(
        key: const ValueKey('invoice-confirm-changes'),
        onPressed: () {
          final note = _note.text.trim();
          if (note.isEmpty) {
            setState(() => _missing = true);
            return;
          }
          Navigator.pop(context, note);
        },
        child: Text(context.l10n.invoiceRequestChanges),
      ),
    ],
  );
}
