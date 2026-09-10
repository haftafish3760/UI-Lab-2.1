/// Vehicle identity/configuration. Confirmed mileage is owned by the shared
/// odometer record, never a second formatted string in this profile.
class VehicleDirectoryProfile {
  const VehicleDirectoryProfile({
    required this.id,
    required this.name,
    required this.yearMakeModel,
    required this.assignment,
    this.active = true,
  });
  final String id;
  final String name;
  final String yearMakeModel;
  final String assignment;
  final bool active;
  String get status => active ? 'In service' : 'Inactive';

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'yearMakeModel': yearMakeModel,
    'assignment': assignment,
    'active': active,
  };

  factory VehicleDirectoryProfile.fromJson(Map<String, Object?> json) {
    final value = VehicleDirectoryProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      yearMakeModel: json['yearMakeModel'] as String,
      assignment: json['assignment'] as String,
      active: json['active'] as bool,
    );
    if (value.id.trim().isEmpty || value.name.trim().isEmpty) {
      throw const FormatException('Vehicle identity and name are required.');
    }
    return value;
  }
}
