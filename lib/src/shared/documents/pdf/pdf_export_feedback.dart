import 'package:flutter/services.dart';
import 'pdf_engine.dart';
import 'pdf_export_service.dart';

/// User-facing feedback never treats opening another app as proof of delivery.
String pdfExportOutcomeMessage(
  PdfExportAction action,
  PdfExportOutcome outcome,
) {
  if (outcome == PdfExportOutcome.cancelled) {
    return 'Cancelled. Your saved document is unchanged.';
  }
  if (action == PdfExportAction.share) {
    return outcome == PdfExportOutcome.unconfirmed
        ? 'Delivery could not be confirmed. Check your sharing app. You can also save the PDF and attach it yourself.'
        : 'The PDF was handed to your sharing app. Check that app to confirm it was sent.';
  }
  if (outcome == PdfExportOutcome.unconfirmed) {
    return 'The result could not be confirmed. Check the destination before trying again.';
  }
  return action == PdfExportAction.save
      ? 'PDF saved.'
      : 'The PDF was handed to the print service.';
}

String pdfExportErrorMessage(Object error) {
  if (error is FormatException) {
    return '${error.message} Review the document before trying again.';
  }
  if (error is StateError) {
    return error.message.toString();
  }
  if (error is PdfRenderFailure) {
    return '${error.message} Your saved information is unchanged.';
  }
  if (error is MissingPluginException || error is UnimplementedError) {
    return 'This action is unavailable on this device. Try Save PDF copy, then attach the file in your email or messaging app.';
  }
  if (error is PlatformException) {
    return 'The device could not finish this action. Check the destination app or try Save PDF copy. Your document remains saved.';
  }
  return 'The PDF action could not finish. Your document remains saved. Try again or use Save PDF copy.';
}
