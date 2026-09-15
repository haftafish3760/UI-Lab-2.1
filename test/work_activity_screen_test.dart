import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/screens/work/work_activity_screen.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'work_activity_history_test.dart' show access, record;

void main() {
  for (final width in [320.0, 430.0, 1440.0]) {
    testWidgets('people and committed activity remain readable at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      addTearDown(harness.dispose);
      final work = (await tester.runAsync(() async {
        final session = await WorkPersistenceSession.open(
          SqliteWorkRepository(await harness.open()),
          access(),
        );
        await session.create(record);
        return session;
      }))!;
      addTearDown(work.dispose);
      final store = PrototypeOperationsStore(workSession: work);
      addTearDown(store.dispose);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const WorkActivityScreen(record: record),
          ),
        ),
      );
      for (
        var i = 0;
        i < 100 && find.text('Saved activity').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(find.text('Saved activity'), findsOneWidget);
      expect(find.text('Created document'), findsOneWidget);
      expect(find.textContaining('Employee ID: creator'), findsWidgets);
      expect(find.textContaining('No employees assigned'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
