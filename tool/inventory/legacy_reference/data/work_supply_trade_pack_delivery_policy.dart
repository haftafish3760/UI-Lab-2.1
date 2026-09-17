import 'work_supply_trade_pack_base_bundle_policy.dart';

class WorkSupplyTradePackDeliveryPolicy {
  const WorkSupplyTradePackDeliveryPolicy({
    required this.localMode,
    required this.cloudMode,
    required this.cloudRequiresSubscription,
    required this.cloudRequiresInternet,
    required this.cloudReadBudgetPerReceipt,
    required this.cloudReadBudgetPerUserPerDay,
  });

  final String localMode;
  final String cloudMode;
  final bool cloudRequiresSubscription;
  final bool cloudRequiresInternet;
  final int cloudReadBudgetPerReceipt;
  final int cloudReadBudgetPerUserPerDay;

  Map<String, Object?> toMap() {
    return {
      'deliveryModes': [localMode, cloudMode],
      'baseInstall': workSupplyTradePackBaseBundlePolicy.toMap(),
      'local': {
        'mode': localMode,
        'offlineCapable': true,
        'fastest': true,
        'requiresDeviceStorage': true,
      },
      'cloudFallback': {
        'mode': cloudMode,
        'offlineCapable': false,
        'requiresInternet': cloudRequiresInternet,
        'requiresSubscription': cloudRequiresSubscription,
        'slowerThanLocal': true,
        'usesCarrierOrWifiData': true,
        'targetCatalogReadsPerReceipt': cloudReadBudgetPerReceipt,
        'targetCatalogReadsPerUserPerDay': cloudReadBudgetPerUserPerDay,
      },
    };
  }
}

const workSupplyTradePackDeliveryPolicy = WorkSupplyTradePackDeliveryPolicy(
  localMode: 'local_gzip_pack',
  cloudMode: 'cloud_catalog_query',
  cloudRequiresSubscription: true,
  cloudRequiresInternet: true,
  cloudReadBudgetPerReceipt: 100,
  cloudReadBudgetPerUserPerDay: 100,
);
