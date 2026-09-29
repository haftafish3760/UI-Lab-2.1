import 'package:flutter/material.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/customer_detail_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/customer_work_history.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';

WorkCustomerProfile client(String id, String name) => WorkCustomerProfile(
  id: id,
  name: name,
  companyName: '',
  phone: '',
  email: '',
  preferredContact: '',
  billingAddress: '',
  locations: [],
  notes: '',
  linkedRecordCount: 99,
);

WorkRecord record(
  String id,
  String name, {
  WorkCustomerProfile? snapshot,
  String creator = 'owner',
}) => WorkRecord(
  id: id,
  kind: WorkRecordKind.estimate,
  number: id,
  title: id,
  client: name,
  customerSnapshot: snapshot,
  detail: '',
  pricing: WorkPricingModel.flatRate,
  total: 100,
  status: WorkRecordStatus.draft,
  createdByEmployeeId: creator,
);

void main() {
  testWidgets(
    'customer screen shows only current employee history and derived counts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final customer = client('a', 'Taylor Smith');
      final store = PrototypeOperationsStore(
        customers: [customer, client('b', customer.name)],
        workRecords: [
          record('own-record', customer.name, snapshot: customer),
          record(
            'other-employee',
            customer.name,
            snapshot: customer,
            creator: 'other',
          ),
          record(
            'other-customer',
            customer.name,
            snapshot: client('b', customer.name),
          ),
        ],
      );
      final scope = OperationalScopeController(technicianEmployeeId: 'owner');
      addTearDown(store.dispose);
      addTearDown(scope.dispose);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: CustomerDetailScreen(
                initialCustomer: customer,
                selectedDay: DateTime(2026, 9, 28),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('own-record'), findsOneWidget);
      expect(find.text('other-customer'), findsNothing);
      expect(find.text('other-employee'), findsNothing);
      expect(find.text('1 linked Work records'), findsOneWidget);
      expect(find.textContaining('99'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test('stable identity separates duplicate names and survives renaming', () {
    final first = client('a', 'Taylor Smith');
    final other = client('b', 'Taylor Smith');
    final renamed = client('a', 'Taylor Jones');
    final rows = [
      record('mine', first.name, snapshot: first),
      record('theirs', other.name, snapshot: other),
      record('legacy', first.name),
    ];
    expect(
      customerWorkHistory(
        customer: first,
        directory: [first, other],
        visibleRecords: rows,
      ).map((r) => r.id),
      ['mine'],
    );
    expect(
      customerWorkHistory(
        customer: renamed,
        directory: [renamed, other],
        visibleRecords: rows,
      ).map((r) => r.id),
      ['mine'],
    );
    expect(
      customerWorkHistory(
        customer: other,
        directory: [first, other],
        visibleRecords: rows,
      ).map((r) => r.id),
      ['theirs'],
    );
  });

  test(
    'legacy unique names remain findable without overriding a stable ID',
    () {
      final selected = client('a', 'Taylor Smith');
      expect(
        customerWorkHistory(
          customer: selected,
          directory: [selected],
          visibleRecords: [
            record('legacy', selected.name),
            record(
              'other-id',
              selected.name,
              snapshot: client('b', selected.name),
            ),
          ],
        ).map((r) => r.id),
        ['legacy'],
      );
    },
  );

  test(
    'empty authorized projection never substitutes customer cached count',
    () {
      final selected = client('a', 'Taylor Smith');
      expect(
        customerWorkHistory(
          customer: selected,
          directory: [selected],
          visibleRecords: [],
        ),
        isEmpty,
      );
    },
  );
}
