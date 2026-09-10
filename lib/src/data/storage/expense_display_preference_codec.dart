/// Stable storage names, independent of translated UI labels or widget layout.
const expenseDisplayCategoryNames = {
  'materials',
  'consumables',
  'fuel',
  'vehiclePayment',
  'vehicleInsurance',
  'vehicleRepair',
  'vehicleMaintenance',
  'vehicle',
  'tools',
  'subcontractor',
  'office',
  'rent',
  'utilities',
  'phoneInternet',
  'licensesTaxes',
  'advertising',
  'training',
  'banking',
  'travel',
  'other',
};

bool validExpenseCategoryChoices(Object? value) =>
    value is List &&
    value.length <= 10 &&
    value.toSet().length == value.length &&
    value.every(expenseDisplayCategoryNames.contains);

bool validExpenseReceiptChoices(Object? value) =>
    value is Map &&
    value.keys.every(expenseDisplayCategoryNames.contains) &&
    value.values.every(const {'basic', 'detailed'}.contains);

bool validExpenseDisplayPreferences(Object? value) =>
    value is Map &&
    value.length == 5 &&
    value['version'] == 1 &&
    value['showJobLinks'] is bool &&
    const {'off', 'topTen', 'custom'}.contains(value['categoryMode']) &&
    validExpenseCategoryChoices(value['customCategories']) &&
    validExpenseReceiptChoices(value['receiptTypes']);
