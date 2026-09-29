import 'package:flutter/material.dart';

import '../layout/app_layout_engine.dart';
import '../theme/app_theme.dart';
import '../theme/operational_card_palette.dart';

@immutable
class OperationalSummaryItem {
  const OperationalSummaryItem({
    required this.id,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    required this.icon,
    this.endColor,
    this.foreground = OperationalCardTone.ink,
    this.selected = false,
  });
  final String id;
  final String label;
  final String value;
  final Color color;
  final Color? endColor;
  final Color foreground;
  final VoidCallback onTap;
  final IconData icon;
  final bool selected;
}

/// A single horizontally scrollable strip. All cards share dimensions; text
/// can grow their common height instead of being cropped or abbreviated.
class OperationalSummaryStrip extends StatelessWidget {
  const OperationalSummaryStrip({
    required this.items,
    this.wide = false,
    super.key,
  });
  final List<OperationalSummaryItem> items;
  final bool wide;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        _buildStrip(context, constraints.maxWidth),
  );

  Widget _buildStrip(BuildContext context, double availableWidth) {
    final scaler = MediaQuery.textScalerOf(context);
    final valueStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: OperationalCardTone.ink,
      fontSize: 15,
      height: 1.15,
      fontWeight: FontWeight.w600,
    );
    var valueWidth = 0.0;
    for (final item in items) {
      final measure = TextPainter(
        text: TextSpan(text: item.value, style: valueStyle),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout();
      if (measure.width > valueWidth) valueWidth = measure.width;
      measure.dispose();
    }
    final minimumWidth = AppLayoutEngine.summaryStripCardWidthFor(
      scaler,
      valueWidth: valueWidth.ceilToDouble(),
    );
    final proposedWidth = items.isEmpty
        ? minimumWidth
        : (availableWidth - 12 * (items.length - 1)) / items.length;
    final width = wide && proposedWidth.isFinite && proposedWidth > minimumWidth
        ? proposedWidth
        : minimumWidth;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              SizedBox(
                width: width,
                child: ConstrainedBox(
                  key: ValueKey('dashboard-summary-${items[index].id}'),
                  constraints: BoxConstraints(
                    minHeight: wide
                        ? 96
                        : AppLayoutEngine.summaryStripCardMinimumHeight,
                  ),
                  child: Semantics(
                    selected: items[index].selected,
                    button: true,
                    child: Material(
                      color: items[index].color,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.surface),
                        side: BorderSide(
                          color: items[index].selected
                              ? items[index].foreground
                              : items[index].color.withValues(alpha: .6),
                          width: items[index].selected ? 2 : 1,
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              items[index].color,
                              items[index].endColor ?? items[index].color,
                            ],
                          ),
                        ),
                        child: InkWell(
                          onTap: items[index].onTap,
                          borderRadius: BorderRadius.circular(AppRadii.surface),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  items[index].selected
                                      ? Icons.check_circle_outline
                                      : items[index].icon,
                                  color: items[index].foreground,
                                  size: 20,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  items[index].label,
                                  style: TextStyle(
                                    color: items[index].foreground,
                                    fontSize: 13,
                                    height: 1.15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                const SizedBox(height: 8),
                                Text(
                                  items[index].value,
                                  style: valueStyle.copyWith(
                                    color: items[index].foreground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
