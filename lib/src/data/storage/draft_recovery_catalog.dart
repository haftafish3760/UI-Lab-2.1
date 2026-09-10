import 'draft_recovery_selection.dart';
import 'draft_repository.dart';
import 'local_record_command.dart';

enum DraftRecoveryAvailability {
  recoverable,
  parentUnavailable,
  conflict,
  unreadable,
  unavailable,
}

/// Domain result, with stable record identity rather than a route/widget key.
class DraftRecoveryPreview {
  const DraftRecoveryPreview({
    required this.title,
    this.availability = DraftRecoveryAvailability.recoverable,
    this.recordId,
  });
  final String title;
  final DraftRecoveryAvailability availability;
  final String? recordId;
}

/// Installed by application/domain services. Access must reflect current
/// authority; these callbacks are not production authentication by themselves.
class DraftRecoveryHandler {
  const DraftRecoveryHandler({
    required this.domain,
    required this.workflowLabel,
    required this.canList,
    required this.inspect,
    required this.canDiscard,
  }) : inspectSelection = null;

  const DraftRecoveryHandler.withSelection({
    required this.domain,
    required this.workflowLabel,
    required this.canList,
    required this.inspectSelection,
    required this.canDiscard,
  }) : inspect = null;
  final String domain;
  final String workflowLabel;
  final bool Function() canList;

  /// Null hides input the actor can no longer access at the record boundary.
  final Future<DraftRecoveryPreview?> Function(Map<String, Object?> input)?
  inspect;
  final Future<DraftRecoveryPreview?> Function(
    DraftRecoverySelection selection,
    Map<String, Object?> input,
  )?
  inspectSelection;
  final Future<bool> Function(DraftRecoveryPreview preview) canDiscard;
}

/// Presentation-safe catalog entry. No payload, database row, or SQL is exposed.
class DraftRecoveryEntry {
  const DraftRecoveryEntry._(
    this._catalog,
    this.domain,
    this.draftId,
    this.revision,
    this.updatedAt,
    this.workflowLabel,
    this.preview,
  );
  final Object _catalog;
  final String domain;
  final String draftId;
  final int revision;
  final DateTime updatedAt;
  final String workflowLabel;
  final DraftRecoveryPreview preview;
}

/// Cross-workflow discovery and explicit discard, independent of navigation.
/// Opening an editor remains the owning workflow's authorized factory operation.
class DraftRecoveryCatalog {
  factory DraftRecoveryCatalog({
    required DraftRepository repository,
    required String organizationId,
    required String ownerId,
    required Iterable<DraftRecoveryHandler> handlers,
  }) {
    final registered = handlers.toList(growable: false);
    final byDomain = {
      for (final handler in registered) handler.domain: handler,
    };
    if (organizationId.trim().isEmpty ||
        ownerId.trim().isEmpty ||
        byDomain.length != registered.length ||
        byDomain.keys.any((domain) => domain.trim().isEmpty)) {
      throw ArgumentError(
        'Recovery requires scoped identities and unique workflow handlers.',
      );
    }
    return DraftRecoveryCatalog._(
      repository,
      organizationId,
      ownerId,
      Map.unmodifiable(byDomain),
    );
  }
  DraftRecoveryCatalog._(
    this._repository,
    this._organizationId,
    this._ownerId,
    this._handlers,
  );
  final DraftRepository _repository;
  final String _organizationId;
  final String _ownerId;
  final Map<String, DraftRecoveryHandler> _handlers;
  final Object _identity = Object();

  Future<List<DraftRecoveryEntry>> list() async {
    final domains = {
      for (final handler in _handlers.values)
        if (handler.canList()) handler.domain,
    };
    final saved = await _repository.listOwned(
      organizationId: _organizationId,
      ownerId: _ownerId,
      domains: domains,
    );
    final entries = <DraftRecoveryEntry>[];
    for (final draft in saved) {
      final entry = await _inspect(draft);
      if (entry != null) entries.add(entry);
    }
    return List.unmodifiable(entries);
  }

  Future<DraftRecoveryEntry?> _inspect(SavedDraft draft) async {
    if (draft.organizationId != _organizationId || draft.ownerId != _ownerId) {
      throw StateError(
        'Recovery repository returned input outside the requested scope.',
      );
    }
    final handler = _handlers[draft.domain];
    if (handler == null || !handler.canList()) return null;
    Map<String, Object?>? input;
    DraftRecoveryPreview? preview;
    try {
      input = _repository.decode(draft);
    } on Object {
      preview = const DraftRecoveryPreview(
        title: 'Saved input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    if (input != null) {
      try {
        final inspectSelection = handler.inspectSelection;
        preview = inspectSelection == null
            ? await handler.inspect!(input)
            : await inspectSelection(
                DraftRecoverySelection(
                  domain: draft.domain,
                  draftId: draft.draftId,
                  revision: draft.revision,
                ),
                input,
              );
      } on Object {
        preview = const DraftRecoveryPreview(
          title: 'Recovery temporarily unavailable — input preserved',
          availability: DraftRecoveryAvailability.unavailable,
        );
      }
    }
    if (preview == null || !handler.canList()) return null;
    return DraftRecoveryEntry._(
      _identity,
      draft.domain,
      draft.draftId,
      draft.revision,
      DateTime.fromMicrosecondsSinceEpoch(draft.updatedAtUs, isUtc: true),
      handler.workflowLabel,
      preview,
    );
  }

  /// Revalidate after selection; callers must refresh instead of acting on an
  /// entry whose saved revision has changed while another editor was active.
  Future<DraftRecoveryEntry> refresh(DraftRecoveryEntry entry) async {
    if (!identical(entry._catalog, _identity)) {
      throw StateError('Recovery entry belongs to another catalog.');
    }
    final handler = _handlers[entry.domain];
    if (handler == null || !handler.canList()) {
      throw StateError('Recovery access is unavailable.');
    }
    final saved = await _repository.find(
      organizationId: _organizationId,
      ownerId: _ownerId,
      domain: entry.domain,
      draftId: entry.draftId,
    );
    if (saved == null || saved.revision != entry.revision) {
      throw const LocalRecordConflict(
        'Saved input changed; refresh the recovery list.',
      );
    }
    final current = await _inspect(saved);
    if (current == null) throw StateError('Recovery access is unavailable.');
    return current;
  }

  Future<void> discard(DraftRecoveryEntry entry) async {
    final current = await refresh(entry);
    final handler = _handlers[current.domain]!;
    if (!await handler.canDiscard(current.preview) || !handler.canList()) {
      throw StateError('Discarding this saved input is unavailable.');
    }
    final consumed = await _repository.consumeIfUnchanged(
      organizationId: _organizationId,
      ownerId: _ownerId,
      domain: current.domain,
      draftId: current.draftId,
      expectedRevision: current.revision,
    );
    if (!consumed) {
      throw const LocalRecordConflict(
        'Saved input changed; refresh before discarding.',
      );
    }
  }
}
