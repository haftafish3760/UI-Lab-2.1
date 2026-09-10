import 'package:flutter/material.dart';

import '../theme/operational_card_palette.dart';
import '../theme/app_semantic_colors.dart';

/// A bounded theme for full-color operational sections, not the page canvas.
/// Header, counts, rows, menus and empty states share readable foregrounds.
class OperationalCardColorScope extends StatelessWidget {
  const OperationalCardColorScope({
    required this.tone,
    required this.builder,
    super.key,
  });
  final OperationalCardTone tone;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const ink = OperationalCardTone.darkInk;
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where(
            (extension) => extension is! AppSemanticColors,
          ),
          AppSemanticColors.light,
        ],
        colorScheme: theme.colorScheme.copyWith(
          surface: tone.row,
          surfaceContainerLow: tone.row,
          surfaceContainerHigh: tone.row,
          surfaceContainerHighest: tone.row,
          onSurface: ink,
          onSurfaceVariant: ink,
          primary: ink,
          primaryContainer: tone.start,
          outline: ink.withValues(alpha: .35),
        ),
        textTheme: theme.textTheme.apply(bodyColor: ink, displayColor: ink),
        iconTheme: theme.iconTheme.copyWith(color: ink),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: ink),
        ),
        popupMenuTheme: theme.popupMenuTheme.copyWith(
          color: tone.row,
          textStyle: const TextStyle(color: ink),
          labelTextStyle: const WidgetStatePropertyAll(TextStyle(color: ink)),
        ),
      ),
      child: Builder(builder: builder),
    );
  }
}
