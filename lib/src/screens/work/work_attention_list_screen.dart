import 'package:flutter/material.dart';

import '../../data/operational_attention.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/operational_attention_panel.dart';
import '../../shared/operational_scope.dart';
import 'work_scope_header.dart';

/// One full-list route for every Work-owned Needs attention panel.
///
/// The caller supplies already permission- and scope-filtered projections and
/// retains exact-record navigation. This screen owns presentation only.
class WorkAttentionListScreen extends StatelessWidget {
  const WorkAttentionListScreen({
    required this.selectedDay,
    required this.items,
    required this.onOpen,
    this.workspaceLabel = 'Needs attention',
    this.screenKey = const ValueKey('work-attention-list'),
    this.rowKeyPrefix = 'work-attention-list',
    this.onSettings,
    super.key,
  });

  final DateTime selectedDay;
  final List<OperationalAttentionItem> items;
  final ValueChanged<OperationalAttentionItem> onOpen;
  final String workspaceLabel;
  final Key screenKey;
  final String rowKeyPrefix;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    return Scaffold(
      key: screenKey,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final available = constraints.maxWidth - insets.horizontal;
            final layout = AppLayoutEngine.detailWorkspaceFor(
              available,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 32),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkScopeHeader(
                          view: scope.view,
                          selectedDay: selectedDay,
                          selectedEmployeeId: scope.selectedEmployeeId,
                          workspaceLabel: workspaceLabel,
                          showBackButton: true,
                          showEmployeeStrip: false,
                          showDateDescription: false,
                          onBack: () => Navigator.pop(context),
                          onViewChanged: scope.setView,
                          onEmployeeChanged: scope.selectEmployee,
                          onSettings: onSettings,
                        ),
                        const SizedBox(height: 12),
                        OperationalAttentionList(
                          items: items,
                          rowKeyFor: (item) =>
                              ValueKey('$rowKeyPrefix-${item.sourceId}'),
                          onOpen: onOpen,
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
