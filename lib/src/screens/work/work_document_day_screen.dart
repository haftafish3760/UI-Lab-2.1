import 'package:flutter/material.dart';

import '../../data/operational_attention.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_attention_panel.dart';
import '../../shared/operational_scope.dart';
import '../../theme/app_semantic_colors.dart';
import 'estimate_models.dart';
import 'work_attention_list_screen.dart';
import 'work_models.dart';
import 'work_record_settings_screen.dart';
import 'work_scope_header.dart';
import 'work_selected_date_bar.dart';

class WorkDocumentDayScreen extends StatefulWidget {
  const WorkDocumentDayScreen({
    required this.initialDay,
    required this.kind,
    required this.preferences,
    required this.showFinancials,
    required this.recordsForDay,
    required this.attentionItemsForDay,
    required this.onOpenRecord,
    required this.onDismissAttention,
    super.key,
  }) : assert(kind != WorkRecordKind.job);

  final DateTime initialDay;
  final WorkRecordKind kind;
  final WorkRecordDisplayPreferences preferences;
  final bool showFinancials;
  final List<WorkRecord> Function(DateTime day) recordsForDay;
  final List<OperationalAttentionItem> Function(DateTime day)
  attentionItemsForDay;
  final Future<void> Function(WorkRecord record) onOpenRecord;
  final void Function(DateTime day, List<OperationalAttentionItem> items)
  onDismissAttention;

  @override
  State<WorkDocumentDayScreen> createState() => _WorkDocumentDayScreenState();
}

class _WorkDocumentDayScreenState extends State<WorkDocumentDayScreen> {
  late var _day = DateUtils.dateOnly(widget.initialDay);

  AppViewMode get _view => OperationalScope.of(context).view;
  String? get _employeeId => OperationalScope.of(context).selectedEmployeeId;
  bool get _isEstimate => widget.kind == WorkRecordKind.estimate;
  String get _recordLabel => _isEstimate ? 'Estimate' : 'Invoice';

  @override
  Widget build(BuildContext context) {
    final attentionItems = widget.attentionItemsForDay(_day);
    final attentionIds = {for (final item in attentionItems) item.sourceId};
    final records = widget
        .recordsForDay(_day)
        .where((record) => !attentionIds.contains(record.id))
        .toList();
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final accent = _isEstimate ? semantic.planned : semantic.success;
    final header = _isEstimate
        ? semantic.plannedSurface
        : semantic.successSurface;
    return Scaffold(
      key: ValueKey('${widget.kind.name}-day-screen'),
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
                          workspaceLabel: '$_recordLabel Day',
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
                          key: ValueKey('${widget.kind.name}-day-date'),
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
                            key: ValueKey('${widget.kind.name}-day-attention'),
                            items: attentionItems,
                            rowKeyFor: (item) => ValueKey(
                              '${widget.kind.name}-day-attention-${item.sourceId}',
                            ),
                            onOpen: _openAttention,
                            onOpenAll: () => _openAttentionList(attentionItems),
                            onDismiss: () {
                              widget.onDismissAttention(_day, attentionItems);
                              setState(() {});
                            },
                          ),
                        ],
                        const SizedBox(height: 10),
                        _DocumentDaySection(
                          kind: widget.kind,
                          records: records,
                          accent: accent,
                          headerColor: header,
                          showFinancials: widget.showFinancials,
                          showStatus: widget.preferences.showStatusDetails,
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
        SnackBar(content: Text('This $_recordLabel is no longer available.')),
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
          workspaceLabel: '$_recordLabel attention',
          screenKey: ValueKey('${widget.kind.name}-day-attention-list'),
          rowKeyPrefix: '${widget.kind.name}-day-attention-list',
        ),
      ),
    );
  }
}

class _DocumentDaySection extends StatelessWidget {
  const _DocumentDaySection({
    required this.kind,
    required this.records,
    required this.accent,
    required this.headerColor,
    required this.showFinancials,
    required this.showStatus,
    required this.onOpen,
  });

  final WorkRecordKind kind;
  final List<WorkRecord> records;
  final Color accent;
  final Color headerColor;
  final bool showFinancials;
  final bool showStatus;
  final ValueChanged<WorkRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final label = kind == WorkRecordKind.estimate ? 'Estimates' : 'Invoices';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: accent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: headerColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Icon(
                      kind == WorkRecordKind.estimate
                          ? Icons.request_quote_outlined
                          : Icons.receipt_long_outlined,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$label for this date',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${records.length}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: records.isEmpty
                  ? Text(
                      'No ${label.toLowerCase()} are recorded for this date.',
                    )
                  : Column(
                      children: [
                        for (
                          var index = 0;
                          index < records.length;
                          index++
                        ) ...[
                          _DocumentDayRow(
                            record: records[index],
                            showFinancials: showFinancials,
                            showStatus: showStatus,
                            onOpen: () => onOpen(records[index]),
                          ),
                          if (index < records.length - 1)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentDayRow extends StatelessWidget {
  const _DocumentDayRow({
    required this.record,
    required this.showFinancials,
    required this.showStatus,
    required this.onOpen,
  });

  final WorkRecord record;
  final bool showFinancials;
  final bool showStatus;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = _recordAccent(context, record);
    final colors = Theme.of(context).colorScheme;
    final status = record.kind == WorkRecordKind.estimate
        ? record.resolvedEstimateStage.label
        : record.status.label;
    return Material(
      key: ValueKey('${record.kind.name}-day-row-${record.id}'),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(color: accent.withValues(alpha: .65)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 5, child: ColoredBox(color: accent)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${record.client} · ${record.number}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          record.title,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        if (showStatus || showFinancials)
                          Wrap(
                            spacing: 10,
                            runSpacing: 2,
                            children: [
                              if (showStatus)
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (showFinancials)
                                Text(
                                  '\$${record.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _recordAccent(BuildContext context, WorkRecord record) {
  final semantic = Theme.of(context).extension<AppSemanticColors>()!;
  if (record.kind == WorkRecordKind.invoice) {
    return switch (record.status) {
      WorkRecordStatus.paid => semantic.success,
      WorkRecordStatus.due || WorkRecordStatus.sent => semantic.current,
      WorkRecordStatus.ready => semantic.planned,
      WorkRecordStatus.draft => semantic.draft,
      _ => semantic.attention,
    };
  }
  return switch (record.resolvedEstimateStage) {
    EstimateStage.draft => semantic.draft,
    EstimateStage.readyToSend ||
    EstimateStage.awaitingCustomer ||
    EstimateStage.viewed => semantic.planned,
    EstimateStage.approved || EstimateStage.converted => semantic.success,
    EstimateStage.changesRequested ||
    EstimateStage.expired => semantic.attention,
    EstimateStage.declined ||
    EstimateStage.archived => Theme.of(context).colorScheme.onSurfaceVariant,
  };
}
