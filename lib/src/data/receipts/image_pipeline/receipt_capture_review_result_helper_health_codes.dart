part of 'receipt_capture_models.dart';

List<String> _nativeExposureControlHealthCodes(
  Map<String, Object?> diagnostics,
) {
  final policy = _diagnosticToken(
    diagnostics['preCaptureExposurePolicy']?.toString() ?? '',
  );
  final outcome = _diagnosticToken(
    diagnostics[ReceiptCaptureDiagnosticKeys.preCaptureExposureOutcome]
            ?.toString() ??
        '',
  );
  final selectedExposure = _diagnosticToken(
    diagnostics['selectedExposureBucket']?.toString() ?? '',
  );
  final skipReason = _diagnosticToken(
    diagnostics['lastPreCaptureExposureSkipReason']?.toString() ?? '',
  );
  return List.unmodifiable([
    if (policy != 'unknown') 'exposure_policy_$policy',
    if (outcome != 'unknown') 'pre_capture_exposure_$outcome',
    if (outcome == 'lifted_for_dim_receipt')
      'pre_capture_exposure_lifted_dim_receipt',
    if (outcome == 'kept_native_auto') 'pre_capture_exposure_native_auto_ok',
    if (outcome == 'skipped') 'pre_capture_exposure_skipped',
    if (selectedExposure == 'exposure_brighter')
      'manual_brightness_user_raised'
    else if (selectedExposure == 'exposure_darker')
      'manual_brightness_user_lowered'
    else if (selectedExposure == 'exposure_baseline')
      'manual_brightness_baseline',
    if (skipReason != 'unknown') 'pre_capture_exposure_skip_$skipReason',
  ]);
}

List<String> _nativeFocusReadabilityHealthCodes(
  Map<String, Object?> diagnostics,
) {
  final codes = <String>[];
  final tapFocusExpected = _diagnosticBool(
    diagnostics['tapFocusControlExpected'],
  );
  final continuousFocusExpected = _diagnosticBool(
    diagnostics['continuousFocusExpected'],
  );
  final focusPolicy = _diagnosticToken(
    diagnostics['focusStrategyPolicy']?.toString() ?? '',
  );
  final focusFallbackPolicy = _diagnosticToken(
    diagnostics['focusReadabilityFallbackPolicy']?.toString() ?? '',
  );
  final lastFocusStatus = _diagnosticToken(
    diagnostics['lastFocusStatus']?.toString() ?? '',
  );
  final readabilityPolicy = _diagnosticToken(
    diagnostics['readabilityGuidancePolicy']?.toString() ?? '',
  );
  final qualityBaseline = _diagnosticBool(
    diagnostics['receiptCameraQualityBaseline'],
  );
  final contractTags = _diagnosticStringList(
    diagnostics['nativeControlContractTags'],
  );

  if (tapFocusExpected == true) {
    codes.add('tap_focus_retirement_regressed');
  } else if (tapFocusExpected == false) {
    codes.add('tap_focus_retired');
  }

  if (continuousFocusExpected == true) {
    codes.add('continuous_focus_expected');
    if (contractTags.isNotEmpty && !contractTags.contains('continuous_focus')) {
      codes.add('continuous_focus_contract_missing');
    }
    if (lastFocusStatus == 'continuous_autofocus_unavailable' ||
        lastFocusStatus == 'continuous_focus_not_requested') {
      codes.add('continuous_focus_expected_but_not_configured_regressed');
    }
  } else if (continuousFocusExpected == false) {
    codes.add('continuous_focus_missing');
    if (contractTags.isNotEmpty &&
        focusFallbackPolicy.contains('review_required') &&
        !contractTags.contains('focus_readability_review')) {
      codes.add('focus_readability_review_contract_missing');
    }
    if (lastFocusStatus == 'continuous_autofocus_configured') {
      codes.add('continuous_focus_configured_when_not_expected_regressed');
    }
  }

  if (focusPolicy == 'continuous_focus_primary_no_tap_assist') {
    codes.add('continuous_focus_primary_ready');
  } else if (focusPolicy != 'unknown') {
    codes.add('continuous_focus_primary_missing');
  }

  if (focusFallbackPolicy != 'unknown') {
    codes.add('focus_readability_fallback_$focusFallbackPolicy');
  }
  if (lastFocusStatus == 'continuous_autofocus_configured') {
    codes.add('native_focus_status_continuous_configured');
  } else if (lastFocusStatus == 'continuous_autofocus_unavailable') {
    codes.add('native_focus_status_continuous_unavailable');
  } else if (lastFocusStatus == 'continuous_focus_not_requested') {
    codes.add('native_focus_status_not_requested');
  } else if (lastFocusStatus == 'continuous_autofocus_configuration_failed') {
    codes.add('native_focus_status_configuration_failed');
  } else if (lastFocusStatus == 'not_used') {
    codes.add('native_focus_status_not_used');
  } else if (lastFocusStatus != 'unknown') {
    codes.add('native_focus_status_unknown');
  }

  if (readabilityPolicy == 'native_camera_receipt_quality_guidance_v1') {
    codes.add('readability_guidance_live_quality_ready');
  } else if (readabilityPolicy ==
      'native_camera_baseline_neutral_receipt_guidance') {
    codes.add('readability_guidance_neutral_workflow_ready');
  } else if (readabilityPolicy != 'unknown') {
    codes.add('readability_guidance_live_missing');
  }

  if (qualityBaseline == true) {
    codes.add('receipt_camera_quality_baseline_ready');
  } else if (qualityBaseline == false) {
    codes.add('receipt_camera_quality_baseline_missing');
  }

  return List.unmodifiable(codes);
}

List<String> _nativeCloseHealthCodes(Map<String, Object?> diagnostics) {
  final closeOutcome = _diagnosticToken(
    diagnostics['closeCapturedPhotoOutcome']?.toString() ?? '',
  );
  final closePolicy = _diagnosticToken(
    diagnostics['closeCapturedPhotoPolicy']?.toString() ?? '',
  );
  final closeAction = _diagnosticToken(
    diagnostics['closeAction']?.toString() ?? '',
  );
  return List.unmodifiable([
    if (closeOutcome != 'unknown') 'native_close_outcome_$closeOutcome',
    if (closePolicy != 'unknown') 'native_close_policy_$closePolicy',
    if (closeAction != 'unknown' && closeAction != 'open')
      'native_close_action_$closeAction',
    if (_diagnosticPositive(diagnostics['closeDuringCaptureCount']) ||
        diagnostics['pendingCloseAfterCapture'] == true)
      'native_close_deferred_during_capture',
    if (_diagnosticPositive(diagnostics['closeRequestCount']))
      'native_close_request_recorded',
    if (diagnostics['closeResultDelivered'] == true)
      'native_close_result_delivered',
    if (_diagnosticPositive(diagnostics['closeRetryCount']))
      'native_close_retry_after_result',
    if (_diagnosticPositive(diagnostics['closeNoPhotoCancelCount']) ||
        closeAction == 'back_no_photo_cancel' ||
        closeAction == 'done_no_photo_cancel')
      'native_close_no_photo_cancel',
    if (_diagnosticPositive(diagnostics['closeReturnedSectionsCount']) ||
        closeAction == 'back_returned_captured_sections' ||
        closeOutcome == 'back_returned_captured_sections' ||
        closeOutcome == 'next_returned_captured_sections')
      'native_close_returned_captured_sections',
    if (closeOutcome == 'capture_failed_after_close')
      'native_close_capture_failed_after_close',
    if (closeOutcome == 'capture_failed_returned_existing_sections')
      'native_close_capture_failed_returned_existing_sections',
    if (closeOutcome == 'closed_without_photo')
      'native_close_closed_without_photo',
    if (closeOutcome == 'close_already_delivered')
      'native_close_already_delivered',
    if (closeOutcome == 'waiting_for_in_flight_capture')
      'native_close_waiting_for_in_flight_capture',
  ]);
}

List<String> _nativeCapturePreviewParityHealthCodes(
  Map<String, Object?> diagnostics,
) {
  final codes = <String>[];
  final readiness = _diagnosticToken(
    diagnostics[ReceiptCaptureDiagnosticKeys.captureReadinessCode]
            ?.toString() ??
        '',
  );
  final manualAllowed =
      diagnostics[ReceiptCaptureDiagnosticKeys.manualCaptureAllowed] == true;
  final autoAllowed =
      diagnostics[ReceiptCaptureDiagnosticKeys.autoCaptureAllowed] == true;
  final autoEnabled =
      diagnostics[ReceiptCaptureDiagnosticKeys.autoCaptureEnabled] == true;
  final stableFrames = _diagnosticZeroOrPositiveInt(
    diagnostics[ReceiptCaptureDiagnosticKeys.stableFrameCount],
  );
  final requiredFrames = _diagnosticPositiveInt(
    diagnostics[ReceiptCaptureDiagnosticKeys.requiredStableFrames],
  );
  if (readiness != 'unknown') {
    codes.add('capture_readiness_$readiness');
  }
  if (manualAllowed) {
    codes.add('manual_capture_allowed');
  }
  if (autoAllowed) {
    codes.add('auto_capture_allowed');
  } else if (autoEnabled) {
    codes.add('auto_capture_held_back');
  }
  if (autoAllowed && !manualAllowed) {
    codes.add('auto_capture_without_manual_shutter_regressed');
  }
  if (readiness == 'auto_capture_ready' && !autoAllowed) {
    codes.add('auto_capture_ready_while_blocked_regressed');
  }
  if (autoAllowed && !autoEnabled) {
    codes.add('auto_capture_allowed_without_request_regressed');
  }
  if (readiness == 'auto_capture_ready' &&
      stableFrames != null &&
      requiredFrames != null &&
      stableFrames < requiredFrames) {
    codes.add('auto_capture_ready_before_stable_regressed');
  }
  if (readiness == 'auto_capture_ready' &&
      (stableFrames == null || requiredFrames == null)) {
    codes.add('auto_capture_ready_missing_stability_evidence');
  }
  if (readiness == 'auto_capture_waiting_for_stability' &&
      stableFrames != null &&
      requiredFrames != null &&
      stableFrames >= requiredFrames) {
    codes.add('auto_capture_waiting_after_stable_regressed');
  }
  if (readiness == 'auto_capture_waiting_for_stability' && !autoEnabled) {
    codes.add('auto_capture_waiting_without_request_regressed');
  }
  if (readiness == 'auto_capture_waiting_for_stability' &&
      (stableFrames == null || requiredFrames == null)) {
    codes.add('auto_capture_waiting_missing_stability_evidence');
  }
  final signal =
      diagnostics[ReceiptCaptureDiagnosticKeys
              .latestCapturedPreviewParitySignal]
          ?.toString()
          .trim();
  final bucket =
      diagnostics[ReceiptCaptureDiagnosticKeys
              .latestCapturedLiveToSavedLumaDeltaBucket]
          ?.toString()
          .trim();
  final lightingEvidence = _diagnosticToken(
    diagnostics[ReceiptCaptureDiagnosticKeys.capturedLightingEvidence]
            ?.toString() ??
        '',
  );
  if (lightingEvidence != 'unknown') {
    codes.add('captured_lighting_evidence_$lightingEvidence');
  }
  if (diagnostics['manualCapturePolicy'] ==
      'guidance_advisory_manual_shutter_always_allowed') {
    codes.add('manual_capture_not_blocked_by_quality_guidance');
  }
  if (signal == null && bucket == null) return List.unmodifiable(codes);
  if (signal == 'saved_photo_darker_than_preview_review_needed' ||
      bucket == 'saved_much_darker_than_preview') {
    codes.add('preview_saved_darker_than_live');
  } else if (signal == 'saved_photo_darker_than_preview_watch' ||
      bucket == 'saved_darker_than_preview') {
    codes.add('preview_saved_darker_than_live_watch');
  } else if (signal == 'saved_photo_brighter_than_preview_review_needed' ||
      bucket == 'saved_much_brighter_than_preview') {
    codes.add('preview_saved_brighter_than_live');
  } else if (signal == 'saved_photo_brighter_than_preview_watch' ||
      bucket == 'saved_brighter_than_preview') {
    codes.add('preview_saved_brighter_than_live_watch');
  } else if (signal == 'saved_photo_matches_preview' ||
      bucket == 'saved_matches_preview') {
    codes.add('preview_saved_parity_ok');
  } else {
    codes.add('preview_saved_parity_review');
  }
  return List.unmodifiable(codes);
}

Set<String> _nativeCaptureSourcePoliciesFor(Map<String, Object?> diagnostics) {
  final policies = <String>{};
  final captureFlow = diagnostics['captureFlow']?.toString().trim() ?? '';
  if (captureFlow == 'existing_receipt_photo_import' ||
      diagnostics['existingPhotoImportUsed'] == true) {
    policies.add('existing_photo_import');
  }
  if (captureFlow == 'document_scanner_backup_receipt_photo' ||
      diagnostics['documentScannerBackupUsed'] == true) {
    policies.add('document_scanner_backup');
  }
  if (captureFlow == 'phone_camera_backup_receipt_photo' ||
      diagnostics['phoneCameraBackupUsed'] == true) {
    policies.add('phone_camera_backup');
  }
  if (diagnostics.containsKey('nativeRecoveryResumeStatus') ||
      diagnostics.containsKey('nativeRecoveryFreshness') ||
      diagnostics['nativeCaptureRecoveryAttachmentState'] ==
          'staged_not_attached') {
    policies.add('native_recovery');
  }
  final policy = diagnostics['nativeCaptureMemoryPolicy']?.toString().trim();
  final workloadProtection = diagnostics['workloadProtectionPolicy']
      ?.toString()
      .trim();
  final workload = diagnostics['cameraWorkloadTier']?.toString().trim();
  final surface = diagnostics['captureSurface']?.toString().trim() ?? '';
  final nativeCapture =
      surface.startsWith('maintainiac_native_') ||
      captureFlow == 'maintainiac_native_receipt_camera' ||
      policy != null;
  if (!nativeCapture) return policies;
  if (diagnostics['storageConstrained'] == true ||
      workloadProtection?.contains('storage_saver') == true ||
      policy?.contains('small_local_proof') == true ||
      policy?.contains('tiny_local_proof') == true) {
    policies.add('storage_saver_native');
  }
  if (workloadProtection?.contains('older_phone') == true ||
      policy?.contains('older_phone') == true ||
      workload == 'light') {
    policies.add('older_phone_native');
  }
  if (workloadProtection == 'flagship_full_workload') {
    policies.add('flagship_native');
  }
  if (workloadProtection == 'balanced_workload') {
    policies.add('balanced_native');
  }
  if (policies.isEmpty) policies.add('normal_native');
  return policies;
}

String _acceptedPhotoQualityOutcomeFor({
  ReceiptPhotoQualityCheck? quality,
  Map<String, Object?>? diagnostics,
}) {
  final nativeWarning =
      ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(diagnostics);
  if (nativeWarning?.isCritical == true || quality?.hasCriticalIssue == true) {
    return 'critical_quality_retake_recommended';
  }
  final coverageDecision = ReceiptPhotoCoverageDecision.fromSignals(
    quality: quality,
    diagnostics: diagnostics,
  );
  if (coverageDecision.shouldPromptForMorePhotos) {
    return 'possible_partial_receipt';
  }
  if (nativeWarning != null || quality?.needsReview == true) {
    return 'needs_review_before_ocr';
  }
  if (quality == null && (diagnostics == null || diagnostics.isEmpty)) {
    return 'accepted_no_quality_signal';
  }
  return 'ready_for_receipt_review';
}

String _nativeControlSetHealthCode(String? controlSet) {
  if (controlSet == null || controlSet.isEmpty) {
    return 'native_control_signal_missing';
  }
  final controls = controlSet
      .split('|')
      .map((control) => control.trim())
      .where((control) => control.isNotEmpty)
      .toSet();
  const requiredControls = {'back', 'settings', 'manual_shutter', 'status'};
  return controls.containsAll(requiredControls)
      ? 'native_controls_ready'
      : 'native_controls_incomplete';
}
