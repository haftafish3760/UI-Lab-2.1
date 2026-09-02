import 'package:flutter/foundation.dart';

import '../../shared/app_view_mode.dart';

enum ExpenseEditorPurpose { manualEntry, receiptReview }

@immutable
class ExpensePermissions {
  const ExpensePermissions({
    required this.canView,
    required this.canViewAmounts,
    required this.canCreate,
    required this.canAttachReceipt,
    required this.canEditOwn,
    required this.canEditTeam,
    required this.canReviewCompanyExpenses,
    required this.canManageScheduledExpenses,
    required this.canConfigureDisplay,
    this.canRemoveOwn = false,
    this.canRemoveTeam = false,
    this.canRestoreOwn = false,
    this.canRestoreTeam = false,
    this.actorEmployeeId = 'alex',
  }) : assert(
         canView ||
             (!canViewAmounts &&
                 !canCreate &&
                 !canAttachReceipt &&
                 !canEditOwn &&
                 !canEditTeam &&
                 !canRemoveOwn &&
                 !canRemoveTeam &&
                 !canRestoreOwn &&
                 !canRestoreTeam &&
                 !canReviewCompanyExpenses &&
                 !canManageScheduledExpenses &&
                 !canConfigureDisplay),
         'An employee who cannot view Expenses cannot act on them.',
       ),
       assert(
         canViewAmounts ||
             (!canCreate &&
                 !canAttachReceipt &&
                 !canEditOwn &&
                 !canEditTeam &&
                 !canRemoveOwn &&
                 !canRemoveTeam &&
                 !canRestoreOwn &&
                 !canRestoreTeam &&
                 !canReviewCompanyExpenses &&
                 !canManageScheduledExpenses),
         'Expense financial actions require amount access.',
       );

  const ExpensePermissions.development()
    : canView = true,
      canViewAmounts = true,
      canCreate = true,
      canAttachReceipt = true,
      canEditOwn = true,
      canEditTeam = true,
      canRemoveOwn = true,
      canRemoveTeam = true,
      canRestoreOwn = true,
      canRestoreTeam = true,
      canReviewCompanyExpenses = true,
      canManageScheduledExpenses = true,
      canConfigureDisplay = true,
      actorEmployeeId = 'alex';

  const ExpensePermissions.technicianDevelopment()
    : canView = true,
      canViewAmounts = true,
      canCreate = true,
      canAttachReceipt = true,
      canEditOwn = true,
      canEditTeam = false,
      canRemoveOwn = false,
      canRemoveTeam = false,
      canRestoreOwn = false,
      canRestoreTeam = false,
      canReviewCompanyExpenses = false,
      canManageScheduledExpenses = false,
      canConfigureDisplay = true,
      actorEmployeeId = 'alex';

  final bool canView;
  final bool canViewAmounts;
  final bool canCreate;
  final bool canAttachReceipt;
  final bool canEditOwn;
  final bool canEditTeam;
  final bool canRemoveOwn;
  final bool canRemoveTeam;
  final bool canRestoreOwn;
  final bool canRestoreTeam;
  final bool canReviewCompanyExpenses;
  final bool canManageScheduledExpenses;
  final bool canConfigureDisplay;
  final String actorEmployeeId;

  bool get hasAddActions => canCreate || canAttachReceipt;

  bool canEditRecord({required bool isOwn}) => isOwn ? canEditOwn : canEditTeam;

  bool canRemoveRecord({required bool isOwn}) =>
      isOwn ? canRemoveOwn : canRemoveTeam;

  bool canRestoreRecord({required bool isOwn}) =>
      isOwn ? canRestoreOwn : canRestoreTeam;

  bool owns({required String? paidByEmployeeId}) =>
      paidByEmployeeId == actorEmployeeId;

  bool canUseEditor({
    required bool isExisting,
    required bool isOwn,
    required ExpenseEditorPurpose purpose,
  }) {
    if (!canView || !canViewAmounts) return false;
    if (isExisting) return canEditRecord(isOwn: isOwn);
    return purpose == ExpenseEditorPurpose.receiptReview
        ? canAttachReceipt
        : canCreate;
  }
}

ExpensePermissions expensePermissionsForView(AppViewMode view) =>
    view == AppViewMode.admin
    ? const ExpensePermissions.development()
    : const ExpensePermissions.technicianDevelopment();
