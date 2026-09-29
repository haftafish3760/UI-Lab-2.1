import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/quote_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_schedule_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import '../../test/support/storage/native_widget_pump.dart';

void main() {
  const path = String.fromEnvironment('DEMO_REVIEW_PATH');
  for (final width in [360.0, 1200.0]) {
    testWidgets('saved demo invoices quotes and schedule render at $width', (
      tester,
    ) async {
      final directory = Directory(path).absolute;
      final root = Directory('output/work-demo').absolute.path;
      expect(path, isNotEmpty);
      expect(directory.path.startsWith('$root/'), isTrue);
      expect(
        File('${directory.path}/review-workspace-id').existsSync(),
        isTrue,
      );
      await tester.binding.setSurfaceSize(Size(width, 1000));
      final persistence = (await tester.runAsync(
        () => LocalPersistence.open(
          directory: directory,
          removeOwnerDemoData: false,
        ),
      ))!;
      final work = (await tester.runAsync(
        () => openUiLabWorkSession(persistence.database),
      ))!;
      final clients = (await tester.runAsync(
        () => openUiLabDirectory(persistence.database),
      ))!;
      final store = PrototypeOperationsStore(
        workSession: work,
        customers: clients.customers,
      );
      final scope = OperationalScopeController();
      addTearDown(() async {
        store.dispose();
        scope.dispose();
        clients.dispose();
        work.dispose();
        await finishNativeOperation(tester, persistence.close);
        await tester.binding.setSurfaceSize(null);
      });
      expect(work.records, hasLength(12));
      final day = DateTime.now();
      final screens = <Widget>[
        InvoiceWorkspaceScreen(initialDay: day),
        QuoteWorkspaceScreen(initialDay: day),
        WorkScheduleScreen(initialDay: day),
      ];
      for (var i = 0; i < screens.length; i++) {
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                key: ValueKey('screen-$i'),
                theme: AppTheme.light,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: screens[i],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await waitForNativeSave(tester, () => !store.workSession!.isSaving);
        expect(tester.takeException(), isNull, reason: 'screen $i at $width');
        // Exercise the scrollable body so lower populated sections and calendars build.
        var sawDemo = find.textContaining('[Demo]').evaluate().isNotEmpty;
        final scroll = find.byType(Scrollable).first;
        for (var n = 0; n < 5; n++) {
          await tester.drag(scroll, const Offset(0, -350));
          await tester.pumpAndSettle();
          sawDemo =
              sawDemo || find.textContaining('[Demo]').evaluate().isNotEmpty;
          expect(
            tester.takeException(),
            isNull,
            reason: 'screen $i scroll $n at $width',
          );
        }
        expect(
          sawDemo,
          isTrue,
          reason: 'Saved demo titles must appear on screen $i',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
