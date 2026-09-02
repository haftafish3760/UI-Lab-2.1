import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/shared/localized_date.dart';
import 'package:ui_lab_2_1/src/shared/operational_attention_panel.dart';
import 'package:ui_lab_2_1/src/shared/section_card.dart';
import 'package:ui_lab_2_1/src/theme/app_semantic_colors.dart';

void main() {
  testWidgets('Expenses keeps total at top and uses shared state colors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const UiLabApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();

    final date = find.byKey(const ValueKey('expenses-date-heading'));
    final total = find.byKey(const ValueKey('daily-expense-total'));
    final attention = find.byKey(const ValueKey('expenses-needs-attention'));
    final drafts = find.byKey(const ValueKey('expense-receipt-drafts-summary'));
    final entries = find.byKey(const ValueKey('expense-entries-section'));
    final dateContext = tester.element(date);
    expect(
      find.text(operationalDateLabel(dateContext, dashboardToday, year: false)),
      findsOneWidget,
    );
    expect(
      find.text(operationalDateLabel(dateContext, dashboardToday)),
      findsNothing,
    );
    expect(
      tester.getTopLeft(total).dy,
      lessThan(tester.getTopLeft(attention).dy),
    );
    expect(
      tester.getTopLeft(date).dy,
      lessThan(tester.getTopLeft(attention).dy),
    );
    expect(
      tester.getTopLeft(attention).dy,
      lessThan(tester.getTopLeft(drafts).dy),
    );
    expect(
      tester.getTopLeft(drafts).dy,
      lessThan(tester.getTopLeft(entries).dy),
    );

    final theme = Theme.of(tester.element(total));
    final semantic = theme.extension<AppSemanticColors>()!;
    final attentionHeading = tester.widget<Container>(
      find.descendant(
        of: attention,
        matching: find.byKey(const ValueKey('operational-attention-heading')),
      ),
    );
    expect(
      (attentionHeading.decoration! as BoxDecoration).color,
      semantic.dangerSurface,
    );
    expect(
      tester.widget<OperationalAttentionPanel>(attention).items,
      isNotEmpty,
    );
    expect(tester.widget<Material>(drafts).color, semantic.draftSurface);
    expect(
      tester
          .widget<Container>(
            find.byKey(const ValueKey('expense-entries-header')),
          )
          .color,
      semantic.currentSurface,
    );

    await tester.tap(find.byKey(const ValueKey('expenses-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SectionCard>(
            find.byKey(const ValueKey('planned-expenses-section')),
          )
          .backgroundColor,
      semantic.plannedSurface,
    );
    expect(find.text('Recurring'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
