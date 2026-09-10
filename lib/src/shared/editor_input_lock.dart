import 'package:flutter/widgets.dart';

/// Prevents input from changing a submitted snapshot while an operation is
/// pending. Pointer blocking alone does not detach a focused keyboard/IME client
/// or prevent keyboard activation of an already focused action.
class EditorInputLock extends StatelessWidget {
  const EditorInputLock({required this.locked, required this.child, super.key});

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) => ExcludeFocus(
    excluding: locked,
    child: AbsorbPointer(absorbing: locked, child: child),
  );
}
