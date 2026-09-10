import 'package:ui_lab_2_1/src/data/work/job_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/customer_draft_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_controller.dart';

import 'support/storage/database_harness.dart';

// Version-one payloads use the original wire names, deliberately independent of
// today's codec and widgets. Keep these fixtures when presentations are replaced.
Map<String, Object?> legacyInput(String kind) => {
  'creatorId': 'owner',
  'number': 'UNFINISHED-1',
  'baseStorageRevision': 0,
  'title': 'Interrupted work',
  'discount': '12.',
  'tax': '',
  'terms': 'Pending terms',
  'client': null,
  'pricing': 'flatRate',
  'template': 'standard',
  'createdOn': '2026-09-09T10:00:00.000Z',
  'items': <Object?>[],
  if (kind == 'estimate') ...{
    'baseRecord': null,
    'estimateId': 'estimate-1',
    'scope': 'Partially entered scope',
    'expiresOn': '2026-10-09T10:00:00.000Z',
    'followUpOn': null,
    'proposedServiceOn': null,
    'itemEditors': {'new': legacyItemsWorkspace()},
    'photoEditor': {
      'photos': <Object?>[],
      'pendingNotes': {'pending-photo': 'Unfinished note'},
    },
    'sitePhotos': <Object?>[],
  } else ...{
    'existingRecordId': null,
    'recordId': 'invoice-1',
    'summary': 'Partially entered summary',
    'issuedOn': '2026-09-09T10:00:00.000Z',
    'dueOn': '2026-10-09T10:00:00.000Z',
    'sourceJobId': null,
    'location': null,
    'paymentMethod': 'Check',
    'itemEditor': legacyItemsWorkspace(),
  },
};

void main() {
  for (final kind in ['estimate', 'invoice', 'job', 'customer']) {
    test(
      '$kind legacy input reopens through a controller without widgets',
      () async {
        final harness = await DatabaseHarness.create();
        addTearDown(harness.dispose);
        var database = await harness.open();
        final input = kind == 'job'
            ? legacyJobInput()
            : kind == 'customer'
            ? legacyCustomerInput()
            : legacyInput(kind);
        final domain = kind == 'customer'
            ? 'directory/customer-editor'
            : 'work/$kind-editor';
        await LocalDraftStore(database).save(
          organizationId: 'business',
          domain: domain,
          draftId: 'legacy-input',
          ownerId: 'owner',
          expectedRevision: 0,
          payload: input,
          occurredAt: DateTime.utc(2026, 9, 9),
        );
        await harness.close(database);
        database = await harness.open();
        final session = DraftAutosaveSession(
          store: LocalDraftStore(database),
          organizationId: 'business',
          domain: domain,
          draftId: 'legacy-input',
          ownerId: 'owner',
        );
        await session.initialize();
        if (kind == 'estimate') {
          final controller = EstimateDraftController(session);
          final restored = controller.recoveredInput!;
          expect(restored.discount, '12.');
          expect(restored.tax, '');
          expect(restored.toPayload(), input);
          controller.updateInput(restored);
          // A presentation's local collection must not alter the saved checkpoint.
          restored.pendingLineItems.clear();
          expect(session.input['itemEditors'], input['itemEditors']);
        } else if (kind == 'invoice') {
          final controller = InvoiceDraftController(session);
          final restored = controller.recoveredInput!;
          expect(restored.discount, '12.');
          expect(restored.tax, '');
          expect(restored.toPayload(), input);
          controller.updateInput(restored);
          expect(
            () => restored.pendingLineItem!.items.clear(),
            throwsUnsupportedError,
          );
          expect(session.input['itemEditor'], input['itemEditor']);
        } else if (kind == 'job') {
          final controller = JobDraftController(session);
          final restored = controller.recoveredInput!;
          expect(restored.scheduledStart.toIso8601String(), input['start']);
          expect(restored.scheduledEnd.toIso8601String(), input['end']);
          expect(restored.toPayload(), input);
          controller.updateInput(restored);
          expect(
            () => restored.pendingLineItem!.items.clear(),
            throwsUnsupportedError,
          );
          expect(session.input['itemEditor'], input['itemEditor']);
        } else {
          final controller = CustomerDraftController(session);
          final restored = controller.recoveredInput!;
          expect(restored.phone, '+1 (555');
          expect(restored.email, 'unfinished@');
          expect(restored.toPayload(), input);
          controller.updateInput(restored);
        }
        await session.close();
        expect(
          session.savedRevision,
          1,
          reason:
              'Opening in a new presentation must not rewrite unchanged data.',
        );
        final stored = await session.store.find(
          organizationId: 'business',
          domain: domain,
          draftId: 'legacy-input',
          ownerId: 'owner',
        );
        expect(session.store.decode(stored!), input);
        expect(await database.select(database.localRecords).get(), isEmpty);
      },
    );
  }
}

Map<String, Object?> legacyJobInput() => {
  'jobId': 'job-1',
  'number': 'JOB-1',
  'source': null,
  'sourceStorageRevision': 0,
  'start': '2026-09-09T23:30:00.000',
  'end': '2026-09-10T01:30:00.000',
  'client': null,
  'location': null,
  'assignee': null,
  'vehicle': null,
  'pricing': 'timeAndMaterials',
  'items': <Object?>[],
  'itemEditor': legacyItemsWorkspace(),
  'title': 'Overnight job',
  'scope': '',
  'notes': 'Not yet finished',
};

Map<String, Object?> legacyCustomerInput() => {
  'customerId': 'customer-1',
  'existingCustomer': null,
  'baseRevision': 0,
  'preferredContact': 'Phone call',
  'name': 'Unfinished client',
  'company': '',
  'phone': '+1 (555',
  'email': 'unfinished@',
  'billing': 'Partial address',
  'notes': '',
  'locationLabel': 'Primary service location',
  'locationAddress': '',
  'accessNotes': 'Gate code pending',
};

// Exact nested wire shape emitted by the existing item editors, with raw input.
Map<String, Object?> legacyItemsWorkspace() => {
  'items': <Object?>[],
  'pendingItem': {
    'lineId': 'pending-line',
    'original': null,
    'name': 'Unfinished item',
    'description': '',
    'quantity': '1.',
    'price': '',
    'cost': '',
    'type': 'material',
    'unit': 'item',
    'billingTreatment': 'nonBillable',
    'sourceExpenseId': null,
    'sourceExpenseLineId': null,
    'sourceReceiptId': null,
    'sourceStockId': null,
    'initialCost': null,
  },
};
