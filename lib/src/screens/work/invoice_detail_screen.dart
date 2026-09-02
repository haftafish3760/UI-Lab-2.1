import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../theme/app_semantic_colors.dart';
import 'invoice_actions_screen.dart';
import 'invoice_permissions.dart';
import 'work_detail_header.dart';
import 'work_models.dart';

part 'invoice_detail_sections.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({
    required this.record,
    this.permissions = const InvoicePermissions.development(),
    super.key,
  });

  final WorkRecord record;
  final InvoicePermissions permissions;

  @override
  Widget build(BuildContext context) {
    if (!permissions.canView) {
      return Scaffold(
        key: ValueKey('invoice-detail-${record.id}'),
        body: const SafeArea(
          child: Center(
            child: Text('You do not have permission to view this invoice.'),
          ),
        ),
      );
    }
    final store = PrototypeOperationsScope.of(context);
    final invoice =
        store.workRecords
            .where((candidate) => candidate.id == record.id)
            .firstOrNull ??
        record;
    final payments = permissions.canViewFinancials
        ? (store.financialEntries
              .where(
                (entry) =>
                    entry.kind == PrototypeFinancialKind.paymentReceived &&
                    entry.sourceId == invoice.number,
              )
              .toList()
            ..sort((a, b) => b.occurredOn.compareTo(a.occurredOn)))
        : <PrototypeFinancialEntry>[];
    final paidCents = payments.fold(0, (sum, entry) => sum + entry.amountCents);
    final totalCents = (invoice.total * 100).round();
    final balanceCents = (totalCents - paidCents).clamp(0, totalCents);
    final sourceJob = store.workRecords
        .where(
          (candidate) =>
              candidate.kind == WorkRecordKind.job &&
              candidate.id == invoice.sourceId,
        )
        .firstOrNull;
    return Scaffold(
      key: ValueKey('invoice-detail-${invoice.id}'),
      floatingActionButton: permissions.hasActions
          ? FloatingActionButton.extended(
              key: const ValueKey('invoice-actions-fab'),
              onPressed: () => _openActions(context, invoice, balanceCents),
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Invoice actions'),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final available = constraints.maxWidth - insets.horizontal;
            final layout = AppLayoutEngine.detailWorkspaceFor(
              available,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 96),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: 'Invoice details',
                          selectedDay:
                              invoice.issuedOn ??
                              invoice.createdOn ??
                              DateTime.now(),
                          onBack: () => Navigator.of(context).pop(),
                          showDateContext: true,
                        ),
                        const SizedBox(height: 16),
                        _InvoiceDetailHeading(
                          invoice: invoice,
                          balanceCents: balanceCents,
                          showFinancials: permissions.canViewFinancials,
                        ),
                        const SizedBox(height: 12),
                        _InvoiceDetailLayout(
                          layout: layout,
                          invoice: invoice,
                          sourceJob: sourceJob,
                          payments: payments,
                          paidCents: paidCents,
                          balanceCents: balanceCents,
                          showFinancials: permissions.canViewFinancials,
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

  Future<void> _openActions(
    BuildContext context,
    WorkRecord invoice,
    int balanceCents,
  ) async {
    if (!permissions.hasActions) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => InvoiceActionsScreen(
          invoice: invoice,
          balanceCents: balanceCents,
          permissions: permissions,
        ),
      ),
    );
  }
}
