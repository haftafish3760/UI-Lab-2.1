import 'package:flutter/material.dart';

/// Groups related fields without adding another card or horizontal inset.
/// The page owns its margins; each field keeps the available working width.
class UtilityFormSection extends StatelessWidget {
  const UtilityFormSection({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Semantics(container: true, explicitChildNodes: true, child: child);
}
