import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/job_list_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import '../test/support/storage/database_harness.dart';
import '../test/support/storage/native_widget_pump.dart';

void main() {
  if (Platform.isAndroid && !const bool.fromEnvironment('STORAGE_QA')) {
    throw StateError(
      'Android job testing requires the isolated STORAGE_QA app.',
    );
  }
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a job entered in the UI survives closing and reopening storage',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final scope = OperationalScopeController();
      var database = (await tester.runAsync(harness.open))!;
      var work = (await tester.runAsync(() => openUiLabWorkSession(database)))!;
      var directory = (await tester.runAsync(
        () => openUiLabDirectory(database),
      ))!;
      const customer = WorkCustomerProfile(
        id: 'qa-job-customer',
        name: 'QA Fictional Customer',
        companyName: '',
        phone: '',
        email: '',
        preferredContact: '',
        billingAddress: '',
        locations: [
          WorkServiceLocation(
            label: 'Test site',
            address: '100 Fictional Lane',
          ),
        ],
        notes: '',
        linkedRecordCount: 0,
      );
      expect(
        await tester.runAsync(() => directory.saveCustomer(customer)),
        isTrue,
      );
      final store = PrototypeOperationsStore(
        workSession: work,
        directorySession: directory,
      );
      addTearDown(() async {
        scope.dispose();
        await harness.dispose();
      });
      const title = 'QA saved job round trip';
      final existing = work.records.map((record) => record.id).toSet();

      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: JobListWorkspaceScreen(
                initialDay: DateTime.now(),
                permissions: const JobWorkspacePermissions.development(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final newJob = find.byKey(const ValueKey('new-job')).evaluate().isNotEmpty
          ? find.byKey(const ValueKey('new-job'))
          : find.byKey(const ValueKey('new-job-inline'));
      await tester.ensureVisible(newJob);
      await tester.tap(newJob);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('job-without-estimate')));
      await waitForNativeSave(
        tester,
        () =>
            find.byKey(const ValueKey('job-title-field')).evaluate().isNotEmpty,
      );

      final clientPicker = find.descendant(
        of: find.byKey(const ValueKey('job-client-field')),
        matching: find.byType(DropdownButtonFormField<String>),
      );
      await tester.ensureVisible(clientPicker);
      await tester.tap(clientPicker);
      await tester.pumpAndSettle();
      await tester.tap(find.text(customer.name).last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('job-title-field')),
        title,
      );
      await tester.enterText(
        find.byKey(const ValueKey('job-scope-field')),
        'Inspect and repair the test fixture.',
      );
      await tester.tap(find.byKey(const ValueKey('save-job')));
      await waitForNativeSave(
        tester,
        () => work.records.any((record) => record.title == title),
      );
      final saved = work.records.singleWhere((record) => record.title == title);
      expect(existing.contains(saved.id), isFalse);
      expect(saved.kind, WorkRecordKind.job);
      expect(saved.client, customer.name);
      expect(saved.serviceLocation, customer.locations.first.address);
      expect(work.storageRevisionFor(saved.id), 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      store.dispose();
      work.dispose();
      directory.dispose();
      await tester.runAsync(() => harness.close(database));
      database = (await tester.runAsync(harness.open))!;
      work = (await tester.runAsync(() => openUiLabWorkSession(database)))!;
      directory = (await tester.runAsync(() => openUiLabDirectory(database)))!;
      final reopened = work.records.singleWhere(
        (record) => record.id == saved.id,
      );
      expect(reopened.title, title);
      expect(reopened.client, customer.name);
      expect(reopened.serviceLocation, customer.locations.first.address);
      expect(work.storageRevisionFor(reopened.id), 1);
      work.dispose();
      directory.dispose();
    },
  );
}
