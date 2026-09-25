part of 'estimate_workspace_screen.dart';

extension _EstimateWorkspaceActions on _EstimateWorkspaceScreenState {
  void _openAttentionItem(OperationalAttentionItem item) {
    final matches = _scopedEstimates.where(
      (record) => record.id == item.sourceId,
    );
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This estimate is no longer available.')),
      );
      return;
    }
    _openEstimate(matches.first);
  }

  void _openAttentionList(List<OperationalAttentionItem> items) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkAttentionListScreen(
          selectedDay: _selectedDay,
          items: items,
          onOpen: _openAttentionItem,
          workspaceLabel: 'Estimate attention',
          screenKey: const ValueKey('estimate-attention-list'),
          rowKeyPrefix: 'estimate-attention-list',
          onSettings: _openSettings,
        ),
      ),
    );
  }

  Future<void> _planJob(WorkRecord estimate) async {
    if (!widget.permissions.canConvertToJob) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You do not have permission to create a job from an estimate.',
          ),
        ),
      );
      return;
    }
    if (!estimate.hasCurrentCustomerApproval ||
        estimate.resolvedEstimateStage != EstimateStage.approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The current estimate must be approved before creating a job.',
          ),
        ),
      );
      return;
    }
    final job = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => WorkJobEditor(
          sourceEstimate: estimate,
          initialDay: estimate.estimateDates?.proposedServiceOn ?? _selectedDay,
        ),
      ),
    );
    if (!mounted || job == null) return;
    if (_store.workSession == null) {
      _store.addWorkRecord(job);
      _store.updateWorkRecord(
        estimate.withEstimateStage(EstimateStage.converted, DateTime.now()),
      );
    }
    _refresh(() {});
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context)
        .push<WorkRecordDisplayPreferences>(
          MaterialPageRoute(
            builder: (_) => WorkRecordSettingsScreen(
              workspaceId: 'estimates',
              workspaceLabel: 'Estimates',
              initial: _preferences,
            ),
          ),
        );
    if (mounted && updated != null) {
      _refresh(() => _fixturePreferences = updated);
    }
  }
}
