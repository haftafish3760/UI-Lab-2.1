import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/documents/pdf/pdf_branding.dart';
import 'package:ui_lab_2_1/src/shared/documents/pdf/pdf_configuration.dart';
import 'package:ui_lab_2_1/src/shared/documents/pdf/pdf_engine.dart';
import 'package:ui_lab_2_1/src/shared/documents/pdf/pdf_font_assets.dart';
import 'package:ui_lab_2_1/src/shared/documents/pdf/pdf_image_resolver.dart';
import 'package:ui_lab_2_1/src/shared/documents/generated_document_snapshot.dart';
import 'support/shared_pdf_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const resolver = PdfImageResolver();
  test('PNG, JPEG and transparent logos preserve aspect and fit bounds', () {
    for (final shape in [(900, 120), (120, 900), (240, 240)]) {
      for (final jpeg in [false, true]) {
        final result = resolver.decode(
          fixtureLogo(shape.$1, shape.$2, jpeg: jpeg, transparent: !jpeg),
        );
        expect(result.issue, isNull);
        final image = result.image!;
        final bounds = image.fit(160, 64);
        expect(bounds.width, lessThanOrEqualTo(160));
        expect(bounds.height, lessThanOrEqualTo(64));
        expect(
          bounds.width / bounds.height,
          closeTo(shape.$1 / shape.$2, .0001),
        );
      }
    }
  });
  test(
    'optional logos fail safely for missing, corrupt, unsupported and oversized sources',
    () async {
      expect(resolver.decode(null).issue, PdfImageIssue.missing);
      expect(
        resolver
            .decode(Uint8List.fromList([137, 80, 78, 71, 1, 2, 3, 4, 5]))
            .issue,
        PdfImageIssue.corrupt,
      );
      expect(
        resolver.decode(Uint8List.fromList([1, 2, 3])).issue,
        PdfImageIssue.unsupported,
      );
      expect(
        resolver.decode(Uint8List(13 * 1024 * 1024)).issue,
        PdfImageIssue.tooLarge,
      );
      expect(
        (await resolver.resolve(
          () async => throw FileSystemException('missing'),
        )).issue,
        PdfImageIssue.missing,
      );
      expect(
        const PdfImageResolver(maxPixels: 10).decode(fixtureLogo(20, 20)).issue,
        PdfImageIssue.tooLarge,
      );
    },
  );
  test(
    'both orientations render multi-page content with all logo scenarios',
    () async {
      final fonts = await PdfFontAssets.load();
      final output = Directory('output/pdf/infrastructure')
        ..createSync(recursive: true);
      for (final landscape in [false, true]) {
        for (final logo in [
          'none',
          'wide',
          'tall',
          'transparent',
          'jpeg',
          'corrupt',
        ]) {
          final image = switch (logo) {
            'none' => null,
            'wide' => resolver.decode(fixtureLogo(900, 120)),
            'tall' => resolver.decode(fixtureLogo(120, 900)),
            'transparent' => resolver.decode(
              fixtureLogo(200, 100, transparent: true),
            ),
            'jpeg' => resolver.decode(fixtureLogo(300, 150, jpeg: true)),
            _ => resolver.decode(
              Uint8List.fromList([137, 80, 78, 71, 0, 0, 0, 0, 0]),
            ),
          };
          final doc = await const PdfEngine().render(
            SharedPdfFixture(),
            branding: PdfBranding(
              companyName:
                  'LONG-COMPANY-BEGIN ${'Service Business Company ' * 6} LONG-COMPANY-END',
              address: 'Company address\nCity and postal code',
              phone: '555-0100',
              email: 'office@example.test',
              footerText: 'Shared footer verification',
            ),
            regularFont: fonts.regular,
            boldFont: fonts.bold,
            logo: image,
            page: PdfPageConfig(landscape: landscape),
          );
          expect(doc.pageCount, greaterThan(2));
          expect(doc.warnings.isNotEmpty, logo == 'corrupt');
          final name = '${landscape ? 'landscape' : 'portrait'}-$logo';
          File('${output.path}/$name.pdf').writeAsBytesSync(doc.bytes);
          File('${output.path}/$name.json').writeAsStringSync(
            jsonEncode({
              'pages': doc.pageCount,
              'rows': 90,
              'landscape': landscape,
            }),
          );
        }
      }
      await expectLater(
        const PdfEngine().render(
          SharedPdfFixture(rows: -1),
          branding: const PdfBranding(companyName: 'Company'),
          regularFont: fonts.regular,
          boldFont: fonts.bold,
        ),
        throwsFormatException,
      );
      await expectLater(
        const PdfEngine().render(
          SharedPdfFixture(),
          branding: const PdfBranding(companyName: 'Company'),
          regularFont: fonts.regular,
          boldFont: fonts.bold,
          page: const PdfPageConfig(maxPages: 1),
        ),
        throwsA(isA<PdfRenderFailure>()),
      );
    },
  );
  test('snapshot data is detached from mutable source maps', () {
    final input = <String, Object?>{'address': 'Old address'};
    final snapshot = GeneratedDocumentSnapshot(
      definitionVersion: '1',
      templateVersion: '1',
      sourceRecordId: 'invoice',
      sourceRevision: 1,
      definition: input,
      branding: input,
      createdAt: DateTime.utc(2026),
    );
    input['address'] = 'New address';
    snapshot.branding['address'] = 'Other address';
    expect(snapshot.branding['address'], 'Old address');
    expect(snapshot.definition['address'], 'Old address');
  });
}
