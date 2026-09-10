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
  });
  final String id;
  final String label;
  final String value;
  final Color color;
  final Color? endColor;
  final Color foreground;
  final VoidCallback onTap;
  final IconData icon;
}

/// A single horizontally scrollable strip. All cards share dimensions; text
/// can grow their common height instead of being cropped or abbreviated.
class OperationalSummaryStrip extends StatelessWidget {
  const OperationalSummaryStrip({required this.items, super.key});
  final List<OperationalSummaryItem> items;

  @override
  Widget build(BuildContext context) {
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
    final width = AppLayoutEngine.summaryStripCardWidthFor(
      scaler,
      valueWidth: valueWidth.ceilToDouble(),
    );
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
                  constraints: const BoxConstraints(
                    minHeight: AppLayoutEngine.summaryStripCardMinimumHeight,
                  ),
                  child: Material(
                    color: items[index].color,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.surface),
                      side: BorderSide(
                        color: items[index].color.withValues(alpha: .6),
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
                                items[index].icon,
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
            ],
          ],
        ),
      ),
    );
  }
}
