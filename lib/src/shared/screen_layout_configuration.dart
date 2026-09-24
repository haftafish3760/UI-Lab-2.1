/// Ordered presentation choices; never grants access to the underlying records.
abstract final class AdminDashboardLayoutConfiguration {
  static const preferenceKey = 'adminDashboardWidgets';
  static const defaults = [
    'work',
    'billing',
    'calendar',
    'entries',
    'approvals',
  ];
  static const available = {
    'work',
    'billing',
    'calendar',
    'entries',
    'approvals',
    'payments',
  };

  static bool isValid(Object? value) =>
      value is List &&
      value.contains('calendar') &&
      value.length == value.toSet().length &&
      value.every((item) => item is String && available.contains(item));
}
