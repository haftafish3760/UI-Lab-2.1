import '../work/quote_detail_screen.dart';
import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import '../work/estimate_detail_screen.dart';
import '../work/estimate_models.dart';
import '../work/invoice_detail_screen.dart';
import '../work/invoice_permissions.dart';
import '../work/job_workspace_screen.dart';
import '../work/work_models.dart';
import 'expense_detail_screen.dart';
import 'expense_permissions.dart';
import 'expenses_scope_header.dart';

class ReportSourcesScreen extends StatelessWidget {
  const ReportSourcesScreen({
    required this.title,
    required this.basis,
    required this.sources,
    super.key,
  });

  final String title;
  final String basis;
  final List<PrototypeReportSource> sources;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    return Scaffold(
      key: const ValueKey('report-sources-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.detailWorkspaceFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: insets.copyWith(top: 10, bottom: 32),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.columnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExpensesScopeHeader(
                          view: scope.view,
                          selectedEmployeeId: scope.selectedEmployeeId,
                          onViewChanged: scope.setView,
                          onEmployeeChanged: scope.selectEmployee,
                          onSettings: () {},
                          showSettings: false,
                          workspaceLabel: 'Report records',
                          showBackButton: true,
                          onBack: () => Navigator.of(context).pop(),
                          showEmployeeStrip: false,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          basis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (sources.isEmpty)
                          const SectionCard(
                            child: Text(
                              'No supporting records in this period.',
                            ),
                          )
                        else
                          for (
                            var index = 0;
                            index < sources.length;
                            index++
                          ) ...[
                            _SourceCard(
                              source: sources[index],
                              onTap: () => _openSource(context, sources[index]),
                            ),
                            if (index != sources.length - 1)
                              const SizedBox(height: 8),
                          ],
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

  Future<void> _openSource(
    BuildContext context,
    PrototypeReportSource source,
  ) async {
    final scope = OperationalScope.of(context);
    final store = PrototypeOperationsScope.of(context);
    switch (source.kind) {
      case PrototypeReportSourceKind.expense:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => ExpenseDetailScreen(
              expenseId: source.id,
              permissions: expensePermissionsForView(scope.view),
            ),
          ),
        );
      case PrototypeReportSourceKind.workRecord:
        final record = store.workRecords
            .where((candidate) => candidate.id == source.id)
            .firstOrNull;
        if (record != null) await _openWorkRecord(context, record, scope.view);
      case PrototypeReportSourceKind.invoiceEntry ||
          PrototypeReportSourceKind.payment:
        final number = source.linkedWorkNumber;
        final invoice = store.workRecords
            .where(
              (candidate) =>
                  candidate.kind == WorkRecordKind.invoice &&
                  candidate.number == number,
            )
            .firstOrNull;
        if (invoice != null) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(
                record: invoice,
                permissions: invoicePermissionsForView(scope.view),
              ),
            ),
          );
        }
    }
  }

  Future<void> _openWorkRecord(
    BuildContext context,
    WorkRecord record,
    AppViewMode view,
  ) async {
    final store = PrototypeOperationsScope.of(context);
    switch (record.kind) {
      case WorkRecordKind.quote:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => QuoteDetailScreen(recordId: record.id),
          ),
        );
      case WorkRecordKind.job:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => JobWorkspaceScreen(
              workRecord: record,
              onWorkRecordUpdated: store.updateWorkRecord,
            ),
          ),
        );
      case WorkRecordKind.estimate:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => EstimateDetailScreen(
              initialRecord: record,
              onUpdated: store.updateWorkRecord,
              onCreateJob: (_) {},
              permissions: view == AppViewMode.admin
                  ? const EstimatePermissions.development()
                  : const EstimatePermissions.technicianDevelopment(),
            ),
          ),
        );
      case WorkRecordKind.invoice:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(
              record: record,
              permissions: invoicePermissionsForView(view),
            ),
          ),
        );
    }
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.onTap});

  final PrototypeReportSource source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SectionCard(
    key: ValueKey('report-source-${source.id}'),
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 62),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Icon(_sourceIcon(source.kind), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      source.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      source.detail,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (source.amountCents != null) ...[
                const SizedBox(width: 8),
                Text(
                  reportMoneyCents(source.amountCents!),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    ),
  );
}

IconData _sourceIcon(PrototypeReportSourceKind kind) => switch (kind) {
  PrototypeReportSourceKind.expense => Icons.receipt_long_outlined,
  PrototypeReportSourceKind.workRecord => Icons.work_outline_rounded,
  PrototypeReportSourceKind.invoiceEntry => Icons.description_outlined,
  PrototypeReportSourceKind.payment => Icons.payments_outlined,
};

String reportMoneyCents(int cents) {
  final amount = cents.abs() / 100;
  final sign = cents < 0 ? '-' : '';
  final parts = amount.toStringAsFixed(2).split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$sign\$$whole.${parts.last}';
}
