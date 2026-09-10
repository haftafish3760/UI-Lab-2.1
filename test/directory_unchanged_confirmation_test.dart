import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_contact_codec.dart';
import 'support/storage/database_harness.dart';

void main() {
  for (final kind in ['customer', 'company']) {
    test(
      '$kind unchanged confirmation checks SQL revision before consuming input',
      () async {
        final harness = await DatabaseHarness.create();
        addTearDown(harness.dispose);
        final db = await harness.open();
        final owner = await openUiLabDirectory(db);
        addTearDown(owner.dispose);
        final secondDb = await harness.open();
        final editor = await DirectoryPersistenceSession.open(
          secondDb,
          owner.permissions,
        );
        addTearDown(editor.dispose);
        final customer = editor.customers.first;
        final company = editor.company;
        final domain = 'directory/$kind-editor';
        final p = owner.permissions;
        final drafts = LocalDraftStore(secondDb);
        Future<LocalDraftCheckpoint> checkpoint(String id) async {
          final revision = await drafts.save(
            organizationId: p.organizationId,
            domain: domain,
            draftId: id,
            ownerId: p.actorEmployeeId,
            expectedRevision: 0,
            payload: {'raw': 'input to preserve'},
            occurredAt: DateTime.now(),
          );
          return LocalDraftCheckpoint(
            domain: domain,
            draftId: id,
            revision: revision,
          );
        }

        Future<bool> confirm(LocalDraftCheckpoint checkpoint) =>
            kind == 'customer'
            ? editor.saveCustomer(
                customer,
                expectedRevision: 1,
                draftCheckpoint: checkpoint,
              )
            : editor.saveCompany(
                company,
                expectedRevision: 1,
                draftCheckpoint: checkpoint,
              );
        // A truly unchanged record can acknowledge the input without inventing
        // another business revision or journal entry.
        expect(await confirm(await checkpoint('current')), isTrue);
        expect(
          kind == 'customer'
              ? editor.customerRevision(customer.id)
              : editor.companyRevision,
          1,
        );
        expect(
          await drafts.list(
            organizationId: p.organizationId,
            domain: domain,
            ownerId: p.actorEmployeeId,
          ),
          isEmpty,
        );
        final retained = await checkpoint('stale');
        expect(
          kind == 'customer'
              ? await owner.saveCustomer(
                  decodeWorkCustomerProfile({
                    ...encodeWorkCustomerProfile(customer),
                    'name': 'Newer name',
                  }),
                )
              : await owner.saveCompany(
                  company.copyWith(companyName: 'Newer name'),
                ),
          isTrue,
        );
        expect(await confirm(retained), isFalse);
        final saved = await drafts.list(
          organizationId: p.organizationId,
          domain: domain,
          ownerId: p.actorEmployeeId,
        );
        expect(saved, hasLength(1));
        expect(drafts.decode(saved.single), {'raw': 'input to preserve'});
        final reopened = await DirectoryPersistenceSession.open(
          secondDb,
          owner.permissions,
        );
        addTearDown(reopened.dispose);
        expect(
          kind == 'customer'
              ? reopened.customers
                    .singleWhere((value) => value.id == customer.id)
                    .name
              : reopened.company.companyName,
          'Newer name',
        );
        expect(
          kind == 'customer'
              ? reopened.customerRevision(customer.id)
              : reopened.companyRevision,
          2,
        );
        await db.verifyIntegrity();
      },
    );
  }
}
