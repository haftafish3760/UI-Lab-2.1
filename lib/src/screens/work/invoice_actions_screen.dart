import 'invoice_approval_actions.dart';
import '../../data/work/invoice_approval_content.dart';
import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../data/work/work_persistence_session.dart';
import '../../theme/operational_card_palette.dart';
import 'work_pdf_delivery.dart';
import '../../shared/documents/pdf/pdf_export_feedback.dart';
import 'invoice_editor_screen.dart';
import 'invoice_payment_entry_screen.dart';
import 'invoice_permissions.dart';
import 'work_detail_header.dart';
import 'work_document_preview_screen.dart';
import 'work_models.dart';
part 'invoice_primary_actions.dart';

class InvoiceActionsScreen extends StatelessWidget {
  const InvoiceActionsScreen({
    required this.invoice,
    required this.balanceCents,
    required this.permissions,
    this.embedded = false,
    super.key,
  });

  final WorkRecord invoice;
  final int balanceCents;
  final InvoicePermissions permissions;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final current =
        store.workRecords
            .where((candidate) => candidate.id == invoice.id)
            .firstOrNull ??
        invoice;
    if (embedded) return _primaryCard(context, current);
    return Scaffold(
      key: const ValueKey('invoice-actions-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final width = AppLayoutEngine.formWorkspaceWidthFor(
              constraints.maxWidth - insets.horizontal,
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
              children: [
                Center(
                  child: SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: 'Invoice actions',
                          selectedDay:
                              current.issuedOn ??
                              current.createdOn ??
                              DateTime.now(),
                          onBack: () => Navigator.of(context).pop(),
                          showDateContext: true,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          current.number,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text('${current.client} · ${current.title}'),
                        const SizedBox(height: 12),
                        SectionCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              if (current.status == WorkRecordStatus.draft &&
                                  permissions.canEditDraft)
                                _InvoiceActionTile(
                                  key: const ValueKey('edit-invoice-draft'),
                                  icon: Icons.edit_outlined,
                                  title: 'Edit invoice draft',
                                  detail:
                                      'Change the customer, work, items, or terms.',
                                  onTap: () => _editDraft(context, current),
                                ),
                              if (permissions.canPreviewCustomerCopy)
                                _InvoiceActionTile(
                                  key: const ValueKey('preview-invoice-copy'),
                                  icon: Icons.picture_as_pdf_outlined,
                                  title: 'Review customer copy',
                                  detail:
                                      'Preview the invoice before preparing delivery.',
                                  onTap: () => _preview(context, current),
                                ),
                              if (current.status == WorkRecordStatus.draft &&
                                  permissions.canIssue)
                                _InvoiceActionTile(
                                  key: const ValueKey('issue-invoice'),
                                  icon: Icons.outbox_outlined,
                                  title: 'Issue invoice',
                                  detail:
                                      'Post the amount to the books. Customer delivery remains separate.',
                                  onTap: () => _issue(context, current),
                                ),
                              if (current.status != WorkRecordStatus.draft &&
                                  current.status != WorkRecordStatus.paid &&
                                  balanceCents > 0 &&
                                  permissions.canRecordPayment)
                                _InvoiceActionTile(
                                  key: const ValueKey('record-invoice-payment'),
                                  icon: Icons.payments_outlined,
                                  title: 'Record payment',
                                  detail:
                                      'Apply money actually received to this invoice.',
                                  onTap: () => _recordPayment(context, current),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _editDraft(BuildContext context, WorkRecord current) async {
    if (!permissions.canEditDraft) return;
    final updated = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorScreen(
          initialDay: current.issuedOn ?? current.createdOn ?? DateTime.now(),
          initialRecord: current,
        ),
      ),
    );
    if (!context.mounted || updated == null) return;
    final store = PrototypeOperationsScope.of(context);
    final saved = await store.updateWorkRecord(updated);
    if (!context.mounted) return;
    if (saved) {
      if (!embedded) Navigator.of(context).pop();
    } else {
      _showSaveFailure(context, store);
    }
  }

  Future<void> _preview(BuildContext context, WorkRecord current) async {
    if (!permissions.canPreviewCustomerCopy) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkDocumentPreviewScreen(record: current),
      ),
    );
  }

  Future<void> _issue(BuildContext context, WorkRecord current) async {
    if (!permissions.canIssue) return;
    if (current.items.isEmpty ||
        current.client.trim().isEmpty ||
        current.client == 'Client not selected' ||
        current.title.trim().isEmpty ||
        current.title == 'Untitled invoice') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add the customer, invoice title and items before sending.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Issue this invoice?'),
        content: const Text(
          'This posts the invoice amount to the company books. It does not email, text, or otherwise deliver the customer copy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Draft'),
          ),
          FilledButton(
            key: const ValueKey('confirm-issue-invoice'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Issue Invoice'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    final store = PrototypeOperationsScope.of(context);
    final issued = current.copyWith(
      status: WorkRecordStatus.due,
      issuedOn: current.issuedOn ?? DateUtils.dateOnly(DateTime.now()),
      dueOn:
          current.dueOn ??
          DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 14)),
    );
    final saved = await store.saveWorkAndFinancial(
      records: [issued],
      entries: [
        PrototypeFinancialEntry(
          id: 'ledger-issued-${current.id}',
          kind: PrototypeFinancialKind.invoiceIssued,
          occurredOn: issued.issuedOn!,
          amountCents: (issued.total * 100).round(),
          sourceId: issued.number,
        ),
      ],
    );
    if (!context.mounted) return;
    if (saved) {
      if (!embedded) Navigator.of(context).pop();
    } else {
      _showSaveFailure(context, store);
    }
  }

  Future<void> _recordPayment(BuildContext context, WorkRecord current) async {
    if (!permissions.canRecordPayment) return;
    final payment = await Navigator.of(context).push<PrototypeFinancialEntry>(
      MaterialPageRoute(
        builder: (_) => InvoicePaymentEntryScreen(
          invoice: current,
          balanceCents: balanceCents,
          initialDay: DateUtils.dateOnly(DateTime.now()),
        ),
      ),
    );
    if (!context.mounted || payment == null) return;
    final store = PrototypeOperationsScope.of(context);
    final saved = await store.recordInvoicePayment(current, payment);
    if (!context.mounted) return;
    if (saved) {
      if (!embedded) Navigator.of(context).pop();
    } else {
      _showSaveFailure(context, store);
    }
  }

  void _showSaveFailure(BuildContext context, PrototypeOperationsStore store) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          store.workSession?.failureMessage ??
              'The changes were not saved. Please try again.',
        ),
      ),
    );
  }
}

class _InvoiceActionTile extends StatelessWidget {
  const _InvoiceActionTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 64,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(detail),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
