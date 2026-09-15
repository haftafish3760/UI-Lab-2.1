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
    super.key,
  });
  final String reference;
  final CompanyDocumentBrandingService? service;
  final ValueChanged<String> onChanged;
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
    try {
      final selected = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );
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
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Company logo', style: Theme.of(context).textTheme.titleMedium),
      FutureBuilder<Uint8List?>(
        future: _image,
        builder: (_, snapshot) => snapshot.hasData
            ? SizedBox(
                height: 100,
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Text(
                    'Logo unavailable. Documents will use the company name.',
                  ),
                ),
              )
            : const Text(
                'Optional. Documents can use your company name without a logo.',
              ),
      ),
      if (_error != null) Text(_error!),
      Wrap(
        spacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _busy || widget.service == null ? null : _choose,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_busy ? 'Adding logo…' : 'Choose PNG or JPEG'),
          ),
          if (widget.reference.isNotEmpty)
            TextButton(
              onPressed: _busy ? null : () => widget.onChanged(''),
              child: const Text('Remove logo'),
            ),
        ],
      ),
      const Text(
        'Review the logo above, then save company information to use it on documents.',
      ),
    ],
  );
}
