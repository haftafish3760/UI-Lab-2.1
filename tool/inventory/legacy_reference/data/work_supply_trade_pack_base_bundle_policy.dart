import 'work_supply_models.dart';
import 'work_supply_trade_pack_tiers.dart';

/// Declares the intended base-install pack set. It does not itself make the
/// current compiled catalog smaller; runtime catalog injection owns that next
/// step. Keeping this policy separate prevents a hosted/downloaded pack from
/// being mistaken for a base-bundled one.
class WorkSupplyTradePackBaseBundlePolicy {
  const WorkSupplyTradePackBaseBundlePolicy({
    required this.bundledTradeNames,
    required this.bundledTier,
    required this.bundledMarketScope,
    required this.bundledLocalePackId,
  });

  final Set<String> bundledTradeNames;
  final WorkSupplyTradePackTier bundledTier;
  final WorkSupplyMarketScope bundledMarketScope;
  final String bundledLocalePackId;

  bool isBundled(WorkSupplyTradePackOption option) {
    return bundledTradeNames.contains(option.tradeName) &&
        option.tier == bundledTier &&
        option.marketScope == bundledMarketScope &&
        option.localePackId == bundledLocalePackId;
  }

  bool isOptional(WorkSupplyTradePackOption option) => !isBundled(option);

  Map<String, Object?> toMap() {
    return {
      'baseInstallMode': 'bundled_peh_core_assets',
      'bundledTrades': bundledTradeNames.toList()..sort(),
      'bundledTier': bundledTier.id,
      'bundledMarketScope': bundledMarketScope.id,
      'bundledLocalePackId': bundledLocalePackId,
      'optionalTierDelivery': {
        'localDownload': 'free_offline_pack',
        'hostedAccess': 'opt_in_subscription_service',
        'firebaseWritesRequired': false,
      },
      'runtimeCatalogInjectionRequired': true,
      'currentCompiledCatalogIsNotStorageProof': true,
    };
  }
}

const workSupplyTradePackBaseBundlePolicy = WorkSupplyTradePackBaseBundlePolicy(
  bundledTradeNames: {'Plumbing', 'Electrical', 'HVAC'},
  bundledTier: WorkSupplyTradePackTier.core,
  bundledMarketScope: WorkSupplyMarketScope.residential,
  bundledLocalePackId: workSupplyDefaultLocalePackId,
);
