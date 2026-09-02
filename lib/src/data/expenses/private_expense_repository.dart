import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'file_expense_repository.dart';

Future<FileExpenseRepository> openPrivateExpenseRepository() async {
  final applicationSupport = await getApplicationSupportDirectory();
  final directory = Directory.fromUri(
    applicationSupport.uri.resolve(
      'maintainiac_ui_lab/${FileExpenseRepository.directoryName}/',
    ),
  );
  return FileExpenseRepository.open(directory);
}
