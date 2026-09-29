import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';

import 'customer_draft_workflow_test.dart' as fixtures;
import 'support/storage/database_harness.dart';

void main() {
  test('accepted customer save survives editor session disposal', () async {
    final harness = await DatabaseHarness.create();
    addTearDown(harness.dispose);
    final db = await harness.open();
    final directory = await openUiLabDirectory(db);
    final pending = directory.saveCustomer(fixtures.original);
    directory.dispose();
    expect(await pending, isTrue);
    final reopened = await openUiLabDirectory(db);
    addTearDown(reopened.dispose);
    expect(reopened.customers.single.id, fixtures.original.id);
  });
}
