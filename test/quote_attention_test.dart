import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/operational_attention.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'support/storage/database_harness.dart';
import 'quote_draft_workflow_test.dart' show quoteInput;

void main() {
  test(
    'quote attention follows saved approval and authority, not display role',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final seed = await openUiLabWorkSession(await harness.open());
      addTearDown(seed.dispose);
      final actor = seed.permissions.actorEmployeeId;
      WorkSessionPermissions grants(bool approve, {bool visible = true}) =>
          WorkSessionPermissions(
            organizationId: seed.permissions.organizationId,
            actorEmployeeId: actor,
            permissionRevision: 'attention',
            visibleCreatorIds: visible ? {actor} : {},
            editableKinds: {WorkRecordKind.quote},
            requiresQuoteApproval: true,
            canApproveQuotes: approve,
          );
      final work = await WorkPersistenceSession.open(
        seed.repository,
        grants(true),
      );
      addTearDown(work.dispose);
      final record =
          buildConfirmedEstimate(
            quoteInput(actor),
            now: DateTime.now(),
          ).copyWith(
            requiresCompanyReview: true,
            estimateCompanyReviewStatus: EstimateCompanyReviewStatus.pending,
          );
      expect(await work.create(record), isTrue);
      expect(
        await work.recordQuoteApproval(
          work.records.single,
          EstimateCompanyReviewDecision.submitted,
        ),
        isTrue,
      );
      final store = PrototypeOperationsStore(workSession: work);
      addTearDown(store.dispose);
      OperationalAttentionQuery query({
        AppViewMode view = AppViewMode.technician,
        String? employee,
        Set<OperationalAttentionResourceKind>? kinds,
      }) => OperationalAttentionQuery(
        panelId: 'test',
        module: OperationalAttentionModule.work,
        view: view,
        access: const OperationalAttentionAccess.adminDevelopment(),
        selectedEmployeeId: employee,
        resourceKinds: kinds,
      );
      final items = store.attentionCenter.itemsFor(query());
      expect(items.single.sourceId, record.id);
      expect(items.single.resourceKind, OperationalAttentionResourceKind.quote);
      expect(items.single.reason, startsWith('Approve quote'));
      expect(store.attentionCenter.itemsFor(query(employee: 'other')), isEmpty);
      expect(
        store.attentionCenter.itemsFor(
          query(kinds: {OperationalAttentionResourceKind.estimate}),
        ),
        isEmpty,
      );
      for (final permission in [grants(false), grants(true, visible: false)]) {
        final limited = await WorkPersistenceSession.open(
          work.repository,
          permission,
        );
        final limitedStore = PrototypeOperationsStore(workSession: limited);
        expect(
          limitedStore.attentionCenter.itemsFor(query(view: AppViewMode.admin)),
          isEmpty,
        );
        limitedStore.dispose();
        limited.dispose();
      }
      expect(
        await work.recordQuoteApproval(
          work.records.single,
          EstimateCompanyReviewDecision.changesRequested,
          note: 'Correct the price',
        ),
        isTrue,
      );
      expect(
        store.attentionCenter.itemsFor(query()).single.reason,
        startsWith('Quote changes requested'),
      );
      expect(
        await work.recordQuoteApproval(
          work.records.single,
          EstimateCompanyReviewDecision.submitted,
        ),
        isTrue,
      );
      expect(
        await work.recordQuoteApproval(
          work.records.single,
          EstimateCompanyReviewDecision.approved,
        ),
        isTrue,
      );
      expect(store.attentionCenter.itemsFor(query()), isEmpty);
    },
  );
}
