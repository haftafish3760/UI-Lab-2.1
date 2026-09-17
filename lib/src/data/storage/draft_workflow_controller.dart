import 'draft_autosave_session.dart';
import 'local_record_command.dart';

/// A workflow's typed input boundary. Presentations supply values, never stored
/// payload keys; changing a form's layout does not change the persistence codec.
class DraftWorkflowController<T> {
  DraftWorkflowController(this.session, this._encode, this._decode);

  final DraftAutosaveSession session;
  final Map<String, Object?> Function(T) _encode;
  final T Function(Map<String, Object?>) _decode;

  T? get recoveredInput =>
      session.input.isEmpty ? null : _decode(session.input);

  /// Explicit workflow transitions may need to materialize new metadata even
  /// without a visible edit (for example a confirmation conflict baseline).
  /// Ordinary presentation recapture should use updateInput instead.
  void persistInputForTransition(T input) =>
      session.replaceInput(_encode(input));

  void updateInput(T input) {
    final encoded = _encode(input);
    final existing = session.input;
    // New optional fields may acquire defaults when an older draft is decoded.
    // Merely displaying those defaults must not rewrite its saved checkpoint.
    // Still go through replaceInput so lifecycle guards and failed-save retry
    // apply even when the typed input is unchanged.
    final unchanged =
        existing.isNotEmpty &&
        canonicalJson(_encode(_decode(existing))) == canonicalJson(encoded);
    session.replaceInput(unchanged ? existing : encoded);
  }
}
