import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_signature_screen.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'handwriting and consent recover; approval and draft consumption are atomic',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1;
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      var work = (await tester.runAsync(() => openSeededTestWorkSession(db)))!;
      final name = find.byKey(const ValueKey('signature-customer-name'));
      Future<void> open() async {
        await tester.pumpWidget(UiLabApp(workSession: work));
        await tester.pumpAndSettle();
        final record = work.records.singleWhere(
          (record) => record.id == 'est-1041',
        );
        Navigator.of(tester.element(find.byType(DashboardScreen))).push(
          MaterialPageRoute<void>(
            builder: (_) => EstimateDetailScreen(
              initialRecord: record,
              onUpdated: (_) {},
              onCreateJob: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final sign = find.text('Record customer approval');
        await tester.ensureVisible(sign);
        await tester.tap(sign);
        await tester.pumpAndSettle();
        await waitForNativeSave(tester, () => name.evaluate().isNotEmpty);
      }

      Future<void> unmount() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        work.dispose();
        await tester.runAsync(() => harness.close(db));
      }

      try {
        await open();
        await tester.enterText(name, '  Morgan Customer  ');
        await tester.drag(
          find.byKey(const ValueKey('estimate-signature-pad')),
          const Offset(80, 30),
        );
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        await tester.binding.handlePopRoute();
        await waitForNativeSave(
          tester,
          () => find.byType(EstimateSignatureScreen).evaluate().isEmpty,
        );
        final retained = (await tester.runAsync(
          () => LocalDraftStore(db).list(
            organizationId: work.permissions.organizationId,
            domain: 'work/estimate-signature',
            ownerId: work.permissions.actorEmployeeId,
          ),
        ))!.single;
        expect(retained.payload, contains('Morgan Customer'));
        await unmount();
        db = (await tester.runAsync(harness.open))!;
        work = (await tester.runAsync(() => openSeededTestWorkSession(db)))!;
        await open();
        tester.view.physicalSize = const Size(900, 1200);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(name).controller!.text,
          '  Morgan Customer  ',
        );
        expect(
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
          isTrue,
        );
        expect(find.text('Use a finger or stylus to sign'), findsNothing);
        final save = find.byKey(const ValueKey('save-customer-signature'));
        await tester.runAsync(
          () => db.customStatement(
            "CREATE TRIGGER fail_signature BEFORE DELETE ON local_drafts WHEN OLD.domain = 'work/estimate-signature' BEGIN SELECT RAISE(ABORT, 'fail'); END",
          ),
        );
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => work.failureMessage != null && !work.isSaving,
        );
        expect(
          work.records
              .singleWhere((record) => record.id == 'est-1041')
              .customerSignature,
          isNull,
        );
        expect(find.byType(EstimateSignatureScreen), findsOneWidget);
        await tester.runAsync(
          () => db.customStatement('DROP TRIGGER fail_signature'),
        );
        await tester.tap(save);
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => find.byType(EstimateSignatureScreen).evaluate().isEmpty,
        );
        final signature = work.records
            .singleWhere((record) => record.id == 'est-1041')
            .customerSignature!;
        expect(signature.signedBy, 'Morgan Customer');
        expect(signature.ink!.hasInk, isTrue);
        final ink = signature.ink!.toJson();
        expect(work.storageRevisionFor('est-1041'), 2);
        expect(
          await tester.runAsync(
            () => LocalDraftStore(db).list(
              organizationId: work.permissions.organizationId,
              domain: 'work/estimate-signature',
              ownerId: work.permissions.actorEmployeeId,
            ),
          ),
          isEmpty,
        );
        await unmount();
        db = (await tester.runAsync(harness.open))!;
        work = (await tester.runAsync(() => openSeededTestWorkSession(db)))!;
        final reopened = work.records
            .singleWhere((record) => record.id == 'est-1041')
            .customerSignature!;
        expect(reopened.ink!.toJson(), ink);
        expect(reopened.signedOn, signature.signedOn);
        expect(reopened.signedRevision, signature.signedRevision);
        expect(
          reopened.invalidate(DateTime.now(), 'Changed scope').ink!.toJson(),
          ink,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        work.dispose();
        await tester.runAsync(harness.dispose);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );
}
