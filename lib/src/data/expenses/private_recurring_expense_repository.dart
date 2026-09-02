import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'file_recurring_expense_repository.dart';

/// Opens recurring-expense records in this app's private Application Support
/// directory. Business records must never be written into Documents.
Future<FileRecurringExpenseRepository>
openPrivateRecurringExpenseRepository() async {
  final applicationSupport = await getApplicationSupportDirectory();
  final directory = Directory.fromUri(
    applicationSupport.uri.resolve(
      'maintainiac_ui_lab/'
      '${FileRecurringExpenseRepository.directoryName}/',
    ),
  );
  return FileRecurringExpenseRepository.open(directory);
}
