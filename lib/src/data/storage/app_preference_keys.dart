/// Stable preference/recovery identifiers. Layout changes do not rename saved keys.
abstract final class AppPreferenceKeys {
  static const workDisplayDraftDomain = 'device/work-display-editor';
  static const workDisplayDraftId = 'work-home';
  static const receiptDisplayDraftDomain = 'device/receipt-display-editor';
  static const receiptDisplayDraftId = 'receipt-intake';
  static const reportDisplayDraftDomain = 'device/report-display-editor';
  static const reportDisplayDraftId = 'reports';
  static const reportDisplayChoices = {
    'showInvoicedRevenue',
    'showMoneyCollected',
    'showRecordedExpenses',
    'showEstimatedGrossProfit',
    'showVehicleHealth',
  };
  static const expenseDisplayDraftDomain = 'device/expense-display-editor';
  static const expenseDisplayDraftId = 'expenses';
  static const workListDraftDomain = 'device/work-list-editor';
  static const workListIds = {'jobs', 'estimates', 'invoices'};
  static const workListChoices = {
    'showStatusDetails',
    'showAssignments',
    'includeClosedRecords',
  };
  static String workListKey(String workspace, String choice) {
    if (!workListIds.contains(workspace) || !workListChoices.contains(choice)) {
      throw ArgumentError('Unsupported Work list preference.');
    }
    return 'workList.$workspace.$choice';
  }
}
