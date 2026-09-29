import 'support/visible_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/reusable_job_library.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/screens/work/reusable_jobs_panel.dart';
import 'package:ui_lab_2_1/src/screens/work/job_list_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_job_editor.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'reusable_job_library_test.dart' as fixture;
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final entry in [
    (360.0, false),
    (1200.0, false),
    (360.0, true),
    (1200.0, true),
  ]) {
    final (width, fromJobs) = entry;
    testWidgets(
      'create edit and reuse common work at $width from Jobs=$fromJobs',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final db = (await tester.runAsync(harness.open))!;
        final work = (await tester.runAsync(
          () => WorkPersistenceSession.open(
            SqliteWorkRepository(db),
            fixture.reusableAccess(schedule: true),
          ),
        ))!;
        final store = PrototypeOperationsStore(
          workSession: work,
          customers: const [
            WorkCustomerProfile(
              id: 'new-client',
              name: 'Jordan Taylor',
              companyName: '',
              phone: '2025550119',
              email: '',
              preferredContact: '',
              billingAddress: '',
              notes: '',
              linkedRecordCount: 0,
              locations: [
                WorkServiceLocation(label: 'Home', address: '42 Example Lane'),
              ],
            ),
          ],
        );
        final scope = OperationalScopeController();
        addTearDown(() async {
          store.dispose();
          scope.dispose();
          work.dispose();
          await finishNativeOperation(tester, harness.dispose);
        });
        Future<void> settle() async {
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 35));
          });
          await tester.pump(const Duration(milliseconds: 16));
        }

        Future<void> until(Finder finder) async {
          await waitForNativeSave(tester, () => finder.evaluate().isNotEmpty);
          expect(finder, findsOneWidget);
        }

        Future<List<SavedReusableJob>> savedJobs() async {
          late List<SavedReusableJob> result;
          await finishNativeOperation(tester, () async {
            result = await ReusableJobLibrary(work).list();
          });
          return result;
        }

        Future<void> tap(Finder finder) async {
          await tapVisibleControl(tester, finder);
          await tester.pump(const Duration(milliseconds: 16));
          await settle();
        }

        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: AppTheme.light,
                home: fromJobs
                    ? JobListWorkspaceScreen(initialDay: DateTime(2026, 9, 28))
                    : Scaffold(
                        body: SingleChildScrollView(
                          child: ReusableWorkTabs(
                            day: DateTime(2026, 9, 28),
                            newWork: const Text('New work actions'),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
        await tap(find.text('Reusable jobs'));
        final create = find.byKey(const ValueKey('new-reusable-job'));
        await until(create);
        await tap(create);
        final title = find.byKey(const ValueKey('reusable-job-title'));
        await until(title);
        await tester.enterText(title, 'Standard faucet replacement');
        await tester.enterText(
          find.byKey(const ValueKey('reusable-job-description')),
          'Remove old faucet and install customer-supplied faucet.',
        );
        await tester.enterText(
          find.byKey(const ValueKey('reusable-job-price')),
          '175.50',
        );
        await tap(find.byKey(const ValueKey('save-reusable-job')));
        await until(create);
        final saved = (await savedJobs()).single;
        expect(saved.job.title, 'Standard faucet replacement');
        expect(saved.job.items.single.customerPrice, 175.50);
        final edit = find.byKey(ValueKey('edit-reusable-${saved.job.id}'));
        await until(edit);
        await tap(edit);
        await until(title);
        expect(
          tester.widget<TextField>(title).controller!.text,
          saved.job.title,
        );
        await tester.enterText(title, 'Kitchen faucet replacement');
        await tap(find.byKey(const ValueKey('save-reusable-job')));
        await until(create);
        final updated = (await savedJobs()).single;
        expect(updated.revision, 2);
        final use = find.byKey(ValueKey('use-reusable-${saved.job.id}'));
        await until(use);
        await tap(use);
        await until(find.byType(WorkJobEditor));
        final jobTitle = find.byKey(const ValueKey('job-title-field'));
        await until(jobTitle);
        expect(
          tester.widget<TextField>(jobTitle).controller!.text,
          'Kitchen faucet replacement',
        );
        expect(
          find.byKey(const ValueKey('job-client-value-none')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('job-location-value-none')),
          findsOneWidget,
        );
        expect(
          work.records,
          isEmpty,
        ); // Using common work opens an editable new job, not an automatic booking.
        expect((await savedJobs()).single.revision, 2);
        await tap(find.byKey(const ValueKey('job-client-value-none')));
        await tap(find.text('Jordan Taylor').last);
        await tap(find.byKey(const ValueKey('save-job')));
        await waitForNativeSave(tester, () => work.records.isNotEmpty);
        final created = work.records.single;
        expect(created.client, 'Jordan Taylor');
        expect(created.serviceLocation, '42 Example Lane');
        expect(created.total, 175.50);
        expect(created.sourceId, isNull);
        expect(created.customerSignature, isNull);
        expect(created.assignedEmployeeIds, isEmpty);
        expect((await savedJobs()).single.revision, 2);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await settle();
      },
    );
  }
}
