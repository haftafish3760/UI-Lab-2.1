import '../../l10n/app_localizations.dart';

enum AppViewMode {
  technician('Technician'),
  admin('Admin');

  const AppViewMode(this.label);
  final String label;

  String localizedLabel(AppLocalizations localizations) => switch (this) {
    AppViewMode.technician => localizations.operationalViewTechnician,
    AppViewMode.admin => localizations.operationalViewAdmin,
  };
}
