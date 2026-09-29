import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_photos_draft_input.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_photo_preview_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_site_photos_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/local_document_preview.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'photo preview and confirmed removal preserve source dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final database = (await tester.runAsync(harness.open))!;
        final image = File('${harness.directory.path}/test-photo.png');
        final bytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=',
        );
        await tester.runAsync(() => image.writeAsBytes(bytes, flush: true));
        final photo = WorkSitePhoto(
          id: 'qa-photo',
          path: image.path,
          name: 'Synthetic inspection photo.png',
          source: WorkSitePhotoSource.file,
          addedOn: DateTime(2026, 9, 27),
          note: 'Before work: damaged fitting.',
        );
        var draft = DraftAutosaveSession(
          store: LocalDraftStore(database),
          organizationId: 'photo-qa',
          domain: 'work/estimate-editor',
          draftId: 'photo-management',
          ownerId: 'qa',
        );
        await tester.runAsync(draft.initialize);
        draft.replaceInput(
          EstimatePhotosDraftInput(
            photos: [photo],
            pendingNotes: const {},
          ).toPayload(),
        );
        await waitForNativeSave(
          tester,
          () => draft.state == DraftSaveState.savedLocally,
        );
        final scope = OperationalScopeController();
        addTearDown(() async {
          scope.dispose();
          if (!draft.isClosed) await finishNativeOperation(tester, draft.close);
          await harness.dispose();
        });
        await tester.pumpWidget(
          OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.8)),
                child: child!,
              ),
              home: EstimateSitePhotosScreen(
                initialDay: DateTime(2026, 9, 27),
                initialPhotos: [photo],
                draftSession: draft,
                onDraftChanged: (input) =>
                    draft.replaceInput(input.toPayload()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final savePhotos = find.byKey(const ValueKey('save-estimate-photos'));
        // Long content must not leave Save occupying the phone viewport.
        expect(savePhotos.hitTestable(), findsNothing);
        await tester.ensureVisible(savePhotos);
        await tester.pumpAndSettle();
        expect(savePhotos.hitTestable(), findsOneWidget);
        expect(
          tester.getTopLeft(savePhotos).dy,
          greaterThan(tester.getBottomLeft(find.text('View photo')).dy),
        );
        await tester.drag(find.byType(ListView).first, const Offset(0, 1800));
        await tester.pumpAndSettle();
        expect(savePhotos.hitTestable(), findsNothing);
        final view = find.text('View photo');
        await tester.ensureVisible(view);
        await tester.pumpAndSettle();
        await tester.tap(view);
        await tester.pumpAndSettle();
        expect(find.byType(EstimatePhotoPreviewScreen), findsOneWidget);
        expect(
          tester
              .widget<LocalDocumentPreview>(find.byType(LocalDocumentPreview))
              .path,
          image.path,
        );
        expect(find.byType(InteractiveViewer), findsOneWidget);
        expect(find.text('This image could not be opened.'), findsNothing);
        expect(find.text(photo.note), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();

        Future<void> requestRemoval() async {
          final menu = find.byTooltip('Photo actions');
          await tester.ensureVisible(menu);
          await tester.pumpAndSettle();
          await tester.tap(menu);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Remove photo'));
          await tester.pumpAndSettle();
        }

        await requestRemoval();
        expect(find.text('Remove photo from this estimate?'), findsOneWidget);
        expect(draft.input['photos'], hasLength(1));
        await tester.tap(find.text('Keep photo'));
        await tester.pumpAndSettle();
        expect(draft.input['photos'], hasLength(1));
        expect(find.text(photo.name), findsOneWidget);
        await requestRemoval();
        await tester.tap(find.text('Remove photo'));
        await waitForNativeSave(
          tester,
          () => draft.state == DraftSaveState.savedLocally,
        );
        expect(draft.input['photos'], isEmpty);
        expect(await tester.runAsync(image.readAsBytes), bytes);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await finishNativeOperation(tester, draft.close);
        draft = DraftAutosaveSession(
          store: LocalDraftStore(database),
          organizationId: 'photo-qa',
          domain: 'work/estimate-editor',
          draftId: 'photo-management',
          ownerId: 'qa',
        );
        await tester.runAsync(draft.initialize);
        expect(draft.input['photos'], isEmpty);
        expect(await tester.runAsync(image.readAsBytes), bytes);
        await finishNativeOperation(tester, draft.close);
      },
    );
  }
}
