import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../expenses/expense_models.dart';
import '../inventory/inventory_models.dart';

class MaterialCostSourcePicker extends StatelessWidget {
  const MaterialCostSourcePicker({required this.costs, super.key});

  final List<MaterialCostRecord> costs;

  @override
  Widget build(BuildContext context) {
    final latest = <String, MaterialCostRecord>{};
    final sorted = [...costs]
      ..sort((a, b) => b.purchasedOn.compareTo(a.purchasedOn));
    for (final record in sorted) {
      latest.putIfAbsent(record.materialId, () => record);
    }
    return _PickerFrame(
      title: 'Add from materials',
      description:
          'Choose a verified purchase cost. You will review the customer price before adding the line item.',
      children: [
        if (latest.isEmpty)
          const SectionCard(
            child: Text('No verified material costs are available.'),
          )
        else
          for (final record in latest.values)
            _SourceRow(
              icon: Icons.inventory_2_outlined,
              title: record.materialName,
              detail:
                  '${record.vendor} · ${inventoryMoney(record.unitCostCents, currencyCode: record.currencyCode)} per ${record.unitLabel}\nConfirmed by ${record.confirmedBy}',
              evidence: record.hasReceiptEvidence
                  ? 'Receipt evidence linked'
                  : 'Manually confirmed cost',
              onTap: () => Navigator.of(context).pop(record),
            ),
      ],
    );
  }
}

class ExpenseEvidenceSourcePicker extends StatelessWidget {
  const ExpenseEvidenceSourcePicker({
    required this.expenses,
    this.recordedOnly = false,
    this.title = 'Link receipt or expense',
    this.description =
        'Choose a recorded business expense. Linking it does not add a customer charge until you explicitly create and review one.',
    super.key,
  });

  final List<ExpenseRecord> expenses;
  final bool recordedOnly;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final eligible =
        expenses
            .where(
              (record) => !recordedOnly || record.countsAsRecordedBusinessCost,
            )
            .toList()
          ..sort((a, b) {
            final left = a.resolvedDate ?? DateTime(1970);
            final right = b.resolvedDate ?? DateTime(1970);
            return right.compareTo(left);
          });
    return _PickerFrame(
      title: title,
      description: description,
      children: [
        if (eligible.isEmpty)
          const SectionCard(child: Text('No recorded expenses are available.'))
        else
          for (final record in eligible)
            _SourceRow(
              icon: record.category.icon,
              title: record.vendor,
              detail:
                  '${record.category.label} · ${expenseMoney(record.amount)}\n${record.job ?? 'Not linked to a job'}',
              evidence:
                  record.receiptStatus ??
                  'Expense record · no receipt attached',
              onTap: () => Navigator.of(context).pop(record),
            ),
      ],
    );
  }
}

class ExpenseLineItemSourcePicker extends StatelessWidget {
  const ExpenseLineItemSourcePicker({required this.expense, super.key});

  final ExpenseRecord expense;

  @override
  Widget build(BuildContext context) {
    final materialLines = expense.lineItems
        .where((line) => line.category == ExpenseCategory.materials)
        .toList();
    return _PickerFrame(
      title: 'Choose a receipt item',
      description:
          'Choose one reviewed material line from ${expense.vendor}. Its cost is evidence only; you still decide whether the customer is charged.',
      children: [
        if (materialLines.isEmpty)
          const SectionCard(
            child: Text(
              'No reviewed material lines are available on this expense. Link the expense from Job records instead, or review an itemized receipt first.',
            ),
          )
        else
          for (final line in materialLines)
            _SourceRow(
              key: ValueKey('expense-line-${line.id}'),
              icon: line.category.icon,
              title: line.description,
              detail:
                  '${_sourceQuantity(line.quantity)} ${line.unit} · ${expenseMoney(line.unitPrice)} each',
              evidence: line.partNumber == null
                  ? '${expense.vendor} · reviewed receipt line'
                  : '${expense.vendor} · Part ${line.partNumber}',
              onTap: () => Navigator.of(context).pop(line),
            ),
      ],
    );
  }
}

class TruckStockSourcePicker extends StatelessWidget {
  const TruckStockSourcePicker({required this.stock, super.key});

  final List<InventoryStockRecord> stock;

  @override
  Widget build(BuildContext context) {
    final available =
        stock
            .where(
              (record) =>
                  record.confidence != InventoryStockConfidence.unknown &&
                  record.quantity > 0,
            )
            .toList()
          ..sort((a, b) => a.materialName.compareTo(b.materialName));
    return _PickerFrame(
      title: 'Use truck stock',
      description:
          'Choose material already carried on a service vehicle. Review the quantity and customer price before saving.',
      children: [
        if (available.isEmpty)
          const SectionCard(
            child: Text('No available truck stock is confirmed.'),
          )
        else
          for (final record in available)
            _SourceRow(
              icon: Icons.local_shipping_outlined,
              title: record.materialName,
              detail:
                  '${record.locationLabel} · ${record.quantity.toStringAsFixed(record.quantity == record.quantity.roundToDouble() ? 0 : 2)} ${record.unitLabel}',
              evidence: record.confidence.label,
              onTap: () => Navigator.of(context).pop(record),
            ),
      ],
    );
  }
}

class _PickerFrame extends StatelessWidget {
  const _PickerFrame({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 12, insets.right, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(description),
                      const SizedBox(height: 14),
                      ...children,
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.evidence,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String evidence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: SectionCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        minTileHeight: 76,
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$detail\n$evidence'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    ),
  );
}

String _sourceQuantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
