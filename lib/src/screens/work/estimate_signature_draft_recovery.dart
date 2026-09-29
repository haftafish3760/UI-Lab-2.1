// ignore_for_file: invalid_use_of_protected_member

part of 'estimate_signature_screen.dart';

extension _SignatureRecovery on EstimateSignatureScreenState {
  SignatureInk get _ink => SignatureInk(
    _strokes.map((stroke) => stroke.map((point) => (point.dx, point.dy))),
    strokeWidth: _strokeWidth,
  );

  Future<void> _openSignatureDraft() async {
    try {
      _work = PrototypeOperationsScope.maybeOf(context)?.workSession;
      final work = _work;
      if (work == null && widget.recoveredWorkflow != null) {
        throw StateError('Recovered input requires its Work session.');
      }
      if (work != null) {
        final workflow =
            widget.recoveredWorkflow ??
            await work.openEstimateSignatureDraft(
              widget.record.id,
              forBusiness: widget.forBusiness,
            );
        if (widget.recoveredWorkflow != null) {
          work.validateEstimateSignatureHandoff(workflow, widget.record.id);
        }
        if (!mounted) {
          await workflow.session.close();
          return;
        }
        _workflow = workflow;
        _base = workflow.input.base;
        if (widget.embedded && _base.revision != widget.record.revision) {
          throw StateError(
            'The document changed. Reopen its approval before signing.',
          );
        }
        _name.text = workflow.input.name;
        _accepted = workflow.input.accepted;
        _strokeWidth =
            workflow.input.ink.strokeWidth ??
            (workflow.input.ink.hasInk ? 1.25 : 3);
        _strokes.addAll(
          workflow.input.ink.strokes.map(
            (stroke) =>
                stroke.map((point) => Offset(point.$1, point.$2)).toList(),
          ),
        );
        _subscription = workflow.session.changes.listen((_) {
          if (mounted) {
            setState(() {});
            widget.onStateChanged?.call();
          }
        });
      } else {
        _previewInput = EstimateSignatureInput(
          base: _base,
          forBusiness: widget.forBusiness,
          baseRevision: 0,
          name: _name.text,
          ink: _ink,
        );
      }
      if (!mounted) return;
      _name.addListener(_nameChanged);
      setState(() => _ready = true);
      widget.onStateChanged?.call();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        setState(
          () => _error =
              'Saved signature could not be opened. Its input has been preserved.',
        );
      }
    }
  }

  void _nameChanged() {
    if (!_ready || _saving) return;
    _workflow?.updateName(_name.text);
    _previewInput = _previewInput?.withName(_name.text);
    setState(() => _accepted = false);
  }

  void _changeAcceptance(bool accepted) {
    if (!_ready || _saving) return;
    _workflow?.setAccepted(accepted);
    _previewInput = _previewInput?.withAcceptance(accepted);
    setState(() => _accepted = accepted);
  }

  void _clearSignature() {
    if (!_ready || _saving) return;
    setState(() {
      _strokes.clear();
      _accepted = false;
    });
    _captureSignature();
  }

  void _addInk(Offset position, {bool newStroke = false}) {
    if (!_ready || _saving) return;
    final box = _padKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || box.size.isEmpty) return;
    final point = Offset(
      (position.dx / box.size.width).clamp(0, 1),
      (position.dy / box.size.height).clamp(0, 1),
    );
    setState(() {
      _accepted = false;
      if (newStroke || _strokes.isEmpty) _strokes.add([]);
      _strokes.last.add(point);
    });
    _captureSignature();
  }

  void _captureSignature() {
    if (!_ready || _saving) return;
    _workflow?.updateInk(_ink);
    _previewInput = _previewInput?.withInk(_ink);
  }

  Future<void> _save() async {
    if (!widget.approvalEnabled ||
        !_ready ||
        _saving ||
        !_accepted ||
        !_ink.hasInk) {
      return;
    }
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter the customer name.');
      return;
    }
    setState(() => _saving = true);
    widget.onStateChanged?.call();
    try {
      final workflow = _workflow;
      final WorkRecord? record;
      if (workflow != null) {
        record = await workflow.confirm();
      } else {
        _previewInput = _previewInput!.prepare();
        record = _previewInput!.confirmedRecord();
      }
      if (record == null) {
        throw StateError(_work!.failureMessage ?? 'Approval was not saved.');
      }
      if (mounted) {
        if (widget.onSaved != null) {
          await widget.onSaved!(record);
        } else {
          await finishDraftRoute(record);
        }
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is StateError
              ? error.message.toString()
              : 'Approval was not saved. Signature input is retained; retry saving.';
        });
        widget.onStateChanged?.call();
      }
    }
  }

  Future<void> _discardSignature() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished signature?'),
        content: const Text(
          'The saved document and any previous approval stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard input'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    setState(() => _saving = true);
    widget.onStateChanged?.call();
    try {
      await _draft?.discard();
      if (mounted) {
        if (widget.onDiscarded != null) {
          widget.onDiscarded!();
        } else {
          await finishDraftRoute();
        }
      }
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Signature could not be discarded. It has been preserved.';
        });
        widget.onStateChanged?.call();
      }
    }
  }
}
