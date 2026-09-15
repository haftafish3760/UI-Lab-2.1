class ReceiptIntakeDisplayPreferences {
  const ReceiptIntakeDisplayPreferences({
    this.showReviewChecklist = true,
    this.showEvidenceReminders = true,
    this.assistanceEnabled = false,
    this.detailedReceipts = false,
  });

  final bool showReviewChecklist;
  final bool showEvidenceReminders;
  final bool assistanceEnabled;
  final bool detailedReceipts;

  ReceiptIntakeDisplayPreferences copyWith({
    bool? showReviewChecklist,
    bool? showEvidenceReminders,
    bool? assistanceEnabled,
    bool? detailedReceipts,
  }) => ReceiptIntakeDisplayPreferences(
    showReviewChecklist: showReviewChecklist ?? this.showReviewChecklist,
    showEvidenceReminders: showEvidenceReminders ?? this.showEvidenceReminders,
    assistanceEnabled: assistanceEnabled ?? this.assistanceEnabled,
    detailedReceipts: detailedReceipts ?? this.detailedReceipts,
  );
}
