import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_store.dart';
import 'package:ui_lab_2_1/src/data/storage/remove_demo_installation.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'support/storage/database_harness.dart';

void main() {
  test('demo cleanup is once-only and preserves settings and other businesses', () async {
    final harness = await DatabaseHarness.create();
    addTearDown(harness.dispose);
    final db = await harness.open();
    final store = LocalRecordStore(db);
    Future<void> write(String org, String id, String domain) => store.commit(
      organizationId: org, commandId: '$id-command', occurredAt: DateTime.now(),
      writes: [LocalRecordWrite(domain: domain, recordId: id, ownerId: 'owner',
        expectedRevision: 0, payload: {'id': id})]);
    await write(expenseUiLabOrganizationId, 'demo', 'work/records');
    await write(expenseUiLabOrganizationId, 'preferences', 'settings/app');
    await write('other-business', 'other', 'work/records');
    await db.customStatement("INSERT INTO local_metadata VALUES ('ui-lab-work-demo-seed', '1')");
    await removeDemoInstallation(db);
    expect(await store.read(organizationId: expenseUiLabOrganizationId,
      domain: 'work/records', ownerIds: {'owner'}), isEmpty);
    expect(await store.read(organizationId: expenseUiLabOrganizationId,
      domain: 'settings/app', ownerIds: {'owner'}), hasLength(1));
    expect(await store.read(organizationId: 'other-business',
      domain: 'work/records', ownerIds: {'owner'}), hasLength(1));
    await write(expenseUiLabOrganizationId, 'real-work', 'work/records');
    await removeDemoInstallation(db);
    expect(await store.read(organizationId: expenseUiLabOrganizationId,
      domain: 'work/records', ownerIds: {'owner'}), hasLength(1));
    await db.verifyIntegrity();
  });
}
