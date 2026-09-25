part of 'receipt_capture_models.dart';

double? _doubleValue(Object? value) {
  final parsed = switch (value) {
    num() => value.toDouble(),
    String() => double.tryParse(value.trim()),
    _ => null,
  };
  if (parsed == null || !parsed.isFinite) return null;
  return parsed;
}

bool _bottomEdgeMissing(
  Map<String, Object?>? diagnostics, {
  required bool nativeCutOffRisk,
  required double? edgeCoverage,
  required double? bottomEdgeScore,
  required double? framingHeightRatio,
}) {
  final detected = _boolValue(
    diagnostics?[ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected],
  );
  if (detected == false) return true;
  if (detected == true) return false;

  final status =
      diagnostics?[ReceiptCaptureDiagnosticKeys.receiptBottomEdgeStatus]
          ?.toString()
          .trim()
          .toLowerCase();
  if (status != null && status.isNotEmpty) {
    if (_missingBottomEdgeStatuses.contains(status)) return true;
    if (_presentBottomEdgeStatuses.contains(status)) return false;
  }

  if (bottomEdgeScore != null &&
      bottomEdgeScore >= 0 &&
      bottomEdgeScore < .20) {
    return true;
  }
  if (nativeCutOffRisk && edgeCoverage != null && edgeCoverage < .45) {
    return true;
  }
  if (nativeCutOffRisk &&
      framingHeightRatio != null &&
      framingHeightRatio > 0 &&
      framingHeightRatio < .52) {
    return true;
  }
  if (nativeCutOffRisk &&
      edgeCoverage == null &&
      bottomEdgeScore == null &&
      framingHeightRatio == null) {
    return true;
  }
  return false;
}

bool _totalsEvidenceMissing(Map<String, Object?>? diagnostics) {
  if (diagnostics == null || !_hasTotalsEvidenceSignal(diagnostics)) {
    return false;
  }
  if (_boolValue(
        diagnostics[ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected],
      ) ==
      true) {
    return false;
  }
  if (_boolValue(
        diagnostics[ReceiptCaptureDiagnosticKeys.receiptTotalDetected],
      ) ==
      true) {
    return false;
  }
  if (_boolValue(
        diagnostics[ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected],
      ) ==
      true) {
    return false;
  }
  if (_intValue(diagnostics['subtotalCandidateLineCount']) > 0) return false;
  if (_intValue(diagnostics['totalCandidateLineCount']) > 0) return false;
  final status =
      diagnostics[ReceiptCaptureDiagnosticKeys.receiptTotalsTextEvidenceStatus]
          ?.toString()
          .trim()
          .toLowerCase();
  if (status != null &&
      status.isNotEmpty &&
      !_missingTotalsEvidenceStatuses.contains(status)) {
    return false;
  }
  return status == null ||
      status.isEmpty ||
      _missingTotalsEvidenceStatuses.contains(status);
}

bool _hasTotalsEvidenceSignal(Map<String, Object?> diagnostics) {
  return diagnostics.containsKey(
        ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected,
      ) ||
      diagnostics.containsKey(
        ReceiptCaptureDiagnosticKeys.receiptTotalDetected,
      ) ||
      diagnostics.containsKey(
        ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected,
      ) ||
      diagnostics.containsKey('subtotalCandidateLineCount') ||
      diagnostics.containsKey('totalCandidateLineCount') ||
      diagnostics.containsKey('taxCandidateLineCount') ||
      diagnostics.containsKey('receiptSummaryLineCount') ||
      diagnostics.containsKey(
        ReceiptCaptureDiagnosticKeys.receiptTotalsTextEvidenceStatus,
      );
}

bool? _boolValue(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == 'yes' || text == '1') return true;
  if (text == 'false' || text == 'no' || text == '0') return false;
  return null;
}

int _intValue(Object? value) {
  if (value is int) return value;
  final parsed = switch (value) {
    num() when value.isFinite => value,
    String() => double.tryParse(value.trim()),
    _ => null,
  };
  if (parsed == null || !parsed.isFinite) return 0;
  if (parsed % 1 != 0) return 0;
  return parsed.toInt();
}

const Set<String> _missingBottomEdgeStatuses = {
  'missing',
  'not_found',
  'cut_off',
  'possibly_cut_off',
  'outside_frame',
  'needs_next_section',
  'continues',
  'bottom_soft_or_missing',
  'bottom_missing',
  'soft_or_missing',
};

const Set<String> _presentBottomEdgeStatuses = {
  'found',
  'present',
  'visible',
  'complete',
  'framed',
  'bottom_visible',
};

const Set<String> _missingTotalsEvidenceStatuses = {
  'missing',
  'none',
  'not_found',
  'no_totals',
  'needs_next_section',
  'incomplete',
};
