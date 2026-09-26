import 'work_items_draft_input.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import 'models/work_models.dart';
import 'work_record_codec.dart';
import 'work_record_detail_codec.dart';

/// Unfinished job work, independent of controllers, widgets and routes.
/// Version-one wire names remain stable for drafts saved by earlier screens.
class JobDraftInput {
  const JobDraftInput({
    required this.jobId,
    required this.number,
    this.purchaseOrderNumber = '',
    this.assignedEmployeeIds = const [],
    required this.sourceEstimate,
    required this.sourceStorageRevision,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.scheduleBufferMinutes = 30,
    required this.client,
    required this.location,
    required this.assignee,
    required this.vehicle,
    required this.pricing,
    required this.items,
    required this.pendingLineItem,
    required this.title,
    required this.scope,
    required this.notes,
  });

  final String jobId;
  final String number;
  final String purchaseOrderNumber;
  final List<String> assignedEmployeeIds;
  final WorkRecord? sourceEstimate;
  final int sourceStorageRevision;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final int scheduleBufferMinutes;
  final String? client;
  final String? location;
  final String? assignee;
  final String? vehicle;
  final WorkPricingModel pricing;
  final List<WorkLineItem> items;
  final WorkItemsDraftInput? pendingLineItem;
  final String title;
  final String scope;
  final String notes;

  Map<String, Object?> toPayload() => {
    'jobId': jobId,
    'number': number,
    'purchaseOrderNumber': purchaseOrderNumber,
    'assignedEmployeeIds': assignedEmployeeIds,
    'source': sourceEstimate == null ? null : encodeWorkRecord(sourceEstimate!),
    'sourceStorageRevision': sourceStorageRevision,
    'start': scheduledStart.toIso8601String(),
    'end': scheduledEnd.toIso8601String(),
    'scheduleBufferMinutes': scheduleBufferMinutes,
    'client': client,
    'location': location,
    'assignee': assignee,
    'vehicle': vehicle,
    'pricing': pricing.name,
    'items': items.map(encodeWorkLineItem).toList(),
    'itemEditor': pendingLineItem?.toPayload(),
    'title': title,
    'scope': scope,
    'notes': notes,
  };

  factory JobDraftInput.fromPayload(Map<String, Object?> input) =>
      JobDraftInput(
        jobId: input['jobId'] as String,
        number: input['number'] as String,
        purchaseOrderNumber: input['purchaseOrderNumber'] as String? ?? '',
        assignedEmployeeIds:
            (input['assignedEmployeeIds'] as List?)?.cast<String>() ?? const [],
        sourceEstimate: input['source'] == null
            ? null
            : decodeWorkRecord(
                (input['source'] as Map).cast<String, Object?>(),
              ),
        sourceStorageRevision: input['sourceStorageRevision'] as int,
        scheduledStart: DateTime.parse(input['start'] as String),
        scheduledEnd: DateTime.parse(input['end'] as String),
        scheduleBufferMinutes: input['scheduleBufferMinutes'] as int? ?? 30,
        client: input['client'] as String?,
        location: input['location'] as String?,
        assignee: input['assignee'] as String?,
        vehicle: input['vehicle'] as String?,
        pricing: WorkPricingModel.values.byName(input['pricing'] as String),
        items: (input['items'] as List)
            .map(
              (item) =>
                  decodeWorkLineItem((item as Map).cast<String, Object?>()),
            )
            .toList(),
        pendingLineItem: input['itemEditor'] == null
            ? null
            : WorkItemsDraftInput.fromPayload(
                (input['itemEditor'] as Map).cast<String, Object?>(),
              ),
        title: input['title'] as String,
        scope: input['scope'] as String,
        notes: input['notes'] as String,
      );
}

class JobDraftController extends DraftWorkflowController<JobDraftInput> {
  JobDraftController(
    DraftAutosaveSession session, {
    Future<WorkRecord?> Function(JobDraftInput, LocalDraftCheckpoint)? confirm,
    // Keep the callback private so callers use guarded confirmation.
    // ignore: prefer_initializing_formals
  }) : _confirm = confirm,
       super(session, (input) => input.toPayload(), JobDraftInput.fromPayload);

  final Future<WorkRecord?> Function(JobDraftInput, LocalDraftCheckpoint)?
  _confirm;

  Future<WorkRecord?> confirm() async {
    final commit = _confirm;
    if (commit == null) throw StateError('Job confirmation is unavailable.');
    WorkRecord? result;
    await session.confirm((checkpoint) async {
      final input = recoveredInput;
      if (input == null) throw StateError('Job input is unavailable.');
      result = await commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}
