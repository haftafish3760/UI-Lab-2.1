class ReportDisplayPreferences {
  const ReportDisplayPreferences({
    required this.showInvoicedRevenue,
    required this.showMoneyCollected,
    required this.showRecordedExpenses,
    required this.showEstimatedGrossProfit,
    required this.showVehicleHealth,
  });

  const ReportDisplayPreferences.defaults()
    : showInvoicedRevenue = true,
      showMoneyCollected = true,
      showRecordedExpenses = true,
      showEstimatedGrossProfit = true,
      showVehicleHealth = true;

  final bool showInvoicedRevenue;
  final bool showMoneyCollected;
  final bool showRecordedExpenses;
  final bool showEstimatedGrossProfit;
  final bool showVehicleHealth;

  ReportDisplayPreferences copyWith({
    bool? showInvoicedRevenue,
    bool? showMoneyCollected,
    bool? showRecordedExpenses,
    bool? showEstimatedGrossProfit,
    bool? showVehicleHealth,
  }) => ReportDisplayPreferences(
    showInvoicedRevenue: showInvoicedRevenue ?? this.showInvoicedRevenue,
    showMoneyCollected: showMoneyCollected ?? this.showMoneyCollected,
    showRecordedExpenses: showRecordedExpenses ?? this.showRecordedExpenses,
    showEstimatedGrossProfit:
        showEstimatedGrossProfit ?? this.showEstimatedGrossProfit,
    showVehicleHealth: showVehicleHealth ?? this.showVehicleHealth,
  );
}
