import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/work/company_document_branding.dart';

/// Company profile UI; the renderer consumes only its saved logo reference.
class CompanyLogoField extends StatefulWidget {
  const CompanyLogoField({
    required this.reference,
    required this.service,
    required this.onChanged,
    this.onBusyChanged,
    super.key,
  });
  final String reference;
  final CompanyDocumentBrandingService? service;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool>? onBusyChanged;
  @override
  State<CompanyLogoField> createState() => _CompanyLogoFieldState();
}

class _CompanyLogoFieldState extends State<CompanyLogoField> {
  bool _busy = false;
  String? _error;
  Future<Uint8List?>? _image;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CompanyLogoField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reference != widget.reference) _load();
  }

  void _load() {
    _image = widget.service?.readLogo(widget.reference);
  }

  Future<void> _choose() async {
    if (_busy || widget.service == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusyChanged?.call(true);
    try {
      final selected = await FilePicker.pickFiles(type: FileType.image);
      final file = selected.isEmpty ? null : selected.single.path;
      if (file == null || !mounted) return;
      final reference = await widget.service!.retainLogo(File(file));
      if (mounted) widget.onChanged(reference);
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : 'The logo could not be added. Your current logo is unchanged.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Logo preview', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        FutureBuilder<Uint8List?>(
          future: _image,
          builder: (_, snapshot) =>
              widget.reference.isNotEmpty &&
                  snapshot.connectionState == ConnectionState.waiting
              ? const Text('Loading company logo…')
              : widget.reference.isNotEmpty && !snapshot.hasData
              ? const Text(
                  'Your saved logo could not be loaded. Try reopening this screen or choose another photo.',
                )
              : snapshot.hasData
              ? SizedBox(
                  height: 56,
                  child: Image.memory(
                    snapshot.data!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Text(
                      'Logo unavailable. Documents will use the company name.',
                    ),
                  ),
                )
              : const Text(
                  'Add your company logo here. It will appear on estimates and invoices.',
                ),
        ),
        if (_error != null) Text(_error!),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy || widget.service == null ? null : _choose,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _busy
                    ? 'Adding logo…'
                    : widget.reference.isEmpty
                    ? 'Choose photo'
                    : 'Change photo',
              ),
            ),
            if (widget.reference.isNotEmpty)
              TextButton(
                onPressed: _busy ? null : () => widget.onChanged(''),
                child: const Text('Remove logo'),
              ),
          ],
        ),
        const Text('Shown on your estimates, quotes, and invoices.'),
      ],
    ),
  );
}
