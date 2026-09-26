import 'package:flutter/foundation.dart';

import '../../shared/app_view_mode.dart';
import '../../data/work/work_session_permissions.dart';
import 'work_models.dart';

@immutable
class InvoicePermissions {
  const InvoicePermissions({
    required this.canView,
    required this.canCreate,
    required this.canViewFinancials,
    required this.canEditDraft,
    required this.canPreviewCustomerCopy,
    required this.canIssue,
    required this.canRecordPayment,
  }) : assert(
         canView ||
             (!canCreate &&
                 !canViewFinancials &&
                 !canEditDraft &&
                 !canPreviewCustomerCopy &&
                 !canIssue &&
                 !canRecordPayment),
         'An employee who cannot view invoices cannot act on them.',
       ),
       assert(
         canViewFinancials ||
             (!canCreate &&
                 !canEditDraft &&
                 !canPreviewCustomerCopy &&
                 !canIssue &&
                 !canRecordPayment),
         'Invoice financial actions require access to invoice financials.',
       );

  const InvoicePermissions.development()
    : canView = true,
      canCreate = true,
      canViewFinancials = true,
      canEditDraft = true,
      canPreviewCustomerCopy = true,
      canIssue = true,
      canRecordPayment = true;

  const InvoicePermissions.technicianDevelopment()
    : canView = true,
      canCreate = true,
      canViewFinancials = true,
      canEditDraft = true,
      canPreviewCustomerCopy = true,
      canIssue = false,
      canRecordPayment = false;

  final bool canView;
  final bool canCreate;
  final bool canViewFinancials;
  final bool canEditDraft;
  final bool canPreviewCustomerCopy;
  final bool canIssue;
  final bool canRecordPayment;

  bool get hasActions =>
      canEditDraft || canPreviewCustomerCopy || canIssue || canRecordPayment;
}

InvoicePermissions invoicePermissionsForView(AppViewMode view) =>
    view == AppViewMode.admin
    ? const InvoicePermissions.development()
    : const InvoicePermissions.technicianDevelopment();

/// The display view is not an authority source once a Work session is active.
/// The current payments ledger is company-wide, so recording there also needs
/// a company-wide grant until employee-scoped payment queries are available.
InvoicePermissions invoicePermissionsForWorkSession(
  AppViewMode view,
  WorkSessionPermissions? grants,
) {
  final display = invoicePermissionsForView(view);
  if (grants == null) return display;
  final canEditInvoices = grants.editableKinds.contains(WorkRecordKind.invoice);
  return InvoicePermissions(
    canView: display.canView,
    canCreate: display.canCreate && canEditInvoices,
    canViewFinancials: display.canViewFinancials,
    canEditDraft: display.canEditDraft && canEditInvoices,
    canPreviewCustomerCopy: display.canPreviewCustomerCopy,
    canIssue: grants.canManageOtherCreators && grants.canIssueInvoices,
    canRecordPayment: grants.canManageOtherCreators && grants.canRecordPayments,
  );
}
