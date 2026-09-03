import 'package:flutter/material.dart';

import 'dashboard/dashboard_screen.dart';
import 'theme/app_theme.dart';

class MaintainiacApp extends StatefulWidget {
  const MaintainiacApp({super.key});

  @override
  State<MaintainiacApp> createState() => _MaintainiacAppState();
}

class _MaintainiacAppState extends State<MaintainiacApp> {
  var themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Maintainiac Dashboard',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: themeMode,
    home: DashboardScreen(
      onToggleTheme: () => setState(
        () => themeMode = themeMode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light,
      ),
    ),
  );
}
