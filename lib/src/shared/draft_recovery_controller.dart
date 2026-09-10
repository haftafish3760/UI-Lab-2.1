import 'package:flutter/foundation.dart';
import '../data/storage/draft_recovery_hub.dart';

/// Reusable recovery interaction state. Widgets supply presentation and route
/// dispatch; this controller owns refresh ordering, action exclusion and errors.
class DraftRecoveryController<T extends Object> extends ChangeNotifier {
  DraftRecoveryController(this._hub, {required this.releaseUnclaimed});
  final DraftRecoveryHub<T> _hub;
  final Future<void> Function(T) releaseUnclaimed;
  RecoveryHubListing<T>? _listing;
  RecoveryHubListing<T>? get listing => _listing;
  bool _loading = false;
  bool get isLoading => _loading;
  bool _acting = false;
  bool get isActing => _acting;
  bool get isBusy => _loading || _acting;
  String? _error;
  String? get error => _error;
  bool _disposed = false;
  int _generation = 0;

  Future<void> refresh() async {
    if (_disposed || _acting) return;
    final generation = ++_generation;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final next = await _hub.list();
      if (!_disposed && generation == _generation) _listing = next;
    } on Object {
      if (!_disposed && generation == _generation) {
        // A failed refresh can mean the owning session was invalidated. Do not
        // retain titles or actionable selections from that retired session.
        _listing = null;
        _error = 'Saved work could not be refreshed. Try again.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  bool _begin(RecoveryHubEntry<T> entry) {
    if (_disposed || isBusy || !(_listing?.entries.contains(entry) ?? false)) {
      return false;
    }
    _acting = true;
    _error = null;
    notifyListeners();
    return true;
  }

  /// The caller owns a returned workflow. If the view disappears while opening,
  /// releaseUnclaimed closes it without discarding any saved input.
  Future<T?> resume(RecoveryHubEntry<T> entry) async {
    if (!_begin(entry)) return null;
    try {
      final result = await _hub.resume(entry);
      if (_disposed) {
        await releaseUnclaimed(result);
        return null;
      }
      return result;
    } on Object {
      if (!_disposed) {
        _error =
            'Saved work could not be opened. Refresh to review its current state.';
      }
      return null;
    } finally {
      _end();
    }
  }

  /// Call only after the user's explicit discard decision. The list changes
  /// after acknowledgement; a failed discard retains the original selection.
  Future<bool> discard(RecoveryHubEntry<T> entry) async {
    if (!_begin(entry)) return false;
    try {
      await _hub.discard(entry);
      if (!_disposed) {
        _listing = RecoveryHubListing(
          entries: _listing!.entries.where(
            (candidate) => !identical(candidate, entry),
          ),
          unavailableProviders: _listing!.unavailableProviders,
        );
      }
      return true;
    } on Object {
      if (!_disposed) {
        _error = 'Saved work was not discarded. Refresh and try again.';
      }
      return false;
    } finally {
      _end();
    }
  }

  void _end() {
    _acting = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
