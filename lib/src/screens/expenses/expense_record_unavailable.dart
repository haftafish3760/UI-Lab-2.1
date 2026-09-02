import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import 'expenses_scope_header.dart';

class ExpenseRecordUnavailable extends StatelessWidget {
  const ExpenseRecordUnavailable({required this.screenKey, super.key});

  final Key screenKey;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    return Scaffold(
      key: screenKey,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.detailWorkspaceFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: insets.copyWith(top: 10, bottom: 32),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.columnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExpensesScopeHeader(
                          view: scope.view,
                          selectedEmployeeId: scope.selectedEmployeeId,
                          onViewChanged: scope.setView,
                          onEmployeeChanged: scope.selectEmployee,
                          onSettings: () {},
                          showBackButton: true,
                          onBack: () => Navigator.pop(context),
                          showSettings: false,
                          workspaceLabel: 'Expense details',
                          showEmployeeStrip: false,
                        ),
                        const SizedBox(height: 14),
                        const SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expense unavailable',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'This record is missing, deleted, or outside '
                                'your current access. No replacement record '
                                'was created.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
