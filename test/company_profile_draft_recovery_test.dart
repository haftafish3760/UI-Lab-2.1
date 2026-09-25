import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/seeded_directory_fixture.dart';
import 'package:ui_lab_2_1/src/screens/work/company_profile_editor.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'company input recovers without changing confirmed defaults and survives failed save',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var database = (await tester.runAsync(harness.open))!;
      var directory = (await tester.runAsync(
        () => openSeededTestDirectory(database),
      ))!;
      expect(
        await tester.runAsync(
          () => directory.saveCompany(
            directory.company.copyWith(defaultCurrency: 'CAD'),
          ),
        ),
        isTrue,
      );
      var store = PrototypeOperationsStore(directorySession: directory);
      final scope = OperationalScopeController();
      addTearDown(() async {
        store.dispose();
        directory.dispose();
        scope.dispose();
        await harness.dispose();
      });
      final originalName = directory.company.companyName;
      Finder field(String label) => find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == label,
      );
      Future<void> open() async {
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: AppTheme.light,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => CompanyProfileEditScreen(
                            initialProfile: store.companyProfile,
                            selectedDay: DateTime(2026, 9, 9),
                          ),
                        ),
                      ),
                      child: const Text('Edit company'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Edit company'));
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => field('Company name').evaluate().isNotEmpty,
        );
      }

      Future<void> save() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(
          find.byKey(const ValueKey('save-company-profile-button')),
          find.byType(ListView).first,
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('save-company-profile-button')),
        );
      }

      await open();
      await save();
      await waitForNativeSave(
        tester,
        () => find.byType(CompanyProfileEditScreen).evaluate().isEmpty,
      );
      expect(store.companyProfile.companyName, originalName);
      await open();
      await tester.enterText(field('Company name'), 'Recovered business');
      await tester.enterText(field('Website'), 'https://');
      await tester.enterText(field('Street address'), '42 Trade Road');
      await tester.enterText(field('Apartment or suite (optional)'), 'Suite 3');
      await tester.enterText(field('City'), 'Roanoke');
      await tester.enterText(field('State'), 'VA');
      await tester.enterText(field('ZIP code'), '24012');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Save company changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      // Simulate interruption rather than deliberately discarding the draft.
      await waitForNativeSave(
        tester,
        () => find.text('Draft saved on this device').evaluate().isNotEmpty,
      );
      expect(store.companyProfile.companyName, originalName);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      directory.dispose();
      await tester.runAsync(() => harness.close(database));
      database = (await tester.runAsync(harness.open))!;
      directory = (await tester.runAsync(
        () => openSeededTestDirectory(database),
      ))!;
      store = PrototypeOperationsStore(directorySession: directory);
      await tester.runAsync(
        () => database.customStatement("""
      CREATE TRIGGER fail_company BEFORE UPDATE ON local_records
      WHEN NEW.domain = 'directory/company'
      BEGIN SELECT RAISE(ABORT, 'injected failure'); END
    """),
      );
      await open();
      expect(
        tester.widget<TextField>(field('Company name')).controller!.text,
        'Recovered business',
      );
      expect(
        tester.widget<TextField>(field('Website')).controller!.text,
        'https://',
      );
      await tester.enterText(field('Website'), 'https://example.test');
      await save();
      await waitForNativeSave(tester, () => directory.failureMessage != null);
      expect(find.byType(CompanyProfileEditScreen), findsOneWidget);
      expect(store.companyProfile.companyName, originalName);
      final drafts = LocalDraftStore(database);
      expect(
        await tester.runAsync(
          () => drafts.list(
            organizationId: directory.permissions.organizationId,
            domain: 'directory/company-editor',
            ownerId: directory.permissions.actorEmployeeId,
          ),
        ),
        hasLength(1),
      );
      await tester.runAsync(
        () => database.customStatement('DROP TRIGGER fail_company'),
      );
      await save();
      await waitForNativeSave(
        tester,
        () => find.byType(CompanyProfileEditScreen).evaluate().isEmpty,
      );
      expect(store.companyProfile.companyName, 'Recovered business');
      expect(store.companyProfile.website, 'https://example.test');
      expect(
        store.companyProfile.address,
        '42 Trade Road\nSuite 3\nRoanoke, VA 24012',
      );
      expect(store.companyProfile.addressParts['city'], 'Roanoke');
      expect(store.companyProfile.defaultCurrency, 'CAD');
      expect(
        await tester.runAsync(
          () => drafts.list(
            organizationId: directory.permissions.organizationId,
            domain: 'directory/company-editor',
            ownerId: directory.permissions.actorEmployeeId,
          ),
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
