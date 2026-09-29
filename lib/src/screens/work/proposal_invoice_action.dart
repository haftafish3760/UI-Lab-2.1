import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/models/estimate_models.dart';
import '../../data/work/models/work_models.dart';
import '../../data/work/work_persistence_session.dart';
import 'invoice_detail_screen.dart';
import 'work_overview_scope.dart';

/// The same visible transition on Estimate and Quote details.
class ProposalInvoiceAction extends StatefulWidget {
  const ProposalInvoiceAction({required this.sourceId, super.key});
  final String sourceId;
  @override
  State<ProposalInvoiceAction> createState() => _ProposalInvoiceActionState();
}

class _ProposalInvoiceActionState extends State<ProposalInvoiceAction> {
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final work = PrototypeOperationsScope.of(context).workSession;
    final visible = visibleWorkOverviewRecords(context).toList();
    final source = visible.where((r) => r.id == widget.sourceId).firstOrNull;
    if (work == null || source == null || !source.isProposal) {
      return const SizedBox.shrink();
    }
    final linked = visible
        .where(
          (r) => r.kind == WorkRecordKind.invoice && r.sourceId == source.id,
        )
        .firstOrNull;
    if (linked != null) {
      return OutlinedButton.icon(
        key: ValueKey('proposal-open-invoice-${source.id}'),
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(record: linked),
          ),
        ),
        icon: const Icon(Icons.receipt_long_outlined),
        label: Text('Open ${linked.number}'),
      );
    }
    if (!work.permissions.canEdit(source) ||
        !work.permissions.editableKinds.contains(WorkRecordKind.invoice) ||
        source.resolvedEstimateStage != EstimateStage.approved ||
        !source.hasCurrentCustomerApproval ||
        !source.companyReviewAllowsCustomerApproval) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'No separate job needed? Create an invoice from this approved work. It stays a draft until you issue it.',
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: ValueKey('proposal-create-invoice-${source.id}'),
          onPressed: _saving
              ? null
              : () async {
                  setState(() {
                    _saving = true;
                    _error = null;
                  });
                  try {
                    final invoice = await work
                        .createInvoiceFromApprovedProposal(
                          sourceId: source.id,
                          expectedSourceStorageRevision: work
                              .storageRevisionFor(source.id),
                          invoiceDate: DateTime.now(),
                        );
                    if (!context.mounted) return;
                    if (invoice == null) {
                      setState(
                        () => _error =
                            work.failureMessage ??
                            'The invoice was not saved. Please retry.',
                      );
                      return;
                    }
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => InvoiceDetailScreen(record: invoice),
                      ),
                    );
                  } on Object {
                    if (mounted) {
                      setState(
                        () => _error =
                            'The invoice could not be created. Your approved work has been kept.',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          icon: const Icon(Icons.receipt_long_outlined),
          label: Text(_saving ? 'Creating invoice…' : 'Create invoice'),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
