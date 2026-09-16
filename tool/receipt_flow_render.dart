// Run with flutter test tool/receipt_flow_render.dart. These are review
// artifacts, not automatically accepted golden baselines.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_entry_flow.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import '../test/support/load_material_test_font.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_welcome_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadMaterialTestFont);
  setUpAll(() async {
    final loader = FontLoader('MaterialIcons');
    loader.addFont(
      File(
        '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes().then(ByteData.sublistView),
    );
    await loader.load();
  });
  for (final dark in [false, true]) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('receipt flow render $width dark $dark', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: _renderTheme(dark ? AppTheme.dark : AppTheme.light),
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => openExpenseEntryFlow(
                      context,
                      expenseDate: DateTime(2026, 9, 15),
                      permissions: const ExpensePermissions.development(),
                      onConfirm: (record) async => record,
                    ),
                    child: const Text('Start'),
                  ),
                ),
              ),
            ),
          ),
        );
        Future<void> capture(String step) async {
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final path =
                'build/receipt-flow-review/${dark ? 'dark' : 'light'}-${width.toInt()}-$step.png';
            final file = File(path);
            await file.parent.create(recursive: true);
            await file.writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }

        final preferences = AppPreferencesController();
        final startContext = tester.element(find.text('Start'));
        Navigator.of(startContext).push<void>(
          MaterialPageRoute(
            builder: (_) => ExpenseWelcomeScreen(preferences: preferences),
          ),
        );
        await capture('welcome');
        await tester.tap(
          find.byKey(const ValueKey('expense-welcome-continue')),
        );
        await capture('assistance');
        final noHelp = find.byKey(const ValueKey('expense-setup-manual'));
        await tester.ensureVisible(noHelp);
        await tester.tap(noHelp);
        final continueSetup = find.byKey(
          const ValueKey('expense-welcome-continue'),
        );
        await tester.ensureVisible(continueSetup);
        await tester.pump();
        await tester.tap(continueSetup);
        await tester.pumpAndSettle();
        preferences.dispose();
        await tester.tap(find.text('Start'));
        await capture('setup');
        await tester.tap(find.byKey(const ValueKey('choose-receipt-category')));
        await capture('categories');
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('continue-expense-setup')));
        await capture('sources');
      });
    }
  }
}

// Explicitly resolve styles which leave their platform font unspecified.
// This only replaces the test binding's Ahem fallback, not product typography.
ThemeData _renderTheme(ThemeData theme) {
  ButtonStyle? font(ButtonStyle? style) => style?.copyWith(
    textStyle: WidgetStatePropertyAll(
      style.textStyle?.resolve({})?.copyWith(fontFamily: 'Roboto'),
    ),
  );
  return theme.copyWith(
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        fontFamily: 'Roboto',
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: font(theme.filledButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: font(theme.outlinedButtonTheme.style),
    ),
  );
}
