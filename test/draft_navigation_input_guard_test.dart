import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_repository.dart';
import 'package:ui_lab_2_1/src/shared/draft_navigation_guard.dart';

class _PendingDraftRepository extends Fake implements DraftRepository {
  final write = Completer<int>();
  @override
  Future<SavedDraft?> find({
    required String organizationId,
    required String domain,
    required String draftId,
    required String ownerId,
  }) async => null;
  @override
  Future<int> save({
    required String organizationId,
    required String domain,
    required String draftId,
    required String ownerId,
    required int expectedRevision,
    required Map<String, Object?> payload,
    required DateTime occurredAt,
  }) => write.future;
}

class _Editor extends StatefulWidget {
  const _Editor({
    required this.busy,
    required this.text,
    required this.focus,
    required this.action,
    this.draft,
    super.key,
  });
  final ValueNotifier<bool> busy;
  final TextEditingController text;
  final FocusNode focus;
  final VoidCallback action;
  final DraftAutosaveSession? draft;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> with DraftNavigationGuard {
  @override
  DraftAutosaveSession? get navigationDraft => widget.draft;
  @override
  bool get blockDraftNavigation => widget.busy.value;
  void refresh() => setState(() {});
  @override
  void initState() {
    super.initState();
    widget.busy.addListener(refresh);
  }

  @override
  void dispose() {
    widget.busy.removeListener(refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      body: Column(
        children: [
          TextField(controller: widget.text, focusNode: widget.focus),
          TextButton(onPressed: widget.action, child: const Text('Action')),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets(
    'pending confirmation excludes keyboard focus and pointer actions; failure permits editing again',
    (tester) async {
      final busy = ValueNotifier(false);
      final text = TextEditingController(text: '12.');
      final focus = FocusNode();
      addTearDown(busy.dispose);
      addTearDown(text.dispose);
      addTearDown(focus.dispose);
      var actions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: _Editor(
            busy: busy,
            text: text,
            focus: focus,
            action: () => actions++,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(TextField));
      expect(focus.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      busy.value = true;
      await tester.pump();
      await tester.pump();
      expect(focus.hasFocus, isFalse);
      expect(focus.canRequestFocus, isFalse);
      expect(tester.testTextInput.hasAnyClients, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.tap(find.text('Action'), warnIfMissed: false);
      expect(text.text, '12.');
      expect(actions, 0);
      busy.value = false;
      await tester.pump();
      await tester.enterText(find.byType(TextField), '12.00');
      expect(text.text, '12.00');
      expect(focus.hasFocus, isTrue);
      await tester.tap(find.text('Action'));
      expect(actions, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'leaving during pending autosave releases the IME and failed flush restores interaction',
    (tester) async {
      final repository = _PendingDraftRepository();
      final draft = DraftAutosaveSession(
        store: repository,
        organizationId: 'org',
        domain: 'test',
        draftId: 'draft',
        ownerId: 'owner',
      );
      await draft.initialize();
      draft.replaceInput({'amount': '12.'});
      final busy = ValueNotifier(false);
      final text = TextEditingController(text: '12.');
      final focus = FocusNode();
      addTearDown(busy.dispose);
      addTearDown(text.dispose);
      addTearDown(focus.dispose);
      final key = GlobalKey<_EditorState>();
      await tester.pumpWidget(
        MaterialApp(
          home: _Editor(
            key: key,
            busy: busy,
            text: text,
            focus: focus,
            draft: draft,
            action: () {},
          ),
        ),
      );
      await tester.showKeyboard(find.byType(TextField));
      final leaving = key.currentState!.leaveDraftRoute();
      var finished = false;
      unawaited(leaving.then((_) => finished = true));
      await tester.pump();
      await tester.pump();
      expect(finished, isFalse);
      expect(focus.hasFocus, isFalse);
      expect(tester.testTextInput.hasAnyClients, isFalse);
      repository.write.completeError(StateError('disk write failed'));
      await leaving;
      await tester.pump();
      expect(
        find.text(
          'Your latest input has not been saved. Retry saving before leaving.',
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), '12.00');
      expect(focus.hasFocus, isTrue);
      expect(text.text, '12.00');
      expect(draft.input['amount'], '12.');
      await expectLater(draft.close(), throwsStateError);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
