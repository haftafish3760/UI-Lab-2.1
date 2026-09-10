import '../storage/local_draft_checkpoint.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import 'models/work_contact_models.dart';
import 'work_contact_codec.dart';

/// Unfinished customer work, independent of controllers, widgets and routes.
/// Version-one wire names remain stable for drafts saved by earlier screens.
class CustomerDraftInput {
  const CustomerDraftInput({
    required this.customerId,
    required this.existingCustomer,
    required this.baseRevision,
    required this.preferredContact,
    required this.name,
    required this.company,
    required this.phone,
    required this.email,
    required this.billing,
    required this.notes,
    required this.locationLabel,
    required this.locationAddress,
    required this.accessNotes,
  });

  final String customerId;
  final WorkCustomerProfile? existingCustomer;
  final int baseRevision;
  final String preferredContact;
  final String name;
  final String company;
  final String phone;
  final String email;
  final String billing;
  final String notes;
  final String locationLabel;
  final String locationAddress;
  final String accessNotes;

  Map<String, Object?> toPayload() => {
    'customerId': customerId,
    'existingCustomer': existingCustomer == null
        ? null
        : encodeWorkCustomerProfile(existingCustomer!),
    'baseRevision': baseRevision,
    'preferredContact': preferredContact,
    'name': name,
    'company': company,
    'phone': phone,
    'email': email,
    'billing': billing,
    'notes': notes,
    'locationLabel': locationLabel,
    'locationAddress': locationAddress,
    'accessNotes': accessNotes,
  };

  factory CustomerDraftInput.fromPayload(Map<String, Object?> input) =>
      CustomerDraftInput(
        customerId: input['customerId'] as String,
        existingCustomer: input['existingCustomer'] == null
            ? null
            : decodeWorkCustomerProfile(
                (input['existingCustomer'] as Map).cast<String, Object?>(),
              ),
        baseRevision: input['baseRevision'] as int,
        preferredContact: input['preferredContact'] as String,
        name: input['name'] as String,
        company: input['company'] as String,
        phone: input['phone'] as String,
        email: input['email'] as String,
        billing: input['billing'] as String,
        notes: input['notes'] as String,
        locationLabel: input['locationLabel'] as String,
        locationAddress: input['locationAddress'] as String,
        accessNotes: input['accessNotes'] as String,
      );
}

class CustomerDraftController
    extends DraftWorkflowController<CustomerDraftInput> {
  CustomerDraftController(
    DraftAutosaveSession session, {
    Future<WorkCustomerProfile?> Function(
      CustomerDraftInput,
      LocalDraftCheckpoint,
    )?
    confirm,
    // Keep the callback private so callers use guarded confirmation.
    // ignore: prefer_initializing_formals
  }) : _confirm = confirm,
       super(
         session,
         (input) => input.toPayload(),
         CustomerDraftInput.fromPayload,
       );

  final Future<WorkCustomerProfile?> Function(
    CustomerDraftInput,
    LocalDraftCheckpoint,
  )?
  _confirm;

  Future<WorkCustomerProfile?> confirm() async {
    final commit = _confirm;
    if (commit == null) {
      throw StateError('Client confirmation is unavailable.');
    }
    WorkCustomerProfile? result;
    await session.confirm((checkpoint) async {
      final input = recoveredInput;
      if (input == null) throw StateError('Client input is unavailable.');
      result = await commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}
