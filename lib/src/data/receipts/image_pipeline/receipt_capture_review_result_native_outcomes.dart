part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultNativeOutcomes on ReceiptPhotoReviewResult {
  String get receiptRequiredBaseFootprintStatusOutcome {
    final counts = receiptRequiredBaseFootprintStatusCounts;
    if (counts.isEmpty) return '';
    if ((counts['blocked'] ?? 0) > 0) return 'blocked';
    if ((counts['review'] ?? 0) > 0) return 'review';
    if ((counts['ready'] ?? 0) > 0) return 'ready';
    return _firstPreferredCountKey(counts, const []);
  }

  String get receiptBrainBaseSizeDecisionOutcome {
    final counts = receiptBrainBaseSizeDecisionCounts;
    if (counts.isEmpty) return '';
    if ((counts['block_base_over_100mb'] ?? 0) > 0) {
      return 'base_size_blocked_over_100mb';
    }
    if ((counts['block_included_parser_pack_in_base'] ?? 0) > 0 ||
        (counts['block_base_requires_optional_pack'] ?? 0) > 0 ||
        (counts['block_optional_pack_attached_to_base'] ?? 0) > 0) {
      return 'base_size_blocked_payload_structure';
    }
    if ((counts['review_base_over_50mb'] ?? 0) > 0) {
      return 'base_size_review_required';
    }
    return 'base_size_ready';
  }

  String get receiptBrainFirstInstallBoundaryOutcome {
    final counts = receiptBrainFirstInstallBoundaryCounts;
    if (counts.isEmpty) return '';
    for (final outcome in const [
      'blocked_capture_depends_on_deferred_pack',
      'blocked_base_reader_missing',
      'blocked_heavy_pack_in_first_install',
      'blocked_deferred_pack_attached_to_first_install',
      'blocked_first_install_over_100mb',
      'review_first_install_over_50mb',
      'ready_base_first_optional_local_pack_later',
      'ready_base_first_cloud_assist_optional_later',
      'ready_base_first_no_extra_receipt_brain',
    ]) {
      if ((counts[outcome] ?? 0) > 0) return outcome;
    }
    return _firstPreferredCountKey(counts, const []);
  }

  String get receiptBrainBasePayloadGuardrailOutcome {
    final baseCanShip = receiptBrainBaseShipWithoutFullOfflineCounts;
    final packChoice = receiptBrainOptionalPackUserChoiceCounts;
    if (baseCanShip.isEmpty && packChoice.isEmpty) return '';
    final baseOk =
        (baseCanShip['true'] ?? 0) > 0 && (baseCanShip['false'] ?? 0) == 0;
    final choiceOk =
        (packChoice['true'] ?? 0) > 0 && (packChoice['false'] ?? 0) == 0;
    if (baseOk && choiceOk) return 'base_payload_optional_packs_ok';
    if (!baseOk && !choiceOk) {
      return 'base_payload_and_optional_pack_choice_review';
    }
    if (!baseOk) return 'base_payload_includes_full_offline_review';
    return 'optional_pack_choice_review';
  }

  String get receiptBrainLowStorageDownloadRiskOutcome {
    final counts = receiptBrainLowStorageDownloadRiskCounts;
    if (counts.isEmpty) return '';
    if ((counts['base_install_blocks_low_storage_users'] ?? 0) > 0) {
      return 'base_install_blocks_low_storage_users';
    }
    if ((counts['full_offline_too_large_for_low_storage'] ?? 0) > 0) {
      return 'full_offline_too_large_for_low_storage';
    }
    if ((counts['full_offline_large_optional_only'] ?? 0) > 0) {
      return 'full_offline_large_optional_only';
    }
    if ((counts['base_safe_optional_brain_deferred_for_low_storage'] ?? 0) >
        0) {
      return 'base_safe_optional_brain_deferred_for_low_storage';
    }
    if ((counts['optional_download_user_choice_required'] ?? 0) > 0) {
      return 'optional_download_user_choice_required';
    }
    if ((counts['base_only_safe_for_low_storage'] ?? 0) > 0) {
      return 'base_only_safe_for_low_storage';
    }
    return 'base_receipt_footprint_ready';
  }

  String get receiptInstallRequiredSegmentOutcome {
    return _firstPreferredCountKey(receiptInstallRequiredSegmentCounts, const [
      'required_base_block_over_100mb',
      'required_base_review_over_50mb',
      'required_base_lean_under_40mb',
    ]);
  }

  String get receiptInstallFullOfflineSegmentOutcome {
    return _firstPreferredCountKey(
      receiptInstallFullOfflineSegmentCounts,
      const [
        'full_offline_over_250mb_optional_or_assist',
        'full_offline_100_to_250mb_optional',
        'full_offline_under_100mb_optional',
        'full_offline_same_as_base',
      ],
    );
  }

  String get receiptInstallLowStorageImpactOutcome {
    return _firstPreferredCountKey(receiptInstallLowStorageImpactCounts, const [
      'blocks_low_storage_users_until_base_trimmed',
      'low_storage_base_only_optional_pack_hidden',
      'larger_storage_can_choose_optional_offline',
      'low_storage_base_flow_ready',
    ]);
  }

  String get receiptInstallRecommendedDistributionOutcome {
    return _firstPreferredCountKey(
      receiptInstallRecommendedDistributionCounts,
      const [
        'split_heavy_receipt_work_before_release',
        'ship_base_hide_large_packs_until_storage_allows',
        'ship_base_offer_optional_offline_receipt_packs',
        'ship_base_receipt_flow_only',
      ],
    );
  }

  String get receiptBrainLocalFirstReadinessOutcome {
    final counts = receiptBrainLocalFirstReadinessCounts;
    if (counts.isEmpty) return '';
    for (final outcome in const [
      'blocked_capture_requires_optional_pack',
      'blocked_base_local_reader_missing',
      'blocked_optional_pack_attached_to_base',
      'blocked_parser_pack_in_required_base',
      'lean_local_ready_optional_packs_deferred',
      'local_ready_optional_offline_pack_available',
      'local_ready_base_only',
    ]) {
      if ((counts[outcome] ?? 0) > 0) return outcome;
    }
    return _firstPreferredCountKey(counts, const []);
  }

  String get receiptBrainLocalFirstReadinessActionOutcome {
    final counts = receiptBrainLocalFirstReadinessActionCounts;
    if (counts.isEmpty) return '';
    for (final outcome in const [
      'restore_capture_without_optional_packs',
      'restore_basic_local_reader',
      'detach_optional_packs_from_base',
      'move_parser_pack_out_of_required_base',
      'keep_capture_and_basic_reader_available',
      'offer_optional_pack_after_user_choice',
      'continue_with_base_local_receipt_flow',
    ]) {
      if ((counts[outcome] ?? 0) > 0) return outcome;
    }
    return _firstPreferredCountKey(counts, const []);
  }

  String get receiptLocalOnlyAcceptanceStatusOutcome {
    final counts = receiptLocalOnlyAcceptanceStatusCounts;
    if (counts.isEmpty) return '';
    for (final outcome in const [
      'blocked_capture_not_available_in_base',
      'blocked_proof_save_not_available_in_base',
      'blocked_basic_local_review_not_available',
      'blocked_heavy_pack_required_before_capture',
      'blocked_cloud_required_before_capture',
      'review_base_receipt_size_before_adding_weight',
      'ready_local_first_optional_packs_deferred',
      'ready_local_first_base_flow',
    ]) {
      if ((counts[outcome] ?? 0) > 0) return outcome;
    }
    return _firstPreferredCountKey(counts, const []);
  }

  String get receiptLocalOnlyAcceptanceActionOutcome {
    final counts = receiptLocalOnlyAcceptanceActionCounts;
    if (counts.isEmpty) return '';
    for (final outcome in const [
      'restore_native_capture_in_required_base',
      'restore_proof_save_and_data_saver_in_required_base',
      'restore_basic_local_reader_before_optional_packs',
      'move_heavy_receipt_pack_out_of_required_capture_flow',
      'restore_local_review_before_cloud_assist',
      'review_base_size_before_adding_receipt_weight',
      'ship_base_capture_save_review_before_optional_packs',
      'continue_local_first_receipt_flow',
    ]) {
      if ((counts[outcome] ?? 0) > 0) return outcome;
    }
    return _firstPreferredCountKey(counts, const []);
  }

  String get nativeLocalOnlyCapturePolicyOutcome {
    final counts = nativeLocalOnlyCapturePolicyCounts;
    if (counts.isEmpty) return '';
    for (final outcome in const [
      'blocked_heavy_pack_required_before_capture',
      'blocked_cloud_required_before_capture',
      'blocked_base_receipt_flow_incomplete',
      'capture_save_basic_review_now_optional_packs_later',
      'capture_save_basic_review_now_base_only',
    ]) {
      if ((counts[outcome] ?? 0) > 0) return outcome;
    }
    return _firstPreferredCountKey(counts, const []);
  }
}
