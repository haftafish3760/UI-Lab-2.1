import 'dart:async';

import 'package:flutter/material.dart';

import '../data/storage/draft_autosave_session.dart';
import 'editor_input_lock.dart';

/// Shared native/visible Back policy for nested editors sharing one draft.
mixin DraftNavigationGuard<T extends StatefulWidget> on State<T> {
  DraftAutosaveSession? get navigationDraft;
  bool get blockDraftNavigation => false;
  bool get allowCleanDraftPop => false;
  bool get confirmDraftExit => false;
  bool get requiresDraftPopGuard => navigationDraft != null;
  bool _allowDraftPop = false;
  bool _leavingDraft = false;

  double? _edgeDragDistance;

  Widget guardDraftNavigation(Widget child) {
    final canPop =
        _allowDraftPop ||
        (!blockDraftNavigation &&
            (allowCleanDraftPop || !requiresDraftPopGuard));
    Widget content = EditorInputLock(
      locked: _leavingDraft || blockDraftNavigation,
      child: child,
    );
    // Flutter's iOS route swipe is disabled when PopScope protects unsaved
    // input. Route a leading-edge swipe through the same save/discard policy.
    // Clean routes retain Flutter's native interactive transition.
    if (!canPop &&
        !blockDraftNavigation &&
        Theme.of(context).platform == TargetPlatform.iOS) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final guardedContent = content;
      content = LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (details) {
            final fromEdge = rtl
                ? constraints.maxWidth - details.localPosition.dx
                : details.localPosition.dx;
            _edgeDragDistance = fromEdge <= 28 ? 0 : null;
          },
          onHorizontalDragUpdate: (details) {
            if (_edgeDragDistance != null) {
              _edgeDragDistance =
                  _edgeDragDistance! +
                  (rtl ? -details.delta.dx : details.delta.dx);
            }
          },
          onHorizontalDragCancel: () => _edgeDragDistance = null,
          onHorizontalDragEnd: (_) {
            final shouldLeave = (_edgeDragDistance ?? 0) >= 56;
            _edgeDragDistance = null;
            if (shouldLeave) unawaited(leaveDraftRoute());
          },
          child: guardedContent,
        ),
      );
    }
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !blockDraftNavigation) unawaited(leaveDraftRoute());
      },
      child: content,
    );
  }

  Future<void> leaveDraftRoute([Object? result]) async {
    if (_leavingDraft || blockDraftNavigation) return;
    setState(() => _leavingDraft = true);
    try {
      if (confirmDraftExit) {
        final choice = await showDialog<String>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: const Text('Keep your changes?'),
            content: const Text(
              'Save a draft to finish later, or discard these changes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, 'edit'),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialog, 'discard'),
                child: const Text('Discard changes'),
              ),
              if (navigationDraft != null)
                FilledButton(
                  onPressed: () => Navigator.pop(dialog, 'save'),
                  child: const Text('Save draft'),
                ),
            ],
          ),
        );
        if (!mounted) return;
        if (choice == null || choice == 'edit') {
          setState(() => _leavingDraft = false);
          return;
        }
        if (choice == 'discard') {
          await navigationDraft?.discard();
          if (mounted) await finishDraftRoute(result);
          return;
        }
      }
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
