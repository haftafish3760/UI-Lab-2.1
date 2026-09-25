import 'package:flutter/foundation.dart';

/// Privacy-safe stage tracing for receipt QA. It records timing and control
/// flow only—never OCR text, merchant data, totals, paths, or user identifiers.
void traceReceiptPipelineStage(
  String stage, {
  required String traceId,
  int? elapsedMs,
  int? sourceCount,
  int? textCharacterCount,
  int? layoutLineCount,
  int? candidateLineCount,
  int? parsedLineCount,
  int? recoveredLineCount,
  String? deviceTier,
  String? destination,
}) {
  if (!kDebugMode) return;
  final fields = <String>[
    'stage=${_safeTraceToken(stage)}',
    'trace=${_safeTraceToken(traceId)}',
    if (elapsedMs != null) 'elapsedMs=$elapsedMs',
    if (sourceCount != null) 'sourceCount=$sourceCount',
    if (textCharacterCount != null) 'textCharacters=$textCharacterCount',
    if (layoutLineCount != null) 'layoutLines=$layoutLineCount',
    if (candidateLineCount != null) 'candidateLines=$candidateLineCount',
    if (parsedLineCount != null) 'parsedLines=$parsedLineCount',
    if (recoveredLineCount != null) 'recoveredLines=$recoveredLineCount',
    if (deviceTier != null) 'deviceTier=${_safeTraceToken(deviceTier)}',
    if (destination != null) 'destination=${_safeTraceToken(destination)}',
  ];
  debugPrint('MAINTAINIAC_RECEIPT_TRACE ${fields.join(' ')}');
}

String newReceiptPipelineTraceId() =>
    DateTime.now().microsecondsSinceEpoch.toRadixString(36);

String _safeTraceToken(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_')
      .substring(0, value.trim().length.clamp(0, 64));
}
