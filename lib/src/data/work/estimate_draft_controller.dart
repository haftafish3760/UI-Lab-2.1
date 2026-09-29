import 'models/work_contact_models.dart';
import 'work_contact_codec.dart';
import 'work_items_draft_input.dart';
import 'estimate_photos_draft_input.dart';
import '../storage/local_draft_checkpoint.dart';
import 'models/work_models.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import 'work_record_detail_codec.dart';
import 'work_record_codec.dart';

/// Raw estimate work, including incomplete numbers and nested unfinished input.
/// Legacy payload names below remain stable regardless of screen composition.
class EstimateDraftInput {
  const EstimateDraftInput({
    this.documentKind = WorkRecordKind.estimate,
    required this.creatorId,
    required this.number,
    this.purchaseOrderNumber = '',
    required this.baseStorageRevision,
    required this.title,
    required this.discount,
    required this.tax,
    required this.terms,
    this.requiresDeposit = false,
    this.depositAmount = '',
    required this.client,
    this.customerSnapshot,
    required this.pricing,
    this.documentPresentation = WorkDocumentPresentation.detailed,
    required this.template,
    required this.createdOn,
    required this.items,
    this.servicePrice = '',
    required this.baseRecord,
    required this.estimateId,
    required this.scope,
    required this.expiresOn,
    required this.followUpOn,
    required this.proposedServiceOn,
    required this.pendingLineItems,
    required this.pendingPhotos,
    required this.sitePhotos,
  });

  final WorkRecordKind documentKind;
  final String creatorId;
  final String number;
  final String purchaseOrderNumber;
  final int baseStorageRevision;
  final String title;
  final String discount;
  final String tax;
  final String terms;
  final bool requiresDeposit;
  final String depositAmount;
  final String? client;
  final WorkCustomerProfile? customerSnapshot;
  final WorkPricingModel pricing;
  final WorkDocumentPresentation documentPresentation;
  final String template;
  final DateTime createdOn;
  final List<WorkLineItem> items;
  final String servicePrice;
  final WorkRecord? baseRecord;
  final String estimateId;
  final String scope;
  final DateTime? expiresOn;
  final DateTime? followUpOn;
  final DateTime? proposedServiceOn;
  final Map<String, WorkItemsDraftInput> pendingLineItems;
  final EstimatePhotosDraftInput? pendingPhotos;
  final List<WorkSitePhoto> sitePhotos;

  Map<String, Object?> toPayload() => {
    'documentKind': documentKind.name,
    'creatorId': creatorId,
    'number': number,
    'purchaseOrderNumber': purchaseOrderNumber,
    'baseStorageRevision': baseStorageRevision,
    'title': title,
    'discount': discount,
    'tax': tax,
    'terms': terms,
    'requiresDeposit': requiresDeposit,
    'depositAmount': depositAmount,
    'client': client,
    'customerSnapshot': customerSnapshot == null
        ? null
        : encodeWorkCustomerProfile(customerSnapshot!),
    'pricing': pricing.name,
    'documentPresentation': documentPresentation.name,
    'template': template,
    'createdOn': createdOn.toIso8601String(),
    'items': items.map(encodeWorkLineItem).toList(),
    'servicePrice': servicePrice,
    'baseRecord': baseRecord == null ? null : encodeWorkRecord(baseRecord!),
    'estimateId': estimateId,
    'scope': scope,
    'expiresOn': expiresOn?.toIso8601String(),
    'followUpOn': followUpOn?.toIso8601String(),
    'proposedServiceOn': proposedServiceOn?.toIso8601String(),
    'itemEditors': pendingLineItems.map(
      (key, value) => MapEntry(key, value.toPayload()),
    ),
    'photoEditor': pendingPhotos?.toPayload(),
    'sitePhotos': sitePhotos.map(encodeWorkSitePhoto).toList(),
  };

  factory EstimateDraftInput.fromPayload(Map<String, Object?> input) =>
      EstimateDraftInput(
        documentKind: WorkRecordKind.values.byName(
          input['documentKind'] as String? ?? 'estimate',
        ),
        creatorId: input['creatorId'] as String,
        number: input['number'] as String,
        purchaseOrderNumber: input['purchaseOrderNumber'] as String? ?? '',
        baseStorageRevision: input['baseStorageRevision'] as int,
        title: input['title'] as String,
        discount: input['discount'] as String,
        tax: input['tax'] as String,
        terms: input['terms'] as String,
        requiresDeposit: input['requiresDeposit'] as bool? ?? false,
        depositAmount: input['depositAmount'] as String? ?? '',
        client: input['client'] as String?,
        customerSnapshot: input['customerSnapshot'] == null
            ? null
            : decodeWorkCustomerProfile(
                (input['customerSnapshot'] as Map).cast<String, Object?>(),
              ),
        pricing: WorkPricingModel.values.byName(input['pricing'] as String),
        documentPresentation: WorkDocumentPresentation.values.byName(
          input['documentPresentation'] as String? ?? 'detailed',
        ),
        template: input['template'] as String,
        createdOn: DateTime.parse(input['createdOn'] as String),
        servicePrice: input['servicePrice'] as String? ?? '',
        items: (input['items'] as List)
            .map(
              (item) =>
                  decodeWorkLineItem((item as Map).cast<String, Object?>()),
            )
            .toList(),
        baseRecord: input['baseRecord'] == null
            ? null
            : decodeWorkRecord(
                (input['baseRecord'] as Map).cast<String, Object?>(),
              ),
        estimateId: input['estimateId'] as String,
        scope: input['scope'] as String,
        expiresOn: DateTime.tryParse(input['expiresOn'] as String? ?? ''),
        followUpOn: DateTime.tryParse(input['followUpOn'] as String? ?? ''),
        proposedServiceOn: DateTime.tryParse(
          input['proposedServiceOn'] as String? ?? '',
        ),
        pendingLineItems: (input['itemEditors'] as Map? ?? {}).map(
          (key, value) => MapEntry(
            key as String,
            WorkItemsDraftInput.fromPayload(
              (value as Map).cast<String, Object?>(),
            ),
          ),
        ),
        pendingPhotos: input['photoEditor'] == null
            ? null
            : EstimatePhotosDraftInput.fromPayload(
                (input['photoEditor'] as Map).cast<String, Object?>(),
              ),
        sitePhotos: (input['sitePhotos'] as List)
            .map(
              (item) =>
                  decodeWorkSitePhoto((item as Map).cast<String, Object?>()),
            )
            .toList(),
      );
}

class EstimateDraftController
    extends DraftWorkflowController<EstimateDraftInput> {
  EstimateDraftController(
    DraftAutosaveSession session, {
    Future<WorkRecord?> Function(EstimateDraftInput, LocalDraftCheckpoint)?
    confirm,
    // Keep the callback private so callers use guarded confirmation.
    // ignore: prefer_initializing_formals
  }) : _confirm = confirm,
       super(
         session,
         (input) => input.toPayload(),
         EstimateDraftInput.fromPayload,
       );

  final Future<WorkRecord?> Function(EstimateDraftInput, LocalDraftCheckpoint)?
  _confirm;

  Future<WorkRecord?> confirm() async {
    final commit = _confirm;
    if (commit == null) {
      throw StateError('Estimate confirmation is unavailable.');
    }
    WorkRecord? result;
    await session.confirm((checkpoint) async {
      final input = recoveredInput;
      if (input == null) throw StateError('Estimate input is unavailable.');
      result = await commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}
