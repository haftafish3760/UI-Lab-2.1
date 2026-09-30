part of 'estimate_editor_screen.dart';

extension _EstimateExit on _EstimateEditorScreenState {
  Future<void> _leaveEstimate(Object? result) async {
    if (blockDraftNavigation || _exitPromptOpen) return;
    _exitPromptOpen = true;
    try {
      await _inlineApproval.currentState?.flushInput();
      if (!mounted) return;
      if (_approving) {
        _refresh(() => _approving = false);
        return;
      }
      if (confirmDraftExit) {
        final choice = await showDialog<String>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: const Text('Save changes to this estimate?'),
            content: const Text(
              'Save your changes, discard them, or keep editing.',
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
              FilledButton(
                onPressed: () => Navigator.pop(dialog, 'save'),
                child: const Text('Save changes'),
              ),
            ],
          ),
        );
        if (!mounted || choice == null || choice == 'edit') return;
        if (choice == 'save') {
          await _confirmEstimate();
          return;
        }
        _refresh(() => _saving = true);
        await _draft?.discard();
      } else {
        await _draft?.flush();
      }
      if (mounted) await finishDraftRoute(result ?? _baseRecord);
    } catch (_) {
      if (mounted) {
        _refresh(() => _saving = false);
        _message(
          'Your changes could not be saved. Please retry before leaving.',
        );
      }
    } finally {
      _exitPromptOpen = false;
    }
  }
}
