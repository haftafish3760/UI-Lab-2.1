import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/screens/work/customer_detail_screen.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'support/storage/database_harness.dart';

void main() {
  for (final canView in [false, true]) {
    testWidgets(
      'client detail enforces directory view=$canView and read-only actions',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final db = (await tester.runAsync(harness.open))!;
        const customer = WorkCustomerProfile(
          id: 'client-a',
          name: 'Private client',
          companyName: '',
          phone: '2025550101',
          email: '',
          preferredContact: '',
          billingAddress: '',
          locations: [],
          notes: '',
          linkedRecordCount: 99,
        );
        final writer = (await tester.runAsync(
          () => DirectoryPersistenceSession.open(
            db,
            const DirectoryPermissions(
              organizationId: 'test-org',
              actorEmployeeId: 'actor',
              permissionRevision: 'seed',
              canViewCustomers: true,
              canManageCustomers: true,
            ),
          ),
        ))!;
        expect(
          await tester.runAsync(() => writer.saveCustomer(customer)),
          isTrue,
        );
        writer.dispose();
        final directory = (await tester.runAsync(
          () => DirectoryPersistenceSession.open(
            db,
            DirectoryPermissions(
              organizationId: 'test-org',
              actorEmployeeId: 'actor',
              permissionRevision: '1',
              canViewCustomers: canView,
            ),
          ),
        ))!;
        final work = (await tester.runAsync(
          () => WorkPersistenceSession.open(
            SqliteWorkRepository(db),
            WorkSessionPermissions(
              organizationId: 'test-org',
              actorEmployeeId: 'actor',
              permissionRevision: '1',
              visibleCreatorIds: {'actor'},
              editableKinds: {},
            ),
          ),
        ))!;
        final store = PrototypeOperationsStore(
          directorySession: directory,
          workSession: work,
        );
        final scope = OperationalScopeController(technicianEmployeeId: 'actor');
        addTearDown(() async {
          store.dispose();
          scope.dispose();
          directory.dispose();
          work.dispose();
          await tester.runAsync(harness.dispose);
        });
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                home: CustomerDetailScreen(
                  initialCustomer: customer,
                  selectedDay: DateTime(2026, 9, 28),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (!canView) {
          expect(find.text('Private client'), findsNothing);
          expect(find.text('2025550101'), findsNothing);
          expect(find.text('New estimate'), findsNothing);
          expect(
            find.text('You do not have permission to view saved clients.'),
            findsOneWidget,
          );
        } else {
          final edit = tester.widget<FilledButton>(
            find.byKey(const ValueKey('edit-customer-button')),
          );
          expect(edit.onPressed, isNull);
          final create = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'New estimate'),
          );
          expect(create.onPressed, isNull);
          expect(find.textContaining('99'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
