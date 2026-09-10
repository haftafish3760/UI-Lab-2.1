import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_site_photos_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/local_document_path_scope.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final denied in [false, true]) {
    testWidgets(
      'estimate thumbnail uses resolved path without changing reference; denied=$denied',
      (tester) async {
        final directory = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('estimate-resolution-'),
        ))!;
        final original = File('${directory.path}/original.image');
        final relocated = File('${directory.path}/relocated.image');
        await tester.runAsync(() => original.writeAsBytes([1, 2, 3]));
        await tester.runAsync(() => relocated.writeAsBytes([4, 5, 6]));
        final photo = WorkSitePhoto(
          id: 'retained-photo',
          path: original.path,
          name: 'Retained photo',
          source: WorkSitePhotoSource.file,
          addedOn: DateTime(2026, 9, 10),
        );
        final scope = OperationalScopeController();
        try {
          await tester.pumpWidget(
            OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: AppTheme.light,
                home: LocalDocumentPathScope(
                  resolve: (reference) {
                    expect(reference, original.path);
                    if (denied) throw StateError('unavailable');
                    return relocated.path;
                  },
                  child: EstimateSitePhotosScreen(
                    initialDay: DateTime(2026, 9, 10),
                    initialPhotos: [photo],
                  ),
                ),
              ),
            ),
          );
          if (denied) {
            expect(find.byType(Image), findsNothing);
            expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
          } else {
            final image = tester.widget<Image>(find.byType(Image));
            expect((image.image as FileImage).file.path, relocated.path);
          }
          expect(photo.path, original.path);
          expect(find.text('Retained photo'), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          scope.dispose();
          await tester.runAsync(() => directory.delete(recursive: true));
        }
      },
    );
  }
}
