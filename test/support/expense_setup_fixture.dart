import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shell/app_shell.dart';

/// Existing-user fixture for module tests. First-use behavior has its own tests.
Future<void> useCompletedExpenseSetup(WidgetTester tester) async {
  final preferences = AppPreferencesScope.maybeOf(
    tester.element(find.byType(AppShell)),
  );
  if (preferences != null && !preferences.expenseSetupCompleted) {
    await preferences.completeExpenseSetup(
      detailed: preferences.receiptDetailedReceipts,
      assistance: preferences.receiptAssistanceEnabled,
    );
    await tester.pump();
  }
}
