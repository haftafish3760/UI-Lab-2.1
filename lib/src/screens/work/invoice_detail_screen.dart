import '../../../l10n/app_localizations_extension.dart';
import '../../data/work/invoice_collection_status.dart';
import '../../data/work/work_record_visibility.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_scope.dart';
import 'invoice_collection_localization.dart';
import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/work/invoice_payment_balance.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../theme/app_semantic_colors.dart';
import 'invoice_actions_screen.dart';
import 'invoice_apply_deposit_button.dart';
import 'invoice_permissions.dart';
import 'work_detail_header.dart';
import 'work_models.dart';
import 'work_activity_screen.dart';

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
    final invoice = store.workRecords
        .where(
          (candidate) =>
              candidate.id == record.id &&
              candidate.kind == WorkRecordKind.invoice,
        )
        .firstOrNull;
    final grants = store.workSession?.permissions;
    final scope = OperationalScope.of(context);
    if (invoice == null ||
        (grants != null &&
            !workRecordIsVisible(
              invoice,
              permissions: grants,
              technicianView: scope.view == AppViewMode.technician,
              selectedEmployeeId: scope.selectedEmployeeId,
            ))) {
      return Scaffold(
        key: ValueKey('invoice-unavailable-${record.id}'),
        appBar: AppBar(title: Text(context.l10n.workInvoiceHeading)),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.workRecordUnavailable),
            ),
          ),
        ),
      );
    }
    final payments = permissions.canViewFinancials
        ? (store.financialEntries
              .where((entry) => paymentBelongsToInvoice(entry, invoice))
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
                          collectionStatus: permissions.canViewFinancials
                              ? invoiceCollectionStatus(
                                  invoice,
                                  payments,
                                  now: DateTime.now(),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        InvoiceActionsScreen(
                          invoice: invoice,
                          balanceCents: balanceCents,
                          permissions: permissions,
                          embedded: true,
                        ),
                        if (permissions.canViewFinancials) ...[
                          const SizedBox(height: 8),
                          InvoiceApplyDepositButton(
                            invoice: invoice,
                            balanceCents: balanceCents,
                          ),
                        ],
                        const SizedBox(height: 12),
                        WorkActivityButton(record: invoice),
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
}
