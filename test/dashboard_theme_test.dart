import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/today_entries.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/today_plan.dart';
import 'package:ui_lab_2_1/src/theme/app_semantic_colors.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
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
    final semantic = AppTheme.dark.extension<AppSemanticColors>()!;
    expect(
      (planHeader.decoration! as BoxDecoration).color,
      semantic.plannedSurface,
    );
    expect(
      (entriesHeader.decoration! as BoxDecoration).color,
      semantic.currentSurface,
    );
    expect(tester.takeException(), isNull);
  });

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
