import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/company_profile_editor.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/shared/company_logo_field.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

const profile = WorkCompanyProfile(
  companyName: 'Example',
  businessCategory: '',
  phone: '',
  email: '',
  website: '',
  address: '',
  logoLabel: '',
  defaultTerms: '',
  defaultCurrency: 'USD',
);

void main() {
  Future<void> open(
    WidgetTester tester, {
    ThemeData? theme,
    double scale = 1,
  }) async {
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    await tester.pumpWidget(
      OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<WorkCompanyProfile>(
                    builder: (_) => CompanyProfileEditScreen(
                      initialProfile: profile,
                      selectedDay: DateTime(2026, 9, 24),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label,
  );

  for (final dark in [false, true]) {
    testWidgets('company form fits narrow screen with large text, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(
        tester,
        theme: dark ? AppTheme.dark : AppTheme.light,
        scale: 1.6,
      );
      expect(
        find.byKey(const ValueKey('save-company-profile-button')).hitTestable(),
        findsOneWidget,
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('save-company-profile-button')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'clean Back leaves without a prompt; phone and email use appropriate keyboards',
    (tester) async {
      await open(tester);
      expect(
        tester.widget<TextField>(field('Business phone')).keyboardType,
        TextInputType.phone,
      );
      expect(
        tester.widget<TextField>(field('Business email')).keyboardType,
        TextInputType.emailAddress,
      );
      expect(
        tester.widget<TextField>(field('Website')).keyboardType,
        TextInputType.url,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Save company changes?'), findsNothing);
    },
  );

  testWidgets(
    'logo-only edit prompts; keep editing preserves it and discard leaves',
    (tester) async {
      await open(tester);
      tester
          .widget<CompanyLogoField>(find.byType(CompanyLogoField))
          .onChanged('new-logo');
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Save company changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CompanyLogoField>(find.byType(CompanyLogoField))
            .reference,
        'new-logo',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
    },
  );

  testWidgets('changed Back saves and incomplete phone stays in editor', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(field('Business phone'), '55512');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Save changes'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CompanyProfileEditScreen), findsOneWidget);
    expect(
      find.text('Enter a 10-digit phone number, including the area code.'),
      findsOneWidget,
    );
    await tester.enterText(field('Business phone'), '5551234567');
    expect(
      tester.widget<TextField>(field('Business phone')).controller!.text,
      '(555) 123-4567',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Save changes'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });
}
