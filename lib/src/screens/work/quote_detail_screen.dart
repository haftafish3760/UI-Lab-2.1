import 'proposal_approval_history_screen.dart';
import 'estimate_delivery_screen.dart';
import 'estimate_approval_screen.dart';
import 'proposal_invoice_action.dart';
import 'work_job_editor.dart';
import 'job_workspace_screen.dart';
import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/quote_status.dart';
import '../../data/work/quote_approval_content.dart';
import '../../data/work/work_persistence_session.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/document_form_section.dart';
import 'quote_editor_screen.dart';
import 'work_detail_header.dart';
import 'work_models.dart';
import 'work_overview_scope.dart';
import 'estimate_models.dart';

part 'quote_company_approval_actions.dart';

class QuoteDetailScreen extends StatefulWidget {
  const QuoteDetailScreen({required this.recordId, super.key});
  final String recordId;
  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  bool _savingApproval = false;
  String? _approvalError;
  void _setApprovalState(bool busy, String? error) => setState(() {
    _savingApproval = busy;
    _approvalError = error;
  });
  Future<void> _edit(WorkRecord record) async {
    await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => QuoteEditorScreen(
          initialDay: record.createdOn ?? DateTime.now(),
          initialRecord: record,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final record = visibleWorkOverviewRecords(context)
        .where((r) => r.kind == WorkRecordKind.quote && r.id == widget.recordId)
        .firstOrNull;
    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quote')),
        body: const Center(child: Text('This quote is unavailable.')),
      );
    }
    final canEdit =
        store.workSession?.permissions.canEdit(record) == true &&
        record.resolvedEstimateStage != EstimateStage.converted;
    Widget section(String title, String value, IconData icon) =>
        DocumentFormSection(
          title: title,
          summary: value,
          icon: icon,
          onTap: canEdit ? () => _edit(record) : null,
        );
    return Scaffold(
      key: const ValueKey('quote-review'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.workFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return SingleChildScrollView(
              padding: insets.copyWith(top: 10, bottom: 28),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: layout.workspaceWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkDetailHeader(
                        label: record.number,
                        selectedDay: record.createdOn ?? DateTime.now(),
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        record.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(quoteStatus(record, DateTime.now()).label),
                      if (record.requiresCompanyReview &&
                          !record.companyReviewAllowsCustomerApproval)
                        const Text(
                          'Supervisor or admin approval is required before sending.',
                        ),
                      const SizedBox(height: 12),
                      ..._approvalActions(record),
                      DocumentFormOverview(
                        groups: [
                          [
                            section(
                              'Client information',
                              [
                                record.client,
                                record.customerSnapshot?.phone ?? '',
                                record.customerSnapshot?.email ?? '',
                              ].where((s) => s.isNotEmpty).join('\n'),
                              Icons.person_outline,
                            ),
                            section(
                              'Description of work',
                              record.detail,
                              Icons.description_outlined,
                            ),
                          ],
                          [
                            section(
                              'Fixed quote price',
                              '\$${record.total.toStringAsFixed(2)}',
                              Icons.payments_outlined,
                            ),
                            if (record.documentPresentation ==
                                WorkDocumentPresentation.detailed)
                              for (final item in record.items)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.name),
                                  subtitle: Text(
                                    '${item.description}\n${item.quantity} ${item.unit} · \$${item.total.toStringAsFixed(2)}',
                                  ),
                                ),
                          ],
                          [
                            if (record.terms.isNotEmpty)
                              section(
                                'Terms and exclusions',
                                record.terms,
                                Icons.rule_outlined,
                              ),
                            if (record.estimateDates?.expiresOn
                                case final expiry?)
                              section(
                                'Valid until',
                                MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(expiry),
                                Icons.event_outlined,
                              ),
                          ],
                        ],
                      ),
                      if (record.hasCurrentCustomerApproval)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.verified_outlined),
                          title: const Text('Customer approved'),
                          subtitle: Text(
                            record.hasCurrentCustomerSignature
                                ? 'Signed by ${record.customerSignature!.signedBy}'
                                : '${record.customerApprovals.last.customerName} · ${record.customerApprovals.last.method.label}',
                          ),
                        )
                      else if (canEdit &&
                          record.companyReviewAllowsCustomerApproval &&
                          (store.workSession!.permissions.canCollectSignature ||
                              store
                                  .workSession!
                                  .permissions
                                  .canRecordCustomerApproval))
                        FilledButton.icon(
                          key: const ValueKey('quote-customer-approval'),
                          onPressed: () async {
                            await Navigator.of(context).push<WorkRecord>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EstimateApprovalScreen(record: record),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                          icon: const Icon(Icons.draw_outlined),
                          label: const Text('Customer signature or approval'),
                        ),
                      for (final job
                          in visibleWorkOverviewRecords(context).where(
                            (candidate) =>
                                candidate.kind == WorkRecordKind.job &&
                                candidate.sourceId == record.id,
                          ))
                        OutlinedButton.icon(
                          key: ValueKey('quote-linked-job-${job.id}'),
                          icon: const Icon(Icons.work_outline),
                          label: Text('Open job: ${job.title}'),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  JobWorkspaceScreen(workRecord: job),
                            ),
                          ),
                        ),
                      if (canEdit &&
                          record.resolvedEstimateStage ==
                              EstimateStage.approved &&
                          record.hasCurrentCustomerApproval &&
                          store.workSession!.permissions.editableKinds.contains(
                            WorkRecordKind.job,
                          ))
                        FilledButton.icon(
                          key: const ValueKey('quote-add-to-jobs'),
                          icon: const Icon(Icons.work_outline),
                          label: const Text('Add to jobs'),
                          onPressed: () async {
                            final job = await Navigator.of(context)
                                .push<WorkRecord>(
                                  MaterialPageRoute(
                                    builder: (_) => WorkJobEditor(
                                      initialDay: DateTime.now(),
                                      sourceEstimate: record,
                                    ),
                                  ),
                                );
                            if (!mounted || !context.mounted) return;
                            setState(() {});
                            if (job != null) {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      JobWorkspaceScreen(workRecord: job),
                                ),
                              );
                            }
                          },
                        ),
                      ProposalInvoiceAction(sourceId: record.id),
                      if (canEdit &&
                          store.workSession!.permissions.canShareDocuments &&
                          record.resolvedEstimateStage != EstimateStage.draft &&
                          record.companyReviewAllowsCustomerApproval)
                        OutlinedButton.icon(
                          key: const ValueKey('quote-delivery-action'),
                          icon: const Icon(Icons.send_outlined),
                          label: const Text('Send quote'),
                          onPressed: () async {
                            await Navigator.of(context).push<WorkRecord>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EstimateDeliveryScreen(record: record),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                      if (record.customerSignature != null ||
                          record.customerApprovals.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.history),
                          label: const Text('Approved versions'),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => ProposalApprovalHistoryScreen(
                                recordId: record.id,
                              ),
                            ),
                          ),
                        ),
                      if (canEdit)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            key: const ValueKey('edit-quote'),
                            onPressed: () => _edit(record),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit quote'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
