import 'package:flutter/material.dart';

/// Editing tools sit outside the content surface, not inside another card.
class ScreenLayoutEditControls extends StatelessWidget {
  const ScreenLayoutEditControls({
    required this.title,
    required this.child,
    this.onEarlier,
    this.onLater,
    this.onRemove,
    super.key,
  });
  final String title;
  final Widget child;
  final VoidCallback? onEarlier;
  final VoidCallback? onLater;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton.icon(
            onPressed: onEarlier,
            icon: const Icon(Icons.arrow_upward, size: 18),
            label: const Text('Earlier'),
          ),
          TextButton.icon(
            onPressed: onLater,
            icon: const Icon(Icons.arrow_downward, size: 18),
            label: const Text('Later'),
          ),
          if (onRemove != null)
            TextButton.icon(
              key: ValueKey('remove-widget-$title'),
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline, size: 18),
              label: const Text('Remove'),
            )
          else
            const Text('Always shown'),
        ],
      ),
      // Layout editing never executes a business action inside a preview.
      AbsorbPointer(child: ExcludeFocus(child: child)),
    ],
  );
}
