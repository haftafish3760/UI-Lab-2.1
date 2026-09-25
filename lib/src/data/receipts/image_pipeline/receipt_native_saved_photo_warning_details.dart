part of 'receipt_capture_models.dart';

extension ReceiptNativeSavedPhotoReviewWarningDetails
    on ReceiptNativeSavedPhotoReviewWarning {
  bool get isCritical =>
      severity == ReceiptNativeSavedPhotoWarningSeverity.critical;

  bool get prefersAddSection =>
      code == 'saved_photo_bottom_too_dark' ||
      code == 'saved_photo_bottom_soft';

  bool get shouldSurface =>
      code != 'saved_photo_ok' ||
      severity != ReceiptNativeSavedPhotoWarningSeverity.notice;

  String get actionCode {
    return switch (code) {
      'saved_photo_darker_than_preview' => 'retake_with_more_light',
      'saved_photo_brighter_than_preview' => 'reduce_brightness_or_glare',
      'saved_photo_brightness_assist_failed_dark' => 'turn_on_light_or_retake',
      'saved_photo_brightness_assist_still_dim' => 'check_text_or_add_light',
      'saved_photo_soft_blur_risk' => 'retake_hold_steady',
      'saved_photo_bottom_too_dark' => 'check_bottom_or_raise_brightness',
      'saved_photo_bottom_soft' => 'check_bottom_or_retake',
      'saved_photo_dimmer_than_preview' => 'review_or_add_light',
      'saved_photo_glare_risk' => 'reduce_glare_or_retake',
      'saved_photo_dirty_lens_or_haze' => 'wipe_lens_or_retake',
      'saved_photo_shadow_risk' => 'move_to_even_light_or_retake',
      'saved_photo_document_scanner_backup' => 'review_backup_scan_crop',
      'saved_photo_phone_camera_backup' => 'review_phone_backup_focus',
      _ => isCritical ? 'retake_before_review' : 'review_if_readable',
    };
  }

  String get parserRiskCode {
    return switch (code) {
      'saved_photo_darker_than_preview' => 'ocr_text_or_total_may_fail',
      'saved_photo_brighter_than_preview' => 'ocr_washed_out_text_may_fail',
      'saved_photo_brightness_assist_failed_dark' =>
        'ocr_text_or_total_may_fail',
      'saved_photo_brightness_assist_still_dim' => 'ocr_text_may_need_review',
      'saved_photo_soft_blur_risk' => 'ocr_item_prices_may_fail',
      'saved_photo_bottom_too_dark' => 'ocr_bottom_total_may_fail',
      'saved_photo_bottom_soft' => 'ocr_bottom_lines_may_fail',
      'saved_photo_dimmer_than_preview' => 'ocr_text_may_need_review',
      'saved_photo_glare_risk' => 'ocr_washed_out_text_may_fail',
      'saved_photo_dirty_lens_or_haze' => 'ocr_hazy_text_may_fail',
      'saved_photo_shadow_risk' => 'ocr_shadowed_text_may_fail',
      'saved_photo_document_scanner_backup' =>
        'ocr_backup_scan_crop_may_need_review',
      'saved_photo_phone_camera_backup' =>
        'ocr_phone_backup_focus_may_need_review',
      _ => 'ocr_review_if_needed',
    };
  }

  String get primaryActionLabel {
    return switch (actionCode) {
      'retake_with_more_light' => 'Retake with more light',
      'reduce_brightness_or_glare' => 'Lower Brightness or reduce glare',
      'turn_on_light_or_retake' => 'Turn on receipt light or retake',
      'check_text_or_add_light' => 'Check text, then add light or retake',
      'retake_hold_steady' => 'Retake while holding steady',
      'check_bottom_or_raise_brightness' =>
        'Add Another Photo or raise Brightness for the bottom lines',
      'check_bottom_or_retake' =>
        'Add Another Photo or retake the bottom lines',
      'review_or_add_light' => 'Check readability, then add light if needed',
      'reduce_glare_or_retake' => 'Reduce glare or retake',
      'wipe_lens_or_retake' => 'Wipe lens or retake',
      'move_to_even_light_or_retake' => 'Move to even light or retake',
      'review_backup_scan_crop' => 'Check backup scan crop and totals',
      'review_phone_backup_focus' => 'Check phone backup focus and totals',
      'retake_before_review' => 'Retake before relying on automatic fill',
      _ => 'Review readability before using this photo',
    };
  }

  String get parserImpactGuidance {
    return switch (parserRiskCode) {
      'ocr_bottom_total_may_fail' =>
        'If the total, tax, barcode, or final lines are hard to read, use Add Another Photo for a clearer bottom section before automatic receipt fill.',
      'ocr_bottom_lines_may_fail' =>
        'If lower item prices or the total look fuzzy, retake or use Add Another Photo for a clearer bottom section before automatic receipt fill.',
      'ocr_item_prices_may_fail' =>
        'Automatic receipt fill may miss item prices if the text is soft; retake before relying on it.',
      'ocr_text_or_total_may_fail' =>
        'Automatic receipt fill may miss receipt text or totals if the saved photo is darker than the preview.',
      'ocr_washed_out_text_may_fail' =>
        'Automatic receipt fill may miss washed-out totals or prices; reduce glare before relying on it.',
      'ocr_hazy_text_may_fail' =>
        'Automatic receipt fill may miss cloudy text or prices; wipe the lens and retake if the saved photo looks hazy.',
      'ocr_shadowed_text_may_fail' =>
        'Automatic receipt fill may miss shadowed text or prices; move the receipt into even light and retake if shadows cover important lines.',
      'ocr_backup_scan_crop_may_need_review' =>
        'Because this came from backup scanner capture, verify crop, bottom edge, subtotal, tax, and total before relying on automatic line fill.',
      'ocr_phone_backup_focus_may_need_review' =>
        'Because this came from phone camera backup capture, verify focus, bottom edge, subtotal, tax, and total before relying on automatic line fill.',
      _ => '',
    };
  }

  String get message {
    final impact = parserImpactGuidance;
    if (impact.isEmpty) return '$title. $guidance';
    return '$title. $guidance $impact';
  }
}
