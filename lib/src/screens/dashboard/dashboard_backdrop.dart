import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Opaque layered background for the Dashboard workspace.
///
/// It keeps the working canvas distinct from both pure white and solid black
/// while leaving semantic color to the operational sections themselves.
class DashboardBackdrop extends StatelessWidget {
  const DashboardBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      key: const ValueKey('dashboard-backdrop'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [AppColors.darkCanvas, AppColors.darkCanvasDeep]
              : const [AppColors.canvas, AppColors.surfaceMuted],
        ),
      ),
      child: child,
    );
  }
}
