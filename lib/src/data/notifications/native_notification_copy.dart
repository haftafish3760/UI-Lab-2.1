import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations_en.dart';
import '../../../l10n/app_localizations_es.dart';
import '../../../l10n/app_localizations_fr.dart';

class NativeNotificationCopy {
  const NativeNotificationCopy({required this.title, required this.body});

  final String title;
  final String body;
}

NativeNotificationCopy nativeNotificationCopyFor(Locale locale) {
  final localizations = switch (locale.languageCode) {
    'es' => AppLocalizationsEsUs(),
    'fr' => AppLocalizationsFrCa(),
    _ => AppLocalizationsEnUs(),
  };
  return NativeNotificationCopy(
    title: localizations.nativeReminderTitle,
    body: localizations.nativeReminderBody,
  );
}
