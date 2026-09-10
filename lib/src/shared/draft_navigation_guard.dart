import 'dart:async';

import 'package:flutter/material.dart';

import '../data/storage/draft_autosave_session.dart';
import 'editor_input_lock.dart';

/// Shared native/visible Back policy for nested editors sharing one draft.
mixin DraftNavigationGuard<T extends StatefulWidget> on State<T> {
  DraftAutosaveSession? get navigationDraft;
  bool get blockDraftNavigation => false;
  bool _allowDraftPop = false;
  bool _leavingDraft = false;

  Widget guardDraftNavigation(Widget child) => PopScope(
    canPop:
        _allowDraftPop || (navigationDraft == null && !blockDraftNavigation),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !blockDraftNavigation) unawaited(leaveDraftRoute());
    },
    child: EditorInputLock(
      locked: _leavingDraft || blockDraftNavigation,
      child: child,
    ),
  );

  Future<void> leaveDraftRoute([Object? result]) async {
    if (_leavingDraft || blockDraftNavigation) return;
    setState(() => _leavingDraft = true);
    try {
      await navigationDraft?.flush();
      if (!mounted) return;
      await finishDraftRoute(result);
    } on Object {
      if (!mounted) return;
      setState(() => _leavingDraft = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your latest input has not been saved. Retry saving before leaving.',
          ),
        ),
      );
    }
  }

  /// Only after an explicit confirmation/discard has committed. Keep the
  /// caller's busy flag active until disposal so input cannot resurrect a
  /// consumed recovery draft between the commit and the route transition.
  Future<void> finishDraftRoute([Object? result]) async {
    setState(() => _allowDraftPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(result);
  }
}
