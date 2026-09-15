part of 'expense_editor_screen.dart';

class _PurchaseFields extends StatelessWidget {
  const _PurchaseFields({
    required this.vendorController,
    required this.jobController,
    required this.expenseDate,
    required this.category,
    required this.onChooseDate,
    required this.onCategoryChanged,
    required this.requireVendor,
  });

  final TextEditingController vendorController;
  final TextEditingController jobController;
  final DateTime expenseDate;
  final ExpenseCategory category;
  final VoidCallback onChooseDate;
  final ValueChanged<ExpenseCategory> onCategoryChanged;
  final bool requireVendor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final vendor = TextFormField(
        key: const ValueKey('expense-vendor-field'),
        controller: vendorController,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: requireVendor
              ? 'Vendor or store'
              : 'Vendor or store (optional)',
          helperText: 'Where the purchase was made',
        ),
        validator: (value) => requireVendor && (value ?? '').trim().isEmpty
            ? 'Enter the vendor or store.'
            : null,
      );
      final date = _ReceiptDateField(date: expenseDate, onTap: onChooseDate);
      final categoryField = DropdownButtonFormField<ExpenseCategory>(
        key: const ValueKey('expense-category-field'),
        isExpanded: true,
        initialValue: category,
        decoration: const InputDecoration(labelText: 'Category (optional)'),
        items: [
          for (final option in ExpenseCategory.values)
            DropdownMenuItem(value: option, child: Text(option.label)),
        ],
        onChanged: (value) {
          if (value != null) onCategoryChanged(value);
        },
      );
      final job = TextFormField(
        key: const ValueKey('expense-job-field'),
        controller: jobController,
        decoration: const InputDecoration(
          labelText: 'Related job (optional)',
          helperText: 'Connect this cost to a job when applicable',
        ),
      );
      if (AppLayoutEngine.stackFormFieldsFor(
        constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
      )) {
        return Column(
          children: [
            vendor,
            const SizedBox(height: 12),
            date,
            const SizedBox(height: 12),
            categoryField,
            const SizedBox(height: 12),
            job,
          ],
        );
      }
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: vendor),
              const SizedBox(width: 12),
              Expanded(child: date),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: categoryField),
              const SizedBox(width: 12),
              Expanded(child: job),
            ],
          ),
        ],
      );
    },
  );
}

class _ReceiptDateField extends StatelessWidget {
  const _ReceiptDateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('expense-receipt-date-field'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(7),
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Receipt date',
        suffixIcon: Icon(Icons.calendar_today_outlined),
      ),
      child: Text(operationalDateLabel(context, date)),
    ),
  );
}
