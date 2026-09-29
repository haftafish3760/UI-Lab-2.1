import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_client_information.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final locale in [const Locale('es', 'US'), const Locale('fr', 'CA')]) {
    testWidgets('client entry uses $locale at accessible phone width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = PrototypeOperationsStore(customers: [], workRecords: []);
      addTearDown(store.dispose);
      final labels = lookupAppLocalizations(locale);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: MaterialApp(
            theme: AppTheme.light,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: EstimateClientInformation(
                  selectedDay: DateTime(2026, 9, 29),
                  selectedClient: null,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(labels.clientSaved), findsOneWidget);
      expect(find.text(labels.clientNoSaved), findsNothing);
      await tester.tap(find.text(labels.clientSaved));
      await tester.pumpAndSettle();
      expect(find.text(labels.clientNoSaved), findsOneWidget);
      await tester.tap(find.text(labels.clientAddNew));
      await tester.pumpAndSettle();
      expect(find.text(labels.clientName), findsOneWidget);
      expect(find.text(labels.clientBusiness), findsOneWidget);
      expect(find.text(labels.clientSaveUse), findsOneWidget);
      expect(find.text('Client name'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
