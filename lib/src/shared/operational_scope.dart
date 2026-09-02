import 'package:flutter/widgets.dart';

import 'app_view_mode.dart';

class OperationalScopeController extends ChangeNotifier {
  OperationalScopeController({
    AppViewMode view = AppViewMode.technician,
    String technicianEmployeeId = 'alex',
    this._selectedVehicleId = 'transit-12',
    String? initialInventoryScopeVehicleId,
  }) : _view = view,
       _technicianEmployeeId = technicianEmployeeId,
       _inventoryVehicleId = initialInventoryScopeVehicleId,
       _selectedEmployeeId = view == AppViewMode.technician
           ? technicianEmployeeId
           : null;

  final String _technicianEmployeeId;
  AppViewMode _view;
  String? _selectedEmployeeId;
  String _selectedVehicleId;
  String? _inventoryVehicleId;
  final Map<String, int> _confirmedOdometerTenths = {
    'transit-12': 421164,
    'service-van-4': 189087,
    'pickup-2': 762041,
  };

  AppViewMode get view => _view;
  String? get selectedEmployeeId => _selectedEmployeeId;
  String get selectedVehicleId => _selectedVehicleId;
  String? get inventoryVehicleId => _view == AppViewMode.technician
      ? _selectedVehicleId
      : _inventoryVehicleId;

  int confirmedOdometerTenthsFor(String vehicleId) =>
      _confirmedOdometerTenths[vehicleId] ?? 0;

  void setView(AppViewMode value) {
    if (_view == value) return;
    _view = value;
    _selectedEmployeeId = value == AppViewMode.admin
        ? null
        : _technicianEmployeeId;
    notifyListeners();
  }

  void selectEmployee(String? employeeId) {
    final next = _view == AppViewMode.technician
        ? _technicianEmployeeId
        : employeeId;
    if (_selectedEmployeeId == next) return;
    _selectedEmployeeId = next;
    notifyListeners();
  }

  void selectVehicle(String vehicleId) {
    if (_selectedVehicleId == vehicleId) return;
    _selectedVehicleId = vehicleId;
    notifyListeners();
  }

  void selectInventoryVehicle(String? vehicleId) {
    if (_view == AppViewMode.technician) {
      if (vehicleId != null) selectVehicle(vehicleId);
      return;
    }
    if (_inventoryVehicleId == vehicleId) return;
    _inventoryVehicleId = vehicleId;
    notifyListeners();
  }

  bool confirmOdometer({
    required String vehicleId,
    required int readingTenths,
  }) {
    final previous = _confirmedOdometerTenths[vehicleId] ?? 0;
    if (readingTenths < previous) return false;
    if (previous == readingTenths) return true;
    _confirmedOdometerTenths[vehicleId] = readingTenths;
    notifyListeners();
    return true;
  }
}

class OperationalScope extends InheritedNotifier<OperationalScopeController> {
  const OperationalScope({
    required OperationalScopeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static OperationalScopeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OperationalScope>();
    assert(scope != null, 'OperationalScope is missing above this route.');
    return scope!.notifier!;
  }
}
