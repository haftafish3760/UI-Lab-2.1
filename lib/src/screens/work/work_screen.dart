import 'package:flutter/material.dart';

import '../../data/operational_attention.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/app_preferences.dart';
import '../../shared/operational_scope.dart';
import '../../shared/operations_workspace.dart';
import '../../shared/operational_attention_panel.dart';
import '../../shared/section_card.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_theme.dart';
import '../dashboard/dashboard_models.dart';
import '../dashboard/employee_status_strip.dart';
import 'company_profile_screen.dart';
import 'customer_edit_screen.dart';
import 'estimate_detail_screen.dart';
import 'estimate_editor_screen.dart';
import 'estimate_models.dart';
import 'estimate_workspace_screen.dart';
import 'invoice_detail_screen.dart';
import 'invoice_editor_screen.dart';
import 'invoice_permissions.dart';
import 'invoice_workspace_screen.dart';
import 'job_list_workspace_screen.dart';
import 'job_workspace_screen.dart';
import 'work_contact_models.dart';
import 'payments_screen.dart';
import 'saved_clients_screen.dart';
import 'job_assignment_editor_sheet.dart';
import 'work_attention_list_screen.dart';
import 'work_job_editor.dart';
import 'work_models.dart';
import 'work_month_calendar.dart';
import 'work_scope_header.dart';
import 'work_settings_screen.dart';
import 'work_shortcuts.dart';

part 'work_home_widgets.dart';
part 'work_section_chrome.dart';
part 'work_home_lanes.dart';
part 'work_actions_screen.dart';
part 'work_screen_actions.dart';
part 'work_day_screen.dart';

class WorkScreen extends StatefulWidget {
  const WorkScreen({super.key});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  var _selectedDay = DateUtils.dateOnly(DateTime.now());
  var _fixturePreferences = const WorkDisplayPreferences();
  WorkDisplayPreferences get _preferences {
    final saved = AppPreferencesScope.maybeOf(context);
    return saved == null
        ? _fixturePreferences
        : WorkDisplayPreferences(
            showEmployeeCards: saved.workShowEmployeeCards,
            showDailySummaries: saved.workShowDailySummaries,
            includeCompletedWork: saved.workIncludeCompletedWork,
          );
  }

  List<WorkRecord> get _records =>
      PrototypeOperationsScope.of(context).workRecords;

  AppViewMode get _view => OperationalScope.of(context).view;
  String? get _selectedEmployeeId =>
      OperationalScope.of(context).selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
        final availableWidth = constraints.maxWidth - insets.horizontal;
        final layout = AppLayoutEngine.workLandingFor(
          availableWidth,
          textScaler: MediaQuery.textScalerOf(context),
        );
        final recordLayout = OperationsWorkspaceLayout(
          columns: 1,
          laneWidth: layout.laneWidth,
          gap: 16,
          workspaceWidth: layout.laneWidth,
        );
        final recordsInScope = _records.where(_recordIsInScope).toList();
        final attentionQuery = _attentionQuery();
        final attentionCenter = PrototypeOperationsScope.of(
          context,
        ).attentionCenter;
        final attentionItems = attentionCenter.itemsFor(attentionQuery);
        final showAttention = attentionCenter.shouldShow(
          attentionQuery,
          attentionItems,
        );
        final employeeStrip =
            _view == AppViewMode.admin && _preferences.showEmployeeCards
            ? EmployeeStatusStrip(
                employees: demoEmployees,
                selectedId: _selectedEmployeeId,
                onSelected: (employee) =>
                    OperationalScope.of(context).selectEmployee(employee.id),
              )
            : null;
        return Scaffold(
          key: const ValueKey('work-module-screen'),
          floatingActionButton: layout.columns == 1
              ? FloatingActionButton.extended(
                  key: const ValueKey('work-actions-fab'),
                  heroTag: 'work-actions-fab',
                  onPressed: _showWorkActions,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add work'),
                )
              : null,
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 96),
              children: [
                SizedBox(
                  width: availableWidth,
                  child: OperationsWorkspaceFrame(
                    layout: layout,
                    primaryContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkScopeHeader(
                          view: _view,
                          selectedDay: _selectedDay,
                          selectedEmployeeId: _selectedEmployeeId,
                          onViewChanged: OperationalScope.of(context).setView,
                          onEmployeeChanged: OperationalScope.of(
                            context,
                          ).selectEmployee,
                          onSettings: _openSettings,
                          showEmployeeStrip: false,
                          showDateContext: false,
                          showDateDescription: false,
                        ),
                        const SizedBox(height: 14),
                        WorkShortcutGrid(
                          key: const ValueKey('work-primary-destinations'),
                          destinations: const [
                            WorkDestination.jobs,
                            WorkDestination.payments,
                            WorkDestination.scheduling,
                            WorkDestination.quotes,
                            WorkDestination.estimates,
                            WorkDestination.invoices,
                          ],
                          onSelected: _handleDestination,
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text(
                              MaterialLocalizations.of(
                                context,
                              ).formatFullDate(_selectedDay),
                              key: const ValueKey('work-date-heading'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (layout.showsInlineModuleActions)
                              FilledButton.icon(
                                key: const ValueKey('work-actions-inline'),
                                onPressed: _showWorkActions,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add work'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        OperationsLaneGrid(
                          key: const ValueKey('work-landing-lanes'),
                          layout: layout,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showAttention) ...[
                                  OperationsLaneGrid(
                                    key: ValueKey(
                                      'work-${layout.columns}-column-attention',
                                    ),
                                    layout: recordLayout,
                                    children: [
                                      OperationalAttentionPanel(
                                        key: const ValueKey(
                                          'work-attention-section',
                                        ),
                                        items: attentionItems,
                                        rowKeyFor: (item) => ValueKey(
                                          'work-attention-${item.sourceId}',
                                        ),
                                        onOpen: _openAttentionItem,
                                        onOpenAll: () =>
                                            _openAttentionList(attentionItems),
                                        onDismiss: () =>
                                            attentionCenter.dismiss(
                                              attentionQuery,
                                              attentionItems,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (employeeStrip != null) ...[
                                  employeeStrip,
                                  const SizedBox(height: 12),
                                ],
                                _WorkLanes(
                                  layout: recordLayout,
                                  view: _view,
                                  selectedDay: _selectedDay,
                                  records: recordsInScope,
                                  attentionRecordIds: {
                                    for (final item in attentionItems)
                                      item.sourceId,
                                  },
                                  showDailySummaries:
                                      _preferences.showDailySummaries,
                                  onOpenJob: _openJob,
                                  onAssignJob: _assignJob,
                                  onOpenJobs: () =>
                                      _openRecordWorkspace(WorkRecordKind.job),
                                  onOpenEstimate: _openEstimate,
                                  onOpenInvoice: _openInvoice,
                                  onOpenEstimates: () => _openRecordWorkspace(
                                    WorkRecordKind.estimate,
                                  ),
                                  onOpenInvoices: () => _openRecordWorkspace(
                                    WorkRecordKind.invoice,
                                  ),
                                  onCreateJob: _createJob,
                                  onCreateEstimate: () =>
                                      _handleAction(_WorkAction.createEstimate),
                                  onCreateInvoice: () =>
                                      _handleAction(_WorkAction.createInvoice),
                                ),
                              ],
                            ),
                            _WorkCalendarPanel(
                              maximumWidth: layout.laneWidth,
                              selectedDay: _selectedDay,
                              onDaySelected: _openWorkDay,
                              entryCountForDay: (day) => recordsInScope
                                  .where((record) => record.occursOn(day))
                                  .length,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _recordIsInScope(WorkRecord record) {
    if (!_preferences.includeCompletedWork &&
        record.status == WorkRecordStatus.completed) {
      return false;
    }
    if (_view == AppViewMode.technician) {
      final employee = dashboardEmployeeById(
        _selectedEmployeeId ?? demoEmployees.first.id,
      );
      return record.createdByEmployeeId == employee.id ||
          record.assignee == employee.name;
    }
    if (_selectedEmployeeId == null) return true;
    final employee = dashboardEmployeeById(_selectedEmployeeId!);
    return record.createdByEmployeeId == employee.id ||
        record.assignee == employee.name;
  }

  OperationalAttentionQuery _attentionQuery() => OperationalAttentionQuery(
    panelId: 'work-home',
    module: OperationalAttentionModule.work,
    view: _view,
    access: _view == AppViewMode.admin
        ? const OperationalAttentionAccess.adminDevelopment()
        : const OperationalAttentionAccess.technicianDevelopment(),
    selectedEmployeeId: _selectedEmployeeId,
    selectedDay: _selectedDay,
  );

  void _updateState(VoidCallback change) => setState(change);
}
