import 'draft_autosave_session.dart';

/// A workflow's typed input boundary. Presentations supply values, never stored
/// payload keys; changing a form's layout does not change the persistence codec.
class DraftWorkflowController<T> {
  DraftWorkflowController(this.session, this._encode, this._decode);

  final DraftAutosaveSession session;
  final Map<String, Object?> Function(T) _encode;
  final T Function(Map<String, Object?>) _decode;

  T? get recoveredInput =>
      session.input.isEmpty ? null : _decode(session.input);

  void updateInput(T input) => session.replaceInput(_encode(input));
}
