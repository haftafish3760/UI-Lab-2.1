import 'package:flutter/material.dart';

import '../../shared/operational_scope.dart';
import 'work_scope_header.dart';

class WorkDetailHeader extends StatelessWidget {
  const WorkDetailHeader({
    required this.label,
    required this.selectedDay,
    required this.onBack,
    this.onSettings,
    this.showDateContext = false,
    this.documentPresentation = false,
    super.key,
  });

  final String label;
  final DateTime selectedDay;
  final VoidCallback onBack;
  final VoidCallback? onSettings;
  final bool showDateContext;
  final bool documentPresentation;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    return WorkScopeHeader(
      documentPresentation: documentPresentation,
      view: scope.view,
      selectedDay: selectedDay,
      selectedEmployeeId: scope.selectedEmployeeId,
      onViewChanged: scope.setView,
      onEmployeeChanged: scope.selectEmployee,
      workspaceLabel: label,
      showBackButton: true,
      onBack: onBack,
      onSettings: onSettings,
      showDateContext: showDateContext,
      showDateDescription: false,
      showEmployeeStrip: false,
    );
  }
}
