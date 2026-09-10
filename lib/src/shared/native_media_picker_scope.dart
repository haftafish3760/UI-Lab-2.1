import 'package:flutter/widgets.dart';
import '../data/storage/native_media_picker_coordinator.dart';

class NativeMediaPickerScope extends InheritedWidget {
  const NativeMediaPickerScope({
    required this.coordinator,
    required super.child,
    super.key,
  });
  final NativeMediaPickerCoordinator coordinator;
  static NativeMediaPickerCoordinator? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<NativeMediaPickerScope>()
      ?.coordinator;
  @override
  bool updateShouldNotify(NativeMediaPickerScope oldWidget) =>
      !identical(coordinator, oldWidget.coordinator);
}
