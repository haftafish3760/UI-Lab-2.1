import 'package:flutter/material.dart';

import '../../data/receipts/receipt_photo_reader.dart';
import '../../data/receipts/receipt_field_proposals.dart';
import '../../data/receipts/receipt_item_parser.dart';
import '../../data/receipts/receipt_item_proposal.dart';
import 'receipt_parsed_items.dart';
import '../../data/receipts/receipt_item_read.dart';
import '../../data/device_capabilities/device_workload_service.dart';
import '../../shared/local_document_path_scope.dart';
import '../../shared/localized_date.dart';

/// Explicit per-photo consent. Source changes invalidate unfinished results.
class ReceiptPhotoTextPanel extends StatefulWidget {
  const ReceiptPhotoTextPanel({
    required this.path,
    this.reader,
    this.onUseDetails,
    this.autoRead = false,
    this.sourceId,
    this.onItemsRead,
    this.onReadingChanged,
    this.initialRead,
    super.key,
  });
  final String path;
  final ReceiptPhotoReader? reader;
  final ValueChanged<ReceiptFieldProposals>? onUseDetails;
  final bool autoRead;
  final String? sourceId;
  final void Function(ReceiptPhotoText, ReceiptItemParseResult)? onItemsRead;
  final ValueChanged<bool>? onReadingChanged;
  final ReceiptItemRead? initialRead;

  @override
  State<ReceiptPhotoTextPanel> createState() => _ReceiptPhotoTextPanelState();
}

class _ReceiptPhotoTextPanelState extends State<ReceiptPhotoTextPanel> {
  ReceiptPhotoReader get _reader => widget.reader ?? NativeReceiptPhotoReader();
  ReceiptPhotoText? _result;
  ReceiptItemParseResult? _items;
  String? _failure;
  bool _busy = false;
  int _generation = 0;
  bool _automaticRequested = false;

  @override
  void initState() {
    super.initState();
    _restoreRead();
  }

  void _restoreRead() {
    final saved = widget.initialRead;
    if (saved == null || saved.evidenceId != widget.sourceId) return;
    _result = ReceiptPhotoText(
      text: saved.recognizedText,
      lines: saved.sourceLines,
      warnings: saved.warnings,
    );
    _items = saved.result;
    _automaticRequested = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleAutomaticRead();
  }

  void _scheduleAutomaticRead() {
    if (_automaticRequested || !widget.autoRead || !_reader.supported) return;
    _automaticRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.autoRead && _result == null) _read();
    });
  }

  @override
  void didUpdateWidget(covariant ReceiptPhotoTextPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.reader != widget.reader ||
        oldWidget.sourceId != widget.sourceId) {
      if (_busy) {
        final notify = oldWidget.onReadingChanged;
        Future.microtask(() => notify?.call(false));
      }
      _generation++;
      _result = null;
      _items = null;
      _failure = null;
      _busy = false;
      _automaticRequested = false;
      _restoreRead();
    }
    _scheduleAutomaticRead();
  }

  Future<void> _read() async {
    if (_busy || !_reader.supported) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _failure = null;
    });
    widget.onReadingChanged?.call(true);
    try {
      final path = LocalDocumentPathScope.resolvePath(context, widget.path);
      final result = await _reader.read(path);
      if (!mounted || generation != _generation) return;
      final items = proposeReceiptItems(
        result,
        sourceId: widget.sourceId ?? widget.path,
      );
      setState(() {
        _result = result;
        _items = items;
      });
      widget.onItemsRead?.call(result, items);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(
        () => _failure = error is DeviceWorkloadUnavailable
            ? error.message
            : 'This photo could not be read. Try again, replace the photo, or enter the expense yourself.',
      );
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _busy = false);
        widget.onReadingChanged?.call(false);
      }
    }
  }

  @override
  void dispose() {
    if (_busy) {
      final notify = widget.onReadingChanged;
      Future.microtask(() => notify?.call(false));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(height: 24),
      Text('Read this photo', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (!_reader.supported)
        const Text(
          'Photo reading is available in the Android and iPhone app. You can enter the expense manually on this device.',
        )
      else ...[
        const Text(
          'Optional. Read text on this device so you can check it against the photo.',
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('read-receipt-photo'),
          onPressed: _busy ? null : _read,
          icon: const Icon(Icons.document_scanner_outlined),
          label: Text(
            _busy
                ? 'Reading photo…'
                : _result == null
                ? 'Read photo'
                : 'Read again',
          ),
        ),
      ],
      if (_busy) const LinearProgressIndicator(),
      if (_failure != null) Text(_failure!, semanticsLabel: _failure),
      if (_result case final result?) ...[
        if (_items case final items?) ReceiptParsedItems(result: items),
        _ReceiptSuggestedFields(
          result: result,
          onUseDetails: widget.onUseDetails,
        ),
        const SizedBox(height: 12),
        Text(
          result.text.trim().isEmpty
              ? 'No readable text found'
              : 'Text found in this photo',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (result.text.trim().isEmpty)
          const Text(
            'Try a sharper photo with the whole receipt visible, or enter the details yourself.',
          )
        else ...[
          const Text(
            'Check against the photo. This text has not been added to your expense. Overlapping photos may repeat items.',
          ),
          const SizedBox(height: 8),
          SelectableText(receiptReadingRows(result).join('\n')),
        ],
      ],
    ],
  );
}

class _ReceiptSuggestedFields extends StatelessWidget {
  const _ReceiptSuggestedFields({required this.result, this.onUseDetails});
  final ReceiptPhotoText result;
  final ValueChanged<ReceiptFieldProposals>? onUseDetails;

  @override
  Widget build(BuildContext context) {
    final proposed = proposeReceiptFields(result);
    String money(int minor) =>
        '${minor < 0 ? '-' : ''}${minor.abs() ~/ 100}.${(minor.abs() % 100).toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          'Suggested receipt details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'Check these against the photo. They are not saved expense details.',
        ),
        if (proposed.merchant case final merchant?) Text('Store: $merchant'),
        if (proposed.date case final date?)
          Text('Date: ${operationalDateLabel(context, date)}'),
        if (proposed.subtotalMinor case final subtotal?)
          Text('Subtotal: ${money(subtotal)}'),
        if (proposed.taxMinor case final tax?) Text('Tax: ${money(tax)}'),
        if (proposed.totalMinor case final total?)
          Text('Total: ${money(total)}'),
        for (final warning in proposed.warnings) Text(warning),
        if (onUseDetails != null &&
            (proposed.totalMinor != null || proposed.merchant != null))
          OutlinedButton(
            key: const ValueKey('use-receipt-suggested-details'),
            onPressed: () => onUseDetails!(proposed),
            child: const Text('Use these details for review'),
          ),
      ],
    );
  }
}
