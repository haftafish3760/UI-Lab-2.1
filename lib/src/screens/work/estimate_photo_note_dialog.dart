import 'package:flutter/material.dart';

/// The dialog owns its controller through its exit animation.
class EstimatePhotoNoteDialog extends StatefulWidget {
  const EstimatePhotoNoteDialog({
    required this.initialText,
    required this.onChanged,
    super.key,
  });
  final String initialText;
  final ValueChanged<String> onChanged;
  @override
  State<EstimatePhotoNoteDialog> createState() =>
      _EstimatePhotoNoteDialogState();
}

class _EstimatePhotoNoteDialogState extends State<EstimatePhotoNoteDialog> {
  late final _controller = TextEditingController(text: widget.initialText);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Photo details'),
    content: TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      autofocus: true,
      minLines: 2,
      maxLines: 5,
      decoration: const InputDecoration(
        hintText: 'Example: Shutoff valve is behind the water heater.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Keep unfinished details'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        child: const Text('Save details'),
      ),
    ],
  );
}
