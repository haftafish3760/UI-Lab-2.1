import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/startup/application_host_controller.dart';
import 'package:ui_lab_2_1/src/startup/application_startup_screen.dart';

void main() {
  for (final width in [320.0, 1400.0]) {
    testWidgets('host blocks entry points without losing route at $width LP', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      final semantics = tester.ensureSemantics();
      bool actionIsAccessible() {
        final root = tester
            .binding
            .renderViews
            .single
            .owner!
            .semanticsOwner!
            .rootSemanticsNode;
        bool found = false;
        void inspect(SemanticsNode node) {
          if (node.getSemanticsData().label == 'Change record') found = true;
          node.visitChildren((child) {
            inspect(child);
            return true;
          });
        }

        if (root != null) inspect(root);
        return found;
      }

      final focus = FocusNode();
      final navigator = GlobalKey<NavigatorState>();
      final host = ApplicationHostController();
      var changes = 0;
      final app = MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Home')),
        routes: {
          '/external': (_) => const Scaffold(body: Text('External route')),
        },
      );
      try {
        await tester.pumpWidget(
          ApplicationStartupScreen(hostController: host, load: () async => app),
        );
        await tester.pumpAndSettle();
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: TextButton(
                focusNode: focus,
                onPressed: () => changes++,
                child: const Text('Change record'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        focus.requestFocus();
        await tester.pump();
        expect(focus.hasFocus, isTrue);
        expect(actionIsAccessible(), isTrue);
        host.blockEntryPoints(true);
        await tester.pumpAndSettle();
        expect(focus.hasFocus, isFalse);
        expect(actionIsAccessible(), isFalse);
        await tester.tap(find.text('Change record'), warnIfMissed: false);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(await tester.binding.handlePopRoute(), isTrue);
        // Exercise the platform navigation channel, not a direct Navigator call.
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/navigation',
          const JSONMethodCodec().encodeMethodCall(
            const MethodCall('pushRouteInformation', {'location': '/external'}),
          ),
          (_) {},
        );
        await tester.pumpAndSettle();
        expect(changes, 0);
        expect(find.text('Change record'), findsOneWidget);
        expect(find.text('External route'), findsNothing);
        expect(host.currentApplication, same(app));
        host.blockEntryPoints(false);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Change record'));
        expect(changes, 1);
        expect(actionIsAccessible(), isTrue);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        expect(host.currentApplication, isNull);
        expect(() => host.blockEntryPoints(true), throwsStateError);
        focus.dispose();
        semantics.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  }
}
