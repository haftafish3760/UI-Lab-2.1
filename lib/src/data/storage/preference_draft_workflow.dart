import 'preference_draft_baseline.dart';
import 'draft_recovery_selection.dart';
import 'app_preferences_repository.dart';
import 'draft_autosave_session.dart';
import 'draft_workflow_controller.dart';
import 'local_draft_checkpoint.dart';

/// Reusable typed settings input; the owning controller defines the codec and
/// confirmed preference command. Widgets never construct storage checkpoints.
class PreferenceDraftWorkflow<T> extends DraftWorkflowController<T> {
  PreferenceDraftWorkflow._(
    super.session,
    super.encode,
    super.decode,
    this._confirm,
    this._repository,
  );

  final Future<bool> Function(T, LocalDraftCheckpoint) _confirm;
  final AppPreferencesRepository _repository;

  /// A recovered workflow must stay with the repository that owns its pending
  /// confirmation. Device identity alone cannot distinguish replaced stores.
  void validateHandoff({
    required AppPreferencesRepository repository,
    required String domain,
    required String draftId,
  }) {
    if (!identical(repository, _repository) ||
        session.domain != domain ||
        session.draftId != draftId) {
      throw StateError(
        'Settings recovery belongs to another workflow or store.',
      );
    }
  }

  T get input => recoveredInput as T;

  Future<bool> confirm() {
    // Legacy input stays byte-for-byte unchanged on open. An explicit confirm
    // first persists its baseline; changes since opening still cannot be lost.
    if (!session.input.containsKey(PreferenceDraftBaseline.payloadKey)) {
      updateInput(input);
    }
    return session.confirm((checkpoint) => _confirm(input, checkpoint));
  }

  static Future<PreferenceDraftWorkflow<T>> open<T>({
    required AppPreferencesRepository repository,
    required String domain,
    required String draftId,
    required T initial,
    DraftRecoverySelection? recoverySelection,
    required Map<String, Object?> Function(T) encode,
    required T Function(Map<String, Object?>) decode,
    required Future<bool> Function(T, LocalDraftCheckpoint) confirm,
  }) async {
    final session = DraftAutosaveSession(
      store: repository.drafts,
      organizationId: 'device',
      ownerId: 'device',
      domain: domain,
      draftId: draftId,
    );
    try {
      await session.initialize();
      recoverySelection?.verify(
        openedDomain: session.domain,
        openedDraftId: session.draftId,
        openedRevision: session.savedRevision,
        hasInput: session.input.isNotEmpty,
      );
      final baseline =
          session.input.containsKey(PreferenceDraftBaseline.payloadKey)
          ? PreferenceDraftBaseline.decode(
              session.input[PreferenceDraftBaseline.payloadKey],
              domain,
              draftId,
            )
          : PreferenceDraftBaseline.capture(repository.values, domain, draftId);
      final workflow = PreferenceDraftWorkflow<T>._(
        session,
        (value) => {
          ...encode(value),
          PreferenceDraftBaseline.payloadKey: baseline,
        },
        decode,
        confirm,
        repository,
      );
      if (session.input.isEmpty) {
        workflow.updateInput(initial);
      } else {
        // Decode before exposing editing so unreadable input is never replaced.
        workflow.input;
      }
      return workflow;
    } on Object {
      await session.close().catchError((Object _) {});
      rethrow;
    }
  }
}
