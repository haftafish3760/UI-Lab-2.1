import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/local_document_path_scope.dart';
import 'package:ui_lab_2_1/src/shared/local_document_preview.dart';

void main() {
  testWidgets(
    'document preview resolves retained references and responds to relocation',
    (tester) async {
      Future<void> show(String path) async {
        await tester.pumpWidget(
          MaterialApp(
            home: LocalDocumentPathScope(
              resolve: (reference) {
                expect(reference, '/original/receipt.image');
                return path;
              },
              child: const LocalDocumentPreview(
                path: '/original/receipt.image',
                kind: LocalDocumentKind.image,
                semanticsLabel: 'Receipt evidence',
              ),
            ),
          ),
        );
        final provider =
            tester.widget<Image>(find.byType(Image)).image as FileImage;
        expect(provider.file.path, path);
      }

      await show('/candidate-one/files/receipt.image');
      await show('/candidate-two/files/receipt.image');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('resolver failure never falls back to the stored file path', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LocalDocumentPathScope(
          resolve: (_) => throw StateError('private internal location'),
          child: const LocalDocumentPreview(
            path: '/original/private.image',
            kind: LocalDocumentKind.image,
            semanticsLabel: 'Receipt evidence',
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.text('This document could not be located.'), findsOneWidget);
    expect(find.textContaining('private internal'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
