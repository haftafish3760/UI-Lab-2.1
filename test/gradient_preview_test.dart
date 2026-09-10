import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/gradient_preview.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'package:ui_lab_2_1/src/shared/section_card.dart';
import 'package:ui_lab_2_1/src/shared/operational_section_heading.dart';
import 'support/load_material_test_font.dart';

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
  for (final pronounced in [false, true]) {
    testWidgets('gradient comparison $pronounced', (tester) async {
      tester.view.physicalSize = const Size(384, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey('comparison'),
              child: ColoredBox(
                color: AppColors.canvas,
                child: GradientComparisonSections(pronounced: pronounced),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sections = tester
          .widgetList<SectionCard>(find.byType(SectionCard))
          .toList();
      expect(sections.length, 2);
      final planGradient = sections.first.gradient! as LinearGradient;
      expect(planGradient.colors.first, GradientComparisonSections.blueTop);
      if (pronounced) {
        expect(planGradient.colors.last, GradientComparisonSections.blueBottom);
      }
      for (final heading in tester.widgetList<OperationalSectionHeading>(
        find.byType(OperationalSectionHeading),
      )) {
        expect(heading.background, Colors.transparent);
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('comparison')),
        matchesGoldenFile(
          'goldens/gradient_${pronounced ? 'pronounced' : 'subtle'}.png',
        ),
      );
    });
  }
  testWidgets('preview switches between the two versions', (tester) async {
    await tester.pumpWidget(const GradientPreviewApp());
    await tester.tap(find.text('Pronounced gradient'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<GradientComparisonSections>(
            find.byType(GradientComparisonSections),
          )
          .pronounced,
      isTrue,
    );
    await tester.tap(find.text('Subtle gradient'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<GradientComparisonSections>(
            find.byType(GradientComparisonSections),
          )
          .pronounced,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
