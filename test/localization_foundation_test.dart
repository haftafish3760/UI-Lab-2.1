import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/operational_attention.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_date_heading.dart';
import 'package:ui_lab_2_1/src/screens/expenses/report_period.dart';
import 'package:ui_lab_2_1/src/screens/work/work_selected_date_bar.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/localized_date.dart';
import 'package:ui_lab_2_1/src/shared/module_month_calendar.dart';
import 'package:ui_lab_2_1/src/shared/operational_header.dart';
import 'package:ui_lab_2_1/src/shared/operational_attention_panel.dart';
import 'package:ui_lab_2_1/src/shell/app_navigation.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  test('release-one language and measurement codes remain stable', () {
    final preferences = AppPreferencesController();
    addTearDown(preferences.dispose);

    expect(preferences.language, AppLanguage.english);
    expect(preferences.language.locale, const Locale('en', 'US'));
    expect(preferences.measurementSystem, AppMeasurementSystem.us);

    preferences
      ..setLanguage(AppLanguage.spanish)
      ..setMeasurementSystem(AppMeasurementSystem.metric);

    expect(preferences.language.locale, const Locale('es', 'US'));
    expect(preferences.measurementSystem, AppMeasurementSystem.metric);
  });

  test('regional catalogs expose English Spanish and Canadian French', () {
    expect(
      lookupAppLocalizations(const Locale('en', 'US')).navExpenses,
      'Expenses',
    );
    expect(
      lookupAppLocalizations(const Locale('es', 'US')).navExpenses,
      'Gastos',
    );
    expect(
      lookupAppLocalizations(const Locale('fr', 'CA')).navExpenses,
      'Dépenses',
    );
    expect(
      lookupAppLocalizations(const Locale('en', 'US')).navInventory,
      'Materials',
    );
    expect(
      lookupAppLocalizations(const Locale('es', 'US')).navInventory,
      'Materiales',
    );
    expect(
      lookupAppLocalizations(const Locale('fr', 'CA')).navInventory,
      'Matériaux',
    );
    expect(
      ReportPeriod.previous90Days.localizedLabel(
        lookupAppLocalizations(const Locale('es', 'US')),
      ),
      '90 días anteriores',
    );
    expect(
      ReportPeriod.yearToDate.localizedLabel(
        lookupAppLocalizations(const Locale('fr', 'CA')),
      ),
      'Depuis le début de l’année',
    );
  });

  for (final configuration
      in <
        ({
          Locale locale,
          String full,
          String weekdayNoYear,
          String dateWithYear,
          String dateNoYear,
        })
      >[
        (
          locale: const Locale('en', 'US'),
          full: 'Monday, August 31, 2026',
          weekdayNoYear: 'Monday, August 31',
          dateWithYear: 'August 31, 2026',
          dateNoYear: 'August 31',
        ),
        (
          locale: const Locale('es', 'US'),
          full: 'lunes, 31 de agosto de 2026',
          weekdayNoYear: 'lunes, 31 de agosto',
          dateWithYear: '31 de agosto de 2026',
          dateNoYear: '31 de agosto',
        ),
        (
          locale: const Locale('fr', 'CA'),
          full: 'lundi 31 août 2026',
          weekdayNoYear: 'lundi 31 août',
          dateWithYear: '31 août 2026',
          dateNoYear: '31 août',
        ),
      ]) {
    testWidgets(
      '${configuration.locale} formats every operational date density',
      (tester) async {
        final day = DateTime(2026, 8, 31);
        await tester.pumpWidget(
          MaterialApp(
            locale: configuration.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Column(
                children: [
                  Text(operationalDateLabel(context, day)),
                  Text(operationalDateLabel(context, day, year: false)),
                  Text(operationalDateLabel(context, day, weekday: false)),
                  Text(
                    operationalDateLabel(
                      context,
                      day,
                      weekday: false,
                      year: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(configuration.full), findsOneWidget);
        expect(find.text(configuration.weekdayNoYear), findsOneWidget);
        expect(find.text(configuration.dateWithYear), findsOneWidget);
        expect(find.text(configuration.dateNoYear), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final locale in const [
    Locale('en', 'US'),
    Locale('es', 'US'),
    Locale('fr', 'CA'),
  ]) {
    testWidgets('$locale report ranges use the active short-date order', (
      tester,
    ) async {
      late String expectedRange;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final dates = MaterialLocalizations.of(context);
              expectedRange =
                  '${dates.formatShortDate(DateTime(2026, 8, 1))}'
                  '–${dates.formatShortDate(DateTime(2026, 8, 31))}';
              return Text(
                ReportPeriod.thisMonth.dateRangeLabel(
                  context,
                  DateTime(2026, 8, 31),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(expectedRange), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the app advertises the three regional release-one choices', (
    tester,
  ) async {
    await tester.pumpWidget(const UiLabApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en', 'US'));
    expect(app.supportedLocales, const [
      Locale('en', 'US'),
      Locale('es', 'US'),
      Locale('fr', 'CA'),
    ]);
  });

  test('platform manifests advertise the supported languages', () {
    final android = File(
      'android/app/src/main/res/xml/locales_config.xml',
    ).readAsStringSync();
    final ios = File('ios/Runner/Info.plist').readAsStringSync();
    final macos = File('macos/Runner/Info.plist').readAsStringSync();

    for (final locale in const ['en-US', 'es-US', 'fr-CA']) {
      expect(android, contains('android:name="$locale"'));
    }
    for (final language in const ['en', 'es', 'fr']) {
      expect(ios, contains('<string>$language</string>'));
      expect(macos, contains('<string>$language</string>'));
    }
  });

  for (final configuration
      in <({Locale locale, String dashboard, String week, String monday})>[
        (
          locale: const Locale('es', 'US'),
          dashboard: 'Inicio',
          week: 'Semana',
          monday: 'lun.',
        ),
        (
          locale: const Locale('fr', 'CA'),
          dashboard: 'Accueil',
          week: 'Semaine',
          monday: 'lun.',
        ),
      ]) {
    testWidgets(
      '${configuration.locale} localizes shared navigation and calendar',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            locale: configuration.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: WorkMonthCalendar(
                        selectedDay: DateTime(2026, 8, 29),
                        entryCountForDay: (day) =>
                            DateUtils.isSameDay(day, DateTime(2026, 8, 29))
                            ? 2
                            : 0,
                        recordKind: CalendarRecordKind.expense,
                        onDaySelected: (_) {},
                      ),
                    ),
                  ),
                  AppBottomNavigation(selectedIndex: 0, onSelected: (_) {}),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(configuration.dashboard), findsOneWidget);
        expect(find.text(configuration.week), findsOneWidget);
        expect(find.text(configuration.monday), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('French calendar reflows at 320 LP and 2x text', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr', 'CA'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: WorkMonthCalendar(
              selectedDay: DateTime(2026, 8, 29),
              entryCountForDay: (day) =>
                  DateUtils.isSameDay(day, DateTime(2026, 8, 29)) ? 2 : 0,
              recordKind: CalendarRecordKind.expense,
              onDaySelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Semaine'), findsOneWidget);
    expect(find.text('lun.'), findsOneWidget);
    final daySemantics = tester.getSemantics(
      find.byKey(const ValueKey('calendar-day-2026-8-29')),
    );
    expect(daySemantics.label, contains('2 dépenses'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('French operational header uses stable localized identities', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const company = OperationalHeaderContextOption(
      id: 'company',
      kind: OperationalContextKind.employee,
      title: 'Company Overview',
      titleKind: OperationalContextTitleKind.companyOverview,
      icon: Icons.business_outlined,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr', 'CA'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: OperationalHeader(
            view: AppViewMode.admin,
            onViewChanged: (_) {},
            selectedContext: company,
            contextOptions: const [company],
            onContextChanged: (_) {},
            settingsTooltip: 'Settings',
            onSettings: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vue:'), findsOneWidget);
    expect(find.text('Administrateur'), findsOneWidget);
    expect(find.text('Employé'), findsOneWidget);
    expect(find.text('EMPLOYÉ'), findsOneWidget);
    expect(find.text('Aperçu de l’entreprise'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('French shared date and attention controls remain complete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final day = DateTime(2026, 8, 31);
    const attention = OperationalAttentionItem(
      id: 'expense-review',
      module: OperationalAttentionModule.expenses,
      resourceKind: OperationalAttentionResourceKind.expense,
      sourceId: 'expense-1',
      title: 'Fournitures centrales',
      reason: 'Approbation requise',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr', 'CA'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                WorkSelectedDateBar(
                  selectedDay: day,
                  onPrevious: () {},
                  onNext: () {},
                ),
                DashboardDateHeading(
                  type: AppLayoutEngine.typographyFor(320),
                  date: day,
                  onReturnToToday: () {},
                ),
                OperationalAttentionPanel(
                  items: const [attention],
                  onOpen: (_) {},
                  onOpenAll: () {},
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('lundi 31 août 2026'), findsWidgets);
    expect(find.byTooltip('Jour précédent'), findsOneWidget);
    expect(find.byTooltip('Jour suivant'), findsOneWidget);
    expect(find.byTooltip('Revenir à aujourd’hui'), findsOneWidget);
    expect(find.byType(Badge), findsNothing);
    expect(find.text('À vérifier'), findsOneWidget);
    expect(find.text('Tout afficher (1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
