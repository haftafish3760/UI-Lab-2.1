import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/documents/document_source.dart';
import 'package:ui_lab_2_1/src/shared/documents/retained_document_source.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'support/storage/database_harness.dart';

void main() {
  test('authorization is checked before and after reading bytes', () async {
    var allowed = false;
    var reads = 0;
    final source = DocumentSource(
      origin: DocumentOrigin.generated,
      fileName: 'document.pdf',
      authorize: () async {
        if (!allowed) throw StateError('Permission denied');
      },
      readBytes: () async {
        reads++;
        allowed = false;
        return Uint8List.fromList([1]);
      },
    );
    await expectLater(source.open(), throwsStateError);
    expect(reads, 0);
    allowed = true;
    await expectLater(source.open(), throwsStateError);
    expect(reads, 1);
  });

  test(
    'uploaded PDF bytes survive reopen and reject other owners or tampering',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      final original = File('${harness.directory.path}/supplier.pdf');
      final bytes = Uint8List.fromList(
        '%PDF-1.7\nOriginal supplier evidence\n%%EOF'.codeUnits,
      );
      await original.writeAsBytes(bytes);
      final file = await LocalAttachmentStore(db).retain(
        source: original,
        organizationId: 'company',
        ownerId: 'employee',
      );
      final id = file.uri.pathSegments.last.replaceFirst('.image', '');
      await original.delete();
      await harness.close(db);
      db = await harness.open();
      DocumentSource source(String company, String owner) =>
          retainedDocumentSource(
            attachments: LocalAttachmentStore(db),
            organizationId: company,
            ownerIds: {owner},
            attachmentId: id,
            fileName: 'supplier.pdf',
            authorize: () async {},
          );
      expect(await source('company', 'employee').open(), bytes);
      await expectLater(source('other', 'employee').open(), throwsStateError);
      await expectLater(source('company', 'other').open(), throwsStateError);
      await file.writeAsBytes([1, 2, 3]);
      await expectLater(source('company', 'employee').open(), throwsStateError);
    },
  );
}
