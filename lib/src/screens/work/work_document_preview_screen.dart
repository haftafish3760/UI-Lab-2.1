import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import 'documents/customer_pdf_screen.dart';
import 'customer_portal_screen.dart';
import 'work_customer_document.dart';
import 'work_pdf_delivery.dart';
import '../../shared/documents/pdf/pdf_export_feedback.dart';
import 'estimate_models.dart';
import 'estimate_items_screen.dart';
import 'work_models.dart';

part 'work_document_preview_actions.dart';

enum WorkDocumentPreviewAction { createJob, deliver }

class WorkDocumentPreviewScreen extends StatefulWidget {
  const WorkDocumentPreviewScreen({
    required this.record,
    this.onRecordUpdated,
    this.canDeliverCustomerCopy,
    super.key,
  });
  final WorkRecord record;
  final ValueChanged<WorkRecord>? onRecordUpdated;
  final bool? canDeliverCustomerCopy;
  @override
  State<WorkDocumentPreviewScreen> createState() =>
      _WorkDocumentPreviewScreenState();
}

class _WorkDocumentPreviewScreenState extends State<WorkDocumentPreviewScreen> {
  late WorkRecord _record = widget.record;
  bool get _canDeliver =>
      widget.canDeliverCustomerCopy ??
      (_record.kind != WorkRecordKind.estimate ||
          (_record.resolvedEstimateStage != EstimateStage.draft &&
              _record.companyReviewAllowsCustomerApproval));

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    return CustomerPdfScreen(
      key: ValueKey('document-preview-${_record.id}'),
      document: workCustomerDocument(
        _record,
        store.companyProfile,
        store.customers.where((c) => c.name == _record.client).firstOrNull,
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Document actions',
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await _editItems();
              case 'send':
                if (_record.kind == WorkRecordKind.estimate) {
                  Navigator.of(context).pop(WorkDocumentPreviewAction.deliver);
                } else {
                  await _showPdfDeliveryOptions(context, _record);
                }
              case 'portal':
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => CustomerPortalScreen(record: _record),
                  ),
                );
              case 'job':
                Navigator.of(context).pop(WorkDocumentPreviewAction.createJob);
            }
          },
          itemBuilder: (_) => [
            if (_record.kind == WorkRecordKind.estimate)
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  _record.hasCurrentCustomerSignature
                      ? 'Customer approval is current'
                      : 'Customer approval has not been recorded',
                ),
              ),
            if (!_canDeliver)
              const PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  'Finish the draft and company approval before sharing.',
                ),
              ),
            if (_canDeliver)
              const PopupMenuItem(
                value: 'send',
                child: Text('PDF delivery options'),
              ),
            if (_canDeliver)
              const PopupMenuItem(
                value: 'portal',
                child: Text('Customer review link or QR code'),
              ),
            if (_record.kind == WorkRecordKind.estimate &&
                widget.onRecordUpdated != null)
              const PopupMenuItem(
                value: 'edit',
                key: ValueKey('edit-estimate-items'),
                child: Text('Edit estimate items'),
              ),
            if (_record.kind == WorkRecordKind.estimate &&
                _record.status == WorkRecordStatus.accepted &&
                _record.hasCurrentCustomerSignature)
              const PopupMenuItem(
                value: 'job',
                key: ValueKey('preview-create-job'),
                child: Text('Create job from estimate'),
              ),
          ],
        ),
      ],
    );
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
    final updated = _record.reviseItems(items, changedOn: DateTime.now());
    if (identical(updated, _record)) return;
    setState(() => _record = updated);
    widget.onRecordUpdated?.call(updated);
  }
}
