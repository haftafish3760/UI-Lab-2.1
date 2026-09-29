import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/screens/work/saved_clients_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_contact_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';

Future<void> _pumpDirectory(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  final scope = OperationalScopeController();
  addTearDown(scope.dispose);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: OperationalScope(
          controller: scope,
          child: SavedClientsScreen(
            initialClients: demoWorkCustomers,
            selectedDay: DateTime(2026, 8, 31),
            onClientsChanged: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _client(String id) => find.byKey(ValueKey('saved-client-$id'));

void main() {
  testWidgets('Saved Clients uses bounded readable rows on desktop', (
    tester,
  ) async {
    await _pumpDirectory(tester, const Size(1440, 900));

    final garcia = _client('customer-garcia');
    final miller = _client('customer-miller');
    final thompson = _client('customer-thompson');
    expect(
      tester.getTopLeft(garcia).dy,
      lessThan(tester.getTopLeft(miller).dy),
    );
    expect(
      tester.getTopLeft(miller).dy,
      lessThan(tester.getTopLeft(thompson).dy),
    );
    expect(tester.getSize(garcia).width, lessThanOrEqualTo(760));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Saved Clients keeps readable rows for large text', (
    tester,
  ) async {
    await _pumpDirectory(tester, const Size(800, 900), textScale: 2);

    final garcia = _client('customer-garcia');
    final miller = _client('customer-miller');
    final thompson = _client('customer-thompson');
    expect(
      tester.getTopLeft(garcia).dy,
      lessThan(tester.getTopLeft(miller).dy),
    );
    expect(
      tester.getTopLeft(miller).dy,
      lessThan(tester.getTopLeft(thompson).dy),
    );
    expect(tester.getSize(garcia).width, lessThanOrEqualTo(760));
    expect(tester.takeException(), isNull);
  });
}
