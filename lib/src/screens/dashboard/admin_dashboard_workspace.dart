part of 'dashboard_screen.dart';

/// Admin-only composition. Technician rendering and settings stay on their
/// original path. This review surface uses the existing development access.
class _AdminDashboardWorkspace extends StatefulWidget {
  const _AdminDashboardWorkspace({required this.body});
  final _DashboardBody body;
  @override
  State<_AdminDashboardWorkspace> createState() =>
      _AdminDashboardWorkspaceState();
}

class _AdminDashboardWorkspaceState extends State<_AdminDashboardWorkspace> {
  List<String>? _draft;
  bool _saving = false;
  String? _error;
  _DashboardBody get body => widget.body;
  bool get editing => _draft != null;

  List<String> get _saved =>
      AppPreferencesScope.maybeOf(context)?.adminDashboardWidgets ??
      AdminDashboardLayoutConfiguration.defaults;

  bool get _approvalsEnabled => PrototypeOperationsScope.of(
    context,
  ).companyProfile.requireEstimateApproval;

  List<String> get _allowed => [
    'work',
    'calendar',
    'entries',
    if (body.employee == null) ...['billing', 'payments'],
    if (_approvalsEnabled) 'approvals',
  ];

  Future<void> _save() async {
    if (_saving ||
        _draft == null ||
        OperationalScope.of(context).view != AppViewMode.admin) {
      return;
    }
    final preferences = AppPreferencesScope.maybeOf(context);
    if (preferences == null) {
      setState(
        () =>
            _error = 'Layout storage is unavailable. Your changes remain here.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await preferences.setAdminDashboardWidgets(List.of(_draft!));
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) {
        _draft = null;
      } else {
        _error =
            'Layout was not saved. Your previous layout is still active. Try Save layout again.';
      }
    });
  }

  void _startEditing() => setState(() {
    _draft = List.of(_saved);
    _error = null;
  });

  Future<void> _add() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AdminWidgetCatalog(
          available: [
            for (final id in _allowed)
              if (!_draft!.contains(id)) id,
          ],
        ),
      ),
    );
    if (!mounted || id == null || _draft == null || !_allowed.contains(id)) {
      return;
    }
    setState(() {
      if (!_draft!.contains(id)) _draft!.add(id);
    });
  }

  void _move(String id, int direction) {
    final visible = _draft!.where(_allowed.contains).toList();
    final visibleTarget = visible.indexOf(id) + direction;
    if (visibleTarget < 0 || visibleTarget >= visible.length) return;
    final index = _draft!.indexOf(id);
    final target = _draft!.indexOf(visible[visibleTarget]);
    setState(() {
      _draft!.removeAt(index);
      _draft!.insert(target, id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = (_draft ?? _saved).where(_allowed.contains).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
        final layout = AppLayoutEngine.operationsFor(
          constraints.maxWidth - insets.horizontal,
          textScaler: MediaQuery.textScalerOf(context),
        );
        return SingleChildScrollView(
          key: const PageStorageKey('admin-dashboard-scroll'),
          padding: insets.copyWith(bottom: 100),
          child: OperationsWorkspaceFrame(
            layout: layout,
            primaryContent: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DashboardDateHeading(
                      type: AppLayoutEngine.typographyFor(
                        layout.workspaceWidth,
                      ),
                      date: body.selectedDate,
                      onReturnToToday: body.onReturnToToday,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        IgnorePointer(
                          ignoring: editing,
                          child: _AdminContextControl(body: body),
                        ),
                        IgnorePointer(
                          ignoring: editing,
                          child: DashboardViewSelector(
                            view: body.view,
                            onChanged: body.onViewChanged,
                          ),
                        ),
                        if (!editing) ...[
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ReportsScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.insights_outlined),
                            label: const Text('Recap'),
                          ),
                          if (layout.columns > 1 && body.onOpenActions != null)
                            FilledButton.icon(
                              onPressed: body.onOpenActions,
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (editing) _editorToolbar(),
                if (!editing) ...[
                  if (body.employee == null) ...[
                    const DashboardEmployeeStatusSummary(),
                    const SizedBox(height: 12),
                  ],
                  AdminAttentionSummary(
                    items: body.attentionItems,
                    onOpen: body.onOpenAllAttention,
                  ),
                  const SizedBox(height: 16),
                ],
                ScreenWidgetBoard(
                  layout: layout,
                  children: [
                    for (final id in active.where(
                      (id) =>
                          editing ||
                          id != 'entries' ||
                          !active.contains('work'),
                    ))
                      KeyedSubtree(
                        key: ValueKey('admin-widget-$id'),
                        child: editing
                            ? ScreenLayoutEditControls(
                                title: adminWidgetLabels[id]!,
                                onEarlier: _saving || active.indexOf(id) == 0
                                    ? null
                                    : () => _move(id, -1),
                                onLater:
                                    _saving ||
                                        active.indexOf(id) == active.length - 1
                                    ? null
                                    : () => _move(id, 1),
                                onRemove: id == 'calendar' || _saving
                                    ? null
                                    : () => setState(() => _draft!.remove(id)),
                                child: _content(id, layout),
                              )
                            : id == 'work' && active.contains('entries')
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _content(id, layout),
                                  SizedBox(height: layout.gap),
                                  KeyedSubtree(
                                    key: const ValueKey('admin-widget-entries'),
                                    child: _content('entries', layout),
                                  ),
                                ],
                              )
                            : _content(id, layout),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) => Material(
    color: AppColors.header,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: AppMenuScope.maybeOpenOf(context),
            tooltip: 'Open navigation menu',
            color: AppColors.onHeader,
            icon: const Icon(Icons.menu_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.onHeader,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PopupMenuButton<String>(
            key: const ValueKey('dashboard-settings-button'),
            tooltip: 'Dashboard settings',
            enabled: !editing,
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.onHeader,
            ),
            onSelected: (_) => _startEditing(),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'layout',
                child: Text('Customize dashboard'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _editorToolbar() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Customize dashboard',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Text(
          'Add or remove widgets and change their order. Calendar stays available.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _saving ? null : _add,
              icon: const Icon(Icons.add),
              label: const Text('Add widgets'),
            ),
            TextButton(
              onPressed: _saving
                  ? null
                  : () => setState(
                      () => _draft = List.of(
                        AdminDashboardLayoutConfiguration.defaults,
                      ),
                    ),
              child: const Text('Restore default layout'),
            ),
            TextButton(
              onPressed: _saving
                  ? null
                  : () => setState(() {
                      _draft = null;
                      _error = null;
                    }),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_saving ? 'Saving…' : 'Save layout'),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, semanticsLabel: _error),
          ),
      ],
    ),
  );

  Widget _content(String id, OperationsWorkspaceLayout layout) => switch (id) {
    'work' =>
      body.employee == null
          ? AdminCompanyWork(date: body.selectedDate, onOpen: body.onOpenPlan)
          : TodayPlan(
              date: body.selectedDate,
              items: body.data.plan,
              onOpen: body.onOpenPlan,
              onAction: body.onPlanAction,
            ),
    'billing' => AdminDashboardOverview(
      date: body.selectedDate,
      permissions: const DashboardPermissions.development(),
      onOpenPlan: body.onOpenPlan,
      onAttention: body.onOpenAllAttention,
      attentionCount: body.attentionItems.length,
    ),
    'calendar' => Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(
        width: math.min(layout.laneWidth, AppLayoutEngine.dashboardLaneMaximum),
        child: DashboardCalendar(
          key: const ValueKey('admin-company-calendar'),
          maximumWidth: math.min(
            layout.laneWidth,
            AppLayoutEngine.dashboardLaneMaximum,
          ),
          selectedDay: body.selectedDate,
          onDaySelected: body.onDateSelected,
          entryCountForDay: body.entryCountForDay,
          needsApprovalForDay: body.needsApprovalForDay,
        ),
      ),
    ),
    'entries' => TodayEntries(
      date: body.selectedDate,
      entries: body.data.entries,
      showOdometer: body.showOdometer,
      onOpen: body.onOpenEntry,
    ),
    'payments' => AdminPaymentsToday(date: body.selectedDate),
    'approvals' => AdminApprovalQueue(
      items: _approvalItems,
      onOpen: body.onOpenAttention,
      onOpenAll: body.onOpenAllAttention,
    ),
    _ => const SizedBox.shrink(),
  };

  List<OperationalAttentionItem> get _approvalItems {
    final records = PrototypeOperationsScope.of(context).workRecords;
    final ids = records
        .where(
          (record) =>
              record.kind == WorkRecordKind.estimate &&
              record.estimateCompanyReviewStatus ==
                  EstimateCompanyReviewStatus.pending,
        )
        .map((record) => record.id)
        .toSet();
    return body.attentionItems
        .where(
          (item) =>
              item.resourceKind == OperationalAttentionResourceKind.estimate &&
              ids.contains(item.sourceId),
        )
        .toList();
  }
}

class _AdminContextControl extends StatelessWidget {
  const _AdminContextControl({required this.body});
  final _DashboardBody body;
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    key: ValueKey(
      body.employee == null
          ? 'company-overview-summary'
          : 'active-employee-summary',
    ),
    tooltip: 'View company overview or an employee',
    initialValue: body.employee?.id ?? 'company',
    onSelected: (id) => id == 'company'
        ? body.onCompanyOverview()
        : body.onEmployeeSelected(demoEmployees.firstWhere((e) => e.id == id)),
    itemBuilder: (_) => [
      const PopupMenuItem(value: 'company', child: Text('Company Overview')),
      for (final employee in demoEmployees)
        PopupMenuItem(value: employee.id, child: Text(employee.name)),
    ],
    child: Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            body.employee == null
                ? Icons.business_outlined
                : Icons.person_outline,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Viewing: ${body.employee?.name ?? 'Company Overview'}',
            ),
          ),
          const Icon(Icons.expand_more, size: 20),
        ],
      ),
    ),
  );
}
