import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ReceiptChoiceCard extends StatelessWidget {
  const ReceiptChoiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.selected,
    super.key,
  });
  final String title, description;
  final IconData icon;
  final VoidCallback? onTap;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: Material(
        color: selected == true ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          side: BorderSide(
            color: selected == true ? colors.primary : colors.outline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: colors.primary),
                    if (selected != null) ...[
                      const Spacer(),
                      Icon(
                        selected!
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: colors.primary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two choices stay side by side; their height grows to fit all text.
class ReceiptChoicePair extends StatelessWidget {
  const ReceiptChoicePair({
    required this.first,
    required this.second,
    super.key,
  });
  final Widget first, second;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
      ],
    ),
  );
}
