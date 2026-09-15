/// Stable expense category identities, including the 5.7 receipt list.
enum ExpenseCategory {
  uncategorized('No category'),
  materials('Materials'),
  consumables('Consumables'),
  fuel('Fuel'),
  vehiclePayment('Vehicle payments'),
  vehicleInsurance('Vehicle insurance'),
  vehicleRepair('Vehicle repairs'),
  vehicleMaintenance('Vehicle maintenance'),
  vehicle('Other vehicle costs'),
  tools('Tools and equipment'),
  subcontractor('Subcontractors'),
  office('Office and business'),
  rent('Rent and storage'),
  utilities('Utilities'),
  phoneInternet('Phone and internet'),
  licensesTaxes('Licenses and taxes'),
  advertising('Advertising'),
  training('Training'),
  banking('Banking and fees'),
  travel('Meals and travel'),
  other('Other'),
  receiptRepair('Repair'),
  receiptMaintenance('Maintenance'),
  receiptInsurance('Insurance'),
  receiptParking('Parking'),
  receiptTolls('Tolls'),
  receiptMeals('Meals'),
  receiptTools('Tools'),
  receiptCellPhone('Cell Phone'),
  receiptRegistration('Registration'),
  receiptLoanLease('Loan/Lease'),
  receiptBackgroundChecks('Background Checks'),
  receiptCarAccessories('Car Accessories'),
  receiptChargingFees('Charging Fees'),
  receiptCleaningSupplies('Cleaning Supplies'),
  receiptCommissions('Commissions'),
  receiptContractLabor('Contract Labor'),
  receiptDeliveryBags('Delivery Bags'),
  receiptDispatchFees('Dispatch Fees'),
  receiptEquipment('Equipment'),
  receiptEquipmentRental('Equipment Rental'),
  receiptFuelAdditives('Fuel Additives'),
  receiptHomeOffice('Home Office'),
  receiptInternet('Internet'),
  receiptLaundry('Laundry'),
  receiptLicenses('Licenses'),
  receiptLodging('Lodging'),
  receiptMedical('Medical'),
  receiptOfficeSupplies('Office Supplies'),
  receiptPassengerAmenities('Passenger Amenities'),
  receiptPermits('Permits'),
  receiptPlatformFees('Platform Fees'),
  receiptPostage('Postage'),
  receiptPrinting('Printing'),
  receiptRent('Rent'),
  receiptRoadsideHelp('Roadside Help'),
  receiptSafetyGear('Safety Gear'),
  receiptStorage('Storage'),
  receiptSubscriptions('Subscriptions'),
  receiptToolRental('Tool Rental'),
  receiptTravel('Travel'),
  receiptUniforms('Uniforms'),
  receiptVehicleParts('Vehicle Parts'),
  receiptVehicleSupplies('Vehicle Supplies'),
  receiptVehicleWash('Vehicle Wash'),
  receiptWasteDisposal('Waste Disposal'),
  receiptBusinessLicense('Business License');

  const ExpenseCategory(this.label);
  final String label;

  String? get storageId => this == uncategorized ? null : name;
  String? get storageLabel => this == uncategorized ? null : label;
  static ExpenseCategory fromStorageId(String? id) =>
      id == null ? uncategorized : values.byName(id);
}

const commonReceiptCategories = <ExpenseCategory>[
  ExpenseCategory.fuel,
  ExpenseCategory.receiptRepair,
  ExpenseCategory.receiptMaintenance,
  ExpenseCategory.receiptInsurance,
  ExpenseCategory.receiptParking,
  ExpenseCategory.receiptTolls,
  ExpenseCategory.receiptMeals,
  ExpenseCategory.receiptTools,
  ExpenseCategory.materials,
  ExpenseCategory.receiptCellPhone,
  ExpenseCategory.receiptRegistration,
  ExpenseCategory.receiptLoanLease,
];

/// The receipt-specific 5.7 list. Older, broader category IDs stay readable
/// for existing records but are not offered as competing new classifications.
final receiptCategories = List<ExpenseCategory>.unmodifiable(
  ExpenseCategory.values.where(
    (category) =>
        category.name.startsWith('receipt') ||
        const {
          ExpenseCategory.fuel,
          ExpenseCategory.materials,
          ExpenseCategory.advertising,
          ExpenseCategory.training,
          ExpenseCategory.utilities,
        }.contains(category),
  ),
);
