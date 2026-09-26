import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_customer_approval.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_signature_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'support/storage/database_harness.dart';

void main() {
  for (final approvalAllowed in [false, true]) {
    for (final signatureAllowed in [false, true]) {
      test(
        'approval=$approvalAllowed signature=$signatureAllowed enforce independent storage authority',
        () async {
          final harness = await DatabaseHarness.create();
          addTearDown(harness.dispose);
          final repository = SqliteWorkRepository(await harness.open());
          final work = await WorkPersistenceSession.open(
            repository,
            WorkSessionPermissions(
              organizationId: 'test-business',
              actorEmployeeId: 'owner',
              permissionRevision: '1',
              visibleCreatorIds: {'owner'},
              editableKinds: {WorkRecordKind.estimate},
              canRecordCustomerApproval: approvalAllowed,
              canCollectSignature: signatureAllowed,
            ),
          );
          addTearDown(work.dispose);
          const estimate = WorkRecord(
            id: 'estimate',
            kind: WorkRecordKind.estimate,
            number: 'EST-1',
            title: 'Repair',
            client: 'Customer',
            detail: 'Repair the fixture',
            pricing: WorkPricingModel.flatRate,
            createdByEmployeeId: 'owner',
            total: 100,
            items: [
              WorkLineItem(
                id: 'labor',
                type: WorkLineItemType.labor,
                name: 'Repair',
                quantity: 1,
                unit: 'job',
                customerPrice: 100,
              ),
            ],
          );
          expect(await work.create(estimate), isTrue);
          final approved = estimate.recordCustomerApproval(
            WorkCustomerApproval(
              method: CustomerApprovalMethod.verbal,
              customerName: 'Customer',
              recordedByEmployeeId: 'owner',
              recordedOn: DateTime.utc(2026, 9, 24),
              revision: 1,
            ),
          );
          expect(
            await work.update(approved),
            approvalAllowed,
            reason: work.failureMessage,
          );
          final current = work.records.single;
          final signed = current.recordEstimateSignature(
            'Customer',
            DateTime.utc(2026, 9, 24),
          );
          expect(
            await work.update(signed),
            signatureAllowed,
            reason: work.failureMessage,
          );
          if (!signatureAllowed) {
            await expectLater(
              work.openEstimateSignatureDraft(estimate.id),
              throwsStateError,
            );
          }
          final reopened = await WorkPersistenceSession.open(
            repository,
            work.permissions,
          );
          addTearDown(reopened.dispose);
          expect(
            reopened.records.single.customerApprovals.length,
            approvalAllowed ? 1 : 0,
          );
          expect(
            reopened.records.single.hasCurrentCustomerSignature,
            signatureAllowed,
          );
        },
      );
    }
  }
}
