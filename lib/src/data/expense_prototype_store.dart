import 'dart:collection';

import 'package:flutter/material.dart';

import '../screens/expenses/expense_models.dart';

class ExpensePrototypeStore extends ChangeNotifier {
  ExpensePrototypeStore({
    List<ExpenseRecord>? expenses,
    List<ExpenseReceiptDraft>? receiptDrafts,
    List<ScheduledExpenseRecord>? scheduledExpenses,
    List<ScheduledExpenseOccurrence>? scheduledExpenseOccurrences,
  }) : _expenses = [...(expenses ?? demoExpenses)],
       _deletedExpenses = [],
       _receiptDrafts = [...(receiptDrafts ?? demoExpenseReceiptDrafts)],
       _scheduledExpenses = [...(scheduledExpenses ?? demoScheduledExpenses)],
       _scheduledExpenseOccurrences = [...?scheduledExpenseOccurrences] {
    if (_scheduledExpenseOccurrences.isEmpty) {
      for (final template in _scheduledExpenses) {
        if (template.state != ScheduledExpenseState.ended) {
          _scheduledExpenseOccurrences.add(_occurrenceFor(template));
        }
      }
    }
    _sortScheduled();
  }

  final List<ExpenseRecord> _expenses;
  final List<ExpenseRecord> _deletedExpenses;
  final List<ExpenseReceiptDraft> _receiptDrafts;
  final List<ScheduledExpenseRecord> _scheduledExpenses;
  final List<ScheduledExpenseOccurrence> _scheduledExpenseOccurrences;

  UnmodifiableListView<ExpenseRecord> get expenses =>
      UnmodifiableListView(_expenses);
  UnmodifiableListView<ExpenseRecord> get deletedExpenses =>
      UnmodifiableListView(_deletedExpenses);
  UnmodifiableListView<ExpenseReceiptDraft> get receiptDrafts =>
      UnmodifiableListView(_receiptDrafts);
  UnmodifiableListView<ScheduledExpenseRecord> get scheduledExpenses =>
      UnmodifiableListView(_scheduledExpenses);
  UnmodifiableListView<ScheduledExpenseOccurrence>
  get scheduledExpenseOccurrences =>
      UnmodifiableListView(_scheduledExpenseOccurrences);

  void addExpense(ExpenseRecord record) {
    if (_expenses.any((candidate) => candidate.id == record.id)) return;
    _expenses.insert(0, record);
    notifyListeners();
  }

  void updateExpense(ExpenseRecord record) {
    final index = _expenses.indexWhere((item) => item.id == record.id);
    if (index < 0) return;
    _expenses[index] = record;
    notifyListeners();
  }

  bool softDeleteExpense(String expenseId) {
    final index = _expenses.indexWhere((item) => item.id == expenseId);
    if (index < 0) return false;
    final record = _expenses.removeAt(index);
    _deletedExpenses.insert(0, record);
    notifyListeners();
    return true;
  }

  ExpenseRecord? restoreExpense(String expenseId) {
    final index = _deletedExpenses.indexWhere((item) => item.id == expenseId);
    if (index < 0 || _expenses.any((item) => item.id == expenseId)) return null;
    final record = _deletedExpenses.removeAt(index);
    _expenses.insert(0, record);
    notifyListeners();
    return record;
  }

  void addScheduledExpense(ScheduledExpenseRecord record) {
    if (_scheduledExpenses.any((item) => item.id == record.id)) return;
    _scheduledExpenses.add(record);
    if (record.state != ScheduledExpenseState.ended) {
      _scheduledExpenseOccurrences.add(_occurrenceFor(record));
    }
    _sortScheduled();
    notifyListeners();
  }

  void updateScheduledExpense(ScheduledExpenseRecord record) {
    final index = _scheduledExpenses.indexWhere((item) => item.id == record.id);
    if (index < 0) return;
    _scheduledExpenses[index] = record;
    final openIndex = _scheduledExpenseOccurrences.indexWhere(
      (item) => item.templateId == record.id && item.isOpen,
    );
    if (openIndex >= 0) {
      _scheduledExpenseOccurrences[openIndex] =
          _scheduledExpenseOccurrences[openIndex].copyWith(
            dueOn: record.nextDueOn,
            expectedAmount: record.amount,
          );
    }
    _sortScheduled();
    notifyListeners();
  }

  ScheduledExpenseOccurrence? currentOccurrenceFor(String templateId) {
    final open = _scheduledExpenseOccurrences.where(
      (item) => item.templateId == templateId && item.isOpen,
    );
    return open.isEmpty ? null : open.first;
  }

  List<ScheduledExpenseOccurrence> occurrencesFor(String templateId) =>
      _scheduledExpenseOccurrences
          .where((item) => item.templateId == templateId)
          .toList()
        ..sort((a, b) => b.dueOn.compareTo(a.dueOn));

  bool updateScheduledExpenseOccurrence({
    required String templateId,
    required String occurrenceId,
    required DateTime dueOn,
    required double expectedAmount,
  }) {
    final templateIndex = _scheduledExpenses.indexWhere(
      (item) => item.id == templateId,
    );
    final occurrenceIndex = _scheduledExpenseOccurrences.indexWhere(
      (item) => item.templateId == templateId && item.id == occurrenceId,
    );
    if (templateIndex < 0 || occurrenceIndex < 0 || expectedAmount <= 0) {
      return false;
    }
    final occurrence = _scheduledExpenseOccurrences[occurrenceIndex];
    if (!occurrence.isOpen) return false;
    final normalizedDueOn = DateUtils.dateOnly(dueOn);
    final conflicts = _scheduledExpenseOccurrences.any(
      (item) =>
          item.id != occurrenceId &&
          item.templateId == templateId &&
          DateUtils.isSameDay(item.dueOn, normalizedDueOn),
    );
    if (conflicts) return false;
    _scheduledExpenseOccurrences[occurrenceIndex] = occurrence.copyWith(
      dueOn: normalizedDueOn,
      expectedAmount: expectedAmount,
    );
    _scheduledExpenses[templateIndex] = _scheduledExpenses[templateIndex]
        .copyWith(nextDueOn: normalizedDueOn);
    _sortScheduled();
    notifyListeners();
    return true;
  }

  ExpenseRecord? markScheduledExpensePaid({
    required String templateId,
    required String occurrenceId,
    required DateTime paidOn,
    double? actualAmount,
  }) {
    final templateIndex = _scheduledExpenses.indexWhere(
      (item) => item.id == templateId,
    );
    final occurrenceIndex = _scheduledExpenseOccurrences.indexWhere(
      (item) => item.templateId == templateId && item.id == occurrenceId,
    );
    if (templateIndex < 0 || occurrenceIndex < 0) return null;
    final template = _scheduledExpenses[templateIndex];
    final occurrence = _scheduledExpenseOccurrences[occurrenceIndex];
    if (occurrence.status == ScheduledExpenseOccurrenceStatus.paid) {
      final expenseId = occurrence.expenseId;
      if (expenseId == null) return null;
      return _expenses.where((item) => item.id == expenseId).firstOrNull;
    }
    if (!template.isActive || !occurrence.isOpen) return null;
    final amount = actualAmount ?? template.amount;
    if (amount <= 0) return null;
    final expenseId = 'EXP-${occurrence.id}';
    final expense = ExpenseRecord(
      id: expenseId,
      vendor: template.title,
      category: template.category,
      amount: amount,
      date: DateUtils.dateOnly(paidOn),
      owner: template.owner,
      receiptStatus: template.receiptRequired
          ? 'Receipt still needed'
          : 'Receipt optional',
    );
    if (_expenses.every((item) => item.id != expenseId)) {
      _expenses.insert(0, expense);
    }
    _scheduledExpenseOccurrences[occurrenceIndex] = occurrence.copyWith(
      status: ScheduledExpenseOccurrenceStatus.paid,
      paidOn: paidOn,
      actualAmount: amount,
      expenseId: expenseId,
    );
    _advanceTemplate(templateIndex, template, occurrence.dueOn);
    _sortScheduled();
    notifyListeners();
    return expense;
  }

  bool skipScheduledExpense({
    required String templateId,
    required String occurrenceId,
  }) {
    final templateIndex = _scheduledExpenses.indexWhere(
      (item) => item.id == templateId,
    );
    final occurrenceIndex = _scheduledExpenseOccurrences.indexWhere(
      (item) => item.templateId == templateId && item.id == occurrenceId,
    );
    if (templateIndex < 0 || occurrenceIndex < 0) return false;
    final template = _scheduledExpenses[templateIndex];
    final occurrence = _scheduledExpenseOccurrences[occurrenceIndex];
    if (!occurrence.isOpen || !template.isActive) return false;
    _scheduledExpenseOccurrences[occurrenceIndex] = occurrence.copyWith(
      status: ScheduledExpenseOccurrenceStatus.skipped,
    );
    _advanceTemplate(templateIndex, template, occurrence.dueOn);
    _sortScheduled();
    notifyListeners();
    return true;
  }

  void setScheduledExpenseState(
    String templateId,
    ScheduledExpenseState state,
  ) {
    final index = _scheduledExpenses.indexWhere(
      (item) => item.id == templateId,
    );
    if (index < 0) return;
    _scheduledExpenses[index] = _scheduledExpenses[index].copyWith(
      state: state,
    );
    notifyListeners();
  }

  void _advanceTemplate(
    int templateIndex,
    ScheduledExpenseRecord template,
    DateTime completedDueOn,
  ) {
    final nextDue = template.nextDueAfter(completedDueOn);
    if (nextDue == null) {
      _scheduledExpenses[templateIndex] = template.copyWith(
        state: ScheduledExpenseState.ended,
      );
      return;
    }
    final updated = template.copyWith(nextDueOn: nextDue);
    _scheduledExpenses[templateIndex] = updated;
    _scheduledExpenseOccurrences.add(_occurrenceFor(updated));
  }

  void _sortScheduled() =>
      _scheduledExpenses.sort((a, b) => a.nextDueOn.compareTo(b.nextDueOn));
}

ScheduledExpenseOccurrence _occurrenceFor(ScheduledExpenseRecord template) {
  final due = DateUtils.dateOnly(template.nextDueOn);
  return ScheduledExpenseOccurrence(
    id: '${template.id}-${due.year}-${due.month}-${due.day}',
    templateId: template.id,
    dueOn: due,
    expectedAmount: template.amount,
  );
}
