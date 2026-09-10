part of 'dashboard_screen.dart';

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.view,
    required this.selectedDate,
    required this.employee,
    required this.data,
    required this.showOdometer,
    required this.onViewChanged,
    required this.onDateSelected,
    required this.onEmployeeSelected,
    required this.onCompanyOverview,
    required this.workday,
    required this.onStartWorkday,
    required this.onSettings,
    required this.onReturnToToday,
    required this.attentionItems,
    required this.onOpenAllAttention,
    required this.onOpenPlan,
    required this.onPlanAction,
    required this.onOpenEntry,
    required this.entryCountForDay,
    required this.needsApprovalForDay,
  });

  final AppViewMode view;
  final DateTime selectedDate;
  final EmployeeStatus? employee;
  final DashboardDayData data;
  final bool showOdometer;
  final ValueChanged<AppViewMode> onViewChanged;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<EmployeeStatus> onEmployeeSelected;
  final VoidCallback onCompanyOverview;
  final DashboardWorkdaySession? workday;
  final VoidCallback onStartWorkday;
  final VoidCallback onSettings;
  final VoidCallback onReturnToToday;
  final List<OperationalAttentionItem> attentionItems;
  final VoidCallback onOpenAllAttention;
  final ValueChanged<PlanItem> onOpenPlan;
  final void Function(PlanItem item, PlanAction action) onPlanAction;
  final ValueChanged<DayEntry> onOpenEntry;
  final int Function(DateTime day) entryCountForDay;
  final bool Function(DateTime day) needsApprovalForDay;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, bodyConstraints) {
        final pageInsets = AppLayoutEngine.pageInsetsFor(
          bodyConstraints.maxWidth,
        );
        final availableWidth = math.max(
          0,
          bodyConstraints.maxWidth - pageInsets.horizontal,
        );
        final layout = AppLayoutEngine.dashboardOperationsFor(
          availableWidth.toDouble(),
          textScaler: scaler,
        );
        final type = AppLayoutEngine.typographyFor(layout.workspaceWidth);
        final employeeStrip = view == AppViewMode.admin
            ? EmployeeStatusStrip(
                employees: demoEmployees,
                selectedId: employee?.id,
                onSelected: onEmployeeSelected,
              )
            : null;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: SizedBox(
                  width: math.min(
                    bodyConstraints.maxWidth,
                    layout.workspaceWidth + pageInsets.horizontal,
                  ),
                  child: ActiveVehicleHeader(
                    ownerPresentation: true,
                    view: view,
                    onViewChanged: onViewChanged,
                    activeEmployee: employee,
                    onEmployeeSelected: onEmployeeSelected,
                    onCompanyOverview: onCompanyOverview,
                    onStartWorkday: onStartWorkday,
                    onSettings: onSettings,
                    showPrimaryAction: false,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: pageInsets.copyWith(top: 12, bottom: 92),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: availableWidth.toDouble(),
                  child: OperationsWorkspaceFrame(
                    layout: layout,
                    primaryContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            width: layout.laneWidth,
                            child: DashboardDateHeading(
                              type: type,
                              date: selectedDate,
                              onReturnToToday: onReturnToToday,
                            ),
                          ),
                        ),
                        if (view == AppViewMode.technician &&
                            workday == null) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FilledButton.icon(
                              key: const ValueKey('start-workday-button'),
                              onPressed: onStartWorkday,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(context.l10n.dashboardStartWorkday),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.startWorkday,
                                foregroundColor: AppColors.ink,
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                          ),
                        ],
                        if (employeeStrip != null) ...[
                          const SizedBox(height: 12),
                          employeeStrip,
                        ],
                        const SizedBox(height: 12),
                        DashboardSummaryStrip(
                          date: selectedDate,
                          data: data,
                          attentionCount: attentionItems.length,
                          onAttention: onOpenAllAttention,
                          onPayments: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PaymentsScreen(initialDay: selectedDate),
                            ),
                          ),
                          onExpenses: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ExpensesDayScreen(day: selectedDate),
                            ),
                          ),
                          onWork: () => onDateSelected(selectedDate),
                          onMiles: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(context.l10n.dashboardMilesLabel),
                              content: Text(
                                context.l10n.dashboardMileageUnavailable,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    MaterialLocalizations.of(
                                      context,
                                    ).closeButtonLabel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (workday != null) ...[
                          ActiveWorkdayOverview(session: workday!),
                          const SizedBox(height: 12),
                        ],
                        _DashboardLanes(
                          layout: layout,
                          date: selectedDate,
                          data: data,
                          showOdometer: showOdometer,
                          onOpenPlan: onOpenPlan,
                          onPlanAction: onPlanAction,
                          onOpenEntry: onOpenEntry,
                          companyOverview:
                              view == AppViewMode.admin && employee == null,
                          calendar: DashboardCalendar(
                            compact: layout.columns == 1,
                            maximumWidth: layout.laneWidth,
                            selectedDay: selectedDate,
                            onDaySelected: onDateSelected,
                            entryCountForDay: entryCountForDay,
                            needsApprovalForDay: needsApprovalForDay,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardLanes extends StatelessWidget {
  const _DashboardLanes({
    required this.layout,
    required this.date,
    required this.data,
    required this.showOdometer,
    required this.onOpenPlan,
    required this.onPlanAction,
    required this.onOpenEntry,
    required this.calendar,
    required this.companyOverview,
  });

  final OperationsWorkspaceLayout layout;
  final DateTime date;
  final DashboardDayData data;
  final bool showOdometer;
  final ValueChanged<PlanItem> onOpenPlan;
  final void Function(PlanItem item, PlanAction action) onPlanAction;
  final ValueChanged<DayEntry> onOpenEntry;
  final Widget calendar;
  final bool companyOverview;

  Widget get plan => KeyedSubtree(
    key: companyOverview
        ? const ValueKey('admin-company-schedule')
        : const ValueKey('dashboard-technician-schedule'),
    child: TodayPlan(
      date: date,
      items: data.plan,
      onOpen: onOpenPlan,
      onAction: onPlanAction,
    ),
  );
  Widget get entries => KeyedSubtree(
    key: companyOverview
        ? const ValueKey('admin-company-entries')
        : const ValueKey('dashboard-technician-entries'),
    child: TodayEntries(
      date: date,
      entries: data.entries,
      showOdometer: showOdometer,
      onOpen: onOpenEntry,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final priorityLane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [plan],
    );
    final calendarLane = KeyedSubtree(
      key: companyOverview
          ? const ValueKey('admin-company-calendar')
          : const ValueKey('dashboard-technician-calendar'),
      child: calendar,
    );
    final lanes = switch (layout.columns) {
      1 => [priorityLane, if (data.entries.isNotEmpty) entries, calendarLane],
      2 => [
        priorityLane,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (data.entries.isNotEmpty) ...[
              entries,
              SizedBox(height: layout.gap),
            ],
            calendarLane,
          ],
        ),
      ],
      _ => [priorityLane, if (data.entries.isNotEmpty) entries, calendarLane],
    };
    return KeyedSubtree(
      key: ValueKey('dashboard-${layout.columns}-lane-row'),
      child: OperationsLaneGrid(layout: layout, children: lanes),
    );
  }
}
