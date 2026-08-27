import 'package:flutter/material.dart';

import 'screens/dashboard/dashboard_screen.dart';
import 'theme/app_theme.dart';

class UiLabApp extends StatelessWidget {
  const UiLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maintainiac UI Lab 2.1',
      theme: AppTheme.light,
      home: const DashboardScreen(),
    );
  }
}
