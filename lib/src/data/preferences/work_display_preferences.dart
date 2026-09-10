class WorkDisplayPreferences {
  const WorkDisplayPreferences({
    this.showEmployeeCards = true,
    this.showDailySummaries = true,
    this.includeCompletedWork = true,
  });

  final bool showEmployeeCards;
  final bool showDailySummaries;
  final bool includeCompletedWork;

  WorkDisplayPreferences copyWith({
    bool? showEmployeeCards,
    bool? showDailySummaries,
    bool? includeCompletedWork,
  }) => WorkDisplayPreferences(
    showEmployeeCards: showEmployeeCards ?? this.showEmployeeCards,
    showDailySummaries: showDailySummaries ?? this.showDailySummaries,
    includeCompletedWork: includeCompletedWork ?? this.includeCompletedWork,
  );
}
