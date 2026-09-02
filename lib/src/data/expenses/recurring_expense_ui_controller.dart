import 'package:flutter/widgets.dart';

import '../../screens/expenses/expense_models.dart';
import 'authorized_recurring_expense_service.dart';
import 'recurring_expense_records.dart';
import 'recurring_expense_repository.dart';
import 'recurring_expense_ui_adapter.dart';

enum RecurringExpenseUiPhase { idle, loading, ready, failed }

class RecurringExpenseUiController extends ChangeNotifier {
  RecurringExpenseUiController(
    this._service,
    this._permissions,
    this._employeeLabelForId, {
    bool recoveredFromDamagedSnapshot = false,
  }) : _showRecoveryNotice = recoveredFromDamagedSnapshot;

  final AuthorizedRecurringExpenseService _service;
  final RecurringExpenseCommandPermissions _permissions;
  final RecurringExpenseEmployeeLabelResolver _employeeLabelForId;
  final Map<String, StoredRecurringExpenseTemplate> _templates = {};
  final Map<String, StoredRecurringExpenseOccurrence> _occurrences = {};
  final Set<String> _pendingIds = {};
  RecurringExpenseUiPhase _phase = RecurringExpenseUiPhase.idle;
  String? _failureMessage;
  int _sourceRevision = 0;
  bool _showRecoveryNotice;
  bool _disposed = false;

  RecurringExpenseUiPhase get phase => _phase;
  String? get failureMessage => _failureMessage;
  bool get isLoading => _phase == RecurringExpenseUiPhase.loading;
  int get sourceRevision => _sourceRevision;
  bool get showRecoveryNotice => _showRecoveryNotice;
  bool isPending(String id) => _pendingIds.contains(id);

  void dismissRecoveryNotice() {
    if (!_showRecoveryNotice) return;
    _showRecoveryNotice = false;
    _notify();
  }

  List<ScheduledExpenseRecord> get records {
    final result =
        _templates.values
            .map(
              (stored) => RecurringExpenseUiAdapter.toUiTemplate(
                stored,
                _employeeLabelForId,
              ),
            )
            .toList()
          ..sort((a, b) => a.nextDueOn.compareTo(b.nextDueOn));
    return List.unmodifiable(result);
  }

  List<ScheduledExpenseOccurrence> get occurrences {
    final result =
        _occurrences.values
            .map(RecurringExpenseUiAdapter.toUiOccurrence)
            .toList()
          ..sort((a, b) => a.dueOn.compareTo(b.dueOn));
    return List.unmodifiable(result);
  }

  ScheduledExpenseRecord? recordById(String templateId) {
    final stored = _templates[templateId];
    return stored == null
        ? null
        : RecurringExpenseUiAdapter.toUiTemplate(stored, _employeeLabelForId);
  }

  ScheduledExpenseOccurrence? currentOccurrenceFor(String templateId) {
    final open =
        _occurrences.values
            .where((item) => item.templateId == templateId && item.isOpen)
            .toList()
          ..sort((a, b) => a.dueOn.compareTo(b.dueOn));
    return open.isEmpty
        ? null
        : RecurringExpenseUiAdapter.toUiOccurrence(open.first);
  }

  List<ScheduledExpenseOccurrence> occurrencesFor(String templateId) =>
      occurrences.where((item) => item.templateId == templateId).toList()
        ..sort((a, b) => b.dueOn.compareTo(a.dueOn));

  Future<bool> load() async {
    _phase = RecurringExpenseUiPhase.loading;
    _failureMessage = null;
    _notify();
    try {
      final results = await Future.wait([
        _service.queryTemplates(permissions: _permissions),
        _service.queryOccurrences(permissions: _permissions),
      ]);
      final templates = results[0] as List<StoredRecurringExpenseTemplate>;
      final occurrences = results[1] as List<StoredRecurringExpenseOccurrence>;
      _templates
        ..clear()
        ..addEntries(templates.map((item) => MapEntry(item.templateId, item)));
      _occurrences
        ..clear()
        ..addEntries(
          occurrences.map((item) => MapEntry(item.occurrenceId, item)),
        );
      _phase = RecurringExpenseUiPhase.ready;
      _sourceRevision += 1;
      _notify();
      return true;
    } on Object catch (error) {
      _fail(error);
      return false;
    }
  }

  Future<ScheduledExpenseRecord?> create(ScheduledExpenseRecord record) =>
      _mutateTemplate(record.id, () async {
        final now = DateTime.now().toUtc();
        final stored = RecurringExpenseUiAdapter.newStoredTemplate(
          record: record,
          organizationId: _permissions.organizationId,
          createdByEmployeeId: _permissions.actorEmployeeId,
          occurredAtUtc: now,
        );
        final result = await _service.createTemplate(
          template: stored,
          initialOccurrence: stored.initialOccurrence(
            occurrenceId: _occurrenceId(stored.templateId, stored.nextDueOn),
            occurredAtUtc: now,
            actorEmployeeId: _permissions.actorEmployeeId,
            permissionRevision: _permissions.permissionRevision,
          ),
          permissions: _permissions,
          occurredAtUtc: now,
        );
        _apply(result);
        return recordById(record.id)!;
      });

  Future<ScheduledExpenseRecord?> update(ScheduledExpenseRecord record) =>
      _mutateTemplate(record.id, () async {
        final current = _requireTemplate(record.id);
        final result = await _service.updateTemplate(
          template: RecurringExpenseUiAdapter.updateStoredTemplate(
            current: current,
            record: record,
          ),
          expectedRevision: current.lifecycle.revision,
          permissions: _permissions,
          occurredAtUtc: DateTime.now().toUtc(),
        );
        _apply(result);
        return recordById(record.id)!;
      });

  Future<ScheduledExpenseOccurrence?> updateOccurrence(
    ScheduledExpenseOccurrence occurrence,
  ) => _mutateOccurrence(occurrence.id, () async {
    final current = _requireOccurrence(occurrence.id);
    final template = _requireTemplate(current.templateId);
    final result = await _service.updateOccurrence(
      templateId: template.templateId,
      occurrence: current.copyWith(
        dueOn: occurrence.dueOn,
        expectedAmount: RecurringExpenseUiAdapter.money(
          occurrence.expectedAmount,
        ),
      ),
      expectedTemplateRevision: template.lifecycle.revision,
      expectedRevision: current.lifecycle.revision,
      permissions: _permissions,
      occurredAtUtc: DateTime.now().toUtc(),
    );
    _apply(result);
    return RecurringExpenseUiAdapter.toUiOccurrence(result.occurrence);
  });

  Future<bool> setState(String templateId, ScheduledExpenseState state) async {
    final result = await _mutateTemplate<ScheduledExpenseRecord>(
      templateId,
      () async {
        final current = _requireTemplate(templateId);
        final updated = await _service.setTemplateState(
          templateId: templateId,
          state: RecurringExpenseUiAdapter.storedState(state),
          expectedRevision: current.lifecycle.revision,
          permissions: _permissions,
          occurredAtUtc: DateTime.now().toUtc(),
        );
        _templates[templateId] = updated;
        return recordById(templateId)!;
      },
    );
    return result != null;
  }

  Future<bool> skip(String templateId, String occurrenceId) async {
    final result = await _mutateOccurrence<ScheduledExpenseOccurrence>(
      occurrenceId,
      () async {
        final template = _requireTemplate(templateId);
        final occurrence = _requireOccurrence(occurrenceId);
        final changed = await _service.skipOccurrence(
          templateId: templateId,
          occurrenceId: occurrenceId,
          expectedTemplateRevision: template.lifecycle.revision,
          expectedOccurrenceRevision: occurrence.lifecycle.revision,
          permissions: _permissions,
          occurredAtUtc: DateTime.now().toUtc(),
        );
        _apply(changed);
        return RecurringExpenseUiAdapter.toUiOccurrence(changed.occurrence);
      },
    );
    return result != null;
  }

  Future<bool> recordPaid({
    required String templateId,
    required String occurrenceId,
    required double actualAmount,
    required DateTime paidOn,
    required String expenseId,
  }) async {
    final result = await _mutateOccurrence<ScheduledExpenseOccurrence>(
      occurrenceId,
      () async {
        final template = _requireTemplate(templateId);
        final occurrence = _requireOccurrence(occurrenceId);
        final changed = await _service.recordPaidOccurrence(
          templateId: templateId,
          occurrenceId: occurrenceId,
          expectedTemplateRevision: template.lifecycle.revision,
          expectedOccurrenceRevision: occurrence.lifecycle.revision,
          actualAmount: RecurringExpenseUiAdapter.money(actualAmount),
          paidOn: paidOn,
          expenseId: expenseId,
          permissions: _permissions,
          occurredAtUtc: DateTime.now().toUtc(),
        );
        _apply(changed);
        return RecurringExpenseUiAdapter.toUiOccurrence(changed.occurrence);
      },
    );
    return result != null;
  }

  Future<T?> _mutateTemplate<T>(String id, Future<T> Function() action) =>
      _mutate(id, action);

  Future<T?> _mutateOccurrence<T>(String id, Future<T> Function() action) =>
      _mutate(id, action);

  Future<T?> _mutate<T>(String id, Future<T> Function() action) async {
    if (!_pendingIds.add(id)) return null;
    _failureMessage = null;
    _notify();
    try {
      final value = await action();
      _phase = RecurringExpenseUiPhase.ready;
      _sourceRevision += 1;
      return value;
    } on Object catch (error) {
      _fail(error);
      return null;
    } finally {
      _pendingIds.remove(id);
      _notify();
    }
  }

  StoredRecurringExpenseTemplate _requireTemplate(String id) =>
      _templates[id] ??
      (throw const RecurringExpenseNotFoundException(
        'Recurring expense does not exist.',
      ));

  StoredRecurringExpenseOccurrence _requireOccurrence(String id) =>
      _occurrences[id] ??
      (throw const RecurringExpenseNotFoundException(
        'Recurring payment does not exist.',
      ));

  void _apply(RecurringExpenseMutationResult result) {
    _templates[result.template.templateId] = result.template;
    _occurrences[result.occurrence.occurrenceId] = result.occurrence;
    final next = result.nextOccurrence;
    if (next != null) _occurrences[next.occurrenceId] = next;
  }

  void _fail(Object error) {
    _failureMessage = switch (error) {
      RecurringExpensePermissionDeniedException() =>
        'You do not have permission to change that planned expense.',
      RecurringExpenseRevisionConflictException() =>
        'That planned expense changed. Reload it and try again.',
      RecurringExpenseStorageException() ||
      RecurringExpenseStorageCorruptionException() =>
        'The planned expense could not be saved safely. Try again.',
      RecurringExpenseInvalidTransitionException(:final message) => message,
      RecurringExpenseNotFoundException() =>
        'That planned expense is no longer available.',
      _ => 'The planned expense could not be changed. Try again.',
    };
    _phase = RecurringExpenseUiPhase.failed;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class RecurringExpenseUiScope
    extends InheritedNotifier<RecurringExpenseUiController> {
  const RecurringExpenseUiScope({
    required RecurringExpenseUiController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static RecurringExpenseUiController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<RecurringExpenseUiScope>()
      ?.notifier;

  static RecurringExpenseUiController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'RecurringExpenseUiScope is missing.');
    return controller!;
  }
}

String _occurrenceId(String templateId, DateTime dueOn) =>
    '$templateId-${dueOn.year.toString().padLeft(4, '0')}-'
    '${dueOn.month.toString().padLeft(2, '0')}-'
    '${dueOn.day.toString().padLeft(2, '0')}';
