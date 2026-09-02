import 'package:flutter/material.dart';

class ExpensePermissionDeniedScaffold extends StatelessWidget {
  const ExpensePermissionDeniedScaffold({
    required this.message,
    required this.screenKey,
    super.key,
  });

  final String message;
  final Key screenKey;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: screenKey,
    body: SafeArea(child: Center(child: Text(message))),
  );
}
