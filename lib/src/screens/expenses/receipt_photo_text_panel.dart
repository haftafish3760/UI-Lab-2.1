import 'package:flutter/material.dart';

import '../../data/receipts/receipt_photo_reader.dart';
import '../../data/device_capabilities/device_workload_service.dart';
import '../../shared/local_document_path_scope.dart';

/// Explicit per-photo consent. Source changes invalidate unfinished results.
class ReceiptPhotoTextPanel extends StatefulWidget {
  const ReceiptPhotoTextPanel({required this.path, this.reader, super.key});
  final String path;
  final ReceiptPhotoReader? reader;

  @override
  State<ReceiptPhotoTextPanel> createState() => _ReceiptPhotoTextPanelState();
}

class _ReceiptPhotoTextPanelState extends State<ReceiptPhotoTextPanel> {
  ReceiptPhotoReader get _reader => widget.reader ?? NativeReceiptPhotoReader();
  ReceiptPhotoText? _result;
  String? _failure;
  bool _busy = false;
  int _generation = 0;

  @override
  void didUpdateWidget(covariant ReceiptPhotoTextPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path || oldWidget.reader != widget.reader) {
      _generation++;
      _result = null;
      _failure = null;
      _busy = false;
    }
  }

  Future<void> _read() async {
    if (_busy || !_reader.supported) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final path = LocalDocumentPathScope.resolvePath(context, widget.path);
      final result = await _reader.read(path);
      if (!mounted || generation != _generation) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(
        () => _failure = error is DeviceWorkloadUnavailable
            ? error.message
            : 'This photo could not be read. Try again, replace the photo, or enter the expense yourself.',
      );
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
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
            'Check against the photo. This text has not been added to your expense or saved. Overlapping photos may repeat items.',
          ),
          const SizedBox(height: 8),
          SelectableText(result.text),
        ],
      ],
    ],
  );
}
