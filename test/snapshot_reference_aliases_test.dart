import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_attachment.dart';
import 'package:ui_lab_2_1/src/data/storage/snapshot_reference_aliases.dart';

void main() {
  const relative = 'receipt_evidence/evidence/folder/image.image';
  const attachment = LocalSnapshotAttachment(
    relativePath: relative,
    sourcePath: '/previous/$relative',
    byteLength: 4,
    digest: 'registered-content',
  );

  test('aliases preserve original keys across native path separators', () {
    for (final reference in [
      '/previous/$relative',
      r'C:\previous\receipt_evidence\evidence\folder\image.image',
      r'C:\previous/receipt_evidence/evidence/folder/image.image',
    ]) {
      expect(
        validateSnapshotReferenceAliases({reference: relative}, [attachment]),
        {reference: relative},
      );
    }
  });

  test(
    'separator handling does not allow traversal or identity substitution',
    () {
      for (final reference in [
        '/previous/../$relative',
        r'C:\previous\..\receipt_evidence\evidence\folder\image.image',
        '/previous/receipt_evidence/evidence/other/image.image',
        '/previous/receipt_evidence/evidence/folder/another.image',
      ]) {
        expect(
          () => validateSnapshotReferenceAliases(
            {reference: relative},
            [attachment],
          ),
          throwsStateError,
        );
      }
      expect(
        () => validateSnapshotReferenceAliases(
          {'/previous/$relative': 'unregistered'},
          [attachment],
        ),
        throwsStateError,
      );
    },
  );
}
