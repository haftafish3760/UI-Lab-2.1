part of 'job_list_workspace_screen.dart';

class JobDayScreen extends StatefulWidget {
  const JobDayScreen({
    required this.initialDay,
    required this.preferences,
    required this.recordsForDay,
    required this.attentionItemsForDay,
    required this.onOpenRecord,
    required this.onDismissAttention,
    super.key,
  });

  final DateTime initialDay;
  final WorkRecordDisplayPreferences preferences;
  final List<WorkRecord> Function(DateTime day) recordsForDay;
  final List<OperationalAttentionItem> Function(DateTime day)
  attentionItemsForDay;
  final Future<void> Function(WorkRecord record) onOpenRecord;
  final void Function(DateTime day, List<OperationalAttentionItem> items)
  onDismissAttention;

  @override
  State<JobDayScreen> createState() => _JobDayScreenState();
}

class _JobDayScreenState extends State<JobDayScreen> {
  late var _day = DateUtils.dateOnly(widget.initialDay);

  AppViewMode get _view => OperationalScope.of(context).view;
  String? get _employeeId => OperationalScope.of(context).selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    final attentionItems = widget.attentionItemsForDay(_day);
    final attentionIds = {for (final item in attentionItems) item.sourceId};
    final records = widget
        .recordsForDay(_day)
        .where((record) => !attentionIds.contains(record.id))
        .toList();
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Scaffold(
      key: const ValueKey('job-day-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.workFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkScopeHeader(
                          view: _view,
                          selectedDay: _day,
                          selectedEmployeeId: _employeeId,
                          workspaceLabel: 'Job Day',
                          showBackButton: true,
                          showDateContext: false,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.of(context).pop(),
                          onViewChanged: OperationalScope.of(context).setView,
                          onEmployeeChanged: OperationalScope.of(
                            context,
                          ).selectEmployee,
                        ),
                        const SizedBox(height: 12),
                        WorkSelectedDateBar(
                          key: const ValueKey('job-day-date'),
                          selectedDay: _day,
                          onPrevious: () => _changeDay(
                            _day.subtract(const Duration(days: 1)),
                          ),
                          onNext: () =>
                              _changeDay(_day.add(const Duration(days: 1))),
                        ),
                        if (attentionItems.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          OperationalAttentionPanel(
                            key: const ValueKey('job-day-attention'),
                            items: attentionItems,
                            rowKeyFor: (item) =>
                                ValueKey('job-day-attention-${item.sourceId}'),
                            onOpen: _openAttention,
                            onOpenAll: () => _openAttentionList(attentionItems),
                            onDismiss: () {
                              widget.onDismissAttention(_day, attentionItems);
                              setState(() {});
                            },
                          ),
                        ],
                        const SizedBox(height: 10),
                        _JobListSection(
                          key: const ValueKey('job-day-records'),
                          title: 'Jobs for this date',
                          icon: Icons.event_available_outlined,
                          records: records,
                          totalCount: records.length,
                          emptyMessage: 'No jobs are recorded for this date.',
                          headerColor: semantic.plannedSurface,
                          borderColor: semantic.planned,
                          selectedDay: _day,
                          preferences: widget.preferences,
                          onOpen: _openRecord,
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

  void _changeDay(DateTime day) =>
      setState(() => _day = DateUtils.dateOnly(day));

  Future<void> _openRecord(WorkRecord record) async {
    await widget.onOpenRecord(record);
    if (mounted) setState(() {});
  }

  Future<void> _openAttention(OperationalAttentionItem item) async {
    final matches = widget
        .recordsForDay(_day)
        .where((record) => record.id == item.sourceId);
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This job is no longer available.')),
      );
      return;
    }
    await _openRecord(matches.first);
  }

  void _openAttentionList(List<OperationalAttentionItem> items) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkAttentionListScreen(
          selectedDay: _day,
          items: items,
          onOpen: _openAttention,
          workspaceLabel: 'Job attention',
          screenKey: const ValueKey('job-day-attention-list'),
          rowKeyPrefix: 'job-day-attention-list',
        ),
      ),
    );
  }
}
