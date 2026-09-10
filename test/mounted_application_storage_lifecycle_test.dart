import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_gateway.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/startup/open_ui_lab_application.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'mounted lifecycle holds storage across resize and preserves raw input after detach',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      final root = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('mounted-lifecycle-'),
      ))!;
      final app =
          (await tester.runAsync(
                () => openUiLabApplication(
                  storageDirectory: root,
                  nativeNotifications:
                      const UnsupportedNativeNotificationGateway(),
                ),
              ))!
              as UiLabApp;
      final lifecycle = app.storageLifecycle!;
      final draft = DraftAutosaveSession(
        store: app.draftStore!,
        organizationId: 'business',
        ownerId: 'owner',
        domain: 'invoice',
        draftId: 'unfinished',
      );
      var closed = false;
      try {
        await tester.pumpWidget(app);
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).first,
        );
        final route = MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Unfinished workflow')),
        );
        navigator.push(route);
        await tester.pumpAndSettle();
        await tester.runAsync(draft.initialize);
        draft.replaceInput({'amount': '12.', 'notes': '  raw  '});
        late void Function() resume;
        await finishNativeOperation(tester, () async {
          resume = await lifecycle.pauseAndFlush();
        });
        expect(draft.isCommittingInput, isTrue);
        expect(route.popDisposition, RoutePopDisposition.doNotPop);
        expect(route.popGestureEnabled, isFalse);
        await navigator.maybePop();
        await tester.pumpAndSettle();
        expect(find.text('Unfinished workflow'), findsOneWidget);
        await expectLater(lifecycle.close(), throwsStateError);
        await tester.runAsync(
          () => expectLater(
            app.preferencesStore!.saveMany({'themeMode': 'dark'}),
            throwsStateError,
          ),
        );
        tester.view.physicalSize = const Size(1400, 900);
        await tester.pump();
        expect(draft.isCommittingInput, isTrue);
        expect(() => draft.replaceInput({'amount': 'wrong'}), throwsStateError);
        resume();
        expect(route.popDisposition, RoutePopDisposition.pop);
        await navigator.maybePop();
        await tester.pumpAndSettle();
        expect(find.text('Unfinished workflow'), findsNothing);
        expect(draft.isCommittingInput, isFalse);
        draft.replaceInput({
          'amount': '12.',
          'notes': '  edited after resume  ',
        });
        await finishNativeOperation(tester, () async {
          await lifecycle.pauseAndFlush();
        });
        await tester.pumpWidget(const SizedBox.shrink());
        await finishNativeOperation(tester, draft.close);
        await tester.runAsync(lifecycle.close);
        closed = true;
        final reopened = (await tester.runAsync(
          () => LocalPersistence.open(directory: root),
        ))!;
        try {
          final saved = await tester.runAsync(
            () => reopened.drafts.find(
              organizationId: 'business',
              ownerId: 'owner',
              domain: 'invoice',
              draftId: 'unfinished',
            ),
          );
          expect(reopened.drafts.decode(saved!), {
            'amount': '12.',
            'notes': '  edited after resume  ',
          });
        } finally {
          await tester.runAsync(reopened.close);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        if (!closed) {
          await finishNativeOperation(tester, draft.close);
          // Fixture-only cleanup after an assertion failure, not a production close path.
          await tester.runAsync(app.workSession!.repository.database.close);
        }
        await tester.runAsync(() => root.delete(recursive: true));
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );
}
