import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/expenses/private_expense_repository.dart';
import 'src/data/expenses/expense_ui_lab_seed.dart';
import 'src/data/expenses/private_recurring_expense_repository.dart';
import 'src/data/expenses/recurring_expense_ui_lab_seed.dart';
import 'src/data/notifications/private_notification_repository.dart';
import 'src/data/notifications/flutter_local_notification_gateway.dart';
import 'src/data/receipts/private_receipt_draft_repository.dart';
import 'src/data/receipts/receipt_draft_ui_lab_seed.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final nativeNotifications = FlutterLocalNotificationGateway();
  await nativeNotifications.initialize();
  final expenses = await openPrivateExpenseRepository();
  await seedExpenseUiLabDemoDataIfEmpty(expenses);
  final recurringExpenses = await openPrivateRecurringExpenseRepository();
  await seedRecurringExpenseUiLabDemoDataIfEmpty(recurringExpenses);
  final receiptDrafts = await openPrivateReceiptDraftRepository();
  await seedReceiptDraftUiLabDemoDataIfEmpty(receiptDrafts);
  final notifications = await openPrivateNotificationRepository();
  runApp(
    UiLabApp(
      expenseRepository: expenses,
      recurringExpenseRepository: recurringExpenses,
      receiptDraftRepository: receiptDrafts,
      notificationRepository: notifications,
      nativeNotificationGateway: nativeNotifications,
    ),
  );
}
