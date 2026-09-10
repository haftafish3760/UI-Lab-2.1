import 'package:flutter/material.dart';
import 'src/screens/dashboard/today_entries.dart';
import 'src/screens/dashboard/today_plan.dart';
import 'src/screens/dashboard/dashboard_models.dart';
import 'src/theme/app_theme.dart';

void main() => runApp(const GradientPreviewApp());

/// Isolated visual trial. Does not write business records or change defaults.
class GradientPreviewApp extends StatefulWidget {
  const GradientPreviewApp({super.key});
  @override
  State<GradientPreviewApp> createState() => _GradientPreviewAppState();
}

class _GradientPreviewAppState extends State<GradientPreviewApp> {
  bool pronounced = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Subtle gradient')),
                  ButtonSegment(
                    value: true,
                    label: Text('Pronounced gradient'),
                  ),
                ],
                selected: {pronounced},
                onSelectionChanged: (value) =>
                    setState(() => pronounced = value.single),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: GradientComparisonSections(pronounced: pronounced),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class GradientComparisonSections extends StatelessWidget {
  const GradientComparisonSections({required this.pronounced, super.key});
  final bool pronounced;
  static const blueTop = Color(0xFF1976B9);
  static const blueBottom = Color(0xFF0F4068);
  static const greenTop = Color(0xFF89C49E);
  static const greenBottom = Color(0xFF59966C);
  LinearGradient gradient(Color top, Color bottom) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [top, pronounced ? bottom : Color.lerp(top, bottom, .30)!],
  );
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TodayPlan(previewGradient: gradient(blueTop, blueBottom)),
            const SizedBox(height: 16),
            TodayEntries(
              previewGradient: gradient(greenTop, greenBottom),
              entries: demoEntries.skip(2).take(3).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
