import 'package:flutter/material.dart';
import '../../../layout/app_layout_engine.dart';
import '../../../shared/section_card.dart';
import '../inventory_models.dart';
import 'inventory_catalog.dart';
import 'inventory_catalog_item_screen.dart';
import 'materials_catalog_labels.dart';
import '../../../../l10n/app_localizations_extension.dart';

/// Catalog identity is shown before entering the separately owned stock form.
class MaterialsCatalogItemDetails extends StatelessWidget {
  const MaterialsCatalogItemDetails({
    required this.item,
    required this.records,
    super.key,
  });
  final InventoryCatalogItem item;
  final List<InventoryStockRecord> records;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.catalogItemDetails)),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
        final width = AppLayoutEngine.formWorkspaceWidthFor(
          constraints.maxWidth - insets.horizontal,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: ListView(
              padding: insets.add(const EdgeInsets.symmetric(vertical: 16)),
              children: [
                Text(
                  item.path
                      .map((part) => materialsBranchLabel(context, part))
                      .join(' / '),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        materialsItemLabel(context, item),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.catalogSize(item.variant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.catalogUnit(
                          materialsUnitLabel(context, item.unit),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.catalogAdd),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => InventoryCatalogItemScreen(
                        item: item,
                        records: records,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
