import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'dashboard_models.dart';

class EmployeeStatusStrip extends StatelessWidget {
  const EmployeeStatusStrip({
    super.key,
    required this.employees,
    required this.selectedId,
    required this.onSelected,
  });

  final List<EmployeeStatus> employees;
  final String? selectedId;
  final ValueChanged<EmployeeStatus> onSelected;

  static const _nameStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 12.5,
    height: 1.05,
  );
  static const _statusStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.05,
  );

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final growth = (scale - 1).clamp(0.0, 1.0);
    final cardWidth = 96 + growth * 74;
    final cardHeight = _cardHeightFor(context, cardWidth, growth);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Employees',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          key: const ValueKey('employee-status-strip'),
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: employees.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) => SizedBox(
              width: cardWidth,
              child: _card(context, employees[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, EmployeeStatus employee) {
    final colors = Theme.of(context).colorScheme;
    final selected = employee.id == selectedId;
    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        side: BorderSide(
          color: selected ? colors.primary : colors.outline,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('employee-${employee.id}'),
        onTap: () => onSelected(employee),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(employee.icon, size: 19, color: employee.color),
              const SizedBox(height: 7),
              Text(employee.name, style: _nameStyle),
              const Spacer(),
              Text(
                employee.status,
                style: _statusStyle.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _cardHeightFor(BuildContext context, double cardWidth, double growth) {
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final textWidth = math.max(1.0, cardWidth - 20);
    final inheritedStyle = DefaultTextStyle.of(context).style;
    final measuredNameStyle = inheritedStyle.merge(_nameStyle);
    final measuredStatusStyle = inheritedStyle.merge(_statusStyle);
    var nameHeight = 0.0;
    var statusHeight = 0.0;
    for (final employee in employees) {
      nameHeight = math.max(
        nameHeight,
        _textHeight(
          employee.name,
          measuredNameStyle,
          textWidth,
          textScaler,
          textDirection,
        ),
      );
      statusHeight = math.max(
        statusHeight,
        _textHeight(
          employee.status,
          measuredStatusStyle,
          textWidth,
          textScaler,
          textDirection,
        ),
      );
    }
    final measuredHeight = 20 + 19 + 7 + nameHeight + 8 + statusHeight;
    return math.max(120 + growth * 90, measuredHeight);
  }

  double _textHeight(
    String value,
    TextStyle style,
    double width,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout(maxWidth: width);
    return painter.height;
  }
}
