import '../storage/local_draft_checkpoint.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import 'models/work_contact_models.dart';
import 'work_contact_codec.dart';

/// Raw company workflow values, independent of visual field arrangement.
/// Persisted version-one keys are retained for backward-compatible recovery.
class CompanyDraftInput {
  const CompanyDraftInput({
    required this.baseProfile,
    required this.baseRevision,
    required this.logoLabel,
    this.logoReference = '',
    required this.name,
    required this.category,
    required this.phone,
    required this.email,
    required this.website,
    required this.address,
    this.addressParts = const {},
    required this.terms,
  });

  final WorkCompanyProfile baseProfile;
  final int baseRevision;
  final String logoLabel;
  final String logoReference;
  final String name;
  final String category;
  final String phone;
  final String email;
  final String website;
  final String address;
  final Map<String, String> addressParts;
  final String terms;

  WorkCompanyProfile confirmedProfile() {
    if (name.trim().isEmpty) {
      throw const FormatException('Enter the company name.');
    }
    if (baseRevision < 0) {
      throw const FormatException('Invalid company revision.');
    }
    return baseProfile.copyWith(
      companyName: name.trim(),
      businessCategory: category.trim(),
      phone: phone.trim(),
      email: email.trim(),
      website: website.trim(),
      address: address.trim(),
      addressParts: addressParts,
      logoLabel: logoLabel,
      logoReference: logoReference,
      defaultTerms: terms.trim(),
    );
  }

  Map<String, Object?> toPayload() => {
    'baseProfile': encodeWorkCompanyProfile(baseProfile),
    'baseRevision': baseRevision,
    'logoLabel': logoLabel,
    'logoReference': logoReference,
    'name': name,
    'category': category,
    'phone': phone,
    'email': email,
    'website': website,
    'address': address,
    'addressParts': addressParts,
    'terms': terms,
  };

  factory CompanyDraftInput.fromPayload(Map<String, Object?> input) =>
      CompanyDraftInput(
        baseProfile: decodeWorkCompanyProfile(
          (input['baseProfile'] as Map).cast<String, Object?>(),
        ),
        baseRevision: input['baseRevision'] as int,
        logoLabel: input['logoLabel'] as String,
        logoReference:
            input['logoReference'] as String? ??
            (input['baseProfile'] as Map)['logoReference'] as String? ??
            '',
        name: input['name'] as String,
        category: input['category'] as String,
        phone: input['phone'] as String,
        email: input['email'] as String,
        website: input['website'] as String,
        address: input['address'] as String,
        addressParts: Map.unmodifiable(
          (input['addressParts'] as Map? ?? const {}).cast<String, String>(),
        ),
        terms: input['terms'] as String,
      );
}

class CompanyDraftController
    extends DraftWorkflowController<CompanyDraftInput> {
  CompanyDraftController(
    DraftAutosaveSession session, {
    Future<bool> Function(
      WorkCompanyProfile,
      CompanyDraftInput,
      LocalDraftCheckpoint,
    )?
    confirm,
    // Keep the transaction callback private; presentations use guarded confirm().
    // ignore: prefer_initializing_formals
  }) : _confirm = confirm,
       super(
         session,
         (input) => input.toPayload(),
         CompanyDraftInput.fromPayload,
       );

  final Future<bool> Function(
    WorkCompanyProfile,
    CompanyDraftInput,
    LocalDraftCheckpoint,
  )?
  _confirm;

  Future<WorkCompanyProfile?> confirm() async {
    final commit = _confirm;
    if (commit == null) {
      throw StateError('This workflow has no confirmation service.');
    }
    WorkCompanyProfile? confirmed;
    final saved = await session.confirm((checkpoint) async {
      final input = recoveredInput;
      if (input == null) throw StateError('There is no saved profile input.');
      final profile = input.confirmedProfile();
      final saved = await commit(profile, input, checkpoint);
      if (saved) confirmed = profile;
      return saved;
    });
    return saved ? confirmed : null;
  }
}
