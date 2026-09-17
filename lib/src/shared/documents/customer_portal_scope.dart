import 'package:flutter/widgets.dart';
import 'customer_portal_gateway.dart';

class CustomerPortalScope extends InheritedWidget {
  const CustomerPortalScope({
    required this.gateway,
    required super.child,
    super.key,
  });
  final CustomerPortalGateway gateway;
  static CustomerPortalGateway? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<CustomerPortalScope>()
      ?.gateway;
  @override
  bool updateShouldNotify(CustomerPortalScope oldWidget) =>
      gateway != oldWidget.gateway;
}
