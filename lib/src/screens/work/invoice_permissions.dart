import 'package:flutter/foundation.dart';

import '../../shared/app_view_mode.dart';

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
