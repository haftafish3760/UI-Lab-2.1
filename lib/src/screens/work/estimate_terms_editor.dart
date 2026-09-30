import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../shared/document_form_fields.dart';

class EstimateTermsEditor extends StatefulWidget {
  const EstimateTermsEditor({required this.controller, super.key});
  final TextEditingController controller;
  @override
  State<EstimateTermsEditor> createState() => _EstimateTermsEditorState();
}

class _EstimateTermsEditorState extends State<EstimateTermsEditor> {
  bool _saving = false;
  static const _presets = {
    'Estimated price and approval':
        'This is an estimate for the work described. The final price may be lower or higher. Additional work or charges require your approval before we proceed.',
    'Time and materials':
        'Labor is estimated using the hours and rates shown, plus materials used. We will obtain your approval before additional work or charges beyond the agreed scope.',
    'Defined scope':
        'This estimate covers only the work and materials listed. Changes to the scope, materials, or price will be presented for your approval before proceeding.',
  };
  Future<void> _save({required bool asDefault}) async {
    final text = widget.controller.text.trim();
    if (_saving || text.isEmpty) return;
    String? name;
    if (!asDefault) {
      final input = TextEditingController();
      name = await showDialog<String>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Save reusable terms'),
          content: TextField(
            controller: input,
            decoration: const InputDecoration(labelText: 'Template name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (input.text.trim().isNotEmpty) {
                  Navigator.pop(dialog, input.text.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      input.dispose();
      if (!mounted || name == null) return;
    }
    setState(() => _saving = true);
    try {
      final store = PrototypeOperationsScope.of(context);
      final profile = store.companyProfile;
      final saved = await store.updateCompanyProfile(
        profile.copyWith(
          defaultEstimateTerms: asDefault ? text : null,
          estimateTermsTemplates: asDefault
              ? null
              : {...profile.estimateTermsTemplates, name!: text},
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? 'Terms saved.'
                  : 'Terms could not be saved. Your text is still here.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terms could not be saved. Your text is still here.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = PrototypeOperationsScope.of(context).companyProfile;
    final templates = {..._presets, ...profile.estimateTermsTemplates};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Add one or more terms below, or write your own. Your selections appear together on the estimate.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in templates.entries)
              OutlinedButton(
                onPressed: _saving
                    ? null
                    : () {
                        final existing = widget.controller.text.trim();
                        if (!existing.contains(entry.value)) {
                          widget.controller.text = existing.isEmpty
                              ? entry.value
                              : '$existing\n\n${entry.value}';
                        }
                        setState(() {});
                      },
                child: Text(
                  widget.controller.text.contains(entry.value)
                      ? '${entry.key} · Added'
                      : entry.key,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        DocumentTermsField(controller: widget.controller),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: _saving ? null : () => _save(asDefault: false),
              child: const Text('Save reusable terms'),
            ),
            TextButton(
              onPressed: _saving ? null : () => _save(asDefault: true),
              child: const Text('Use as estimate default'),
            ),
          ],
        ),
      ],
    );
  }
}
