import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapPath = 'docs/maintainiac_5_7_capability_migration_map.md';

  test(
    '5.7 migration map protects the source and prevents wholesale copying',
    () {
      final map = File(mapPath).readAsStringSync();

      expect(map, contains('/Users/rbbie/Documents/Maintainiac_5.7_Active'));
      expect(map, contains('5.7 is read-only'));
      expect(map, contains('Do not copy files from 5.7 into UI Lab'));
      expect(map, contains('Presence is not proof'));
      expect(
        map,
        contains('No code begins until the owner approves this slice'),
      );
      expect(map, contains('Compare 5.7 dirty-state fingerprint before/after'));
      expect(map, contains('tool/audit_maintainiac_5_7_source.sh'));
    },
  );

  test('map preserves expensive engines behind characterization gates', () {
    final map = File(mapPath).readAsStringSync();

    expect(
      map,
      contains('expense_receipt_parser.dart` | Preserve engine; add adapter'),
    );
    expect(map, contains('complete\n`lib/screens/work_supplies/data/` tree'));
    expect(map, contains('independent black-box\ncharacterization tests'));
    expect(map, contains('golden_fixtures.json'));
    expect(map, contains('holdout_fixtures.json'));
    expect(map, contains('All capabilities in this 0.1 map are only'));
    expect(map, contains('**Discovered**'));
  });

  test('map separates receipt review, expense approval, and destinations', () {
    final map = File(mapPath).readAsStringSync();

    expect(map, contains('Separate reviews'));
    expect(map, contains('requireApprovalForEveryExpense'));
    expect(map, contains('save the business Expense'));
    expect(map, contains('cost history'));
    expect(map, contains('stock-receipt transaction'));
    expect(map, contains('allocate confirmed lines to one or more Jobs'));
    expect(map, contains('The user can accept none, one, or'));
  });

  test('map gates migration on the unfinished operational UI', () {
    final map = File(mapPath).readAsStringSync();

    expect(map, contains('## 9. Pre-migration UI readiness gate'));
    expect(map, contains('**Work home:**'));
    expect(map, contains('**Active Jobs:**'));
    expect(map, contains('**Estimates:**'));
    expect(map, contains('**Invoices:**'));
    expect(map, contains('Do not transplant OCR, Inventory parsing'));
  });

  test('first data slice remains local, manual, and reversible', () {
    final map = File(mapPath).readAsStringSync();

    expect(map, contains('### Slice E1: manual local Expense foundation'));
    expect(map, contains('Explicitly out of scope:'));
    expect(map, contains('- OCR, parsing, AI, and long-receipt stitching;'));
    expect(map, contains('- inventory/material transfer;'));
    expect(map, contains('- Firebase backup/sync;'));
    expect(map, contains('Never alter or delete the protected 5.7 boxes'));
  });
}
