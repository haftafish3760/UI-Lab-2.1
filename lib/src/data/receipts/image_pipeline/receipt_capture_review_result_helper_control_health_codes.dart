part of 'receipt_capture_models.dart';

List<String> _nativeControlReadinessHealthCodes(
  Map<String, Object?> diagnostics,
) {
  final codes = <String>[];
  final contractTags = _diagnosticStringList(
    diagnostics['nativeControlContractTags'],
  );
  var checkedControls = 0;
  var missingControls = 0;
  void check({
    required String name,
    required bool expected,
    required String actualKey,
    List<String> contractAliases = const [],
  }) {
    final contractExpected =
        contractTags.contains(name) ||
        contractAliases.any(contractTags.contains);
    if (_retiredNativeContractControls.contains(name) &&
        contractExpected &&
        !expected) {
      codes.add('${name}_contract_retirement_regressed');
      return;
    }
    final actual = diagnostics[actualKey]?.toString().trim();
    if (_retiredNativeContractControls.contains(name) &&
        !expected &&
        _retiredControlLooksActive(actual)) {
      codes.add('${name}_actual_retirement_regressed');
      return;
    }
    if (!expected && !contractExpected) return;
    if (actual == null || actual.isEmpty) {
      missingControls++;
      codes.add('${name}_actual_control_missing');
      return;
    }
    checkedControls++;
    final token = _diagnosticToken(actual);
    codes.add(
      token == 'ready'
          ? '${name}_actual_control_ready'
          : '${name}_actual_control_missing',
    );
    if (token != 'ready') missingControls++;
  }

  if (contractTags.isNotEmpty) {
    codes.add('native_control_contract_tags_present');
    codes.add('native_control_contract_${contractTags.length}_tags');
    for (final tag in contractTags) {
      codes.add('native_control_contract_expected_${_diagnosticToken(tag)}');
    }
  }
  check(
    name: 'back',
    expected: diagnostics['backControlExpected'] == true,
    actualKey: 'backControlActual',
  );
  check(
    name: 'settings',
    expected: diagnostics['settingsControlExpected'] == true,
    actualKey: 'settingsControlActual',
  );
  check(
    name: 'manual_shutter',
    expected: diagnostics['manualShutterAlwaysAvailable'] == true,
    actualKey: 'manualShutterControlActual',
  );
  check(
    name: 'tap_focus',
    expected: diagnostics['tapFocusControlExpected'] == true,
    actualKey: 'tapFocusControlActual',
  );
  check(
    name: 'pinch_zoom',
    expected: diagnostics['pinchZoomControlExpected'] == true,
    actualKey: 'pinchZoomControlActual',
  );
  check(
    name: 'exposure_slider',
    expected: diagnostics['exposureSliderControlExpected'] == true,
    actualKey: 'exposureSliderControlActual',
    contractAliases: const ['brightness_slider'],
  );
  check(
    name: 'exposure_reset',
    expected: diagnostics['exposureResetControlExpected'] == true,
    actualKey: 'exposureResetControlActual',
    contractAliases: const ['brightness_reset'],
  );
  check(
    name: 'torch',
    expected: diagnostics['torchControlExpected'] == true,
    actualKey: 'torchControlActual',
  );
  check(
    name: 'focus_lock',
    expected: diagnostics['focusLockControlExpected'] == true,
    actualKey: 'focusLockControlActual',
  );
  check(
    name: 'exposure_lock',
    expected: diagnostics['exposureLockControlExpected'] == true,
    actualKey: 'exposureLockControlActual',
    contractAliases: const ['brightness_lock'],
  );
  check(
    name: 'white_balance_lock',
    expected: diagnostics['whiteBalanceLockControlExpected'] == true,
    actualKey: 'whiteBalanceLockControlActual',
  );

  final summary = diagnostics['nativeControlReadinessSummary']
      ?.toString()
      .trim();
  if (summary != null && summary.isNotEmpty) {
    codes.add('native_control_readiness_${_diagnosticToken(summary)}');
  } else if (checkedControls > 0) {
    codes.add('native_control_readiness_ready');
  }
  if (missingControls > 0) codes.add('native_control_readiness_missing');
  return List.unmodifiable(codes);
}

const _retiredNativeContractControls = {
  'tap_focus',
  'focus_lock',
  'exposure_lock',
  'white_balance_lock',
};

bool _retiredControlLooksActive(String? value) {
  if (value == null || value.isEmpty) return false;
  final token = _diagnosticToken(value);
  return token == 'ready' ||
      token == 'enabled' ||
      token == 'visible_enabled' ||
      token == 'requested' ||
      token == 'active' ||
      token == 'locked';
}

List<String> _nativeCaptureLatencyHealthCodes(
  Map<String, Object?> diagnostics,
) {
  final bucket = _diagnosticToken(
    diagnostics[ReceiptCaptureDiagnosticKeys.latestNativeCaptureLatencyBucket]
            ?.toString() ??
        '',
  );
  if (bucket == 'unknown') return const [];
  final codes = <String>['native_capture_latency_$bucket'];
  if (bucket.startsWith('review_fast') ||
      bucket.startsWith('review_good') ||
      bucket.startsWith('save_fast') ||
      bucket.startsWith('save_good')) {
    codes.add('native_capture_latency_ready');
  } else if (bucket.startsWith('review_watch') ||
      bucket.startsWith('save_review')) {
    codes.add('native_capture_latency_watch');
  } else if (bucket.contains('slow')) {
    codes.add('native_capture_latency_slow');
  }
  return List.unmodifiable(codes);
}

List<String> _nativeCaptureReviewTransitionHealthCodes(
  Map<String, Object?> diagnostics,
) {
  final policy = _diagnosticToken(
    diagnostics['nativeCaptureReviewTransitionPolicy']?.toString() ?? '',
  );
  final target = _diagnosticToken(
    diagnostics['nativeCaptureReviewTransitionTarget']?.toString() ?? '',
  );
  final discard = _diagnosticToken(
    diagnostics['nativeCaptureReviewDiscardPolicy']?.toString() ?? '',
  );
  return List.unmodifiable([
    if (policy == 'captured_photos_must_open_review_then_receipt_details')
      'native_capture_review_transition_ready'
    else
      'native_capture_review_transition_missing',
    if (target == 'receipt_photo_review_next_to_receipt_details')
      'native_capture_review_target_receipt_details',
    if (discard == 'never_discard_captured_photo_on_back')
      'native_capture_review_discard_protected'
    else
      'native_capture_review_discard_policy_missing',
  ]);
}

List<String> _receiptReviewOpeningHealthCodes(
  Map<String, Object?> diagnostics,
) {
  final route = _diagnosticToken(
    diagnostics['receiptReviewOpeningRoute']?.toString() ?? '',
  );
  final source = _diagnosticToken(
    diagnostics['receiptReviewOpeningSource']?.toString() ?? '',
  );
  final policy = _diagnosticToken(
    diagnostics['receiptReviewOpeningPolicy']?.toString() ?? '',
  );
  final firstAction = _diagnosticToken(
    diagnostics['receiptReviewOpeningExpectedFirstAction']?.toString() ?? '',
  );
  return List.unmodifiable([
    if (route != 'unknown') 'receipt_review_opening_route_$route',
    if (source != 'unknown') 'receipt_review_opening_source_$source',
    if (policy == 'open_photo_review_before_ocr_or_receipt_form')
      'receipt_review_opening_before_ocr',
    if (firstAction == 'next_or_add_photo_visible_before_scroll')
      'receipt_review_opening_core_actions_visible',
  ]);
}
