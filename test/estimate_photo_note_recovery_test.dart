import 'package:flutter/material.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_photos_draft_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_site_photos_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'unfinished photo note survives route disposal and SQLite reopen',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var database = (await tester.runAsync(harness.open))!;
      DraftAutosaveSession makeDraft() => DraftAutosaveSession(
        store: LocalDraftStore(database),
        organizationId: 'company',
        domain: 'work/estimate-editor',
        draftId: 'photo-input',
        ownerId: 'alex',
      );
      var draft = makeDraft();
      await tester.runAsync(draft.initialize);
      addTearDown(() async {
        await harness.dispose();
      });
      final photo = WorkSitePhoto(
        id: 'photo',
        path: '/missing-test-image',
        name: 'Valve.jpg',
        source: WorkSitePhotoSource.file,
        addedOn: DateTime(2026, 9, 9),
      );
      final scope = OperationalScopeController();
      addTearDown(scope.dispose);
      Future<void> open() async {
        await tester.pumpWidget(
          OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => EstimateSitePhotosScreen(
                          initialDay: DateTime(2026, 9, 9),
                          initialPhotos: [photo],
                          draftSession: draft,
                          recoveryInput: draft.input.isEmpty
                              ? null
                              : EstimatePhotosDraftInput.fromPayload(
                                  draft.input,
                                ),
                          onDraftChanged: (input) =>
                              draft.replaceInput(input.toPayload()),
                        ),
                      ),
                    ),
                    child: const Text('Open photos'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open photos'));
        await tester.pumpAndSettle();
      }

      await open();
      await tester.tap(find.text('Add or edit note'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Valve behind the ');
      await tester.tap(find.text('Keep unfinished note'));
      await tester.pumpAndSettle();
      await waitForNativeSave(
        tester,
        () => draft.state == DraftSaveState.savedLocally,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('save-estimate-photos')),
            )
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await waitForNativeSave(
        tester,
        () => find.byType(EstimateSitePhotosScreen).evaluate().isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(draft.close);
      await tester.runAsync(() => harness.close(database));
      database = (await tester.runAsync(harness.open))!;
      draft = makeDraft();
      await tester.runAsync(draft.initialize);
      await open();
      await tester.tap(find.text('Add or edit note'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Valve behind the ',
      );
      await tester.enterText(
        find.byType(TextField),
        'Valve behind the heater.',
      );
      await tester.tap(find.text('Save note'));
      await tester.pumpAndSettle();
      await waitForNativeSave(
        tester,
        () => draft.state == DraftSaveState.savedLocally,
      );
      expect(draft.input['pendingNotes'], isEmpty);
      expect(
        ((draft.input['photos'] as List).single as Map)['note'],
        'Valve behind the heater.',
      );
      await tester.tap(find.byKey(const ValueKey('save-estimate-photos')));
      await waitForNativeSave(
        tester,
        () => find.byType(EstimateSitePhotosScreen).evaluate().isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(draft.close);
    },
  );
}
