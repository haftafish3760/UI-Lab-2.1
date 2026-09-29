import 'package:flutter/material.dart';

import '../data/storage/draft_autosave_session.dart';
import 'editor_draft_status.dart';

class NestedEditorDraftStatus extends StatelessWidget {
  const NestedEditorDraftStatus({
    required this.session,
    this.showRoutineStatus = true,
    super.key,
  });
  final DraftAutosaveSession session;
  final bool showRoutineStatus;

  @override
  Widget build(BuildContext context) => StreamBuilder<DraftSaveState>(
    stream: session.changes,
    initialData: session.state,
    builder: (context, snapshot) => EditorDraftStatus(
      showRoutineStatus: showRoutineStatus,
      state: snapshot.data ?? session.state,
      onRetry: session.retry,
    ),
  );
}
