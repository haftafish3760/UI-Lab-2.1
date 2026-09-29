import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/work_items_editor.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'package:ui_lab_2_1/src/shared/editor_draft_status.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'labor form separates fields and puts explanations first at $scale text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scope = OperationalScopeController();
        addTearDown(scope.dispose);
        await tester.pumpWidget(
          OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: WorkLineItemEditor(
                initialType: WorkLineItemType.labor,
                initialUnit: 'hour',
                allowedTypes: [WorkLineItemType.labor],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Finder field(String label) => find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        final name = field('Labor name');
        final description = field('Description');
        await tester.ensureVisible(description);
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(description).dy - tester.getBottomLeft(name).dy,
          greaterThanOrEqualTo(20),
        );
        final workers = field('Number of workers');
        await tester.ensureVisible(workers);
        await tester.pumpAndSettle();
        expect(
          tester
              .getBottomLeft(
                find.text(
                  'Use a separate labor entry for different rates or hours.',
                ),
              )
              .dy,
          lessThan(tester.getTopLeft(workers).dy),
        );
        final cost = field('Your cost per worker-hour (optional)');
        await tester.ensureVisible(cost);
        await tester.pumpAndSettle();
        expect(
          tester
              .getBottomLeft(
                find.text(
                  'Private cost for estimated gross profit. Never shown on the customer copy.',
                ),
              )
              .dy,
          lessThan(tester.getTopLeft(cost).dy),
        );
        expect(
          tester.widget<TextField>(workers).textInputAction,
          TextInputAction.next,
        );
        final units = tester.widget<DropdownButton<String>>(
          find.byType(DropdownButton<String>),
        );
        expect(
          units.items!.map((item) => item.value),
          containsAll(['mile', 'kilometer', 'trip', 'load']),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('quiet save status still exposes write failure and retry', (
    tester,
  ) async {
    var retried = false;
    Future<void> show(DraftSaveState state) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorDraftStatus(
            state: state,
            showRoutineStatus: false,
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    await show(DraftSaveState.saving);
    expect(find.text('Saving on this device…'), findsNothing);
    await show(DraftSaveState.savedLocally);
    expect(find.text('Draft saved on this device'), findsNothing);
    await show(DraftSaveState.notSaved);
    expect(find.text('Latest changes have not been saved.'), findsOneWidget);
    await tester.tap(find.text('Retry save'));
    expect(retried, isTrue);
  });
}
