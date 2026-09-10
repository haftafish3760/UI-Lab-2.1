import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_gateway.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_ui_controller.dart';
import 'package:ui_lab_2_1/src/startup/open_ui_lab_application.dart';

class _UnavailableNotifications extends UnsupportedNativeNotificationGateway {
  @override
  Future<void> initialize() async =>
      throw StateError('private platform failure');
  @override
  Future<String?> takeLaunchPayload() async {
    await initialize();
    return null;
  }
}

void main() {
  test(
    'notification failure cannot block opening or recovering SQLite drafts',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'notification-startup-',
      );
      UiLabApp? app;
      try {
        app =
            await openUiLabApplication(
                  storageDirectory: directory,
                  nativeNotifications: _UnavailableNotifications(),
                )
                as UiLabApp;
        await app.draftStore!.save(
          organizationId: 'org',
          ownerId: 'user',
          domain: 'invoice',
          draftId: 'unfinished',
          expectedRevision: 0,
          payload: {'raw': '  12.  '},
          occurredAt: DateTime.now(),
        );
        await closeUnstartedApplication(app);
        app = null;
        app =
            await openUiLabApplication(
                  storageDirectory: directory,
                  nativeNotifications: _UnavailableNotifications(),
                )
                as UiLabApp;
        final recovered = await app.draftStore!.find(
          organizationId: 'org',
          ownerId: 'user',
          domain: 'invoice',
          draftId: 'unfinished',
        );
        expect(app.draftStore!.decode(recovered!), {'raw': '  12.  '});
      } finally {
        if (app != null) await closeUnstartedApplication(app);
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'notification launch failure stays in reminder state, not an uncaught app error',
    (tester) async {
      await tester.pumpWidget(
        UiLabApp(nativeNotificationGateway: _UnavailableNotifications()),
      );
      await tester.pumpAndSettle();
      final element = tester.element(find.byType(Scaffold).first);
      final controller = NativeNotificationUiScope.maybeOf(element)!;
      expect(controller.phase, NativeNotificationUiPhase.failed);
      expect(
        controller.failureMessage,
        'Device reminders could not be updated.',
      );
      expect(find.textContaining('private platform failure'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
