import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'file_receipt_draft_repository.dart';

Future<FileReceiptDraftRepository> openPrivateReceiptDraftRepository() async {
  final applicationSupport = await getApplicationSupportDirectory();
  final directory = Directory.fromUri(
    applicationSupport.uri.resolve(
      'maintainiac_ui_lab/${FileReceiptDraftRepository.directoryName}/',
    ),
  );
  return FileReceiptDraftRepository.open(directory);
}
