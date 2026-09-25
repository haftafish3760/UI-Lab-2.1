part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultNativeBrainSignals
    on ReceiptPhotoReviewResult {
  Map<String, int> get receiptBrainReleaseActionCounts {
    return _diagnosticValueCounts(
      this,
      'receiptBrainRequiredBaseReleaseActionCode',
    );
  }

  Map<String, int> get receiptBrainInstallDistributionCounts {
    return _diagnosticValueCounts(
      this,
      'receiptBrainInstallDistributionModeCode',
    );
  }

  Map<String, int> get receiptBrainStorageClassCounts {
    return _diagnosticValueCounts(this, 'receiptBrainStorageClass');
  }

  Map<String, int> get receiptBrainLocalOcrModeCounts {
    return _diagnosticValueCounts(this, 'receiptBrainLocalOcrMode');
  }

  Map<String, int> get receiptBrainBaseSizeDecisionCounts {
    return _diagnosticValueCounts(this, 'receiptBrainBaseSizeDecisionCode');
  }

  Map<String, int> get receiptBrainFirstInstallBoundaryCounts {
    return _diagnosticValueCounts(this, 'receiptBrainFirstInstallBoundaryCode');
  }

  Map<String, int> get receiptBrainFirstInstallBoundaryActionCounts {
    return _diagnosticValueCounts(
      this,
      'receiptBrainFirstInstallBoundaryActionCode',
    );
  }

  Map<String, int> get receiptBrainFirstInstallCanRunLowStorageCounts {
    return _diagnosticBoolCounts(
      this,
      'receiptBrainFirstInstallCanRunOnLowStoragePhones',
    );
  }

  Map<String, int> get receiptBrainFirstInstallRequiresBaseCapabilityCounts {
    return _diagnosticBoolCounts(
      this,
      'receiptBrainFirstInstallRequiresOnlyBaseCapabilities',
    );
  }

  Map<String, int> get receiptBrainFirstInstallBoundarySummaryCounts {
    return _diagnosticPresenceCounts(
      this,
      'receiptBrainFirstInstallBoundarySummary',
    );
  }

  Map<String, int> get receiptBrainBaseNeedsSizeReviewCounts {
    return _diagnosticBoolCounts(this, 'receiptBrainBaseNeedsSizeReview');
  }

  Map<String, int> get receiptBrainBaseBlocksLowStorageCounts {
    return _diagnosticBoolCounts(this, 'receiptBrainBaseBlocksLowStorageUsers');
  }

  Map<String, int> get receiptBrainFullOfflineExceedsBaseGuardrailCounts {
    return _diagnosticBoolCounts(
      this,
      'receiptBrainFullOfflineExceedsBaseGuardrail',
    );
  }

  Map<String, int> get receiptBrainFullOfflineMustStayOptionalCounts {
    return _diagnosticBoolCounts(
      this,
      'receiptBrainFullOfflineMustStayOptional',
    );
  }

  Map<String, int> get receiptBrainLowStorageDownloadRiskCounts {
    return _diagnosticValueCounts(
      this,
      'receiptBrainLowStorageDownloadRiskCode',
    );
  }

  Map<String, int> get receiptInstallRequiredSegmentCounts {
    return _diagnosticValueCounts(this, 'receiptInstallRequiredSegmentCode');
  }

  Map<String, int> get receiptInstallFullOfflineSegmentCounts {
    return _diagnosticValueCounts(this, 'receiptInstallFullOfflineSegmentCode');
  }

  Map<String, int> get receiptInstallLowStorageImpactCounts {
    return _diagnosticValueCounts(
      this,
      'receiptInstallLowStorageUserImpactCode',
    );
  }

  Map<String, int> get receiptInstallRecommendedDistributionCounts {
    return _diagnosticValueCounts(
      this,
      'receiptInstallRecommendedDistributionCode',
    );
  }

  Map<String, int> get receiptInstallCameraShellParserFreeCounts {
    return _diagnosticBoolCounts(this, 'receiptInstallCameraShellParserFree');
  }

  Map<String, int> get receiptInstallBaseUsefulOnTinyPhonesCounts {
    return _diagnosticBoolCounts(this, 'receiptInstallBaseUsefulOnTinyPhones');
  }

  Map<String, int> get receiptInstallOptionalPacksRequireConsentCounts {
    return _diagnosticBoolCounts(
      this,
      'receiptInstallOptionalPacksRequireConsent',
    );
  }

  Map<String, int> get receiptBrainRequiredBasePayloadCounts {
    return _diagnosticListValueCounts(
      this,
      'receiptBrainRequiredBasePayloadCodes',
    );
  }

  Map<String, int> get receiptBrainOptionalPayloadCounts {
    return _diagnosticListValueCounts(this, 'receiptBrainOptionalPayloadCodes');
  }

  Map<String, int> get receiptBrainBaseShipWithoutFullOfflineCounts {
    return _diagnosticBoolCounts(
      this,
      'receiptBrainBaseCanShipWithoutFullOfflineBrain',
    );
  }

  Map<String, int> get receiptBrainBaseVersusFullOfflineSummaryCounts {
    return _diagnosticPresenceCounts(
      this,
      'receiptBrainUserFacingBaseVersusFullOfflineSummary',
    );
  }

  Map<String, int> get receiptBrainOptionalPackUserChoiceCounts {
    return _diagnosticBoolCounts(
      this,
      'receiptBrainOptionalParserPacksRequireUserChoice',
    );
  }

  Map<String, int> get receiptBrainBaseLocalReadingAvailableCounts {
    return _diagnosticBoolCounts(
      this,
      'receiptBrainBaseLocalReceiptReadingAvailable',
    );
  }

  Map<String, int> get receiptBrainBaseWorksWithoutCloudAssistCounts {
    return _diagnosticBoolCounts(
      this,
      'receiptBrainBaseWorksWithoutCloudAssist',
    );
  }

  Map<String, int> get receiptBrainLocalFirstReadinessCounts {
    return _diagnosticValueCounts(this, 'receiptBrainLocalFirstReadinessCode');
  }

  Map<String, int> get receiptBrainLocalFirstReadinessActionCounts {
    return _diagnosticValueCounts(
      this,
      'receiptBrainLocalFirstReadinessActionCode',
    );
  }

  Map<String, int> get receiptBrainLocalFirstReadinessSummaryCounts {
    return _diagnosticPresenceCounts(
      this,
      'receiptBrainUserFacingLocalFirstReadinessSummary',
    );
  }

  Map<String, int> get receiptLocalOnlyAcceptanceStatusCounts {
    return _diagnosticValueCounts(this, 'receiptLocalOnlyAcceptanceStatusCode');
  }

  Map<String, int> get receiptLocalOnlyAcceptanceActionCounts {
    return _diagnosticValueCounts(this, 'receiptLocalOnlyAcceptanceActionCode');
  }

  Map<String, int> get receiptLocalOnlyBaseFlowCanRunCounts {
    return _diagnosticBoolCounts(this, 'receiptLocalOnlyBaseFlowCanRunNow');
  }

  Map<String, int> get receiptLocalOnlyBlocksLowStorageCounts {
    return _diagnosticBoolCounts(this, 'receiptLocalOnlyBlocksLowStorageUsers');
  }

  Map<String, int> get receiptLocalOnlyEvidenceCounts {
    return _diagnosticListValueCounts(this, 'receiptLocalOnlyEvidenceCodes');
  }

  Map<String, int> get nativeLocalOnlyCapturePolicyCounts {
    return _diagnosticValueCounts(this, 'localOnlyCapturePolicy');
  }

  Map<String, int> get nativeLocalOnlyBaseFlowCanRunCounts {
    return _diagnosticBoolCounts(this, 'localOnlyBaseFlowCanRunNow');
  }

  Map<String, int> get nativeLocalOnlyHeavyPacksMayBlockCaptureCounts {
    return _diagnosticBoolCounts(this, 'localOnlyHeavyPacksMayBlockCapture');
  }

  Map<String, int> get nativeLocalOnlyCloudAssistMayBlockCaptureCounts {
    return _diagnosticBoolCounts(this, 'localOnlyCloudAssistMayBlockCapture');
  }

  Map<String, int> get receiptRequiredBaseFootprintStatusCounts {
    return _diagnosticValueCounts(
      this,
      'receiptRequiredBaseFootprintStatusCode',
    );
  }

  Map<String, int> get receiptRequiredBaseFootprintCanShipCounts {
    return _diagnosticBoolCounts(this, 'receiptRequiredBaseFootprintCanShip');
  }

  Map<String, int> get receiptRequiredBaseFootprintReviewCounts {
    return _diagnosticBoolCounts(
      this,
      'receiptRequiredBaseFootprintRequiresReview',
    );
  }

  Map<String, int> get receiptRequiredBaseFootprintBlockingReasonCounts {
    return _diagnosticListValueCounts(
      this,
      'receiptRequiredBaseFootprintBlockingReasonCodes',
    );
  }

  Map<String, int> get receiptRequiredBaseFootprintReviewReasonCounts {
    return _diagnosticListValueCounts(
      this,
      'receiptRequiredBaseFootprintReviewReasonCodes',
    );
  }
}
