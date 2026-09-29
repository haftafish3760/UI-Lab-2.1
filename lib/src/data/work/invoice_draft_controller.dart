import 'models/work_contact_models.dart';
import 'work_contact_codec.dart';
import 'work_items_draft_input.dart';
import '../storage/local_draft_checkpoint.dart';
import 'models/work_models.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import 'work_record_detail_codec.dart';

/// Raw invoice work, including incomplete numbers and nested unfinished input.
/// Legacy payload names below remain stable regardless of screen composition.
class InvoiceDraftInput {
  const InvoiceDraftInput({
    required this.creatorId,
    required this.number,
    this.purchaseOrderNumber = '',
    this.servicePrice = '',
    this.itemized = false,
    required this.baseStorageRevision,
    required this.title,
    required this.discount,
    required this.tax,
    required this.terms,
    required this.client,
    this.customerSnapshot,
    required this.pricing,
    required this.template,
    required this.createdOn,
    required this.items,
    required this.existingRecordId,
    required this.recordId,
    required this.summary,
    required this.issuedOn,
    required this.dueOn,
    required this.sourceJobId,
    required this.location,
    required this.paymentMethod,
    required this.pendingLineItem,
  });

  final String creatorId;
  final String number;
  final String purchaseOrderNumber;
  final String servicePrice;
  final bool itemized;
  final int baseStorageRevision;
  final String title;
  final String discount;
  final String tax;
  final String terms;
  final String? client;
  final WorkCustomerProfile? customerSnapshot;
  final WorkPricingModel pricing;
  final String template;
  final DateTime createdOn;
  final List<WorkLineItem> items;
  final String? existingRecordId;
  final String recordId;
  final String summary;
  final DateTime issuedOn;
  final DateTime dueOn;
  final String? sourceJobId;
  final String? location;
  final String paymentMethod;
  final WorkItemsDraftInput? pendingLineItem;

  Map<String, Object?> toPayload() => {
    'creatorId': creatorId,
    'number': number,
    'purchaseOrderNumber': purchaseOrderNumber,
    'servicePrice': servicePrice,
    'itemized': itemized,
    'baseStorageRevision': baseStorageRevision,
    'title': title,
    'discount': discount,
    'tax': tax,
    'terms': terms,
    'client': client,
    'customerSnapshot': customerSnapshot == null
        ? null
        : encodeWorkCustomerProfile(customerSnapshot!),
    'pricing': pricing.name,
    'template': template,
    'createdOn': createdOn.toIso8601String(),
    'items': items.map(encodeWorkLineItem).toList(),
    'existingRecordId': existingRecordId,
    'recordId': recordId,
    'summary': summary,
    'issuedOn': issuedOn.toIso8601String(),
    'dueOn': dueOn.toIso8601String(),
    'sourceJobId': sourceJobId,
    'location': location,
    'paymentMethod': paymentMethod,
    'itemEditor': pendingLineItem?.toPayload(),
  };

  factory InvoiceDraftInput.fromPayload(Map<String, Object?> input) =>
      InvoiceDraftInput(
        creatorId: input['creatorId'] as String,
        number: input['number'] as String,
        purchaseOrderNumber: input['purchaseOrderNumber'] as String? ?? '',
        servicePrice: input['servicePrice'] as String? ?? '',
        itemized: input['itemized'] as bool? ?? false,
        baseStorageRevision: input['baseStorageRevision'] as int,
        title: input['title'] as String,
        discount: input['discount'] as String,
        tax: input['tax'] as String,
        terms: input['terms'] as String,
        client: input['client'] as String?,
        customerSnapshot: input['customerSnapshot'] == null
            ? null
            : decodeWorkCustomerProfile(
                (input['customerSnapshot'] as Map).cast<String, Object?>(),
              ),
        pricing: WorkPricingModel.values.byName(input['pricing'] as String),
        template: input['template'] as String,
        createdOn: DateTime.parse(input['createdOn'] as String),
        items: (input['items'] as List)
            .map(
              (item) =>
                  decodeWorkLineItem((item as Map).cast<String, Object?>()),
            )
            .toList(),
        existingRecordId: input['existingRecordId'] as String?,
        recordId: input['recordId'] as String,
        summary: input['summary'] as String,
        issuedOn: DateTime.parse(input['issuedOn'] as String),
        dueOn: DateTime.parse(input['dueOn'] as String),
        sourceJobId: input['sourceJobId'] as String?,
        location: input['location'] as String?,
        paymentMethod: input['paymentMethod'] as String,
        pendingLineItem: input['itemEditor'] == null
            ? null
            : WorkItemsDraftInput.fromPayload(
                (input['itemEditor'] as Map).cast<String, Object?>(),
              ),
      );
}

class InvoiceDraftController
    extends DraftWorkflowController<InvoiceDraftInput> {
  InvoiceDraftController(
    DraftAutosaveSession session, {
    Future<WorkRecord?> Function(InvoiceDraftInput, LocalDraftCheckpoint, bool)?
    confirm,
    // Keep the callback private so callers use guarded confirmation.
    // ignore: prefer_initializing_formals
  }) : _confirm = confirm,
       super(
         session,
         (input) => input.toPayload(),
         InvoiceDraftInput.fromPayload,
       );

  final Future<WorkRecord?> Function(
    InvoiceDraftInput,
    LocalDraftCheckpoint,
    bool,
  )?
  _confirm;

  Future<WorkRecord?> confirm({bool issue = false}) async {
    final commit = _confirm;
    if (commit == null) {
      throw StateError('Invoice confirmation is unavailable.');
    }
    WorkRecord? result;
    await session.confirm((checkpoint) async {
      final input = recoveredInput;
      if (input == null) throw StateError('Invoice input is unavailable.');
      result = await commit(input, checkpoint, issue);
      return result != null;
    });
    return result;
  }
}
