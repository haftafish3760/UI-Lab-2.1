import 'package:flutter/material.dart';

import '../layout/dashboard_layout.dart';
import '../theme/app_theme.dart';
import 'dashboard_calendar.dart';
import 'dashboard_header.dart';
import 'dashboard_interactions.dart';
import 'dashboard_models.dart';
import 'dashboard_navigation.dart';
import 'dashboard_sections.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.onToggleTheme, super.key});

  final VoidCallback onToggleTheme;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var selectedDate = DateTime(2026, 9, 1);
  var attentionDismissed = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
        return const SizedBox.shrink();
      }
      final layout = DashboardLayout.from(
        Size(constraints.maxWidth, constraints.maxHeight),
        MediaQuery.textScalerOf(context),
      );
      return Scaffold(
        body: _DashboardCanvas(
          layout: layout,
          selectedDate: selectedDate,
          attentionDismissed: attentionDismissed,
          onDateSelected: (date) => setState(() => selectedDate = date),
          onDismissAttention: () => setState(() => attentionDismissed = true),
          onRestoreAttention: () => setState(() => attentionDismissed = false),
          onToggleTheme: widget.onToggleTheme,
          onUnavailable: _showUnavailable,
        ),
        bottomNavigationBar: layout.useNavigationRail
            ? null
            : SafeArea(
                top: false,
                child: DashboardBottomNavigation(
                  onUnavailable: _showUnavailable,
                ),
              ),
        floatingActionButton: layout.useNavigationRail
            ? null
            : FloatingActionButton.extended(
                key: const ValueKey('dashboard-add-record-fab'),
                onPressed: () => showDashboardActionDirectory(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add record'),
              ),
      );
    },
  );

  void _showUnavailable(String destination) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$destination is frozen while Dashboard is reviewed.'),
        ),
      );
  }
}

class _DashboardCanvas extends StatelessWidget {
  const _DashboardCanvas({
    required this.layout,
    required this.selectedDate,
    required this.attentionDismissed,
    required this.onDateSelected,
    required this.onDismissAttention,
    required this.onRestoreAttention,
    required this.onToggleTheme,
    required this.onUnavailable,
  });

  final DashboardLayout layout;
  final DateTime selectedDate;
  final bool attentionDismissed;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onDismissAttention;
  final VoidCallback onRestoreAttention;
  final VoidCallback onToggleTheme;
  final ValueChanged<String> onUnavailable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.canvasTop, colors.canvasBottom],
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (layout.useNavigationRail)
              DashboardNavigationRail(onUnavailable: onUnavailable),
            Expanded(
              child: CustomScrollView(
                key: const ValueKey('dashboard-scroll-view'),
                slivers: [
                  SliverPadding(
                    padding: layout.pageInsets.copyWith(top: 12, bottom: 92),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: SizedBox(
                          key: const ValueKey('dashboard-workspace'),
                          width: layout.workspaceWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 800,
                                  ),
                                  child: DashboardHeader(
                                    showWideActions: layout.useNavigationRail,
                                    onOpenMenu: () =>
                                        showDashboardBusinessMenu(context),
                                    onOpenSettings: () => showDashboardSettings(
                                      context,
                                      onToggleTheme,
                                    ),
                                    onAddRecord: () =>
                                        showDashboardActionDirectory(context),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DashboardDateSummary(
                                date: selectedDate,
                                onStartWorkday: () =>
                                    showStartWorkdayConfirmation(context),
                              ),
                              const SizedBox(height: 14),
                              _DashboardLanes(
                                layout: layout,
                                selectedDate: selectedDate,
                                attentionDismissed: attentionDismissed,
                                onDateSelected: onDateSelected,
                                onDismissAttention: onDismissAttention,
                                onRestoreAttention: onRestoreAttention,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLanes extends StatelessWidget {
  const _DashboardLanes({
    required this.layout,
    required this.selectedDate,
    required this.attentionDismissed,
    required this.onDateSelected,
    required this.onDismissAttention,
    required this.onRestoreAttention,
  });

  final DashboardLayout layout;
  final DateTime selectedDate;
  final bool attentionDismissed;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onDismissAttention;
  final VoidCallback onRestoreAttention;

  Widget get attention => AttentionRegion(
    dismissed: attentionDismissed,
    onDismiss: onDismissAttention,
    onRestore: onRestoreAttention,
  );

  Widget get plan => const DashboardRecordSection(
    key: ValueKey('todays-plan-section'),
    title: "Today's plan",
    countLabel: '3 of 4 scheduled items',
    icon: Icons.event_note_outlined,
    tone: DashboardSectionTone.plan,
    records: planRecords,
  );

  Widget get entries => const DashboardRecordSection(
    key: ValueKey('todays-entries-section'),
    title: "Today's entries",
    countLabel: '3 of 5 recorded items',
    icon: Icons.fact_check_outlined,
    tone: DashboardSectionTone.entries,
    records: entryRecords,
  );

  Widget get calendar =>
      DashboardCalendar(selected: selectedDate, onSelected: onDateSelected);

  @override
  Widget build(BuildContext context) {
    final lanes = switch (layout.lanes) {
      DashboardLaneCount.one => [attention, plan, entries, calendar],
      DashboardLaneCount.two => [
        _Lane(gap: layout.gap, children: [attention, plan]),
        _Lane(gap: layout.gap, children: [entries, calendar]),
      ],
      DashboardLaneCount.three => [
        _Lane(gap: layout.gap, children: [attention, plan]),
        entries,
        calendar,
      ],
    };
    return Wrap(
      key: ValueKey('dashboard-${layout.columnCount}-lane-layout'),
      spacing: layout.gap,
      runSpacing: layout.gap,
      children: [
        for (final lane in lanes)
          SizedBox(width: layout.laneWidth, child: lane),
      ],
    );
  }
}

class _Lane extends StatelessWidget {
  const _Lane({required this.gap, required this.children});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < children.length; index++) ...[
        children[index],
        if (index != children.length - 1) SizedBox(height: gap),
      ],
    ],
  );
}
