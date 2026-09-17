import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../layout/app_layout_engine.dart';

class MaterialsInventoryTileData {
  const MaterialsInventoryTileData({
    required this.label,
    required this.onTap,
    this.detail = '',
  });
  final String label, detail;
  final VoidCallback onTap;
}

/// User-created inventory choices. All labels participate in width/height budgeting.
/// The same component handles categories, exact items and inventory projections.
class MaterialsInventoryTiles extends StatelessWidget {
  const MaterialsInventoryTiles({
    required this.entries,
    required this.listView,
    super.key,
  });
  final List<MaterialsInventoryTileData> entries;
  final bool listView;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      final scaler = MediaQuery.textScalerOf(context);
      final direction = Directionality.of(context);
      final style = theme.textTheme.bodyMedium!.copyWith(
        fontSize: AppLayoutEngine.typographyFor(constraints.maxWidth).rowTitle,
        fontWeight: FontWeight.w600,
      );
      double measure(String text, {double width = double.infinity}) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: direction,
          textScaler: scaler,
        )..layout(maxWidth: width);
        final value = width.isInfinite ? painter.width : painter.height;
        painter.dispose();
        return value;
      }

      var longestWord = 0.0;
      for (final entry in entries) {
        for (final word in '${entry.label} ${entry.detail}'.split(
          RegExp(r'\s+'),
        )) {
          longestWord = math.max(longestWord, measure(word));
        }
      }
      final grid = AppLayoutEngine.materialsInventoryFor(
        constraints.maxWidth,
        textScaler: scaler,
        longestWordWidth: longestWord,
      );
      final width = listView
          ? math.min(
              constraints.maxWidth,
              AppLayoutEngine.maximumFormWorkspaceWidth,
            )
          : grid.tileWidth;
      final textWidth = math.max(1.0, width - 24);
      var height = 80.0;
      for (final entry in entries) {
        height = math.max(
          height,
          32 +
              
              measure(entry.label, width: textWidth) +
              (entry.detail.isEmpty
                  ? 0
                  : 8 + measure(entry.detail, width: textWidth)),
        );
      }
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: listView ? width : constraints.maxWidth,
          child: Wrap(
            spacing: grid.gap,
            runSpacing: grid.gap,
            children: [
              for (final entry in entries)
                SizedBox(
                  key: ValueKey('materials:${entry.label}'),
                  width: width,
                  height: height,
                  child: Semantics(
                    button: true,
                    child: Material(
                      color: Colors.transparent,
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outline),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.alphaBlend(
                                theme.colorScheme.primary.withValues(
                                  alpha: .18,
                                ),
                                theme.colorScheme.surface,
                              ),
                              theme.colorScheme.surface,
                            ],
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: entry.onTap,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  entry.label,
                                  textAlign: TextAlign.center,
                                  style: style,
                                ),
                                if (entry.detail.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    entry.detail,
                                    textAlign: TextAlign.center,
                                    style: style,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
