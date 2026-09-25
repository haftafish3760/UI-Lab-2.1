part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultBrainInstallMetadata
    on ReceiptPhotoReviewResult {
  Map<String, Object?> get privacySafeReceiptBrainInstallMetadata {
    return {
      if (receiptBrainReleaseActionCounts.isNotEmpty)
        'receiptBrainReleaseActionCounts': receiptBrainReleaseActionCounts,
      if (receiptBrainReleaseActionCounts.isNotEmpty)
        'receiptBrainReleaseActionOutcome': receiptBrainReleaseActionOutcome,
      if (receiptBrainInstallDistributionCounts.isNotEmpty)
        'receiptBrainInstallDistributionCounts':
            receiptBrainInstallDistributionCounts,
      if (receiptBrainInstallDistributionCounts.isNotEmpty)
        'receiptBrainInstallDistributionOutcome':
            receiptBrainInstallDistributionOutcome,
      if (receiptBrainStorageClassCounts.isNotEmpty)
        'receiptBrainStorageClassCounts': receiptBrainStorageClassCounts,
      if (receiptBrainLocalOcrModeCounts.isNotEmpty)
        'receiptBrainLocalOcrModeCounts': receiptBrainLocalOcrModeCounts,
      if (receiptBrainBaseSizeDecisionCounts.isNotEmpty)
        'receiptBrainBaseSizeDecisionCounts':
            receiptBrainBaseSizeDecisionCounts,
      if (receiptBrainBaseSizeDecisionCounts.isNotEmpty)
        'receiptBrainBaseSizeDecisionOutcome':
            receiptBrainBaseSizeDecisionOutcome,
      if (receiptBrainFirstInstallBoundaryCounts.isNotEmpty)
        'receiptBrainFirstInstallBoundaryCounts':
            receiptBrainFirstInstallBoundaryCounts,
      if (receiptBrainFirstInstallBoundaryCounts.isNotEmpty)
        'receiptBrainFirstInstallBoundaryOutcome':
            receiptBrainFirstInstallBoundaryOutcome,
      if (receiptBrainFirstInstallBoundaryActionCounts.isNotEmpty)
        'receiptBrainFirstInstallBoundaryActionCounts':
            receiptBrainFirstInstallBoundaryActionCounts,
      if (receiptBrainFirstInstallCanRunLowStorageCounts.isNotEmpty)
        'receiptBrainFirstInstallCanRunLowStorageCounts':
            receiptBrainFirstInstallCanRunLowStorageCounts,
      if (receiptBrainFirstInstallRequiresBaseCapabilityCounts.isNotEmpty)
        'receiptBrainFirstInstallRequiresBaseCapabilityCounts':
            receiptBrainFirstInstallRequiresBaseCapabilityCounts,
      if (receiptBrainFirstInstallBoundarySummaryCounts.isNotEmpty)
        'receiptBrainFirstInstallBoundarySummaryCounts':
            receiptBrainFirstInstallBoundarySummaryCounts,
      if (receiptBrainBaseNeedsSizeReviewCounts.isNotEmpty)
        'receiptBrainBaseNeedsSizeReviewCounts':
            receiptBrainBaseNeedsSizeReviewCounts,
      if (receiptBrainBaseBlocksLowStorageCounts.isNotEmpty)
        'receiptBrainBaseBlocksLowStorageCounts':
            receiptBrainBaseBlocksLowStorageCounts,
      if (receiptBrainFullOfflineExceedsBaseGuardrailCounts.isNotEmpty)
        'receiptBrainFullOfflineExceedsBaseGuardrailCounts':
            receiptBrainFullOfflineExceedsBaseGuardrailCounts,
      if (receiptBrainFullOfflineMustStayOptionalCounts.isNotEmpty)
        'receiptBrainFullOfflineMustStayOptionalCounts':
            receiptBrainFullOfflineMustStayOptionalCounts,
      if (receiptBrainLowStorageDownloadRiskCounts.isNotEmpty)
        'receiptBrainLowStorageDownloadRiskCounts':
            receiptBrainLowStorageDownloadRiskCounts,
      if (receiptBrainLowStorageDownloadRiskCounts.isNotEmpty)
        'receiptBrainLowStorageDownloadRiskOutcome':
            receiptBrainLowStorageDownloadRiskOutcome,
      if (receiptInstallRequiredSegmentCounts.isNotEmpty)
        'receiptInstallRequiredSegmentCounts':
            receiptInstallRequiredSegmentCounts,
      if (receiptInstallRequiredSegmentCounts.isNotEmpty)
        'receiptInstallRequiredSegmentOutcome':
            receiptInstallRequiredSegmentOutcome,
      if (receiptInstallFullOfflineSegmentCounts.isNotEmpty)
        'receiptInstallFullOfflineSegmentCounts':
            receiptInstallFullOfflineSegmentCounts,
      if (receiptInstallFullOfflineSegmentCounts.isNotEmpty)
        'receiptInstallFullOfflineSegmentOutcome':
            receiptInstallFullOfflineSegmentOutcome,
      if (receiptInstallLowStorageImpactCounts.isNotEmpty)
        'receiptInstallLowStorageImpactCounts':
            receiptInstallLowStorageImpactCounts,
      if (receiptInstallLowStorageImpactCounts.isNotEmpty)
        'receiptInstallLowStorageImpactOutcome':
            receiptInstallLowStorageImpactOutcome,
      if (receiptInstallRecommendedDistributionCounts.isNotEmpty)
        'receiptInstallRecommendedDistributionCounts':
            receiptInstallRecommendedDistributionCounts,
      if (receiptInstallRecommendedDistributionCounts.isNotEmpty)
        'receiptInstallRecommendedDistributionOutcome':
            receiptInstallRecommendedDistributionOutcome,
      if (receiptInstallCameraShellParserFreeCounts.isNotEmpty)
        'receiptInstallCameraShellParserFreeCounts':
            receiptInstallCameraShellParserFreeCounts,
      if (receiptInstallBaseUsefulOnTinyPhonesCounts.isNotEmpty)
        'receiptInstallBaseUsefulOnTinyPhonesCounts':
            receiptInstallBaseUsefulOnTinyPhonesCounts,
      if (receiptInstallOptionalPacksRequireConsentCounts.isNotEmpty)
        'receiptInstallOptionalPacksRequireConsentCounts':
            receiptInstallOptionalPacksRequireConsentCounts,
      if (receiptBrainRequiredBasePayloadCounts.isNotEmpty)
        'receiptBrainRequiredBasePayloadCounts':
            receiptBrainRequiredBasePayloadCounts,
      if (receiptBrainOptionalPayloadCounts.isNotEmpty)
        'receiptBrainOptionalPayloadCounts': receiptBrainOptionalPayloadCounts,
      if (receiptBrainBaseShipWithoutFullOfflineCounts.isNotEmpty)
        'receiptBrainBaseShipWithoutFullOfflineCounts':
            receiptBrainBaseShipWithoutFullOfflineCounts,
      if (receiptBrainBaseVersusFullOfflineSummaryCounts.isNotEmpty)
        'receiptBrainBaseVersusFullOfflineSummaryCounts':
            receiptBrainBaseVersusFullOfflineSummaryCounts,
      if (receiptBrainOptionalPackUserChoiceCounts.isNotEmpty)
        'receiptBrainOptionalPackUserChoiceCounts':
            receiptBrainOptionalPackUserChoiceCounts,
      if (receiptBrainBaseLocalReadingAvailableCounts.isNotEmpty)
        'receiptBrainBaseLocalReadingAvailableCounts':
            receiptBrainBaseLocalReadingAvailableCounts,
      if (receiptBrainBaseWorksWithoutCloudAssistCounts.isNotEmpty)
        'receiptBrainBaseWorksWithoutCloudAssistCounts':
            receiptBrainBaseWorksWithoutCloudAssistCounts,
      if (receiptBrainLocalFirstReadinessCounts.isNotEmpty)
        'receiptBrainLocalFirstReadinessCounts':
            receiptBrainLocalFirstReadinessCounts,
      if (receiptBrainLocalFirstReadinessCounts.isNotEmpty)
        'receiptBrainLocalFirstReadinessOutcome':
            receiptBrainLocalFirstReadinessOutcome,
      if (receiptBrainLocalFirstReadinessActionCounts.isNotEmpty)
        'receiptBrainLocalFirstReadinessActionCounts':
            receiptBrainLocalFirstReadinessActionCounts,
      if (receiptBrainLocalFirstReadinessActionCounts.isNotEmpty)
        'receiptBrainLocalFirstReadinessActionOutcome':
            receiptBrainLocalFirstReadinessActionOutcome,
      if (receiptBrainLocalFirstReadinessSummaryCounts.isNotEmpty)
        'receiptBrainLocalFirstReadinessSummaryCounts':
            receiptBrainLocalFirstReadinessSummaryCounts,
      if (receiptLocalOnlyAcceptanceStatusCounts.isNotEmpty)
        'receiptLocalOnlyAcceptanceStatusCounts':
            receiptLocalOnlyAcceptanceStatusCounts,
      if (receiptLocalOnlyAcceptanceStatusCounts.isNotEmpty)
        'receiptLocalOnlyAcceptanceStatusOutcome':
            receiptLocalOnlyAcceptanceStatusOutcome,
      if (receiptLocalOnlyAcceptanceActionCounts.isNotEmpty)
        'receiptLocalOnlyAcceptanceActionCounts':
            receiptLocalOnlyAcceptanceActionCounts,
      if (receiptLocalOnlyAcceptanceActionCounts.isNotEmpty)
        'receiptLocalOnlyAcceptanceActionOutcome':
            receiptLocalOnlyAcceptanceActionOutcome,
      if (receiptLocalOnlyBaseFlowCanRunCounts.isNotEmpty)
        'receiptLocalOnlyBaseFlowCanRunCounts':
            receiptLocalOnlyBaseFlowCanRunCounts,
      if (receiptLocalOnlyBlocksLowStorageCounts.isNotEmpty)
        'receiptLocalOnlyBlocksLowStorageCounts':
            receiptLocalOnlyBlocksLowStorageCounts,
      if (receiptLocalOnlyEvidenceCounts.isNotEmpty)
        'receiptLocalOnlyEvidenceCounts': receiptLocalOnlyEvidenceCounts,
      if (nativeLocalOnlyCapturePolicyCounts.isNotEmpty)
        'nativeLocalOnlyCapturePolicyCounts':
            nativeLocalOnlyCapturePolicyCounts,
      if (nativeLocalOnlyCapturePolicyCounts.isNotEmpty)
        'nativeLocalOnlyCapturePolicyOutcome':
            nativeLocalOnlyCapturePolicyOutcome,
      if (nativeLocalOnlyBaseFlowCanRunCounts.isNotEmpty)
        'nativeLocalOnlyBaseFlowCanRunCounts':
            nativeLocalOnlyBaseFlowCanRunCounts,
      if (nativeLocalOnlyHeavyPacksMayBlockCaptureCounts.isNotEmpty)
        'nativeLocalOnlyHeavyPacksMayBlockCaptureCounts':
            nativeLocalOnlyHeavyPacksMayBlockCaptureCounts,
      if (nativeLocalOnlyCloudAssistMayBlockCaptureCounts.isNotEmpty)
        'nativeLocalOnlyCloudAssistMayBlockCaptureCounts':
            nativeLocalOnlyCloudAssistMayBlockCaptureCounts,
      if (receiptRequiredBaseFootprintStatusCounts.isNotEmpty)
        'receiptRequiredBaseFootprintStatusCounts':
            receiptRequiredBaseFootprintStatusCounts,
      if (receiptRequiredBaseFootprintStatusOutcome.isNotEmpty)
        'receiptRequiredBaseFootprintStatusOutcome':
            receiptRequiredBaseFootprintStatusOutcome,
      if (receiptRequiredBaseFootprintCanShipCounts.isNotEmpty)
        'receiptRequiredBaseFootprintCanShipCounts':
            receiptRequiredBaseFootprintCanShipCounts,
      if (receiptRequiredBaseFootprintReviewCounts.isNotEmpty)
        'receiptRequiredBaseFootprintReviewCounts':
            receiptRequiredBaseFootprintReviewCounts,
      if (receiptRequiredBaseFootprintBlockingReasonCounts.isNotEmpty)
        'receiptRequiredBaseFootprintBlockingReasonCounts':
            receiptRequiredBaseFootprintBlockingReasonCounts,
      if (receiptRequiredBaseFootprintReviewReasonCounts.isNotEmpty)
        'receiptRequiredBaseFootprintReviewReasonCounts':
            receiptRequiredBaseFootprintReviewReasonCounts,
      if (receiptBrainBasePayloadGuardrailOutcome.isNotEmpty)
        'receiptBrainBasePayloadGuardrailOutcome':
            receiptBrainBasePayloadGuardrailOutcome,
    };
  }
}
