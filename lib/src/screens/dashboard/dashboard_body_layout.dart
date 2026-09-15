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
    required this.onOpenActions,
    required this.onEndWorkday,
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
  final VoidCallback? onOpenActions;
  final VoidCallback onEndWorkday;

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
          hasEntries: data.entries.isNotEmpty,
        );
        final type = AppLayoutEngine.typographyFor(layout.workspaceWidth);
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: SizedBox(
                  width:
                      bodyConstraints.maxWidth <=
                          AppLayoutEngine.compactHeaderMaximum
                      ? bodyConstraints.maxWidth
                      : math.min(
                          bodyConstraints.maxWidth,
                          layout.workspaceWidth + pageInsets.horizontal,
                        ),
                  child: ActiveVehicleHeader(
                    dashboardWide: true,
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
              padding: pageInsets.copyWith(
                top: 12,
                bottom: layout.columns == 1 ? 16 : 92,
              ),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: availableWidth.toDouble(),
                  child: OperationsWorkspaceFrame(
                    layout: layout,
                    primaryContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (layout.columns > 1)
                          _DashboardCommandBar(body: this, layout: layout)
                        else
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
                        if (layout.columns == 1) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (view == AppViewMode.technician &&
                                  workday == null)
                                Expanded(
                                  child: FilledButton.icon(
                                    key: const ValueKey('start-workday-button'),
                                    onPressed: onStartWorkday,
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: Text(
                                      context.l10n.dashboardStartWorkday,
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.startWorkday,
                                      foregroundColor: AppColors.ink,
                                      minimumSize: const Size(0, 48),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DashboardViewSelector(
                                  view: view,
                                  onChanged: onViewChanged,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (view == AppViewMode.admin && employee == null)
                          AdminDashboardOverview(
                            summaryOnly: true,
                            date: selectedDate,
                            permissions:
                                const DashboardPermissions.development(),
                            onOpenPlan: onOpenPlan,
                            onAttention: onOpenAllAttention,
                            attentionCount: attentionItems.length,
                          ),
                        if (view != AppViewMode.admin)
                          DashboardSummaryStrip(
                            wide: layout.columns > 1,
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
                          ActiveWorkdayOverview(
                            session: workday!,
                            showLegacyNextJob: layout.columns == 1,
                          ),
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
                            maximumWidth: layout.calendarWidth,
                            selectedDay: selectedDate,
                            onDaySelected: onDateSelected,
                            entryCountForDay: entryCountForDay,
                            needsApprovalForDay: needsApprovalForDay,
                          ),
                        ),
                        if (view == AppViewMode.admin)
                          const SizedBox(height: 20),
                        if (view == AppViewMode.admin && employee != null) ...[
                          AdminEmployeeOverview(
                            employee: employee!,
                            date: selectedDate,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (view == AppViewMode.admin && employee == null)
                          AdminDashboardOverview(
                            date: selectedDate,
                            permissions:
                                const DashboardPermissions.development(),
                            onOpenPlan: onOpenPlan,
                            onAttention: onOpenAllAttention,
                            attentionCount: attentionItems.length,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (layout.columns == 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 92),
                  child: CalendarWidthSection(
                    child: DashboardCalendar(
                      key: ValueKey(
                        view == AppViewMode.admin && employee == null
                            ? 'admin-company-calendar'
                            : 'dashboard-technician-calendar',
                      ),
                      maximumWidth: AppLayoutEngine.calendarMaximum,
                      selectedDay: selectedDate,
                      onDaySelected: onDateSelected,
                      entryCountForDay: entryCountForDay,
                      needsApprovalForDay: needsApprovalForDay,
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

  final DashboardWorkspaceLayout layout;
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
      previewCount: layout.columns > 1 ? 6 : 3,
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
      previewCount: layout.columns > 1 ? 6 : 3,
      date: date,
      entries: data.entries,
      showOdometer: showOdometer,
      onOpen: onOpenEntry,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final calendarLane = KeyedSubtree(
      key: companyOverview
          ? const ValueKey('admin-company-calendar')
          : const ValueKey('dashboard-technician-calendar'),
      child: calendar,
    );
    if (layout.columns > 1) {
      return KeyedSubtree(
        key: ValueKey('dashboard-${layout.columns}-lane-row'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: layout.columns == 3 && data.entries.isNotEmpty
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: plan),
                        SizedBox(width: layout.gap),
                        Expanded(child: entries),
                      ],
                    )
                  : Align(
                      alignment: AlignmentDirectional.topStart,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            plan,
                            if (data.entries.isNotEmpty) ...[
                              SizedBox(height: layout.gap),
                              entries,
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
            SizedBox(width: layout.gap),
            SizedBox(width: layout.calendarWidth, child: calendarLane),
          ],
        ),
      );
    }
    final lanes = [plan, if (data.entries.isNotEmpty) entries];
    return KeyedSubtree(
      key: ValueKey('dashboard-${layout.columns}-lane-row'),
      child: OperationsLaneGrid(layout: layout, children: lanes),
    );
  }
}
