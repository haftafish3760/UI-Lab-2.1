import 'package:flutter/material.dart';
import '../../data/expenses/expense_workflow_models.dart';

/// Icons belong to presentation; category identities and wire names stay stable.
extension ExpenseCategoryPresentation on ExpenseCategory {
  IconData get icon => switch (this) {
    ExpenseCategory.materials => Icons.inventory_2_outlined,
    ExpenseCategory.consumables => Icons.cleaning_services_outlined,
    ExpenseCategory.fuel => Icons.local_gas_station_outlined,
    ExpenseCategory.vehiclePayment => Icons.directions_car_filled_outlined,
    ExpenseCategory.vehicleInsurance => Icons.verified_user_outlined,
    ExpenseCategory.vehicleRepair => Icons.car_repair_outlined,
    ExpenseCategory.vehicleMaintenance => Icons.build_circle_outlined,
    ExpenseCategory.vehicle => Icons.local_shipping_outlined,
    ExpenseCategory.tools => Icons.handyman_outlined,
    ExpenseCategory.subcontractor => Icons.groups_outlined,
    ExpenseCategory.office => Icons.business_center_outlined,
    ExpenseCategory.rent => Icons.warehouse_outlined,
    ExpenseCategory.utilities => Icons.bolt_outlined,
    ExpenseCategory.phoneInternet => Icons.cell_tower_outlined,
    ExpenseCategory.licensesTaxes => Icons.account_balance_outlined,
    ExpenseCategory.advertising => Icons.campaign_outlined,
    ExpenseCategory.training => Icons.school_outlined,
    ExpenseCategory.banking => Icons.credit_card_outlined,
    ExpenseCategory.travel => Icons.route_outlined,
    ExpenseCategory.other => Icons.receipt_long_outlined,
  };
}
