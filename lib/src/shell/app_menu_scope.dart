import 'package:flutter/widgets.dart';

/// Makes the one global operations menu available to every shared header.
class AppMenuScope extends InheritedWidget {
  const AppMenuScope({required this.onOpen, required super.child, super.key});

  final VoidCallback onOpen;

  static VoidCallback? maybeOpenOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppMenuScope>()?.onOpen;

  @override
  bool updateShouldNotify(AppMenuScope oldWidget) => onOpen != oldWidget.onOpen;
}
