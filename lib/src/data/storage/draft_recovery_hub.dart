import 'draft_recovery_catalog.dart';

/// Adapter around an owning workflow service. Its resume/discard callbacks must
/// retain that service's current authorization and exact-revision checks.
class DraftRecoveryProvider<T extends Object> {
  const DraftRecoveryProvider({
    required this.id,
    required this.label,
    required this.list,
    required this.resume,
    required this.discard,
  });
  final String id, label;
  final Future<List<DraftRecoveryEntry>> Function() list;
  final Future<T> Function(DraftRecoveryEntry) resume;
  final Future<void> Function(DraftRecoveryEntry) discard;
}

/// Carries the original service-owned selection internally. Rebuilding a screen
/// never reconstructs a selection from a title, list position or widget key.
class RecoveryHubEntry<T extends Object> {
  const RecoveryHubEntry._(this._hub, this._provider, this._entry);
  final Object _hub;
  final DraftRecoveryProvider<T> _provider;
  final DraftRecoveryEntry _entry;
  String get providerId => _provider.id;
  String get workflowLabel => _entry.workflowLabel;
  String get title => _entry.preview.title;
  DateTime get updatedAt => _entry.updatedAt;
  DraftRecoveryAvailability get availability => _entry.preview.availability;
}

class RecoveryProviderFailure {
  const RecoveryProviderFailure(this.providerId, this.label);
  final String providerId, label;
}

/// A failed provider is explicit: a partial result is never an empty-success
/// claim that the user has no remaining work. Exceptions/payloads are not exposed.
class RecoveryHubListing<T extends Object> {
  RecoveryHubListing({
    required Iterable<RecoveryHubEntry<T>> entries,
    required Iterable<RecoveryProviderFailure> unavailableProviders,
  }) : entries = List.unmodifiable(entries),
       unavailableProviders = List.unmodifiable(unavailableProviders);
  final List<RecoveryHubEntry<T>> entries;
  final List<RecoveryProviderFailure> unavailableProviders;
  bool get isComplete => unavailableProviders.isEmpty;
}

/// Aggregates catalogs without moving entries into a different catalog, losing
/// owner scope, or bypassing domain-specific recovery checks. T is the caller's
/// typed workflow result, not a route or database row.
class DraftRecoveryHub<T extends Object> {
  DraftRecoveryHub(Iterable<DraftRecoveryProvider<T>> providers)
    : _providers = List.unmodifiable(providers) {
    final ids = _providers.map((provider) => provider.id).toSet();
    if (ids.length != _providers.length || ids.any((id) => id.trim().isEmpty)) {
      throw ArgumentError('Recovery provider identities must be unique.');
    }
  }
  final List<DraftRecoveryProvider<T>> _providers;
  final Object _identity = Object();
  bool _active = true;
  void invalidate() => _active = false;
  void _requireActive() {
    if (!_active) throw StateError('Recovery session is no longer active.');
  }

  Future<RecoveryHubListing<T>> list() async {
    _requireActive();
    final results = await Future.wait(
      _providers.map((provider) async {
        try {
          final entries = await provider.list();
          return RecoveryHubListing<T>(
            entries: entries.map(
              (entry) => RecoveryHubEntry._(_identity, provider, entry),
            ),
            unavailableProviders: const [],
          );
        } on Object {
          return RecoveryHubListing<T>(
            entries: const [],
            unavailableProviders: [
              RecoveryProviderFailure(provider.id, provider.label),
            ],
          );
        }
      }),
    );
    _requireActive();
    final entries = results.expand((result) => result.entries).toList()
      ..sort((a, b) {
        final time = b.updatedAt.compareTo(a.updatedAt);
        if (time != 0) return time;
        final provider = a.providerId.compareTo(b.providerId);
        if (provider != 0) return provider;
        final domain = a._entry.domain.compareTo(b._entry.domain);
        return domain != 0
            ? domain
            : a._entry.draftId.compareTo(b._entry.draftId);
      });
    return RecoveryHubListing(
      entries: entries,
      unavailableProviders: results.expand(
        (result) => result.unavailableProviders,
      ),
    );
  }

  void _requireOwnEntry(RecoveryHubEntry<T> entry) {
    _requireActive();
    if (!identical(entry._hub, _identity)) {
      throw StateError('Recovery selection belongs to another session.');
    }
  }

  Future<T> resume(RecoveryHubEntry<T> entry) async {
    _requireOwnEntry(entry);
    return entry._provider.resume(entry._entry);
  }

  Future<void> discard(RecoveryHubEntry<T> entry) async {
    _requireOwnEntry(entry);
    await entry._provider.discard(entry._entry);
  }
}
