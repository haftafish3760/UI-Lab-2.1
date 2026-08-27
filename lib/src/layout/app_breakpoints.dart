import 'package:flutter/widgets.dart';

enum AppLayoutClass { phone, tablet, desktop }

abstract final class AppBreakpoints {
  static const tablet = 600.0;
  static const desktop = 1200.0;

  static AppLayoutClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return AppLayoutClass.desktop;
    if (width >= tablet) return AppLayoutClass.tablet;
    return AppLayoutClass.phone;
  }
}
