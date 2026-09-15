import 'receipt_entry_setup.dart';
import 'package:flutter/foundation.dart';
import 'receipt_selected_details.dart';
import 'receipt_item_read.dart';

const _unchangedReceiptDraftValue = Object();

enum ReceiptDraftEvidenceKind { photo, pdf }

enum ReceiptDraftEvidenceState { active, removed }

enum ReceiptDraftState { inProgress, submitted, discarded }

enum ReceiptDraftAuditAction { created, updated, submitted, discarded }

@immutable
class ReceiptDraftEvidence {
  ReceiptDraftEvidence({
    required this.evidenceId,
    required this.originalName,
    required this.kind,
    required this.localPath,
    required this.sha256,
    required this.byteLength,
    required this.order,
    this.state = ReceiptDraftEvidenceState.active,
    DateTime? removedAtUtc,
  }) : removedAtUtc = removedAtUtc?.toUtc() {
    _requireText(evidenceId, 'evidenceId');
    _requireText(originalName, 'originalName');
    _requireText(localPath, 'localPath');
    _requireText(sha256, 'sha256');
    if (byteLength < 1) {
      throw ArgumentError.value(byteLength, 'byteLength', 'Must be positive.');
    }
    if (order < 0) {
      throw ArgumentError.value(order, 'order', 'Cannot be negative.');
    }
    if ((state == ReceiptDraftEvidenceState.removed) !=
        (this.removedAtUtc != null)) {
      throw const FormatException(
        'Removed receipt evidence must retain its removal time.',
      );
    }
  }

  final String evidenceId;
  final String originalName;
  final ReceiptDraftEvidenceKind kind;
  final String localPath;
  final String sha256;
  final int byteLength;
  final int order;
  final ReceiptDraftEvidenceState state;
  final DateTime? removedAtUtc;

  bool get isActive => state == ReceiptDraftEvidenceState.active;

  ReceiptDraftEvidence copyWith({
    int? order,
    ReceiptDraftEvidenceState? state,
    Object? removedAtUtc = _unchangedReceiptDraftValue,
  }) => ReceiptDraftEvidence(
    evidenceId: evidenceId,
    originalName: originalName,
    kind: kind,
    localPath: localPath,
    sha256: sha256,
    byteLength: byteLength,
    order: order ?? this.order,
    state: state ?? this.state,
    removedAtUtc: identical(removedAtUtc, _unchangedReceiptDraftValue)
        ? this.removedAtUtc
        : removedAtUtc as DateTime?,
  );

  Map<String, Object?> toJson() => {
    'evidenceId': evidenceId,
    'originalName': originalName,
    'kind': kind.name,
    'localPath': localPath,
    'sha256': sha256,
    'byteLength': byteLength,
    'order': order,
    'state': state.name,
    'removedAtUtc': removedAtUtc?.toIso8601String(),
  };

  factory ReceiptDraftEvidence.fromJson(Map<String, Object?> json) =>
      ReceiptDraftEvidence(
        evidenceId: _requiredString(json, 'evidenceId'),
        originalName: _requiredString(json, 'originalName'),
        kind: ReceiptDraftEvidenceKind.values.byName(
          _requiredString(json, 'kind'),
        ),
        localPath: _requiredString(json, 'localPath'),
        sha256: _requiredString(json, 'sha256'),
        byteLength: _requiredInt(json, 'byteLength'),
        order: _requiredInt(json, 'order'),
        state: ReceiptDraftEvidenceState.values.byName(
          _requiredString(json, 'state'),
        ),
        removedAtUtc: _optionalUtc(json, 'removedAtUtc'),
      );
}

@immutable
class ReceiptDraftLifecycle {
  ReceiptDraftLifecycle({
    required this.revision,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) : createdAtUtc = createdAtUtc.toUtc(),
       updatedAtUtc = updatedAtUtc.toUtc() {
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'Must be positive.');
    }
  }

  final int revision;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  ReceiptDraftLifecycle next(DateTime occurredAtUtc) => ReceiptDraftLifecycle(
    revision: revision + 1,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: occurredAtUtc,
  );

  Map<String, Object?> toJson() => {
    'revision': revision,
    'createdAtUtc': createdAtUtc.toIso8601String(),
    'updatedAtUtc': updatedAtUtc.toIso8601String(),
  };

  factory ReceiptDraftLifecycle.fromJson(Map<String, Object?> json) =>
      ReceiptDraftLifecycle(
        revision: _requiredInt(json, 'revision'),
        createdAtUtc: _requiredUtc(json, 'createdAtUtc'),
        updatedAtUtc: _requiredUtc(json, 'updatedAtUtc'),
      );
}

@immutable
class ReceiptDraftAuditEvent {
  ReceiptDraftAuditEvent({
    required this.action,
    required this.actorEmployeeId,
    required this.permissionRevision,
    required DateTime occurredAtUtc,
    required this.toRevision,
    this.fromRevision,
  }) : occurredAtUtc = occurredAtUtc.toUtc() {
    _requireText(actorEmployeeId, 'actorEmployeeId');
    _requireText(permissionRevision, 'permissionRevision');
  }

  final ReceiptDraftAuditAction action;
  final String actorEmployeeId;
  final String permissionRevision;
  final DateTime occurredAtUtc;
  final int? fromRevision;
  final int toRevision;

  Map<String, Object?> toJson() => {
    'action': action.name,
    'actorEmployeeId': actorEmployeeId,
    'permissionRevision': permissionRevision,
    'occurredAtUtc': occurredAtUtc.toIso8601String(),
    'fromRevision': fromRevision,
    'toRevision': toRevision,
  };

  factory ReceiptDraftAuditEvent.fromJson(Map<String, Object?> json) =>
      ReceiptDraftAuditEvent(
        action: ReceiptDraftAuditAction.values.byName(
          _requiredString(json, 'action'),
        ),
        actorEmployeeId: _requiredString(json, 'actorEmployeeId'),
        permissionRevision: _requiredString(json, 'permissionRevision'),
        occurredAtUtc: _requiredUtc(json, 'occurredAtUtc'),
        fromRevision: json['fromRevision'] as int?,
        toRevision: _requiredInt(json, 'toRevision'),
      );
}

@immutable
class StoredReceiptDraft {
  StoredReceiptDraft({
    required this.draftId,
    required this.organizationId,
    required this.ownerEmployeeId,
    required this.title,
    required DateTime expenseDate,
    required List<ReceiptDraftEvidence> evidence,
    required this.lifecycle,
    this.state = ReceiptDraftState.inProgress,
    this.submittedExpenseId,
    List<ReceiptDraftAuditEvent> auditTrail = const [],
    this.linkedJobId,
    this.linkedJobLabel,
    this.selectedDetails,
    this.entrySetup,
    List<ReceiptItemRead> itemReads = const [],
  }) : expenseDate = DateTime(
         expenseDate.year,
         expenseDate.month,
         expenseDate.day,
       ),
       evidence = List.unmodifiable(
         <ReceiptDraftEvidence>[...evidence]..sort(_compareEvidence),
       ),
       auditTrail = List.unmodifiable(auditTrail),
       itemReads = List.unmodifiable(itemReads) {
    _requireText(draftId, 'draftId');
    _requireText(organizationId, 'organizationId');
    _requireText(ownerEmployeeId, 'ownerEmployeeId');
    _requireText(title, 'title');
    if (itemReads.map((read) => read.evidenceId).toSet().length !=
        itemReads.length) {
      throw const FormatException('Receipt item source IDs must be unique.');
    }
    if (evidence.map((item) => item.evidenceId).toSet().length !=
        evidence.length) {
      throw const FormatException('Receipt evidence IDs must be unique.');
    }
    if (state == ReceiptDraftState.submitted) {
      _requireText(submittedExpenseId ?? '', 'submittedExpenseId');
    } else if (submittedExpenseId != null) {
      throw const FormatException(
        'Only a submitted receipt draft may link a submitted Expense.',
      );
    }
  }

  final String draftId;
  final String organizationId;
  final String ownerEmployeeId;
  final String title;
  final DateTime expenseDate;
  final String? linkedJobId;
  final String? linkedJobLabel;
  final List<ReceiptDraftEvidence> evidence;
  final ReceiptDraftLifecycle lifecycle;
  final ReceiptDraftState state;
  final String? submittedExpenseId;
  final List<ReceiptDraftAuditEvent> auditTrail;
  final ReceiptSelectedDetails? selectedDetails;
  final ReceiptEntrySetup? entrySetup;
  final List<ReceiptItemRead> itemReads;

  List<ReceiptItemRead> get activeItemReads => List.unmodifiable([
    for (final image in activeEvidence)
      for (final read in itemReads)
        if (read.matches(image.evidenceId, image.sha256)) read,
  ]);

  /// Removed or replaced evidence must never supply the next form's values.
  ReceiptSelectedDetails? get activeSelectedDetails {
    final selected = selectedDetails;
    return selected != null &&
            activeEvidence.any(
              (item) => selected.matches(item.evidenceId, item.sha256),
            )
        ? selected
        : null;
  }

  List<ReceiptDraftEvidence> get activeEvidence =>
      List.unmodifiable(evidence.where((item) => item.isActive));

  StoredReceiptDraft copyWith({
    String? title,
    DateTime? expenseDate,
    Object? linkedJobId = _unchangedReceiptDraftValue,
    Object? linkedJobLabel = _unchangedReceiptDraftValue,
    List<ReceiptDraftEvidence>? evidence,
    ReceiptDraftLifecycle? lifecycle,
    ReceiptDraftState? state,
    Object? submittedExpenseId = _unchangedReceiptDraftValue,
    List<ReceiptDraftAuditEvent>? auditTrail,
    Object? selectedDetails = _unchangedReceiptDraftValue,
    List<ReceiptItemRead>? itemReads,
    ReceiptEntrySetup? entrySetup,
  }) => StoredReceiptDraft(
    draftId: draftId,
    organizationId: organizationId,
    ownerEmployeeId: ownerEmployeeId,
    title: title ?? this.title,
    expenseDate: expenseDate ?? this.expenseDate,
    linkedJobId: identical(linkedJobId, _unchangedReceiptDraftValue)
        ? this.linkedJobId
        : linkedJobId as String?,
    linkedJobLabel: identical(linkedJobLabel, _unchangedReceiptDraftValue)
        ? this.linkedJobLabel
        : linkedJobLabel as String?,
    evidence: evidence ?? this.evidence,
    lifecycle: lifecycle ?? this.lifecycle,
    state: state ?? this.state,
    submittedExpenseId:
        identical(submittedExpenseId, _unchangedReceiptDraftValue)
        ? this.submittedExpenseId
        : submittedExpenseId as String?,
    auditTrail: auditTrail ?? this.auditTrail,
    itemReads: itemReads ?? this.itemReads,
    entrySetup: entrySetup ?? this.entrySetup,
    selectedDetails: identical(selectedDetails, _unchangedReceiptDraftValue)
        ? this.selectedDetails
        : selectedDetails as ReceiptSelectedDetails?,
  );

  Map<String, Object?> toJson() => {
    'draftId': draftId,
    'organizationId': organizationId,
    'ownerEmployeeId': ownerEmployeeId,
    'title': title,
    'expenseDate': expenseDate.toIso8601String(),
    'linkedJobId': linkedJobId,
    'linkedJobLabel': linkedJobLabel,
    'evidence': evidence.map((item) => item.toJson()).toList(),
    'lifecycle': lifecycle.toJson(),
    'state': state.name,
    'submittedExpenseId': submittedExpenseId,
    'auditTrail': auditTrail.map((item) => item.toJson()).toList(),
    'selectedDetails': selectedDetails?.toJson(),
    'itemReads': itemReads.map((read) => read.toJson()).toList(),
    'entrySetup': entrySetup?.toJson(),
  };

  factory StoredReceiptDraft.fromJson(
    Map<String, Object?> json,
  ) => StoredReceiptDraft(
    draftId: _requiredString(json, 'draftId'),
    organizationId: _requiredString(json, 'organizationId'),
    ownerEmployeeId: _requiredString(json, 'ownerEmployeeId'),
    title: _requiredString(json, 'title'),
    expenseDate: _requiredDate(json, 'expenseDate'),
    linkedJobId: json['linkedJobId'] as String?,
    linkedJobLabel: json['linkedJobLabel'] as String?,
    evidence: _mapList(json, 'evidence', ReceiptDraftEvidence.fromJson),
    lifecycle: ReceiptDraftLifecycle.fromJson(_requiredMap(json, 'lifecycle')),
    state: ReceiptDraftState.values.byName(_requiredString(json, 'state')),
    submittedExpenseId: json['submittedExpenseId'] as String?,
    auditTrail: _mapList(json, 'auditTrail', ReceiptDraftAuditEvent.fromJson),
    itemReads: decodeReceiptItemReads(json),
    entrySetup: json['entrySetup'] == null
        ? null
        : ReceiptEntrySetup.fromJson(_requiredMap(json, 'entrySetup')),
    selectedDetails: json['selectedDetails'] == null
        ? null
        : ReceiptSelectedDetails.fromJson(
            _requiredMap(json, 'selectedDetails'),
          ),
  );
}

int _compareEvidence(ReceiptDraftEvidence left, ReceiptDraftEvidence right) {
  final order = left.order.compareTo(right.order);
  return order != 0 ? order : left.evidenceId.compareTo(right.evidenceId);
}

void _requireText(String value, String name) {
  if (value.trim().isEmpty) throw ArgumentError.value(value, name, 'Required.');
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing $key.');
  }
  return value;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Missing $key.');
  return value;
}

DateTime _requiredDate(Map<String, Object?> json, String key) {
  final value = DateTime.tryParse(_requiredString(json, key));
  if (value == null) throw FormatException('Invalid $key.');
  return value;
}

DateTime _requiredUtc(Map<String, Object?> json, String key) =>
    _requiredDate(json, key).toUtc();

DateTime? _optionalUtc(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('Invalid $key.');
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Invalid $key.');
  return parsed.toUtc();
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('Missing $key.');
  return value.cast<String, Object?>();
}

List<T> _mapList<T>(
  Map<String, Object?> json,
  String key,
  T Function(Map<String, Object?>) decode,
) {
  final value = json[key];
  if (value is! List) throw FormatException('Missing $key.');
  return value.map((item) {
    if (item is! Map) throw FormatException('Invalid $key item.');
    return decode(item.cast<String, Object?>());
  }).toList();
}
