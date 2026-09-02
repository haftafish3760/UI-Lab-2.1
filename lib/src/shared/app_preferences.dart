import 'package:flutter/material.dart';

enum AppLanguage {
  english(Locale('en', 'US')),
  spanish(Locale('es', 'US')),
  french(Locale('fr', 'CA'));

  const AppLanguage(this.locale);

  final Locale locale;
}

enum AppMeasurementSystem { us, metric }

class AppPreferencesController extends ChangeNotifier {
  AppPreferencesController({
    ThemeMode initialThemeMode = ThemeMode.light,
    AppLanguage initialLanguage = AppLanguage.english,
    AppMeasurementSystem initialMeasurementSystem = AppMeasurementSystem.us,
  }) : _themeMode = initialThemeMode,
       _language = initialLanguage,
       _measurementSystem = initialMeasurementSystem;

  ThemeMode _themeMode;
  AppLanguage _language;
  AppMeasurementSystem _measurementSystem;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  AppMeasurementSystem get measurementSystem => _measurementSystem;

  void setThemeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
  }

  void setLanguage(AppLanguage value) {
    if (_language == value) return;
    _language = value;
    notifyListeners();
  }

  void setMeasurementSystem(AppMeasurementSystem value) {
    if (_measurementSystem == value) return;
    _measurementSystem = value;
    notifyListeners();
  }
}

class AppPreferencesScope extends InheritedNotifier<AppPreferencesController> {
  const AppPreferencesScope({
    required AppPreferencesController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppPreferencesController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppPreferencesScope>();
    assert(scope != null, 'AppPreferencesScope is missing above this route.');
    return scope!.notifier!;
  }
}
