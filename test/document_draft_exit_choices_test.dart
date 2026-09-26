import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/shared/draft_navigation_guard.dart';

class _Draft extends Fake implements DraftAutosaveSession {
  int saves = 0;
  int discards = 0;
  bool fail = false;
  @override
  Future<void> flush() async {
    if (fail) throw StateError('Disk full');
    saves++;
  }

  @override
  Future<void> discard() async {
    discards++;
  }
}

class _Editor extends StatefulWidget {
  const _Editor(this.draft, {this.changed = true});
  final _Draft draft;
  final bool changed;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> with DraftNavigationGuard {
  @override
  DraftAutosaveSession get navigationDraft => widget.draft;
  @override
  bool get confirmDraftExit => widget.changed;
  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: leaveDraftRoute),
        title: const Text('Editor'),
      ),
      body: const SizedBox.expand(),
    ),
  );
}

void main() {
  Future<_Draft> open(
    WidgetTester tester, {
    bool changed = true,
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    final draft = _Draft();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => _Editor(draft, changed: changed),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return draft;
  }

  testWidgets('Android Back offers keep editing, save draft, and discard', (
    tester,
  ) async {
    final draft = await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Save draft'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Editor'), findsOneWidget);
    expect(draft.saves, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();
    expect(draft.saves, 1);
    expect(draft.discards, 0);
    expect(find.text('Open'), findsOneWidget);
  });
  testWidgets('discard is explicit and does not save the discarded input', (
    tester,
  ) async {
    final draft = await open(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(draft.discards, 1);
    expect(draft.saves, 0);
    expect(find.text('Open'), findsOneWidget);
  });
  testWidgets('failed save keeps editor open and permits retry', (
    tester,
  ) async {
    final draft = await open(tester)
      ..fail = true;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();
    expect(find.text('Editor'), findsOneWidget);
    expect(draft.discards, 0);
    draft.fail = false;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });
  testWidgets('unchanged form leaves without a changes prompt', (tester) async {
    await open(tester, changed: false);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Keep your changes?'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });
  testWidgets('iOS leading edge gesture opens the same draft choices', (
    tester,
  ) async {
    await open(tester, platform: TargetPlatform.iOS);
    await tester.dragFrom(const Offset(4, 250), const Offset(180, 0));
    await tester.pumpAndSettle();
    expect(find.text('Keep your changes?'), findsOneWidget);
    expect(find.text('Editor'), findsOneWidget);
  });
}
