import 'package:flutter/material.dart';
import '../../layout/app_layout_engine.dart';
import 'work_models.dart';

/// A customer-price projection only; calculations stay with the line item.
class EstimateDocumentItems extends StatelessWidget {
  const EstimateDocumentItems({required this.items, super.key});
  final List<WorkLineItem> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = AppLayoutEngine.stackFormFieldsFor(
        constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
      );
      final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
      Widget cell(String text, {bool numeric = false, bool heading = false}) =>
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Text(
              text,
              textAlign: numeric ? TextAlign.end : TextAlign.start,
              style: heading
                  ? style?.copyWith(fontWeight: FontWeight.w700)
                  : style,
            ),
          );
      String money(double value) => '\$${value.toStringAsFixed(2)}';
      String quantity(double value) => value == value.truncateToDouble()
          ? value.toStringAsFixed(0)
          : value.toString();
      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in items) ...[
              Text(item.name, style: Theme.of(context).textTheme.titleSmall),
              if (item.description.trim().isNotEmpty) Text(item.description),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(),
                  1: FlexColumnWidth(),
                },
                children: [
                  TableRow(
                    children: [
                      cell('Quantity'),
                      cell(
                        '${quantity(item.quantity)} ${item.unit}',
                        numeric: true,
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      cell('Unit price'),
                      cell(money(item.customerPrice), numeric: true),
                    ],
                  ),
                  TableRow(
                    children: [
                      cell('Amount', heading: true),
                      cell(money(item.total), numeric: true, heading: true),
                    ],
                  ),
                ],
              ),
              const Divider(),
            ],
          ],
        );
      }
      return Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(1.5),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        border: TableBorder(
          horizontalInside: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        children: [
          TableRow(
            children: [
              cell('Description', heading: true),
              cell('Quantity', numeric: true, heading: true),
              cell('Unit price', numeric: true, heading: true),
              cell('Amount', numeric: true, heading: true),
            ],
          ),
          for (final item in items)
            TableRow(
              children: [
                cell(
                  [
                    item.name,
                    if (item.description.trim().isNotEmpty) item.description,
                  ].join('\n'),
                ),
                cell('${quantity(item.quantity)} ${item.unit}', numeric: true),
                cell(money(item.customerPrice), numeric: true),
                cell(money(item.total), numeric: true),
              ],
            ),
        ],
      );
    },
  );
}
