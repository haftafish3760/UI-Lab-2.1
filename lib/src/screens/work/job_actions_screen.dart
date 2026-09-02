part of 'job_workspace_screen.dart';

enum _JobAction {
  addMaterials,
  linkExpense,
  addReceipt,
  addPhoto,
  editNotes,
  startTravel,
  markArrived,
  startWork,
  pauseWork,
  resumeWork,
  needsReturnVisit,
  completeJob,
  reschedule,
  reassign,
}

class _JobActionsScreen extends StatelessWidget {
  const _JobActionsScreen({
    required this.job,
    required this.selectedDay,
    required this.permissions,
  });

  final ActiveJobRecord job;
  final DateTime selectedDay;
  final JobWorkspacePermissions permissions;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    final recordActions = <_JobAction>[
      if (permissions.canAddMaterials) _JobAction.addMaterials,
      if (permissions.canLinkExpenses) _JobAction.linkExpense,
      if (permissions.canAttachReceipts) ...[
        _JobAction.addReceipt,
        _JobAction.addPhoto,
      ],
      if (permissions.canEditJob) _JobAction.editNotes,
    ];
    final operationActions = <_JobAction>[
      if (permissions.canChangeStatus) ..._statusActions(job.status),
      if (permissions.canChangeStatus) _JobAction.reschedule,
      if (permissions.canEditJob) _JobAction.reassign,
    ];
    return Scaffold(
      key: const ValueKey('job-actions-screen'),
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
                    width: layout.columnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkScopeHeader(
                          view: scope.view,
                          selectedDay: selectedDay,
                          selectedEmployeeId: scope.selectedEmployeeId,
                          workspaceLabel: 'Job actions',
                          showBackButton: true,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.pop(context),
                          onViewChanged: scope.setView,
                          onEmployeeChanged: scope.selectEmployee,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          job.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _JobActionGroups(
                          layout: layout,
                          operationActions: operationActions,
                          recordActions: recordActions,
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

  static List<_JobAction> _statusActions(JobStatus status) => switch (status) {
    JobStatus.scheduled => const [
      _JobAction.startTravel,
      _JobAction.markArrived,
    ],
    JobStatus.enRoute => const [_JobAction.markArrived],
    JobStatus.arrived => const [_JobAction.startWork],
    JobStatus.inProgress => const [
      _JobAction.pauseWork,
      _JobAction.needsReturnVisit,
      _JobAction.completeJob,
    ],
    JobStatus.paused => const [
      _JobAction.resumeWork,
      _JobAction.needsReturnVisit,
      _JobAction.completeJob,
    ],
    JobStatus.needsReturnVisit => const [],
    JobStatus.completed => const [],
  };
}

class _JobActionGroups extends StatelessWidget {
  const _JobActionGroups({
    required this.layout,
    required this.operationActions,
    required this.recordActions,
  });

  final DetailWorkspaceLayout layout;
  final List<_JobAction> operationActions;
  final List<_JobAction> recordActions;

  @override
  Widget build(BuildContext context) {
    final groups = <Widget>[
      if (operationActions.isNotEmpty)
        _JobActionGroup(
          title: 'Status and schedule',
          icon: Icons.task_alt_outlined,
          actions: operationActions,
        ),
      if (recordActions.isNotEmpty)
        _JobActionGroup(
          title: 'Job records',
          icon: Icons.playlist_add_check_circle_outlined,
          actions: recordActions,
        ),
    ];
    if (layout.columns == 1 || groups.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < groups.length; index++) ...[
            groups[index],
            if (index != groups.length - 1) SizedBox(height: layout.gap),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < groups.length; index++) ...[
          SizedBox(width: layout.columnWidth, child: groups[index]),
          if (index != groups.length - 1) SizedBox(width: layout.gap),
        ],
      ],
    );
  }
}

class _JobActionGroup extends StatelessWidget {
  const _JobActionGroup({
    required this.title,
    required this.icon,
    required this.actions,
  });

  final String title;
  final IconData icon;
  final List<_JobAction> actions;

  @override
  Widget build(BuildContext context) => _WorkspaceSection(
    title: title,
    icon: icon,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final grid = AppLayoutEngine.workShortcutsFor(
          constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
        );
        return Wrap(
          spacing: grid.gap,
          runSpacing: grid.gap,
          children: [
            for (final action in actions)
              SizedBox(
                width: grid.tileWidth,
                child: _JobActionTile(
                  action: action,
                  iconExtent: grid.iconExtent,
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _JobActionTile extends StatelessWidget {
  const _JobActionTile({required this.action, required this.iconExtent});

  final _JobAction action;
  final double iconExtent;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final (accent, surface) = action.colors(semantic);
    return Semantics(
      button: true,
      label: '${action.label}. ${action.detail}',
      child: InkWell(
        key: ValueKey('job-action-${action.name}'),
        onTap: () => Navigator.pop(context, action),
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconExtent,
                height: iconExtent,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  border: Border.all(color: accent, width: 1.2),
                ),
                child: Icon(action.icon, color: accent, size: 28),
              ),
              const SizedBox(height: 5),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on _JobAction {
  JobStatus? get targetStatus => switch (this) {
    _JobAction.startTravel => JobStatus.enRoute,
    _JobAction.markArrived => JobStatus.arrived,
    _JobAction.startWork || _JobAction.resumeWork => JobStatus.inProgress,
    _JobAction.pauseWork => JobStatus.paused,
    _JobAction.needsReturnVisit => JobStatus.needsReturnVisit,
    _JobAction.completeJob => JobStatus.completed,
    _ => null,
  };

  String get label => switch (this) {
    _JobAction.addMaterials => 'Add materials',
    _JobAction.linkExpense => 'Link existing expense',
    _JobAction.addReceipt => 'Add receipt photo',
    _JobAction.addPhoto => 'Add job photo',
    _JobAction.editNotes => 'Edit job notes',
    _JobAction.startTravel => 'Start travel',
    _JobAction.markArrived => 'Mark arrived',
    _JobAction.startWork => 'Start work',
    _JobAction.pauseWork => 'Pause work',
    _JobAction.resumeWork => 'Resume work',
    _JobAction.needsReturnVisit => 'Needs return visit',
    _JobAction.completeJob => 'Complete job',
    _JobAction.reschedule => 'Reschedule job',
    _JobAction.reassign => 'Reassign job',
  };

  String get detail => switch (this) {
    _JobAction.addMaterials =>
      'Use truck stock, a recorded purchase, or a manual material',
    _JobAction.linkExpense => 'Choose a business expense already recorded',
    _JobAction.addReceipt => 'Capture or choose receipt evidence',
    _JobAction.addPhoto => 'Document conditions or completed work',
    _JobAction.editNotes => 'Update internal notes for this job',
    _JobAction.startTravel => 'Record travel to this job',
    _JobAction.markArrived => 'Record that the technician reached the site',
    _JobAction.startWork => 'Begin active work on this job',
    _JobAction.pauseWork => 'Pause without marking the job complete',
    _JobAction.resumeWork => 'Continue work after a pause',
    _JobAction.needsReturnVisit =>
      'Stop this visit without marking the job complete',
    _JobAction.completeJob => 'Finish the job and preserve its records',
    _JobAction.reschedule => 'Choose a new date and arrival time',
    _JobAction.reassign => 'Change the technician or vehicle',
  };

  IconData get icon => switch (this) {
    _JobAction.addMaterials => Icons.inventory_2_outlined,
    _JobAction.linkExpense => Icons.receipt_long_outlined,
    _JobAction.addReceipt => Icons.document_scanner_outlined,
    _JobAction.addPhoto => Icons.add_a_photo_outlined,
    _JobAction.editNotes => Icons.edit_note_outlined,
    _JobAction.startTravel => Icons.route_outlined,
    _JobAction.markArrived => Icons.location_on_outlined,
    _JobAction.startWork => Icons.play_arrow_rounded,
    _JobAction.pauseWork => Icons.pause_rounded,
    _JobAction.resumeWork => Icons.play_circle_outline,
    _JobAction.needsReturnVisit => Icons.event_busy_outlined,
    _JobAction.completeJob => Icons.check_circle_outline,
    _JobAction.reschedule => Icons.event_repeat_outlined,
    _JobAction.reassign => Icons.person_add_alt_1_outlined,
  };

  (Color, Color) colors(AppSemanticColors semantic) => switch (this) {
    _JobAction.startTravel ||
    _JobAction.markArrived ||
    _JobAction.startWork ||
    _JobAction.resumeWork => (semantic.current, semantic.currentSurface),
    _JobAction.completeJob => (semantic.success, semantic.successSurface),
    _JobAction.pauseWork ||
    _JobAction.needsReturnVisit ||
    _JobAction.reschedule => (semantic.attention, semantic.attentionSurface),
    _JobAction.addReceipt ||
    _JobAction.addPhoto => (semantic.planned, semantic.plannedSurface),
    _ => (semantic.current, semantic.currentSurface),
  };
}
