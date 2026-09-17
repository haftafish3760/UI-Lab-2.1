import 'work_supply_color.dart';
import 'work_supply_item_identity_resolver.dart';
import 'work_supply_models.dart';

part 'work_supply_catalog_search.dart';
part 'work_supply_catalog_sizes.dart';
part 'work_supply_catalog_intelligence.dart';
part 'work_supply_electrical_catalog_intelligence.dart';
part 'work_supply_hvac_catalog_intelligence.dart';
part 'work_supply_catalog_tier_signals.dart';
part 'work_supply_catalog_hvac_and_general_signals.dart';
part 'work_supply_catalog_metadata_builders.dart';
part 'work_supply_catalog_trade_metadata_helpers.dart';
part 'work_supply_catalog_shape_signals.dart';
part 'work_supply_electrical_metadata_intelligence.dart';
part 'work_supply_plumbing_catalog_intelligence.dart';
part 'work_supply_plumbing_catalog_tier_constants.dart';
part 'work_supply_plumbing_metadata_intelligence.dart';
part 'catalog/plumbing/plumbing_catalog.dart';
part 'catalog/plumbing/fittings/copper.dart';
part 'catalog/plumbing/fittings/pvc_schedule_40.dart';
part 'catalog/plumbing/fittings/cpvc.dart';
part 'catalog/plumbing/fittings/pex.dart';
part 'catalog/plumbing/fittings/black_iron.dart';
part 'catalog/plumbing/fittings/galvanized_steel.dart';
part 'catalog/plumbing/fittings/brass.dart';
part 'catalog/plumbing/fittings/push_fit.dart';
part 'catalog/plumbing/fittings/cast_iron_and_no_hub.dart';
part 'catalog/plumbing/fittings/pvc_dwv.dart';
part 'catalog/plumbing/fittings/abs_dwv.dart';
part 'catalog/plumbing/generated_plumbing_items.dart';
part 'catalog/plumbing/generated_plumbing_service_truck_catalog.dart';
part 'catalog/plumbing/generated_plumbing_service_truck_tools_catalog.dart';
part 'catalog/plumbing/generated_plumbing_drain_finish_catalog.dart';
part 'catalog/plumbing/generated_plumbing_seals_service_catalog.dart';
part 'catalog/plumbing/fittings/fittings_catalog.dart';
part 'catalog/plumbing/pipe_and_tubing/pipe_and_tubing_catalog.dart';
part 'catalog/plumbing/valves/valves_catalog.dart';
part 'catalog/plumbing/supply_lines/supply_lines_catalog.dart';
part 'catalog/plumbing/drainage_waste_vent/drainage_waste_vent_catalog.dart';
part 'catalog/plumbing/toilet_repair/toilet_repair_catalog.dart';
part 'catalog/plumbing/sink_and_faucet_repair/sink_and_faucet_repair_catalog.dart';
part 'catalog/plumbing/shower_and_tub_repair/shower_and_tub_repair_catalog.dart';
part 'catalog/plumbing/water_heater/water_heater_catalog.dart';
part 'catalog/plumbing/pumps/pumps_catalog.dart';
part 'catalog/plumbing/hangers_and_supports/hangers_and_supports_catalog.dart';
part 'catalog/plumbing/consumables/consumables_catalog.dart';
part 'catalog/electrical/electrical_catalog.dart';
part 'catalog/electrical/wire_and_cable/wire_and_cable_catalog.dart';
part 'catalog/electrical/breakers/breakers_catalog.dart';
part 'catalog/electrical/devices/devices_catalog.dart';
part 'catalog/electrical/boxes_and_covers/boxes_and_covers_catalog.dart';
part 'catalog/electrical/conduit_and_fittings/conduit_and_fittings_catalog.dart';
part 'catalog/electrical/connectors_and_consumables/connectors_and_consumables_catalog.dart';
part 'catalog/electrical/grounding_and_bonding/grounding_and_bonding_catalog.dart';
part 'catalog/electrical/panels_and_service_equipment/panels_and_service_equipment_catalog.dart';
part 'catalog/electrical/lighting/lighting_catalog.dart';
part 'catalog/electrical/generated_electrical_support.dart';
part 'catalog/electrical/generated_electrical_service_catalog.dart';
part 'catalog/electrical/electrical_core_supplemental_catalog.dart';
part 'catalog/electrical/generated_electrical_bulk_catalog.dart';
part 'catalog/hvac/hvac_catalog.dart';
part 'catalog/hvac/air_filters/air_filters_catalog.dart';
part 'catalog/hvac/controls_and_electrical/controls_and_electrical_catalog.dart';
part 'catalog/hvac/refrigerant_lines/refrigerant_lines_catalog.dart';
part 'catalog/hvac/ductwork_and_air_distribution/ductwork_and_air_distribution_catalog.dart';
part 'catalog/hvac/condensate/condensate_catalog.dart';
part 'catalog/hvac/tape_and_sealants/tape_and_sealants_catalog.dart';
part 'catalog/hvac/motors_and_blower_parts/motors_and_blower_parts_catalog.dart';
part 'catalog/hvac/ignition_and_gas_heat/ignition_and_gas_heat_catalog.dart';
part 'catalog/hvac/refrigerant_service/refrigerant_service_catalog.dart';
part 'catalog/hvac/generated_hvac_service_catalog.dart';
part 'catalog/hvac/hvac_core_supplemental_catalog.dart';
part 'catalog/hvac/generated_hvac_detail_catalog.dart';
part 'catalog/hvac/detail/hvac_filter_iaq_and_air_distribution_detail_catalog.dart';
part 'catalog/hvac/detail/hvac_controls_lines_and_condensate_detail_catalog.dart';
part 'catalog/hvac/detail/hvac_equipment_and_service_detail_catalog.dart';
part 'catalog/hvac/generated_hvac_system_catalog.dart';
part 'catalog/hvac/generated_hvac_equipment_catalog.dart';
part 'catalog/hvac/generated_hvac_service_truck_catalog.dart';
part 'catalog/hvac/generated_hvac_service_truck_controls_catalog.dart';
part 'catalog/hvac/generated_hvac_service_truck_airflow_catalog.dart';
part 'catalog/hvac/generated_hvac_service_truck_vent_gas_catalog.dart';
part 'catalog/hvac/generated_hvac_service_truck_diagnostics_catalog.dart';
part 'catalog/hvac/generated_hvac_service_truck_hydronic_catalog.dart';
part 'catalog/hvac/generated_hvac_service_truck_rtu_catalog.dart';
part 'catalog/carpentry/carpentry_catalog.dart';
part 'catalog/carpentry/lumber/lumber_catalog.dart';
part 'catalog/carpentry/sheet_goods/sheet_goods_catalog.dart';
part 'catalog/carpentry/fasteners/fasteners_catalog.dart';
part 'catalog/carpentry/trim_and_hardware/trim_and_hardware_catalog.dart';
part 'catalog/carpentry/connectors_and_framing_hardware/connectors_and_framing_hardware_catalog.dart';
part 'catalog/carpentry/adhesives_and_sealants/adhesives_and_sealants_catalog.dart';
part 'catalog/carpentry/decking_and_exterior_wood/decking_and_exterior_wood_catalog.dart';
part 'catalog/carpentry/generated_carpentry_service_catalog.dart';
part 'catalog/carpentry/generated_carpentry_detail_catalog.dart';
part 'catalog/cabinets_countertops/cabinets_countertops_catalog.dart';
part 'catalog/cabinets_countertops/generated_cabinets_countertops_detail_catalog.dart';
part 'catalog/windows_doors/windows_doors_catalog.dart';
part 'catalog/windows_doors/generated_windows_doors_detail_catalog.dart';
part 'catalog/garage_doors_openers/garage_doors_openers_catalog.dart';
part 'catalog/garage_doors_openers/generated_garage_doors_openers_detail_catalog.dart';
part 'catalog/appliance_installation_repair/appliance_installation_repair_catalog.dart';
part 'catalog/appliance_installation_repair/generated_appliance_installation_repair_detail_catalog.dart';
part 'catalog/well_septic_water_treatment/well_septic_water_treatment_catalog.dart';
part 'catalog/well_septic_water_treatment/generated_well_septic_water_treatment_detail_catalog.dart';
part 'catalog/insulation/insulation_catalog.dart';
part 'catalog/insulation/batt_insulation/batt_insulation_catalog.dart';
part 'catalog/insulation/foam_and_air_sealing/foam_and_air_sealing_catalog.dart';
part 'catalog/insulation/blown_insulation/blown_insulation_catalog.dart';
part 'catalog/insulation/vapor_barriers_and_accessories/vapor_barriers_and_accessories_catalog.dart';
part 'catalog/insulation/generated_insulation_service_catalog.dart';
part 'catalog/insulation/generated_insulation_detail_catalog.dart';
part 'catalog/drywall/drywall_catalog.dart';
part 'catalog/painting/painting_catalog.dart';
part 'catalog/drywall/panels_and_board/panels_and_board_catalog.dart';
part 'catalog/drywall/compound_and_mud/compound_and_mud_catalog.dart';
part 'catalog/drywall/tape_bead_and_trim/tape_bead_and_trim_catalog.dart';
part 'catalog/drywall/texture_and_patch/texture_and_patch_catalog.dart';
part 'catalog/drywall/fasteners_and_adhesives/fasteners_and_adhesives_catalog.dart';
part 'catalog/drywall/generated_drywall_service_catalog.dart';
part 'catalog/drywall/generated_drywall_detail_catalog.dart';
part 'catalog/painting/paint/paint_catalog.dart';
part 'catalog/painting/paint_prep_and_supplies/paint_prep_and_supplies_catalog.dart';
part 'catalog/painting/caulk_and_patch/caulk_and_patch_catalog.dart';
part 'catalog/painting/generated_painting_service_catalog.dart';
part 'catalog/painting/generated_painting_detail_catalog.dart';
part 'catalog/tile/tile_catalog.dart';
part 'catalog/tile/tile_materials/tile_materials_catalog.dart';
part 'catalog/tile/setting_materials/setting_materials_catalog.dart';
part 'catalog/tile/waterproofing/waterproofing_catalog.dart';
part 'catalog/tile/tools_and_accessories/tools_and_accessories_catalog.dart';
part 'catalog/tile/generated_tile_service_catalog.dart';
part 'catalog/tile/generated_tile_surface_catalog.dart';
part 'catalog/tile/generated_tile_install_catalog.dart';
part 'catalog/tile/generated_tile_field_catalog.dart';
part 'catalog/flooring/flooring_catalog.dart';
part 'catalog/flooring/generated_flooring_detail_catalog.dart';
part 'catalog/roofing/roofing_catalog.dart';
part 'catalog/roofing/roof_covering/roof_covering_catalog.dart';
part 'catalog/roofing/flashing_and_sealants/flashing_and_sealants_catalog.dart';
part 'catalog/roofing/vents_and_roof_accessories/vents_and_roof_accessories_catalog.dart';
part 'catalog/roofing/gutters_and_drainage/gutters_and_drainage_catalog.dart';
part 'catalog/roofing/generated_roofing_service_catalog.dart';
part 'catalog/roofing/generated_roofing_detail_catalog.dart';
part 'catalog/siding_exterior/siding_exterior_catalog.dart';
part 'catalog/siding_exterior/generated_siding_exterior_detail_catalog.dart';
part 'catalog/fencing/fencing_catalog.dart';
part 'catalog/fencing/generated_fencing_service_catalog.dart';
part 'catalog/fencing/generated_fencing_detail_catalog.dart';
part 'catalog/fencing/generated_fencing_field_catalog.dart';
part 'catalog/masonry_concrete/masonry_concrete_catalog.dart';
part 'catalog/masonry_concrete/concrete/concrete_catalog.dart';
part 'catalog/masonry_concrete/masonry_materials/masonry_materials_catalog.dart';
part 'catalog/masonry_concrete/reinforcement_and_forms/reinforcement_and_forms_catalog.dart';
part 'catalog/masonry_concrete/anchors_and_repair/anchors_and_repair_catalog.dart';
part 'catalog/masonry_concrete/generated_masonry_concrete_service_catalog.dart';
part 'catalog/masonry_concrete/generated_masonry_concrete_detail_catalog.dart';
part 'catalog/landscaping/landscaping_catalog.dart';
part 'catalog/landscaping/irrigation/irrigation_catalog.dart';
part 'catalog/landscaping/drainage_and_erosion/drainage_and_erosion_catalog.dart';
part 'catalog/landscaping/hardscape/hardscape_catalog.dart';
part 'catalog/landscaping/generated_landscaping_service_catalog.dart';
part 'catalog/landscaping/generated_landscaping_detail_catalog.dart';
part 'catalog/low_voltage_data/low_voltage_data_catalog.dart';
part 'catalog/low_voltage_data/cable/cable_catalog.dart';
part 'catalog/low_voltage_data/terminations/terminations_catalog.dart';
part 'catalog/low_voltage_data/boxes_and_plates/boxes_and_plates_catalog.dart';
part 'catalog/low_voltage_data/testers_and_tools/testers_and_tools_catalog.dart';
part 'catalog/low_voltage_data/generated_low_voltage_data_service_catalog.dart';
part 'catalog/low_voltage_data/generated_low_voltage_data_detail_catalog.dart';
part 'catalog/tools_safety/tools_safety_catalog.dart';
part 'catalog/tools_safety/tools/tools_catalog.dart';
part 'catalog/tools_safety/safety/safety_catalog.dart';
part 'catalog/tools_safety/measuring_and_layout/measuring_and_layout_catalog.dart';
part 'catalog/tools_safety/adhesives_and_general_consumables/adhesives_and_general_consumables_catalog.dart';
part 'catalog/tools_safety/generated_tools_safety_service_catalog.dart';
part 'catalog/tools_safety/generated_tools_safety_detail_catalog.dart';

final workSupplyTrades = _hydrateTrades(<WorkSupplyTrade>[
  plumbingCatalog,
  electricalCatalog,
  hvacCatalog,
  carpentryCatalog,
  drywallCatalog,
  paintingCatalog,
  roofingCatalog,
  tileCatalog,
  cabinetsCountertopsCatalog,
  windowsDoorsCatalog,
  garageDoorsOpenersCatalog,
  applianceInstallationRepairCatalog,
  wellSepticWaterTreatmentCatalog,
  flooringCatalog,
  insulationCatalog,
  sidingExteriorCatalog,
  fencingCatalog,
  masonryConcreteCatalog,
  landscapingCatalog,
  lowVoltageDataCatalog,
  toolsSafetyCatalog,
]);

final Map<String, WorkSupplyItem> _workSupplyCatalogItemsById = {};

final workSupplyCatalogItems = _dedupeWorkSupplyCatalogItems([
  for (final trade in workSupplyTrades)
    for (final category in trade.categories)
      for (final system in category.systems)
        for (final type in system.itemTypes) ...type.items,
]);

List<WorkSupplyItem> _dedupeWorkSupplyCatalogItems(List<WorkSupplyItem> items) {
  final byKey = <String, WorkSupplyItem>{};
  for (final item in items) {
    final key = tradeScopedWorkSupplyItemKey(item);
    final existing = byKey[key];
    if (existing == null || _isExpandedCatalogItem(existing)) {
      byKey[key] = item;
    }
  }
  final deduped = byKey.values.toList();
  _workSupplyCatalogItemsById
    ..clear()
    ..addEntries(deduped.map((item) => MapEntry(item.id, item)));
  return deduped;
}

WorkSupplyItem? workSupplyCatalogItemById(String id) =>
    _workSupplyCatalogItemsById[id.trim()];

WorkSupplyTrade _trade(
  String name,
  Color color,
  List<WorkSupplyCategory> categories,
) {
  return WorkSupplyTrade(name: name, color: color, categories: categories);
}

WorkSupplyCategory _category(String name, List<WorkSupplySystem> systems) {
  return WorkSupplyCategory(name: name, systems: systems);
}

WorkSupplySystem _system(String name, List<WorkSupplyItemType> itemTypes) {
  return WorkSupplySystem(name: name, itemTypes: itemTypes);
}

WorkSupplyItemType _type(String name, List<WorkSupplyItem> items) {
  return WorkSupplyItemType(name: name, items: items);
}

List<WorkSupplyItem> _variants(
  String baseName,
  String unit,
  List<String> variants,
  List<String> aliases,
) {
  return [
    for (final variant in variants)
      WorkSupplyItem(
        id: '',
        name: '$variant $baseName',
        trade: '',
        category: '',
        system: '',
        itemType: '',
        variant: variant,
        unit: unit,
        aliases: aliases,
      ),
  ];
}

List<WorkSupplyTrade> _hydrateTrades(List<WorkSupplyTrade> trades) {
  var itemNumber = 0;
  return [
    for (final trade in trades)
      WorkSupplyTrade(
        name: trade.name,
        color: trade.color,
        categories: [
          for (final category in trade.categories)
            WorkSupplyCategory(
              name: category.name,
              systems: [
                for (final system in category.systems)
                  WorkSupplySystem(
                    name: system.name,
                    itemTypes: [
                      for (final type in system.itemTypes)
                        WorkSupplyItemType(
                          name: type.name,
                          items: [
                            for (final item in type.items)
                              _hydrateCatalogItem(
                                id: _sequentialItemId(++itemNumber),
                                source: item,
                                tradeName: trade.name,
                                categoryName: category.name,
                                systemName: system.name,
                                itemTypeName: type.name,
                              ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
        ],
      ),
  ];
}

String _sequentialItemId(int value) {
  return 'MI-${value.toString().padLeft(3, '0')}';
}

WorkSupplyItem _hydrateCatalogItem({
  required String id,
  required WorkSupplyItem source,
  required String tradeName,
  required String categoryName,
  required String systemName,
  required String itemTypeName,
}) {
  final hydrated = WorkSupplyItem(
    id: id,
    name: source.name,
    trade: tradeName,
    category: categoryName,
    system: systemName,
    itemType: itemTypeName,
    variant: source.variant,
    unit: source.unit,
    aliases: source.aliases,
    marketScopes: source.marketScopes,
    packTier: source.packTier,
    parserPriority: source.parserPriority,
    intelligence: source.intelligence,
  );
  final resolvedAliases = _resolveWorkSupplyAliases(hydrated);
  final aliased = WorkSupplyItem(
    id: hydrated.id,
    name: hydrated.name,
    trade: hydrated.trade,
    category: hydrated.category,
    system: hydrated.system,
    itemType: hydrated.itemType,
    variant: hydrated.variant,
    unit: hydrated.unit,
    aliases: resolvedAliases,
    marketScopes: hydrated.marketScopes,
    packTier: hydrated.packTier,
    parserPriority: hydrated.parserPriority,
    intelligence: hydrated.intelligence,
  );
  return WorkSupplyItem(
    id: aliased.id,
    name: aliased.name,
    trade: aliased.trade,
    category: aliased.category,
    system: aliased.system,
    itemType: aliased.itemType,
    variant: aliased.variant,
    unit: aliased.unit,
    aliases: aliased.aliases,
    marketScopes: _resolveWorkSupplyMarketScopes(aliased),
    packTier: _resolveWorkSupplyPackTier(aliased),
    parserPriority: _resolveWorkSupplyParserPriority(aliased),
    intelligence: _resolveWorkSupplyItemIntelligence(aliased),
  );
}
