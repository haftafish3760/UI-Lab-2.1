part of 'receipt_capture_models.dart';

List<String> _receiptRetakeInvalidOrderCodes({
  required Map<String, Object?> diagnostics,
  required int? originalSection,
  required int? finalSection,
}) {
  final codes = <String>[];
  final replacementOffset = _diagnosticZeroOrPositiveInt(
    diagnostics['receiptRetakeReplacementOffset'],
  );
  final insertedExtra = _diagnosticBool(
    diagnostics['receiptRetakeInsertedExtraSection'],
  );
  final preservedSlot = _diagnosticBool(
    diagnostics['receiptRetakePreservedOriginalSlot'],
  );
  final hasPrevious = _diagnosticBool(
    diagnostics['receiptRetakeHasPreviousAlignmentContext'],
  );
  final hasNext = _diagnosticBool(
    diagnostics['receiptRetakeHasNextAlignmentContext'],
  );
  final hasTwoSided = _diagnosticBool(
    diagnostics['receiptRetakeHasTwoSidedAlignmentContext'],
  );
  final previousSection = _diagnosticPositiveInt(
    diagnostics['receiptRetakePreviousContextSectionNumber'],
  );
  final nextSection = _diagnosticPositiveInt(
    diagnostics['receiptRetakeNextContextSectionNumber'],
  );
  final previousFinalSection = _diagnosticPositiveInt(
    diagnostics['receiptRetakePreviousContextFinalSectionNumber'],
  );
  final nextFinalSection = _diagnosticPositiveInt(
    diagnostics['receiptRetakeNextContextFinalSectionNumber'],
  );
  final replacementCount = _diagnosticPositiveInt(
    diagnostics['receiptRetakeReplacementCount'],
  );
  final hasRetakeMetadata =
      originalSection != null ||
      finalSection != null ||
      replacementOffset != null ||
      insertedExtra != null ||
      preservedSlot != null ||
      hasPrevious != null ||
      hasNext != null ||
      hasTwoSided != null ||
      previousSection != null ||
      nextSection != null ||
      previousFinalSection != null ||
      nextFinalSection != null ||
      _diagnosticToken(
            diagnostics['receiptRetakeGuidanceCode']?.toString() ?? '',
          ) !=
          'unknown' ||
      _diagnosticToken(
            diagnostics['receiptRetakeOrderPolicy']?.toString() ?? '',
          ) !=
          'unknown';
  if (hasRetakeMetadata && originalSection == null) {
    codes.add('retake_invalid_missing_original_section');
  }
  if (hasRetakeMetadata && finalSection == null) {
    codes.add('retake_invalid_missing_final_section');
  }
  if (originalSection == null || finalSection == null) {
    return List.unmodifiable(codes);
  }
  if (previousFinalSection != null &&
      previousSection != null &&
      previousFinalSection != previousSection) {
    codes.add('retake_invalid_previous_context_final_section_mismatch');
  }
  if (nextFinalSection != null &&
      nextSection != null &&
      replacementCount != null &&
      nextFinalSection != nextSection + replacementCount - 1) {
    codes.add('retake_invalid_next_context_final_section_mismatch');
  }
  if (finalSection < originalSection) {
    codes.add('retake_invalid_final_before_original');
  }
  if (preservedSlot == true && finalSection != originalSection) {
    codes.add('retake_invalid_preserved_slot_moved');
  }
  if (insertedExtra == true && replacementOffset != null) {
    final expectedFinalSection = originalSection + replacementOffset + 1;
    if (finalSection != expectedFinalSection) {
      codes.add('retake_invalid_offset_final_mismatch');
    }
  }
  if (insertedExtra == true && replacementOffset == null) {
    codes.add('retake_invalid_extra_without_offset');
  }
  if (insertedExtra != true &&
      replacementOffset != null &&
      !(preservedSlot == true && replacementOffset == 0)) {
    codes.add('retake_invalid_offset_without_extra');
  }
  if (hasTwoSided == true && (hasPrevious != true || hasNext != true)) {
    codes.add('retake_invalid_two_sided_flags');
  }
  if (hasPrevious == true && previousSection == null) {
    codes.add('retake_invalid_missing_previous_context_section');
  }
  if (hasPrevious != true && previousSection != null) {
    codes.add('retake_invalid_unexpected_previous_context_section');
  }
  if (hasNext == true && nextSection == null) {
    codes.add('retake_invalid_missing_next_context_section');
  }
  if (hasNext != true && nextSection != null) {
    codes.add('retake_invalid_unexpected_next_context_section');
  }
  if (previousSection != null && previousSection >= originalSection) {
    codes.add('retake_invalid_previous_context_order');
  }
  if (previousSection != null && previousSection + 1 != originalSection) {
    codes.add('retake_invalid_previous_context_gap');
  }
  if (nextSection != null && nextSection <= originalSection) {
    codes.add('retake_invalid_next_context_order');
  }
  if (nextSection != null && nextSection != originalSection + 1) {
    codes.add('retake_invalid_next_context_gap');
  }
  if (hasPrevious == true && hasNext == true && hasTwoSided != true) {
    codes.add('retake_invalid_two_sided_section_without_flag');
  }
  return List.unmodifiable(codes);
}

List<String> _receiptNativeGhostRetakeInvalidOrderCodes({
  required bool hasRetakeMetadata,
  required Map<String, Object?> diagnostics,
  required int? originalSection,
}) {
  if (!hasRetakeMetadata) return const [];
  final ghostVisible = _diagnosticBool(
    diagnostics['previousSectionGhostGuideVisible'],
  );
  final previousSection = _diagnosticPositiveInt(
    diagnostics['receiptRetakePreviousContextSectionNumber'],
  );
  final hasPrevious = _diagnosticBool(
    diagnostics['receiptRetakeHasPreviousAlignmentContext'],
  );
  if (ghostVisible != true) return const [];
  final codes = <String>[];
  if (hasPrevious != true) {
    codes.add('retake_invalid_ghost_without_previous_context');
  }
  if (previousSection == null) {
    codes.add('retake_invalid_ghost_missing_previous_section');
  }
  if (originalSection != null && previousSection != null) {
    if (previousSection >= originalSection) {
      codes.add('retake_invalid_ghost_previous_after_target');
    }
    if (previousSection + 1 != originalSection) {
      codes.add('retake_invalid_ghost_previous_gap');
    }
  }
  return List.unmodifiable(codes);
}

List<String> _receiptRetakeInvalidGuidanceCodes({
  required bool hasRetakeMetadata,
  required int? originalSection,
  required String guidance,
  required Map<String, Object?> diagnostics,
}) {
  if (!hasRetakeMetadata || guidance == 'unknown') return const [];
  if (originalSection == null) return const [];
  final hasPrevious = _diagnosticBool(
    diagnostics['receiptRetakeHasPreviousAlignmentContext'],
  );
  final hasNext = _diagnosticBool(
    diagnostics['receiptRetakeHasNextAlignmentContext'],
  );
  final hasTwoSided = _diagnosticBool(
    diagnostics['receiptRetakeHasTwoSidedAlignmentContext'],
  );
  final codes = <String>[];
  if (originalSection <= 1 &&
      guidance != 'retake_top_with_next_context' &&
      guidance != 'retake_single_section_no_context') {
    codes.add('retake_invalid_guidance_for_top_section');
  }
  if (originalSection > 1 &&
      (guidance == 'retake_top_with_next_context' ||
          guidance == 'retake_single_section_no_context')) {
    codes.add('retake_invalid_top_guidance_for_later_section');
  }
  switch (guidance) {
    case 'retake_top_with_next_context':
      if (hasNext != true) {
        codes.add('retake_invalid_top_guidance_missing_next_context');
      }
      if (hasPrevious == true) {
        codes.add('retake_invalid_top_guidance_with_previous_context');
      }
      if (hasTwoSided == true) {
        codes.add('retake_invalid_top_guidance_with_two_sided_context');
      }
    case 'retake_middle_with_previous_next_context':
      if (hasPrevious != true || hasNext != true || hasTwoSided != true) {
        codes.add('retake_invalid_middle_guidance_context_mismatch');
      }
    case 'retake_bottom_with_previous_context':
      if (hasPrevious != true) {
        codes.add('retake_invalid_bottom_guidance_missing_previous_context');
      }
      if (hasNext == true) {
        codes.add('retake_invalid_bottom_guidance_with_next_context');
      }
      if (hasTwoSided == true) {
        codes.add('retake_invalid_bottom_guidance_with_two_sided_context');
      }
    case 'retake_single_section_no_context':
      if (hasPrevious == true || hasNext == true || hasTwoSided == true) {
        codes.add('retake_invalid_single_guidance_with_alignment_context');
      }
  }
  return List.unmodifiable(codes);
}

List<String> _receiptRetakeInvalidPreviousGuideReasonCodes({
  required bool hasRetakeMetadata,
  required int? originalSection,
  required String previousSectionReason,
}) {
  if (!hasRetakeMetadata ||
      previousSectionReason == 'unknown' ||
      originalSection == null ||
      originalSection > 1) {
    return const [];
  }
  return const ['retake_invalid_previous_guide_for_top_section'];
}

List<String> _receiptInsertInvalidOrderCodes({
  required Map<String, Object?> diagnostics,
  required int? anchorSection,
  required int? finalSection,
}) {
  final codes = <String>[];
  final offset = _diagnosticZeroOrPositiveInt(
    diagnostics['receiptInsertAfterOffset'],
  );
  final followingSection = _diagnosticPositiveInt(
    diagnostics['receiptInsertFollowingContextSectionNumber'],
  );
  final followingFinalSection = _diagnosticPositiveInt(
    diagnostics['receiptInsertFollowingContextFinalSectionNumber'],
  );
  final insertCount = _diagnosticPositiveInt(diagnostics['receiptInsertCount']);
  final preservedAnchor = _diagnosticBool(
    diagnostics['receiptInsertPreservedAnchorSlot'],
  );
  final hasInsertMetadata =
      anchorSection != null ||
      finalSection != null ||
      offset != null ||
      preservedAnchor != null ||
      followingSection != null ||
      followingFinalSection != null ||
      _diagnosticToken(
            diagnostics['receiptInsertOrderPolicy']?.toString() ?? '',
          ) !=
          'unknown';
  if (hasInsertMetadata && anchorSection == null) {
    codes.add('insert_invalid_missing_anchor_section');
  }
  if (hasInsertMetadata && finalSection == null) {
    codes.add('insert_invalid_missing_final_section');
  }
  if (anchorSection == null || finalSection == null) {
    return List.unmodifiable(codes);
  }
  if (followingFinalSection != null &&
      followingSection != null &&
      insertCount != null &&
      followingFinalSection != followingSection + insertCount) {
    codes.add('insert_invalid_following_context_final_section_mismatch');
  }
  if (finalSection <= anchorSection) {
    codes.add('insert_invalid_final_not_after_anchor');
  }
  if (preservedAnchor == true && finalSection <= anchorSection) {
    codes.add('insert_invalid_preserved_anchor_overlap');
  }
  if (offset == null) {
    codes.add('insert_invalid_missing_offset');
  } else if (finalSection != anchorSection + offset + 1) {
    codes.add('insert_invalid_offset_final_mismatch');
  }
  return List.unmodifiable(codes);
}

List<String> _receiptManualReorderInvalidOrderCodes({
  required Map<String, Object?> diagnostics,
  required int? originalSection,
  required int? finalSection,
  required String direction,
}) {
  if (originalSection == null || finalSection == null) return const [];
  final codes = <String>[];
  final expectedFinalSection = switch (direction) {
    'earlier' => originalSection - 1,
    'later' => originalSection + 1,
    _ => null,
  };
  if (expectedFinalSection == null) {
    codes.add('manual_reorder_invalid_direction');
  } else if (finalSection != expectedFinalSection) {
    codes.add('manual_reorder_invalid_non_adjacent_move');
  }
  if (_diagnosticBool(diagnostics['receiptManualReorderPreservedPhotoPath']) !=
      true) {
    codes.add('manual_reorder_invalid_missing_preserved_path');
  }
  return List.unmodifiable(codes);
}

List<String> _receiptRetakeContextCodes(Map<String, Object?> diagnostics) {
  final codes = <String>[];
  if (_diagnosticBool(diagnostics['receiptRetakePreservedOriginalSlot']) ==
      true) {
    codes.add('retake_preserved_original_slot');
  }
  if (_diagnosticBool(diagnostics['receiptRetakeInsertedExtraSection']) ==
      true) {
    codes.add('retake_inserted_extra_section');
  }
  if (_diagnosticBool(
        diagnostics['receiptRetakeHasPreviousAlignmentContext'],
      ) ==
      true) {
    codes.add('retake_previous_alignment_context');
  }
  if (_diagnosticBool(diagnostics['receiptRetakeHasNextAlignmentContext']) ==
      true) {
    codes.add('retake_next_alignment_context');
  }
  if (_diagnosticBool(
        diagnostics['receiptRetakeHasTwoSidedAlignmentContext'],
      ) ==
      true) {
    codes.add('retake_two_sided_alignment_context');
  }
  final previousSection = _diagnosticPositiveInt(
    diagnostics['receiptRetakePreviousContextSectionNumber'],
  );
  if (previousSection != null) {
    codes.add(
      previousSection > 9
          ? 'retake_previous_context_section_10_plus'
          : 'retake_previous_context_section_$previousSection',
    );
  }
  final nextSection = _diagnosticPositiveInt(
    diagnostics['receiptRetakeNextContextSectionNumber'],
  );
  if (nextSection != null) {
    codes.add(
      nextSection > 9
          ? 'retake_next_context_section_10_plus'
          : 'retake_next_context_section_$nextSection',
    );
  }
  final previousFinalSection = _diagnosticPositiveInt(
    diagnostics['receiptRetakePreviousContextFinalSectionNumber'],
  );
  if (previousFinalSection != null) {
    codes.add(
      previousFinalSection > 9
          ? 'retake_previous_context_final_section_10_plus'
          : 'retake_previous_context_final_section_$previousFinalSection',
    );
  }
  final nextFinalSection = _diagnosticPositiveInt(
    diagnostics['receiptRetakeNextContextFinalSectionNumber'],
  );
  if (nextFinalSection != null) {
    codes.add(
      nextFinalSection > 9
          ? 'retake_next_context_final_section_10_plus'
          : 'retake_next_context_final_section_$nextFinalSection',
    );
  }
  return List.unmodifiable(codes);
}

List<String> _receiptInsertContextCodes(Map<String, Object?> diagnostics) {
  final codes = <String>[];
  if (_diagnosticBool(diagnostics['receiptInsertPreservedAnchorSlot']) ==
      true) {
    codes.add('insert_preserved_anchor_slot');
  }
  final offset = _diagnosticZeroOrPositiveInt(
    diagnostics['receiptInsertAfterOffset'],
  );
  if (offset != null) {
    codes.add(offset > 9 ? 'insert_offset_10_plus' : 'insert_offset_$offset');
  }
  final followingSection = _diagnosticPositiveInt(
    diagnostics['receiptInsertFollowingContextSectionNumber'],
  );
  if (followingSection != null) {
    codes.add(
      followingSection > 9
          ? 'insert_following_context_section_10_plus'
          : 'insert_following_context_section_$followingSection',
    );
  }
  final followingFinalSection = _diagnosticPositiveInt(
    diagnostics['receiptInsertFollowingContextFinalSectionNumber'],
  );
  if (followingFinalSection != null) {
    codes.add(
      followingFinalSection > 9
          ? 'insert_following_context_final_section_10_plus'
          : 'insert_following_context_final_section_$followingFinalSection',
    );
  }
  return List.unmodifiable(codes);
}

List<String> _receiptManualReorderContextCodes(
  Map<String, Object?> diagnostics,
) {
  final codes = <String>[];
  if (_diagnosticBool(diagnostics['receiptManualReorderPreservedPhotoPath']) ==
      true) {
    codes.add('manual_reorder_preserved_photo_path');
  }
  return List.unmodifiable(codes);
}

List<String> _receiptRemovalContextCodes(Map<String, Object?> diagnostics) {
  final codes = <String>[];
  if (_diagnosticBool(diagnostics['receiptRemoveSectionShifted']) == true) {
    codes.add('remove_section_shifted');
  }
  if (_diagnosticBool(diagnostics['receiptRemoveSectionShifted']) == false) {
    codes.add('remove_section_not_shifted');
  }
  return List.unmodifiable(codes);
}
