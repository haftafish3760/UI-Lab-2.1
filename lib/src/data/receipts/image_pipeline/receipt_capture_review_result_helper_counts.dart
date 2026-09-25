part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultHelpers on ReceiptPhotoReviewResult {
  String get nativeCloseCapturedPhotoHealthOutcome {
    final counts = nativeCloseCapturedPhotoOutcomeCounts;
    for (final outcome in const [
      'capture_failed_after_close',
      'closed_without_photo',
      'close_already_delivered',
      'capture_failed_returned_existing_sections',
      'waiting_for_in_flight_capture',
      'close_outcome_unknown',
      'back_returned_captured_sections',
      'next_returned_captured_sections',
      'open_or_not_closed',
    ]) {
      if ((counts[outcome] ?? 0) > 0) return outcome;
    }
    return counts.isEmpty ? 'close_outcome_unknown' : counts.keys.first;
  }

  String get nativeCloseCapturedPhotoActionLabel {
    return switch (nativeCloseCapturedPhotoHealthOutcome) {
      'back_returned_captured_sections' =>
        'Back returned captured receipt sections for review',
      'next_returned_captured_sections' || 'done_returned_captured_sections' =>
        'Next returned captured receipt sections for review',
      'capture_failed_after_close' =>
        'Capture finished after close and needs recovery review',
      'capture_failed_returned_existing_sections' =>
        'Last receipt section failed, existing sections opened for review',
      'closed_without_photo' || 'back_no_photo_cancel' =>
        'Camera closed before a receipt photo was saved',
      'close_already_delivered' => 'Camera close result was already delivered',
      'waiting_for_in_flight_capture' =>
        'Camera waited for an in-flight capture before closing',
      'open_or_not_closed' => 'Camera remained open for receipt capture',
      _ => 'Camera close outcome needs review',
    };
  }

  Map<String, int> get nativeRecoveryFreshnessCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final value = diagnostics['nativeRecoveryFreshness']?.toString().trim();
      if (value == null || value.isEmpty) continue;
      final token = _diagnosticToken(value);
      if (token == 'unknown') continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get nativeRecoveryStorageStatusCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final value = diagnostics['nativeRecoveryStorageStatus']
          ?.toString()
          .trim();
      if (value == null || value.isEmpty) continue;
      final token = _diagnosticToken(value);
      if (token == 'unknown') continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get nativeCaptureSourcePolicyCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      for (final policy in _nativeCaptureSourcePoliciesFor(diagnostics)) {
        counts[policy] = (counts[policy] ?? 0) + 1;
      }
    }
    return Map.unmodifiable(counts);
  }

  String get nativeCaptureSourcePolicyOutcome {
    final counts = nativeCaptureSourcePolicyCounts;
    for (final policy in const [
      'existing_photo_import',
      'document_scanner_backup',
      'phone_camera_backup',
      'native_recovery',
      'storage_saver_native',
      'older_phone_native',
      'flagship_native',
      'balanced_native',
      'normal_native',
    ]) {
      if ((counts[policy] ?? 0) > 0) return policy;
    }
    return 'unknown';
  }

  String get receiptBrainReleaseActionOutcome {
    final counts = receiptBrainReleaseActionCounts;
    for (final action in const [
      'move_heavy_receipt_work_to_optional_packs_before_release',
      'remove_included_parser_packs_from_required_base',
      'restore_base_capture_without_optional_packs',
      'detach_optional_receipt_packs_from_required_base',
      'ship_lean_base_and_defer_optional_receipt_packs',
      'ship_lean_base_offer_explicit_receipt_pack_download',
      'ship_lean_base_receipt_capture',
    ]) {
      if ((counts[action] ?? 0) > 0) return action;
    }
    return counts.isEmpty ? 'receipt_brain_action_unknown' : counts.keys.first;
  }

  String get receiptBrainInstallDistributionOutcome {
    final counts = receiptBrainInstallDistributionCounts;
    for (final mode in const [
      'required_base_blocked_until_optionalized',
      'base_app_only_optional_cloud_assist',
      'base_app_cloud_assist_or_later_download',
      'base_app_small_optional_receipt_pack',
      'base_app_explicit_optional_receipt_packs',
      'base_app_full_offline_optional',
      'base_app_local_reader_sufficient',
      'base_app_full_local_reader_sufficient',
      'base_app_until_storage_is_checked',
    ]) {
      if ((counts[mode] ?? 0) > 0) return mode;
    }
    return counts.isEmpty ? 'receipt_brain_install_unknown' : counts.keys.first;
  }

  String get nativeCameraUiHealthOutcome {
    final counts = nativeCameraUiHealthCounts;
    if ((counts['settings_contract_missing'] ?? 0) > 0) {
      return 'settings_contract_missing';
    }
    if ((counts['settings_control_missing'] ?? 0) > 0) {
      return 'settings_control_missing';
    }
    if ((counts['settings_button_placement_missing'] ?? 0) > 0) {
      return 'settings_button_placement_missing';
    }
    if ((counts['tap_focus_contract_retirement_regressed'] ?? 0) > 0) {
      return 'tap_focus_contract_retirement_regressed';
    }
    if ((counts['tap_focus_actual_retirement_regressed'] ?? 0) > 0) {
      return 'tap_focus_actual_retirement_regressed';
    }
    for (final entry in counts.entries) {
      if (entry.value > 0 && entry.key.endsWith('_retirement_regressed')) {
        return entry.key;
      }
    }
    if ((counts['continuous_focus_expected_but_not_configured_regressed'] ??
            0) >
        0) {
      return 'continuous_focus_expected_but_not_configured_regressed';
    }
    if ((counts['continuous_focus_configured_when_not_expected_regressed'] ??
            0) >
        0) {
      return 'continuous_focus_configured_when_not_expected_regressed';
    }
    if ((counts['native_control_readiness_missing'] ?? 0) > 0) {
      return 'native_control_readiness_missing';
    }
    if ((counts['native_controls_incomplete'] ?? 0) > 0) {
      return 'native_controls_incomplete';
    }
    if ((counts['native_control_signal_missing'] ?? 0) > 0) {
      return 'native_control_signal_missing';
    }
    if ((counts['tap_focus_retirement_regressed'] ?? 0) > 0) {
      return 'tap_focus_retirement_regressed';
    }
    if ((counts['continuous_focus_missing'] ?? 0) > 0) {
      return 'continuous_focus_missing';
    }
    if ((counts['continuous_focus_contract_missing'] ?? 0) > 0) {
      return 'continuous_focus_contract_missing';
    }
    if ((counts['focus_readability_review_contract_missing'] ?? 0) > 0) {
      return 'focus_readability_review_contract_missing';
    }
    if ((counts['continuous_focus_primary_missing'] ?? 0) > 0) {
      return 'continuous_focus_primary_missing';
    }
    if ((counts['native_focus_status_configuration_failed'] ?? 0) > 0) {
      return 'native_focus_status_configuration_failed';
    }
    if ((counts['native_focus_status_not_used'] ?? 0) > 0) {
      return 'native_focus_status_not_used';
    }
    if ((counts['readability_guidance_live_missing'] ?? 0) > 0) {
      return 'readability_guidance_live_missing';
    }
    if ((counts['receipt_camera_quality_baseline_missing'] ?? 0) > 0) {
      return 'receipt_camera_quality_baseline_missing';
    }
    if ((counts['preview_dominance_missing'] ?? 0) > 0) {
      return 'preview_dominance_missing';
    }
    if ((counts['auto_capture_without_manual_shutter_regressed'] ?? 0) > 0) {
      return 'auto_capture_without_manual_shutter_regressed';
    }
    if ((counts['auto_capture_ready_while_blocked_regressed'] ?? 0) > 0) {
      return 'auto_capture_ready_while_blocked_regressed';
    }
    if ((counts['auto_capture_allowed_without_request_regressed'] ?? 0) > 0) {
      return 'auto_capture_allowed_without_request_regressed';
    }
    if ((counts['auto_capture_ready_before_stable_regressed'] ?? 0) > 0) {
      return 'auto_capture_ready_before_stable_regressed';
    }
    if ((counts['auto_capture_ready_missing_stability_evidence'] ?? 0) > 0) {
      return 'auto_capture_ready_missing_stability_evidence';
    }
    if ((counts['auto_capture_waiting_after_stable_regressed'] ?? 0) > 0) {
      return 'auto_capture_waiting_after_stable_regressed';
    }
    if ((counts['auto_capture_waiting_without_request_regressed'] ?? 0) > 0) {
      return 'auto_capture_waiting_without_request_regressed';
    }
    if ((counts['auto_capture_waiting_missing_stability_evidence'] ?? 0) > 0) {
      return 'auto_capture_waiting_missing_stability_evidence';
    }
    if ((counts['preview_saved_darker_than_live'] ?? 0) > 0) {
      return 'preview_saved_darker_than_live';
    }
    if ((counts['preview_saved_brighter_than_live'] ?? 0) > 0) {
      return 'preview_saved_brighter_than_live';
    }
    if ((counts['native_close_deferred_during_capture'] ?? 0) > 0) {
      return 'native_close_deferred_during_capture';
    }
    if ((counts['native_close_retry_after_result'] ?? 0) > 0) {
      return 'native_close_retry_after_result';
    }
    if ((counts['native_close_no_photo_cancel'] ?? 0) > 0) {
      return 'native_close_no_photo_cancel';
    }
    if ((counts['native_capture_review_transition_missing'] ?? 0) > 0) {
      return 'native_capture_review_transition_missing';
    }
    if ((counts['native_capture_review_discard_policy_missing'] ?? 0) > 0) {
      return 'native_capture_review_discard_policy_missing';
    }
    if ((counts['native_capture_latency_slow'] ?? 0) > 0) {
      return 'native_capture_latency_slow';
    }
    if ((counts['native_capture_latency_watch'] ?? 0) > 0) {
      return 'native_capture_latency_watch';
    }
    if ((counts['preview_saved_darker_than_live_watch'] ?? 0) > 0) {
      return 'preview_saved_darker_than_live_watch';
    }
    if ((counts['preview_saved_brighter_than_live_watch'] ?? 0) > 0) {
      return 'preview_saved_brighter_than_live_watch';
    }
    if ((counts['native_controls_ready'] ?? 0) > 0) {
      return 'native_controls_ready';
    }
    return 'native_ui_signal_missing';
  }
}
