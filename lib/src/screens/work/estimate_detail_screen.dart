import '../../shared/editor_input_lock.dart';
import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/storage/local_record_command.dart';
import '../../data/work/work_record_codec.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../theme/app_semantic_colors.dart';
import 'estimate_actions_screen.dart';
import 'estimate_delivery_screen.dart';
import 'estimate_editor_screen.dart';
import 'estimate_items_screen.dart';
import 'stored_estimate_items_editor.dart';
import 'estimate_models.dart';
import 'estimate_signature_screen.dart';
import 'estimate_review_reason_dialog.dart';
import 'work_detail_header.dart';
import 'work_document_preview_screen.dart';
import 'work_models.dart';

part 'estimate_detail_widgets.dart';
part 'estimate_detail_record_cards.dart';
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
  var _saving = false;
  var _initializedPersistence = false;
  int _baseStorageRevision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedPersistence) return;
    _initializedPersistence = true;
    final work = PrototypeOperationsScope.maybeOf(context)?.workSession;
    final current = work?.records
        .where((record) => record.id == _record.id)
        .firstOrNull;
    if (current != null) {
      _record = current;
      _baseStorageRevision = work!.storageRevisionFor(current.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EditorInputLock(
      locked: _saving,
      child: LayoutBuilder(
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
      ),
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
        await _markReady();
      case EstimateAction.createJob:
        widget.onCreateJob(_record);
    }
  }

  Future<void> _editItems() async {
    final work = PrototypeOperationsScope.maybeOf(context)?.workSession;
    if (work != null) {
      final result = await Navigator.of(context).push<List<WorkLineItem>>(
        MaterialPageRoute(
          builder: (_) =>
              StoredEstimateItemsEditor(record: _record, work: work),
        ),
      );
      if (!mounted || result == null) return;
      final saved = work.records
          .where((record) => record.id == _record.id)
          .firstOrNull;
      if (saved != null) await _update(saved);
      return;
    }

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
    await _update(_record.reviseItems(items, changedOn: DateTime.now()));
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
    if (mounted && updated != null) await _update(updated);
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
    final delivery = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => EstimateDeliveryScreen(record: _record),
      ),
    );
    if (!mounted || delivery == null) return;
    await _update(delivery);
  }

  Future<void> _collectSignature() async {
    if (!_record.companyReviewAllowsCustomerApproval) {
      _showCompanyReviewRequired();
      return;
    }
    final signed = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => EstimateSignatureScreen(record: _record),
      ),
    );
    if (!mounted || signed == null) return;
    await _update(signed);
  }

  Future<void> _markReady() async {
    if (_record.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add labor, materials, or a flat-rate item first.'),
        ),
      );
      return;
    }
    if (_record.requiresCompanyReview) {
      await _submitCompanyReview();
      return;
    }
    await _update(
      _record.withEstimateStage(EstimateStage.readyToSend, DateTime.now()),
    );
  }

  Future<void> _update(WorkRecord record) async {
    if (_saving || identical(record, _record)) return;
    final work = PrototypeOperationsScope.maybeOf(context)?.workSession;
    if (work == null) {
      setState(() => _record = record);
      widget.onUpdated(record);
      return;
    }
    setState(() => _saving = true);
    final current = work.records
        .where((item) => item.id == record.id)
        .firstOrNull;
    if (current == null ||
        current.kind != WorkRecordKind.estimate ||
        record.id != _record.id) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This estimate is no longer available.')),
      );
      return;
    }
    final alreadySaved =
        canonicalJson(encodeWorkRecord(current)) ==
        canonicalJson(encodeWorkRecord(record));
    final saved =
        alreadySaved ||
        await work.save(
          records: [record],
          expectedStorageRevisions: {record.id: _baseStorageRevision},
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) {
        _record = record;
        _baseStorageRevision = work.storageRevisionFor(record.id);
      }
    });
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            work.failureMessage ??
                'The estimate was not saved. Previous values remain active.',
          ),
        ),
      );
    }
  }
}
