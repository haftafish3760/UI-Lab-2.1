import 'package:flutter/widgets.dart';
import '../data/account/account_gateway.dart';

class AccountScope extends InheritedWidget {
  const AccountScope({required this.gateway, required super.child, super.key});
  final AccountGateway gateway;
  static AccountGateway? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccountScope>()?.gateway;
  @override
  bool updateShouldNotify(AccountScope oldWidget) =>
      gateway != oldWidget.gateway;
}
