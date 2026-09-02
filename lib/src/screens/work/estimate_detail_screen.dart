import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../theme/app_semantic_colors.dart';
import 'estimate_actions_screen.dart';
import 'estimate_delivery_screen.dart';
import 'estimate_editor_screen.dart';
import 'estimate_items_screen.dart';
import 'estimate_models.dart';
import 'estimate_signature_screen.dart';
import 'work_detail_header.dart';
import 'work_document_preview_screen.dart';
import 'work_models.dart';

part 'estimate_detail_widgets.dart';
part 'estimate_detail_actions.dart';
part 'estimate_company_review_card.dart';
part 'estimate_company_review_handlers.dart';

class EstimateDetailScreen extends StatefulWidget {
  const EstimateDetailScreen({
    required this.initialRecord,
    required this.onUpdated,
    required this.onCreateJob,
    this.permissions = const EstimatePermissions.development(),
    super.key,
  });

  final WorkRecord initialRecord;
  final ValueChanged<WorkRecord> onUpdated, onCreateJob;
  final EstimatePermissions permissions;

  @override
  State<EstimateDetailScreen> createState() => _EstimateDetailScreenState();
}

class _EstimateDetailScreenState extends State<EstimateDetailScreen> {
  late var _record = widget.initialRecord;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
        final layout = AppLayoutEngine.detailWorkspaceFor(
          constraints.maxWidth - insets.horizontal,
          textScaler: MediaQuery.textScalerOf(context),
        );
        final compactActions = layout.columns == 1;
        final overview = Column(
          children: [
            _EstimateStatusCard(record: _record),
            const SizedBox(height: 12),
            _EstimateDatesCard(record: _record),
            const SizedBox(height: 12),
            _EstimateHistoryCard(record: _record),
          ],
        );
        final content = Column(
          children: [
            _EstimateScopeCard(record: _record),
            const SizedBox(height: 12),
            _EstimateItemsCard(
              record: _record,
              onEdit: widget.permissions.canEditItems ? _editItems : null,
            ),
            if (!compactActions) ...[
              const SizedBox(height: 12),
              _EstimateActionCard(
                record: _record,
                onEditDetails: _editEstimate,
                onPreview: _preview,
                onDelivery: _prepareDelivery,
                onSignature: _collectSignature,
                onReady: _markReady,
                onCreateJob: () => widget.onCreateJob(_record),
                permissions: widget.permissions,
              ),
            ],
          ],
        );
        return Scaffold(
          key: ValueKey('estimate-detail-${_record.id}'),
          floatingActionButton: compactActions
              ? FloatingActionButton.extended(
                  key: const ValueKey('estimate-actions-fab'),
                  onPressed: _openActions,
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  label: const Text('Estimate actions'),
                )
              : null,
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: 'Estimate details',
                          selectedDay:
                              _record.estimateDates?.createdOn ??
                              _record.createdOn ??
                              DateTime.now(),
                          onBack: () => Navigator.of(context).pop(),
                          showDateContext: true,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          key: ValueKey('document-preview-${_record.id}'),
                        ),
                        _EstimateDetailHeading(record: _record),
                        if (_record.requiresCompanyReview) ...[
                          const SizedBox(height: 14),
                          _EstimateCompanyReviewCard(
                            record: _record,
                            permissions: widget.permissions,
                            onApprove: _approveCompanyReview,
                            onReturn: _returnCompanyReview,
                            onReject: _rejectCompanyReview,
                            onEdit: _editEstimate,
                            onSubmit: _submitCompanyReview,
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (layout.columns == 1) ...[
                          overview,
                          const SizedBox(height: 12),
                          content,
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: layout.columnWidth,
                                child: overview,
                              ),
                              SizedBox(width: layout.gap),
                              SizedBox(
                                width: layout.columnWidth,
                                child: content,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openActions() async {
    final action = await Navigator.of(context).push<EstimateAction>(
      MaterialPageRoute(
        builder: (_) => EstimateActionsScreen(
          record: _record,
          permissions: widget.permissions,
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case EstimateAction.edit:
        await _editEstimate();
      case EstimateAction.preview:
        await _preview();
      case EstimateAction.delivery:
        await _prepareDelivery();
      case EstimateAction.signature:
        await _collectSignature();
      case EstimateAction.markReady:
        _markReady();
      case EstimateAction.createJob:
        widget.onCreateJob(_record);
    }
  }

  Future<void> _editItems() async {
    final items = await Navigator.of(context).push<List<WorkLineItem>>(
      MaterialPageRoute(
        builder: (_) => EstimateItemsScreen(
          initialItems: _record.items,
          pricing: _record.pricing,
          selectedDay: _record.estimateDates?.createdOn ?? _record.createdOn,
        ),
      ),
    );
    if (!mounted || items == null) return;
    _update(_record.reviseItems(items, changedOn: DateTime.now()));
  }

  Future<void> _editEstimate() async {
    final updated = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => EstimateEditorScreen(
          initialDay:
              _record.estimateDates?.createdOn ??
              _record.createdOn ??
              DateTime.now(),
          initialRecord: _record,
        ),
      ),
    );
    if (mounted && updated != null) _update(updated);
  }

  Future<void> _preview() async {
    final action = await Navigator.of(context).push<WorkDocumentPreviewAction>(
      MaterialPageRoute(
        builder: (_) => WorkDocumentPreviewScreen(
          record: _record,
          canDeliverCustomerCopy:
              widget.permissions.canSend &&
              _record.resolvedEstimateStage != EstimateStage.draft &&
              _record.companyReviewAllowsCustomerApproval,
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case WorkDocumentPreviewAction.createJob:
        widget.onCreateJob(_record);
      case WorkDocumentPreviewAction.deliver:
        await _prepareDelivery();
    }
  }

  Future<void> _prepareDelivery() async {
    if (!_record.companyReviewAllowsCustomerApproval) {
      _showCompanyReviewRequired();
      return;
    }
    final delivery = await Navigator.of(context).push<EstimateDeliveryChoice>(
      MaterialPageRoute(
        builder: (_) => EstimateDeliveryScreen(record: _record),
      ),
    );
    if (!mounted || delivery == null) return;
    _update(
      _record.recordEstimateDelivery(
        method: delivery.method,
        recipient: delivery.recipient,
        occurredOn: DateTime.now(),
      ),
    );
  }

  Future<void> _collectSignature() async {
    if (!_record.companyReviewAllowsCustomerApproval) {
      _showCompanyReviewRequired();
      return;
    }
    final signedBy = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EstimateSignatureScreen(record: _record),
      ),
    );
    if (!mounted || signedBy == null) return;
    _update(_record.recordEstimateSignature(signedBy, DateTime.now()));
  }

  void _markReady() {
    if (_record.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add labor, materials, or a flat-rate item first.'),
        ),
      );
      return;
    }
    if (_record.requiresCompanyReview) {
      _submitCompanyReview();
      return;
    }
    _update(
      _record.withEstimateStage(EstimateStage.readyToSend, DateTime.now()),
    );
  }

  void _update(WorkRecord record) {
    if (identical(record, _record)) return;
    setState(() => _record = record);
    widget.onUpdated(record);
  }
}

class _EstimateStatusCard extends StatelessWidget {
  const _EstimateStatusCard({required this.record});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) {
    final stage = record.resolvedEstimateStage;
    final signature = record.customerSignature;
    return SectionCard(
      backgroundColor: stage.needsAttention
          ? Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: .55)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Customer status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            stage.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(stage.nextStep),
          if (record.hasCurrentCustomerSignature) ...[
            const Divider(height: 22),
            const Text(
              'Customer approval is current',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text('Approved by ${signature!.signedBy}'),
            Text('Approval applies to revision ${signature.signedRevision}.'),
          ] else if (signature != null) ...[
            const Divider(height: 22),
            const Text(
              'Customer approval required again',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(signature.invalidationReason ?? 'The estimate changed.'),
          ],
        ],
      ),
    );
  }
}

class _EstimateScopeCard extends StatelessWidget {
  const _EstimateScopeCard({required this.record});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Proposed work', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(record.detail),
        const Divider(height: 22),
        Text(
          'Pricing: ${record.pricing == WorkPricingModel.flatRate ? 'Flat rate' : 'Time and materials'}',
        ),
        Text('Template: ${record.template}'),
        Text('Terms: ${record.terms}'),
      ],
    ),
  );
}

class _EstimateDatesCard extends StatelessWidget {
  const _EstimateDatesCard({required this.record});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) {
    final dates = record.estimateDates;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Estimate dates',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (dates == null)
            const Text('No detailed estimate dates are recorded.')
          else ...[
            _DetailDate(label: 'Created', value: dates.createdOn),
            _DetailDate(label: 'Last edited', value: dates.lastEditedOn),
            _DetailDate(label: 'Sent', value: dates.sentOn),
            _DetailDate(label: 'Follow up', value: dates.followUpOn),
            _DetailDate(label: 'Valid through', value: dates.expiresOn),
            _DetailDate(
              label: 'Proposed service date',
              value: dates.proposedServiceOn,
            ),
          ],
        ],
      ),
    );
  }
}

class _EstimateItemsCard extends StatelessWidget {
  const _EstimateItemsCard({required this.record, required this.onEdit});
  final WorkRecord record;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final labor = record.items.where(
      (item) => item.type == WorkLineItemType.labor,
    );
    final materials = record.items.where(
      (item) => item.type == WorkLineItemType.material,
    );
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Labor and materials',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  key: const ValueKey('edit-estimate-items'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
            ],
          ),
          _ItemSummary(label: 'Labor', items: labor.toList()),
          const Divider(height: 20),
          _ItemSummary(label: 'Materials', items: materials.toList()),
        ],
      ),
    );
  }
}

class _ItemSummary extends StatelessWidget {
  const _ItemSummary({required this.label, required this.items});
  final String label;
  final List<WorkLineItem> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      if (items.isEmpty)
        const Text('None recorded')
      else
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text('${item.name} · ${item.quantity} ${item.unit}'),
          ),
    ],
  );
}

class _EstimateHistoryCard extends StatelessWidget {
  const _EstimateHistoryCard({required this.record});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Revision and delivery history',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text('Current revision: ${record.revision}'),
        for (final revision in record.estimateRevisionHistory.reversed)
          Text('Revision ${revision.revision}: ${revision.description}'),
        for (final delivery in record.estimateDeliveries.reversed)
          Text('${delivery.method.label}: ${delivery.description}'),
        if (record.estimateRevisionHistory.isEmpty &&
            record.estimateDeliveries.isEmpty)
          const Text('No earlier revisions or deliveries are recorded.'),
      ],
    ),
  );
}
