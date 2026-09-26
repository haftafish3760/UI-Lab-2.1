import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/company_contact_card.dart';
import 'package:ui_lab_2_1/src/screens/work/company_contact_card.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  final profile = demoWorkCompany.copyWith(
    companyName: 'Álvarez; Service, Inc.',
    address: '123 Private Lane\nTown, TX 75001',
    businessIdentifier: 'PRIVATE-ID',
    defaultTerms: 'PRIVATE-TERMS',
    logoReference: '/private/logo.png',
  );
  test(
    'offline contact includes public details and escapes field injection',
    () {
      final value = companyContactVCard(
        profile.copyWith(companyName: 'Company\nNOTE:Injected'),
      );
      expect(value, contains(r'FN:Company\nNOTE:Injected'));
      expect(value, isNot(contains('\r\nNOTE:Injected')));
      expect(value, contains('VERSION:3.0'));
      for (final private in [
        'Private Lane',
        'PRIVATE-ID',
        'PRIVATE-TERMS',
        '/private/logo.png',
      ]) {
        expect(value, isNot(contains(private)));
      }
      expect(value, contains('TEL;TYPE=WORK,VOICE:'));
      expect(value, contains('EMAIL;TYPE=INTERNET,WORK:'));
    },
  );
  test(
    'address appears only when explicitly included and Unicode folds safely',
    () {
      final value = companyContactVCard(
        profile.copyWith(companyName: 'Á' * 100),
        includeAddress: true,
      );
      expect(value, contains('123 Private Lane'));
      for (final line in value.split('\r\n')) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75));
      }
      expect(value.replaceAll('\r\n ', ''), contains('FN:${'Á' * 100}'));
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'contact card renders at 320 LP enlarged text ${dark ? "dark" : "light"}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompanyContactCard(
                  profile: profile,
                  logo: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.business),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(profile.address), findsNothing);
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        expect(find.text(profile.address), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
