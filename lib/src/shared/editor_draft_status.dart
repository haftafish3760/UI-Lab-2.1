import 'package:flutter/material.dart';

import '../data/storage/draft_autosave_session.dart';

/// Shared, plain-language local acknowledgment. Never implies cloud backup.
class EditorDraftStatus extends StatelessWidget {
  const EditorDraftStatus({
    required this.state,
    required this.onRetry,
    this.onDiscard,
    super.key,
  });
  final DraftSaveState state;
  final VoidCallback onRetry;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(switch (state) {
          DraftSaveState.unchanged => 'Your input will save on this device.',
          DraftSaveState.saving => 'Saving on this device…',
          DraftSaveState.savedLocally => 'Draft saved on this device',
          DraftSaveState.notSaved => 'Latest changes have not been saved.',
          DraftSaveState.discarded => 'Unfinished input discarded',
        }),
        if (state == DraftSaveState.notSaved)
          TextButton(onPressed: onRetry, child: const Text('Retry save')),
        if (onDiscard != null)
          TextButton(
            onPressed: onDiscard,
            child: const Text('Discard unfinished input'),
          ),
      ],
    ),
  );
}
