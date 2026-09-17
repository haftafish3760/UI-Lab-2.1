part of 'receipt_intake_screen.dart';

extension _ReceiptIntakeMedia on _ReceiptIntakeScreenState {
  Future<void> _openPastedText() async {
    if (_openingPicker ||
        _savingDraft ||
        !widget.permissions.canAttachReceipt) {
      return;
    }
    final submission = ReceiptSubmissionScope.maybeOf(context);
    if (submission == null) {
      _showDraftMessage(
        'Local receipt storage is unavailable. Reopen the app before editing.',
      );
      return;
    }
    if (!await _persistDraft() || !mounted) return;
    final id = _activeDraftId;
    if (id == null) return;
    _updateMedia(() => _openingPicker = true);
    try {
      final editor = submission.openTextEditing(id);
      ReceiptTextInput? result;
      try {
        result = await Navigator.of(context).push<ReceiptTextInput>(
          MaterialPageRoute(
            builder: (_) => ReceiptTextEntryScreen(editor: editor),
          ),
        );
      } finally {
        await editor.close();
      }
      if (!mounted) return;
      // Back also saves input. Refresh the parent revision before any later save
      // so its older snapshot cannot overwrite text or trigger a false conflict.
      final saved = submission.receipts.recordById(id);
      if (saved != null) {
        _acceptMediaReceipt(saved);
        _updateMedia(() => _pastedText = saved.entrySetup?.pastedText ?? '');
      }
      if (result != null && result.text == null) {
        await _openReceiptEditor(imageCount: _evidence.length);
      }
    } on Object {
      _showDraftMessage(
        'Receipt text could not be saved or reopened. Your saved receipt is retained.',
      );
    } finally {
      _updateMedia(() => _openingPicker = false);
    }
  }

  Future<void> _pick(
    Future<List<ReceiptEvidenceSelection>> Function() choose,
  ) async {
    if (_openingPicker) return;
    _updateMedia(() => _openingPicker = true);
    try {
      if (!await _persistDraft() || !mounted) return;
      final selected = await choose();
      if (!mounted || selected.isEmpty) return;
      _updateMedia(() {
        for (final item in selected) {
          if (_evidence.every((current) => current.path != item.path)) {
            _evidence.add(item);
          }
        }
      });
      await _persistDraft();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ReceiptSourcePicker.friendlyError(error))),
      );
    } finally {
      if (mounted) _updateMedia(() => _openingPicker = false);
    }
  }

  bool _hasPendingMedia(ReceiptMediaSession? media) =>
      media?.pending?.destination == MediaPickerDestination.receipt &&
      media?.pending?.targetId == (_activeDraftId ?? widget.draftId);

  Future<void> _pickMedia(MediaPickerSource source) async {
    final media = ReceiptSubmissionScope.maybeOf(context)?.media;
    if (media == null) {
      await _pick(switch (source) {
        MediaPickerSource.camera => _picker.capturePhoto,
        MediaPickerSource.library => _picker.choosePhotos,
        MediaPickerSource.files => _picker.chooseFiles,
      });
      return;
    }
    if (_openingPicker) return;
    // The external activity always has a durably saved destination first.
    if (!await _persistDraft() || !mounted) return;
    final id = _activeDraftId;
    final revision = _evidenceBaseRevision;
    if (id == null || revision == null) return;
    _updateMedia(() => _openingPicker = true);
    try {
      final stored = await media.pick(
        receiptId: id,
        revision: revision,
        source: source,
      );
      if (stored != null) _acceptMediaReceipt(stored);
    } catch (_) {
      _showDraftMessage(
        media.failure ?? 'The photo selection could not be saved.',
      );
    } finally {
      if (mounted) _updateMedia(() => _openingPicker = false);
    }
  }

  void _acceptMediaReceipt(draft_data.StoredReceiptDraft receipt) {
    if (!mounted) return;
    _updateMedia(() {
      _activeDraftId = receipt.draftId;
      _evidenceBaseRevision = receipt.lifecycle.revision;
      _draftFailure = null;
      _evidence
        ..clear()
        ..addAll(receipt.activeEvidence.map(_selectionFromStored));
    });
  }

  Widget _mediaRecoveryNotice(ReceiptMediaSession media) {
    if (!_hasPendingMedia(media)) {
      return const SizedBox.shrink();
    }
    final request = media.pending!;
    final isFile = request.source == MediaPickerSource.files;
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isFile ? 'Unfinished file selection' : 'Unfinished photo selection',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            media.failure ??
                (isFile && request.returnedFiles == null
                    ? 'Your receipt is saved. Choose the file again to finish the interrupted selection.'
                    : 'Your receipt is saved. Recover the selection, or discard it to continue editing.'),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const ValueKey('recover-receipt-photos'),
                onPressed: media.busy
                    ? null
                    : () async {
                        try {
                          final receipt = await media.retry(request.targetId);
                          if (receipt != null) {
                            _acceptMediaReceipt(receipt);
                          } else if (media.pending != null) {
                            _showDraftMessage(
                              'No selected files have returned yet. Your receipt and pending selection are still saved.',
                            );
                          }
                        } catch (_) {
                          _showDraftMessage(
                            media.failure ?? 'Photo recovery is unavailable.',
                          );
                        }
                      },
                child: Text(
                  isFile
                      ? (request.returnedFiles == null
                            ? 'Choose file again'
                            : 'Recover files')
                      : 'Recover photos',
                ),
              ),
              TextButton(
                key: const ValueKey('discard-receipt-photo-selection'),
                onPressed: media.busy
                    ? null
                    : () async {
                        final discard = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Discard this selection?'),
                            content: const Text(
                              'Your saved receipt and its existing evidence will remain. The pending selection will not be attached.',
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
                        if (discard != true) return;
                        try {
                          await media.discardSelection(request);
                          if (mounted) _updateMedia(() => _draftFailure = null);
                        } catch (_) {
                          _showDraftMessage(
                            'The selection was not discarded. Retry when local storage is available.',
                          );
                        }
                      },
                child: Text(
                  isFile ? 'Discard file selection' : 'Discard photo selection',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
