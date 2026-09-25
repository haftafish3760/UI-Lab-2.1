part of 'receipt_capture_models.dart';

List<String> _nativeSettingsControlHealthCodes(
  Map<String, Object?> diagnostics,
  String? controlSet,
) {
  final expected = diagnostics['settingsControlExpected'] == true;
  final controls = (controlSet ?? '')
      .split('|')
      .map((control) => control.trim())
      .where((control) => control.isNotEmpty)
      .toSet();
  final codes = <String>[];
  if (expected && controls.contains('settings')) {
    codes.add('settings_control_visible');
  } else if (expected) {
    codes.add('settings_control_missing');
  }

  final contract = diagnostics['settingsContractVersion']?.toString().trim();
  if (contract == 'receipt_native_camera_settings_v1') {
    codes.add('settings_contract_v1');
  } else if (expected) {
    codes.add('settings_contract_missing');
  }

  final placement = diagnostics['settingsButtonPlacement']?.toString().trim();
  if (placement == 'top_bar_right') {
    codes.add('settings_button_top_bar_right');
  } else if (expected) {
    codes.add('settings_button_placement_missing');
  }

  final openCount = diagnostics['settingsOpenCount'];
  if (openCount is num && openCount.isFinite && openCount > 0) {
    codes.add('settings_opened');
  } else if (openCount is num && openCount.isFinite) {
    codes.add('settings_not_opened');
  }
  return List.unmodifiable(codes);
}
