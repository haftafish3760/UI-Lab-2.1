part of 'inventory_screen.dart';

class _InventoryDateHeading extends StatelessWidget {
  const _InventoryDateHeading({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final type = AppLayoutEngine.typographyFor(constraints.maxWidth);
      return Text(
        operationalDateLabel(
          context,
          selectedDate,
          year: selectedDate.year != DateTime.now().year,
        ),
        key: const ValueKey('inventory-date-heading'),
        style: TextStyle(
          fontSize: type.pageTitle,
          fontWeight: FontWeight.w600,
          height: 1.15,
        ),
      );
    },
  );
}

class _InventoryHeading extends StatelessWidget {
  const _InventoryHeading({
    required this.view,
    required this.showWideActions,
    required this.onRecordCost,
    required this.onVerifyStock,
  });

  final AppViewMode view;
  final bool showWideActions;
  final VoidCallback onRecordCost;
  final VoidCallback? onVerifyStock;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 10,
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Materials and cost history',
              key: const ValueKey('inventory-heading'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              view == AppViewMode.admin
                  ? 'Find confirmed company purchase costs and review what stock locations are actually known.'
                  : 'Look up what you paid before and review dated stock for your assigned truck.',
            ),
          ],
        ),
      ),
      if (showWideActions)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onRecordCost,
              icon: const Icon(Icons.price_check_outlined),
              label: const Text('Record purchase cost'),
            ),
            OutlinedButton.icon(
              onPressed: onVerifyStock,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Verify truck stock'),
            ),
          ],
        ),
    ],
  );
}

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({required this.costs, required this.stock});
  final List<MaterialCostRecord> costs;
  final List<InventoryStockRecord> stock;

  @override
  Widget build(BuildContext context) {
    final materials = costs.map((record) => record.materialId).toSet().length;
    final expenseSources = costs
        .where((record) => record.hasExpenseSource)
        .length;
    final low = stock.where((record) => record.isLow).length;
    final unknown = stock
        .where(
          (record) => record.confidence == InventoryStockConfidence.unknown,
        )
        .length;
    final values = <Widget>[
      _InventorySummaryValue(
        key: const ValueKey('verified-material-count'),
        label: 'Materials with cost history',
        value: '$materials',
      ),
      _InventorySummaryValue(
        key: const ValueKey('linked-expense-count'),
        label: 'Linked expense records',
        value: '$expenseSources',
      ),
      _InventorySummaryValue(
        key: const ValueKey('low-stock-count'),
        label: 'Known low stock',
        value: '$low',
      ),
      _InventorySummaryValue(
        key: const ValueKey('unknown-stock-count'),
        label: 'Counts marked unknown',
        value: '$unknown',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final columns = AppLayoutEngine.summaryMetricColumnsFor(
          constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
        );
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final value in values)
              SizedBox(width: itemWidth, child: value),
          ],
        );
      },
    );
  }
}

class _InventorySummaryValue extends StatelessWidget {
  const _InventorySummaryValue({
    required this.label,
    required this.value,
    super.key,
  });
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(11),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );
}

class _InventoryLanes extends StatelessWidget {
  const _InventoryLanes({
    required this.layout,
    required this.costs,
    required this.stock,
    required this.search,
    required this.preferences,
    required this.onSearch,
    required this.onMaterial,
    required this.onStock,
    required this.onCalendarDay,
  });

  final OperationsWorkspaceLayout layout;
  final List<MaterialCostRecord> costs;
  final List<InventoryStockRecord> stock;
  final String search;
  final InventoryDisplayPreferences preferences;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onMaterial;
  final ValueChanged<InventoryStockRecord> onStock;
  final ValueChanged<DateTime> onCalendarDay;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _MaterialCostList(
        costs: costs,
        search: search,
        onSearch: onSearch,
        onMaterial: onMaterial,
      ),
      if (preferences.showTruckStock)
        _TruckStockList(stock: stock, onStock: onStock),
      if (preferences.showCostSources) _CostSourceGuide(costs: costs),
    ];
    return Column(
      key: ValueKey('inventory-${layout.columns}-column-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (layout.columns == 1) ...[
          for (var index = 0; index < sections.length; index++) ...[
            sections[index],
            if (index != sections.length - 1) SizedBox(height: layout.gap),
          ],
        ] else
          Wrap(
            spacing: layout.gap,
            runSpacing: layout.gap,
            children: [
              for (final section in sections)
                SizedBox(width: layout.laneWidth, child: section),
            ],
          ),
        SizedBox(height: layout.gap),
        _InventoryCalendar(
          costs: costs,
          maximumWidth: layout.laneWidth,
          onDaySelected: onCalendarDay,
        ),
      ],
    );
  }
}

class _MaterialCostList extends StatelessWidget {
  const _MaterialCostList({
    required this.costs,
    required this.search,
    required this.onSearch,
    required this.onMaterial,
  });
  final List<MaterialCostRecord> costs;
  final String search;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onMaterial;

  @override
  Widget build(BuildContext context) {
    final query = search.trim().toLowerCase();
    final filtered = costs.where((record) {
      return query.isEmpty ||
          record.materialName.toLowerCase().contains(query) ||
          record.vendor.toLowerCase().contains(query) ||
          record.trade.toLowerCase().contains(query);
    }).toList()..sort((a, b) => b.purchasedOn.compareTo(a.purchasedOn));
    final latest = <String, MaterialCostRecord>{};
    for (final record in filtered) {
      latest.putIfAbsent(record.materialId, () => record);
    }
    return _InventorySection(
      title: 'Verified cost history',
      icon: Icons.price_check_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            key: const ValueKey('inventory-search-field'),
            onChanged: onSearch,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Search materials',
              hintText: 'Name, vendor, or trade',
            ),
          ),
        ),
        if (latest.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No verified material costs match this search.'),
          )
        else
          for (final record in latest.values)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SectionCard(
                key: ValueKey('inventory-cost-record-${record.id}'),
                padding: EdgeInsets.zero,
                child: ListTile(
                  minTileHeight: 66,
                  title: Text(record.materialName),
                  subtitle: Text('${record.vendor} · ${record.trade}'),
                  trailing: Text(
                    '${inventoryMoney(record.unitCostCents, currencyCode: record.currencyCode)}\nper ${record.unitLabel}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => onMaterial(record.materialId),
                ),
              ),
            ),
      ],
    );
  }
}

class _TruckStockList extends StatelessWidget {
  const _TruckStockList({required this.stock, required this.onStock});
  final List<InventoryStockRecord> stock;
  final ValueChanged<InventoryStockRecord> onStock;

  @override
  Widget build(BuildContext context) => _InventorySection(
    title: 'Truck stock',
    icon: Icons.local_shipping_outlined,
    children: [
      if (stock.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No stock is tracked for this vehicle scope.'),
        )
      else
        for (final record in stock)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: SectionCard(
              key: ValueKey('inventory-stock-record-${record.id}'),
              padding: EdgeInsets.zero,
              child: ListTile(
                minTileHeight: 64,
                leading: Icon(
                  record.isLow
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                ),
                title: Text(record.materialName),
                subtitle: Text(
                  '${record.locationLabel} · ${record.confidence.label}',
                ),
                trailing: record.confidence == InventoryStockConfidence.unknown
                    ? const Text('Unknown')
                    : Text(
                        '${record.quantity} ${record.unitLabel}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                onTap: () => onStock(record),
              ),
            ),
          ),
    ],
  );
}

class _CostSourceGuide extends StatelessWidget {
  const _CostSourceGuide({required this.costs});
  final List<MaterialCostRecord> costs;

  @override
  Widget build(BuildContext context) {
    final linked = costs.where((record) => record.hasExpenseSource).length;
    return _InventorySection(
      title: 'Cost sources',
      icon: Icons.link_outlined,
      children: [
        ListTile(
          title: const Text('Linked expense records'),
          trailing: Text('$linked'),
        ),
        ListTile(
          title: const Text('Direct verified entries'),
          trailing: Text('${costs.length - linked}'),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Text(
            'A linked expense remains the financial source. Receipt-derived '
            'details remain proposals until a person reviews and confirms them.',
          ),
        ),
      ],
    );
  }
}

class _InventoryCalendar extends StatelessWidget {
  const _InventoryCalendar({
    required this.costs,
    required this.maximumWidth,
    required this.onDaySelected,
  });
  final List<MaterialCostRecord> costs;
  final double maximumWidth;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Materials calendar',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        WorkMonthCalendar(
          maximumWidth: maximumWidth,
          selectedDay: inventoryDemoToday,
          entryCountForDay: (day) => costs
              .where((record) => DateUtils.isSameDay(record.purchasedOn, day))
              .length,
          recordKind: CalendarRecordKind.inventoryRecord,
          onDaySelected: onDaySelected,
        ),
      ],
    );
  }
}

class _InventorySection extends StatelessWidget {
  const _InventorySection({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        ListTile(
          minTileHeight: 48,
          tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          leading: Icon(icon),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        ...children,
      ],
    ),
  );
}
