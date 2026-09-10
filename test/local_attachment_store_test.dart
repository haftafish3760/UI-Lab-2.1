import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_store.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'retained bytes survive source deletion and reopen; scope and corruption are enforced',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      final source = File('${harness.directory.path}/picker.tmp');
      await source.writeAsBytes([1, 2, 3, 4], flush: true);
      final retained = await LocalAttachmentStore(
        db,
      ).retain(source: source, organizationId: 'company', ownerId: 'alex');
      await source.delete();
      await harness.close(db);
      db = await harness.open();
      final store = LocalAttachmentStore(db);
      expect(
        await (await store.verifiedFiles(
          organizationId: 'company',
          ownerIds: {'alex'},
        )).single.readAsBytes(),
        [1, 2, 3, 4],
      );
      expect(
        await store.verifiedFiles(organizationId: 'other', ownerIds: {'alex'}),
        isEmpty,
      );
      expect(
        await store.verifiedFiles(
          organizationId: 'company',
          ownerIds: {'jordan'},
        ),
        isEmpty,
      );
      await retained.writeAsBytes([4, 3, 2, 1], flush: true);
      await expectLater(
        store.verifiedFiles(organizationId: 'company', ownerIds: {'alex'}),
        throwsStateError,
      );
    },
  );
  test(
    'failed manifest transaction publishes no retained image record',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final source = File('${harness.directory.path}/picker.tmp');
      await source.writeAsBytes([5, 6], flush: true);
      await db.customStatement(
        "CREATE TRIGGER fail_attachment BEFORE INSERT ON local_records WHEN NEW.domain = 'attachments/files' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      await expectLater(
        LocalAttachmentStore(
          db,
        ).retain(source: source, organizationId: 'company', ownerId: 'alex'),
        throwsA(anything),
      );
      expect(
        await LocalRecordStore(db).read(
          organizationId: 'company',
          domain: LocalAttachmentStore.domain,
          ownerIds: {'alex'},
        ),
        isEmpty,
      );
      expect(await source.readAsBytes(), [5, 6]);
    },
  );
}
