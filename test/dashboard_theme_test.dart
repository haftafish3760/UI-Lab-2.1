import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/today_entries.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/today_plan.dart';
import 'package:ui_lab_2_1/src/theme/operational_card_palette.dart';
import 'package:ui_lab_2_1/src/shared/section_card.dart';
import 'package:ui_lab_2_1/src/shared/recorded_entries_section.dart';
import 'package:ui_lab_2_1/src/shared/operational_section_heading.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  test('Work stays teal and Miles stays violet', () {
    expect(OperationalCardPalette.work.start, const Color(0xFF146C70));
    expect(OperationalCardPalette.miles.start, const Color(0xFF6954A0));
    expect(OperationalCardPalette.work.foreground, OperationalCardTone.ink);
  });
  testWidgets('pending entries use the shared full orange attention fill', (
    tester,
  ) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final entry = demoEntries.first.copyWith(
        reviewStatus: DayEntryReviewStatus.needsApproval,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(body: TodayEntries(entries: [entry])),
        ),
      );
      await tester.pumpAndSettle();
      final row = tester.widget<Material>(
        find.byKey(ValueKey('day-entry-${entry.id}')),
      );
      expect(row.color, OperationalCardPalette.attention.start);
      expect(row.color, const Color(0xFFC8955B));
      expect(
        _contrast(OperationalCardPalette.attention.foreground, row.color!),
        greaterThanOrEqualTo(4.5),
      );
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('Plan and Entries title rows align with and without Show all', (
    tester,
  ) async {
    for (final planCount in [1, demoPlan.length]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  TodayPlan(items: demoPlan.take(planCount).toList()),
                  TodayEntries(entries: demoEntries.take(1).toList()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final plan = find.byKey(const ValueKey('today-plan-header'));
      final entries = find.byKey(const ValueKey('today-entries-header'));
      expect(tester.getSize(plan).height, 59);
      expect(tester.getSize(entries).height, tester.getSize(plan).height);
      for (final header in [plan, entries]) {
        final divider = tester.widget<Divider>(
          find.descendant(of: header, matching: find.byType(Divider)),
        );
        expect(divider.thickness, 1);
        if (header == entries) {
          expect(divider.color, OperationalCardPalette.entries.row);
        }
        final title = find.descendant(
          of: header,
          matching: find.text(
            header == plan ? "Today's Plan" : "Today's Entries",
          ),
        );
        final line = find.descendant(
          of: header,
          matching: find.byType(Divider),
        );
        expect(
          tester.getTopLeft(line).dy - tester.getBottomLeft(title).dy,
          closeTo(16, 1),
        );
      }
      expect(find.byType(OperationalSectionHeading), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    }
  });
  test(
    'Entries stays between rejected dark forest and pale jade treatments',
    () {
      const tone = OperationalCardPalette.entries;
      expect(tone.start, const Color(0xFF72AE88));
      expect(tone.end, tone.start);
      expect(tone.row, const Color(0xFFAEC8B7));
      expect(
        tone.start.computeLuminance(),
        greaterThan(const Color(0xFF3E6047).computeLuminance()),
      );
      expect(
        tone.start.computeLuminance(),
        lessThan(const Color(0xFFA8D5BA).computeLuminance()),
      );
      expect(
        tone.row.computeLuminance(),
        greaterThan(tone.start.computeLuminance()),
      );
      expect(
        tone.row.computeLuminance(),
        lessThan(const Color(0xFFDEE9E0).computeLuminance()),
      );
    },
  );
  test('light mode uses tinted high-contrast surfaces', () {
    final theme = AppTheme.light;
    expect(theme.scaffoldBackgroundColor, AppColors.canvas);
    expect(theme.scaffoldBackgroundColor, isNot(Colors.white));
    expect(theme.colorScheme.surface, isNot(Colors.white));
    expect(theme.colorScheme.surface, isNot(Colors.black));
    expect(theme.colorScheme.onSurface, AppColors.ink);
    expect(
      _contrast(AppColors.ink, AppColors.surface),
      greaterThanOrEqualTo(7),
    );
    expect(
      _contrast(AppColors.muted, AppColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppColors.onHeader, AppColors.header),
      greaterThanOrEqualTo(7),
    );
  });

  test('module icon colors remain restrained and distinct in both modes', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final modules = theme.extension<AppModuleColors>()!;
      final tones = <Color>{
        modules.dashboard,
        modules.work,
        modules.expenses,
        modules.inventory,
        modules.maintenance,
      };
      expect(tones, hasLength(5));
      for (final tone in tones) {
        expect(
          _contrast(tone, theme.colorScheme.surface),
          greaterThanOrEqualTo(3),
        );
      }
    }
  });

  test('dark mode uses neutral charcoal working surfaces', () {
    final theme = AppTheme.dark;
    expect(theme.scaffoldBackgroundColor, AppColors.darkCanvas);
    expect(theme.colorScheme.surface, AppColors.darkSurface);
    expect(theme.colorScheme.surfaceContainerLow, AppColors.darkSurfaceMuted);
    expect(theme.colorScheme.surfaceContainerHigh, AppColors.darkSurfaceStrong);
  });

  testWidgets('dark Plan and Entries headers preserve semantic hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Row(
            children: [
              Expanded(child: TodayPlan()),
              Expanded(child: TodayEntries()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final planHeader = tester.widget<Container>(
      find.byKey(const ValueKey('today-plan-header')),
    );
    final entriesHeader = tester.widget<Container>(
      find.byKey(const ValueKey('today-entries-header')),
    );
    expect(
      (planHeader.decoration! as BoxDecoration).color,
      OperationalCardPalette.plan.start,
    );
    expect(
      (entriesHeader.decoration! as BoxDecoration).color,
      OperationalCardPalette.entries.start,
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'meaning colors are distinct, dark enough, and legible throughout gradients',
    () {
      const tones = [
        OperationalCardPalette.plan,
        OperationalCardPalette.entries,
        OperationalCardPalette.attention,
        OperationalCardPalette.payments,
        OperationalCardPalette.expenses,
        OperationalCardPalette.miles,
        OperationalCardPalette.work,
      ];
      expect(tones.map((tone) => tone.start).toSet(), hasLength(7));
      for (final tone in tones) {
        for (var step = 0; step <= 20; step++) {
          final fill = Color.lerp(tone.start, tone.end, step / 20)!;
          expect(_contrast(tone.foreground, fill), greaterThanOrEqualTo(4.5));
        }
        expect(
          _contrast(
            tone == OperationalCardPalette.plan ||
                    tone == OperationalCardPalette.entries
                ? OperationalCardTone.darkInk
                : tone.foreground,
            tone.row,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(
          theme.floatingActionButtonTheme.backgroundColor,
          OperationalCardPalette.action,
        );
        expect(
          theme.floatingActionButtonTheme.backgroundColor,
          isNot(OperationalCardPalette.plan.start),
        );
      }
    },
  );

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets(
      'full sections and rows retain meaning colors in ${theme.brightness}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Column(children: [TodayPlan(), TodayEntries()]),
              ),
            ),
          ),
        );
        final sections = tester
            .widgetList<SectionCard>(find.byType(SectionCard))
            .toList();
        expect(find.byType(RecordedEntriesSection), findsOneWidget);
        expect(sections[0].gradient, isNull);
        expect(sections[1].gradient, isNull);
        final planHeader = tester.widget<Container>(
          find.byKey(const ValueKey('today-plan-header')),
        );
        final entriesHeader = tester.widget<Container>(
          find.byKey(const ValueKey('today-entries-header')),
        );
        expect(
          sections[0].backgroundColor,
          (planHeader.decoration! as BoxDecoration).color,
        );
        expect(
          sections[1].backgroundColor,
          (entriesHeader.decoration! as BoxDecoration).color,
        );
        final planRow = tester.widget<Material>(
          find.byKey(ValueKey('plan-row-${demoPlan.first.id}')),
        );
        final entryRow = tester.widget<Material>(
          find.byKey(ValueKey('day-entry-${demoEntries.first.id}')),
        );
        expect(planRow.color, OperationalCardPalette.plan.row);
        expect(entryRow.color, OperationalCardPalette.attention.start);
        final ordinaryRow = tester.widget<Material>(
          find.byKey(ValueKey('day-entry-${demoEntries[2].id}')),
        );
        expect(ordinaryRow.color, OperationalCardPalette.entries.row);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('long plan titles reflow instead of clipping', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const title =
        'Replace kitchen faucet and repair the damaged cabinet supply lines';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: TodayPlan(
            items: [
              PlanItem(
                '8:00 AM',
                title,
                'Maya Thompson',
                Icons.plumbing_outlined,
                Colors.blue,
                id: 'long-title',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(title), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('plan-row-long-title'))).height,
      greaterThan(60),
    );
    expect(tester.takeException(), isNull);
  });
}

double _contrast(Color foreground, Color background) {
  final light = foreground.computeLuminance();
  final dark = background.computeLuminance();
  final lighter = light > dark ? light : dark;
  final darker = light > dark ? dark : light;
  return (lighter + .05) / (darker + .05);
}
