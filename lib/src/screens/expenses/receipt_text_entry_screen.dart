import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/receipts/receipt_text_editing_session.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../shared/editor_draft_status.dart';
import '../../shared/editor_input_lock.dart';
import '../../layout/app_layout_engine.dart';
import '../../theme/app_theme.dart';

class ReceiptTextInput {
  const ReceiptTextInput(this.text);

  /// Null means the user explicitly chose to enter structured details instead.
  final String? text;
}

class ReceiptTextEntryScreen extends StatefulWidget {
  const ReceiptTextEntryScreen({required this.editor, super.key});
  final ReceiptTextEditingSession editor;
  @override
  State<ReceiptTextEntryScreen> createState() => _ReceiptTextEntryState();
}

class _ReceiptTextEntryState extends State<ReceiptTextEntryScreen> {
  late final _text = TextEditingController(text: widget.editor.text);
  bool _leaving = false, _allowPop = false;

  @override
  void initState() {
    super.initState();
    widget.editor.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _leave([ReceiptTextInput? result]) async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      await widget.editor.flush();
      if (!mounted) return;
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, result);
    } on Object {
      if (mounted) setState(() => _leaving = false);
    }
  }

  Future<void> _discardUnsaved() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unsaved text?'),
        content: const Text(
          'Only changes that could not be saved will be discarded. The saved receipt will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard unsaved text'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _leaving = true);
    try {
      await widget.editor.discardUnsavedAndClose();
      if (!mounted) return;
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) setState(() => _leaving = false);
    }
  }

  @override
  void dispose() {
    widget.editor.removeListener(_refresh);
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(_leave());
    },
    child: EditorInputLock(
      locked: _leaving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Paste receipt text')),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final insets = AppLayoutEngine.pageInsetsFor(
                constraints.maxWidth,
              );
              final width = AppLayoutEngine.formWorkspaceWidthFor(
                constraints.maxWidth - insets.horizontal,
              );
              return SingleChildScrollView(
                padding: insets.copyWith(top: 12, bottom: 24),
                child: Center(
                  child: SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Paste the receipt text you copied from an email or another app. Nothing is read from your clipboard until you paste it.',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const ValueKey('receipt-pasted-text'),
                          controller: _text,
                          minLines: 8,
                          maxLines: 20,
                          maxLength: 100000,
                          decoration: const InputDecoration(
                            labelText: 'Receipt text',
                          ),
                          onChanged: widget.editor.updateText,
                        ),
                        const SizedBox(height: 16),
                        EditorDraftStatus(
                          state: widget.editor.state,
                          onRetry: widget.editor.retry,
                        ),
                        if (widget.editor.failure != null)
                          Text(widget.editor.failure!),
                        if (widget.editor.state == DraftSaveState.notSaved)
                          TextButton(
                            onPressed: _discardUnsaved,
                            child: const Text('Discard unsaved text'),
                          ),
                        FilledButton.icon(
                          key: const ValueKey('confirm-receipt-text'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _text.text.trim().isEmpty
                              ? null
                              : () => _leave(ReceiptTextInput(_text.text)),
                          icon: const Icon(Icons.check),
                          label: const Text('Use this text'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          key: const ValueKey('manual-receipt-entry'),
                          onPressed: () => _leave(const ReceiptTextInput(null)),
                          child: const Text('Enter amount and details instead'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
