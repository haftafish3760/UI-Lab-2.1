import 'package:flutter/material.dart';

import '../data/storage/draft_autosave_session.dart';
import 'editor_draft_status.dart';

class NestedEditorDraftStatus extends StatelessWidget {
  const NestedEditorDraftStatus({required this.session, super.key});
  final DraftAutosaveSession session;

  @override
  Widget build(BuildContext context) => StreamBuilder<DraftSaveState>(
    stream: session.changes,
    initialData: session.state,
    builder: (context, snapshot) => EditorDraftStatus(
      state: snapshot.data ?? session.state,
      onRetry: session.retry,
    ),
  );
}
