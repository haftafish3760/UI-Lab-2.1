class WorkRecordDisplayPreferences {
  const WorkRecordDisplayPreferences({
    this.showStatusDetails = true,
    this.showAssignments = true,
    this.includeClosedRecords = true,
  });

  final bool showStatusDetails;
  final bool showAssignments;
  final bool includeClosedRecords;
}
