import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../document_source.dart';

enum PdfExportAction { save, share, print }

enum PdfExportOutcome { completed, cancelled, unconfirmed }

/// File destination mechanics only. No document/business lookup or status edits.
class PdfExportService {
  const PdfExportService({this.shareFile});

  /// Optional native adapter for hosts/tests; authorization stays in this service.
  final Future<ShareResult> Function(ShareParams)? shareFile;
  Future<PdfExportOutcome> export(
    DocumentSource source,
    PdfExportAction action, {
    Rect shareOrigin = const Rect.fromLTWH(0, 0, 1, 1),
    String? subject,
    String? text,
    String? recipient,
    String? composeMethod,
  }) async {
    final bytes = await source.open();
    if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw const FormatException('This file is not a PDF.');
    }
    await source.authorize();
    final name =
        '${source.fileName.replaceAll(RegExp(r'[^a-zA-Z0-9 _.-]'), '-').replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')}.pdf';
    switch (action) {
      case PdfExportAction.save:
        final path = await FilePicker.saveFile(
          fileName: name,
          bytes: bytes,
          mimeType: 'application/pdf',
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        return path == null
            ? PdfExportOutcome.cancelled
            : PdfExportOutcome.completed;
      case PdfExportAction.print:
        final printed = await Printing.layoutPdf(
          name: name,
          onLayout: (_) async => bytes,
        );
        return printed
            ? PdfExportOutcome.completed
            : PdfExportOutcome.cancelled;
      case PdfExportAction.share:
        if (composeMethod != null &&
            recipient != null &&
            recipient.trim().isNotEmpty) {
          try {
            final result =
                await const MethodChannel(
                  'maintainiac/document_compose',
                ).invokeMethod<String>('compose', {
                  'bytes': bytes,
                  'recipient': recipient.trim(),
                  'method': composeMethod,
                  'name': name,
                  'subject': subject,
                  'text': text,
                });
            return result == 'cancelled'
                ? PdfExportOutcome.cancelled
                : PdfExportOutcome.unconfirmed;
          } on MissingPluginException {
            throw StateError(
              'Recipient-aware composition is unavailable on this device. Choose Share PDF to use an installed app.',
            );
          } on PlatformException catch (error) {
            throw StateError(
              error.message ?? 'The composer could not open. Try Share PDF.',
            );
          }
        }
        final result = await (shareFile ?? SharePlus.instance.share)(
          ShareParams(
            subject: subject,
            text: text,
            files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
            fileNameOverrides: [name],
            sharePositionOrigin: shareOrigin,
          ),
        );
        return switch (result.status) {
          ShareResultStatus.success => PdfExportOutcome.completed,
          ShareResultStatus.dismissed => PdfExportOutcome.cancelled,
          ShareResultStatus.unavailable => PdfExportOutcome.unconfirmed,
        };
    }
  }
}
