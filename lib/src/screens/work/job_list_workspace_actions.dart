part of 'job_list_workspace_screen.dart';

extension _JobListWorkspaceActions on _JobListWorkspaceScreenState {
  Future<void> _createJob() async {
    final job = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => WorkJobEditor(initialDay: _selectedDay),
      ),
    );
    if (mounted && job != null) _store.addWorkRecord(job);
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context)
        .push<WorkRecordDisplayPreferences>(
          MaterialPageRoute(
            builder: (_) => WorkRecordSettingsScreen(
              workspaceId: 'jobs',
              workspaceLabel: 'Jobs',
              initial: _preferences,
            ),
          ),
        );
    if (mounted && updated != null) {
      _refresh(() => _fixturePreferences = updated);
    }
  }

  Future<void> _openJob(WorkRecord record) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => JobWorkspaceScreen(
          workRecord: record,
          onWorkRecordUpdated: _store.updateWorkRecord,
          permissions: widget.permissions,
        ),
      ),
    );
  }

  Future<void> _openAttentionItem(OperationalAttentionItem item) async {
    final matches = _scopedJobs.where((record) => record.id == item.sourceId);
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This job is no longer available.')),
      );
      return;
    }
    await _openJob(matches.first);
  }

  void _openAttentionList(List<OperationalAttentionItem> items) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkAttentionListScreen(
          selectedDay: _selectedDay,
          items: items,
          onOpen: _openAttentionItem,
          workspaceLabel: 'Job attention',
          screenKey: const ValueKey('job-attention-list'),
          rowKeyPrefix: 'job-attention-list',
          onSettings: _openSettings,
        ),
      ),
    );
  }
}
