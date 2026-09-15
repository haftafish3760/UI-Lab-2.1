import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ui_lab_2_1/src/shared/documents/document_source.dart';
import 'package:ui_lab_2_1/src/shared/documents/pdf/pdf_export_service.dart';
import 'package:ui_lab_2_1/src/shared/documents/pdf/pdf_export_feedback.dart';

void main() {
  final bytes = Uint8List.fromList('%PDF-1.7\nfixture\n%%EOF'.codeUnits);
  DocumentSource source({
    Future<void> Function()? authorize,
    Uint8List? data,
  }) => DocumentSource(
    origin: DocumentOrigin.generated,
    fileName: 'Invoice / 25.PDF',
    authorize: authorize ?? () async {},
    readBytes: () async => data ?? bytes,
  );

  test(
    'native adapter receives exact authorized PDF bytes and filename',
    () async {
      var checks = 0;
      final exporter = PdfExportService(
        shareFile: (params) async {
          expect(checks, 3);
          expect(await params.files!.single.readAsBytes(), bytes);
          expect(params.files!.single.mimeType, 'application/pdf');
          expect(params.fileNameOverrides, ['Invoice - 25.pdf']);
          expect(params.subject, 'Invoice 25');
          return const ShareResult('email', ShareResultStatus.success);
        },
      );
      expect(
        await exporter.export(
          source(
            authorize: () async {
              checks++;
            },
          ),
          PdfExportAction.share,
          subject: 'Invoice 25',
        ),
        PdfExportOutcome.completed,
      );
    },
  );

  test('permission revoked before handoff prevents native sharing', () async {
    var checks = 0;
    var opened = false;
    final exporter = PdfExportService(
      shareFile: (_) async {
        opened = true;
        return const ShareResult('', ShareResultStatus.success);
      },
    );
    await expectLater(
      exporter.export(
        source(
          authorize: () async {
            checks++;
            if (checks == 3) {
              throw StateError('Permission revoked');
            }
          },
        ),
        PdfExportAction.share,
      ),
      throwsStateError,
    );
    expect(opened, isFalse);
  });

  test('invalid PDF never reaches native sharing', () async {
    var opened = false;
    final exporter = PdfExportService(
      shareFile: (_) async {
        opened = true;
        return const ShareResult('', ShareResultStatus.success);
      },
    );
    await expectLater(
      exporter.export(
        source(data: Uint8List.fromList([1, 2])),
        PdfExportAction.share,
      ),
      throwsFormatException,
    );
    expect(opened, isFalse);
  });

  test('cancellation and unavailable Windows result remain distinct', () async {
    for (final pair in [
      (ShareResultStatus.dismissed, PdfExportOutcome.cancelled),
      (ShareResultStatus.unavailable, PdfExportOutcome.unconfirmed),
    ]) {
      final exporter = PdfExportService(
        shareFile: (_) async => ShareResult('', pair.$1),
      );
      expect(await exporter.export(source(), PdfExportAction.share), pair.$2);
    }
    expect(
      pdfExportOutcomeMessage(
        PdfExportAction.share,
        PdfExportOutcome.unconfirmed,
      ),
      contains('could not be confirmed'),
    );
    expect(
      pdfExportOutcomeMessage(
        PdfExportAction.share,
        PdfExportOutcome.completed,
      ),
      contains('confirm it was sent'),
    );
  });

  test('validation is actionable and native errors do not leak details', () {
    expect(
      pdfExportErrorMessage(const FormatException('Add an item.')),
      contains('Add an item.'),
    );
    expect(
      pdfExportErrorMessage(MissingPluginException()),
      contains('Save PDF copy'),
    );
    final message = pdfExportErrorMessage(
      PlatformException(code: 'secret-path', message: 'private data'),
    );
    expect(message, isNot(contains('private data')));
    expect(message, isNot(contains('secret-path')));
  });
}
