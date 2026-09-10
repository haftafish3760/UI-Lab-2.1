part of 'estimate_site_photos_screen.dart';

extension _EstimatePhotoMedia on _EstimateSitePhotosScreenState {
  Future<void> _loadPendingMedia() async {
    final workflow = widget.mediaWorkflow;
    if (workflow == null) return;
    try {
      final selection = await workflow.pendingSelection();
      if (!mounted) return;
      _refreshMedia(() => _pendingMedia = selection);
    } catch (error) {
      if (mounted) _showPickerError(error);
    }
  }

  Future<bool> _pickNativeMedia(MediaPickerSource source) async {
    final workflow = widget.mediaWorkflow;
    if (workflow == null) return false;
    if (_mediaLocked) return true;
    _refreshMedia(() => _importing = true);
    try {
      _publishPhotos();
      final editor = await workflow.pick(source);
      if (editor != null) _acceptMediaEditor(editor);
    } catch (error) {
      if (mounted) _showPickerError(error);
    } finally {
      if (mounted) {
        await _loadPendingMedia();
        _refreshMedia(() => _importing = false);
      }
    }
    return true;
  }

  void _acceptMediaEditor(EstimatePhotosDraftInput editor) {
    if (!mounted) return;
    _refreshMedia(() {
      _photos
        ..clear()
        ..addAll(editor.photos);
      _pendingNotes = Map.of(editor.pendingNotes);
      _pendingMedia = null;
    });
    // Keep the parent widget synchronized with the now-committed raw input.
    // The ordinary autosave sees identical input and does not create a revision.
    widget.onDraftChanged?.call(editor);
  }

  Future<void> _recoverNativeMedia() async {
    final workflow = widget.mediaWorkflow;
    if (workflow == null || _importing) return;
    _refreshMedia(() => _importing = true);
    try {
      final editor = await workflow.recover();
      if (editor != null) _acceptMediaEditor(editor);
    } catch (error) {
      if (mounted) _showPickerError(error);
    } finally {
      if (mounted) {
        await _loadPendingMedia();
        _refreshMedia(() => _importing = false);
      }
    }
  }

  Widget _pendingMediaNotice() => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _pendingMedia?.source == MediaPickerSource.files
              ? 'Unfinished file selection'
              : 'Unfinished photo selection',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const Text(
          'Recover the selection, or discard it to continue editing. Your estimate input is saved.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              key: const ValueKey('recover-estimate-photos'),
              onPressed: _importing ? null : _recoverNativeMedia,
              child: Text(
                _pendingMedia?.requiresFileReselection == true
                    ? 'Choose file again'
                    : 'Recover photos',
              ),
            ),
            TextButton(
              key: const ValueKey('discard-estimate-photo-selection'),
              onPressed: _importing
                  ? null
                  : () async {
                      final workflow = widget.mediaWorkflow;
                      final request = _pendingMedia;
                      if (workflow == null || request == null) return;
                      final discard = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Discard this selection?'),
                          content: const Text(
                            'Your estimate input and existing photos will remain. The pending photos will not be attached.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Keep selection'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Discard selection'),
                            ),
                          ],
                        ),
                      );
                      if (discard != true || !mounted) return;
                      _refreshMedia(() => _importing = true);
                      try {
                        await workflow.discard(request);
                      } catch (error) {
                        if (mounted) _showPickerError(error);
                      } finally {
                        if (mounted) {
                          await _loadPendingMedia();
                          _refreshMedia(() => _importing = false);
                        }
                      }
                    },
              child: Text(
                _pendingMedia?.source == MediaPickerSource.files
                    ? 'Discard file selection'
                    : 'Discard photo selection',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
