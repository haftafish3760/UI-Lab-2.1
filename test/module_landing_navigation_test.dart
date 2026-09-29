import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_repository.dart';
import 'package:ui_lab_2_1/src/shared/draft_navigation_guard.dart';
import 'package:ui_lab_2_1/src/shared/module_landing_navigation.dart';

class _Repository extends Fake implements DraftRepository {
  bool fail = false;
  Map<String, Object?>? saved;
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
  }) async {
    if (fail) throw StateError('Injected storage failure');
    saved = Map.of(payload);
    return expectedRevision + 1;
  }
}

class _Editor extends StatefulWidget {
  const _Editor(this.draft);
  final DraftAutosaveSession draft;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> with DraftNavigationGuard {
  @override
  DraftAutosaveSession get navigationDraft => widget.draft;
  @override
  bool get confirmDraftExit => true;
  @override
  Widget build(BuildContext context) =>
      guardDraftNavigation(const Scaffold(body: Text('Unfinished invoice')));
}

void main() {
  for (final fail in [false, true]) {
    testWidgets(
      'landing navigation respects choice and save result failure=$fail',
      (tester) async {
        final repository = _Repository()..fail = fail;
        final draft = DraftAutosaveSession(
          store: repository,
          organizationId: 'org',
          domain: 'invoice',
          draftId: 'draft',
          ownerId: 'owner',
        );
        await draft.initialize();
        draft.replaceInput({'title': 'Kitchen repair', 'price': '125.'});
        final navigation = ModuleLandingNavigation();
        await tester.pumpWidget(
          MaterialApp(
            home: ModuleLandingScope(
              navigation: navigation,
              child: Navigator(
                key: navigation.key,
                observers: [navigation],
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Work landing')),
                ),
              ),
            ),
          ),
        );
        navigation.key.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Invoices')),
          ),
        );
        await tester.pumpAndSettle();
        navigation.key.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => _Editor(draft)),
        );
        await tester.pumpAndSettle();
        final cancelled = navigation.returnToLanding();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Keep editing'));
        await tester.pumpAndSettle();
        expect(await cancelled, isFalse);
        expect(find.text('Unfinished invoice'), findsOneWidget);
        final leaving = navigation.returnToLanding();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save draft'));
        await tester.pumpAndSettle();
        expect(await leaving, !fail);
        if (fail) {
          expect(find.text('Unfinished invoice'), findsOneWidget);
          expect(draft.input['price'], '125.');
          repository.fail = false;
          draft.retry();
          await draft.flush();
        } else {
          expect(find.text('Work landing'), findsOneWidget);
          expect(find.text('Invoices'), findsNothing);
          expect(repository.saved?['price'], '125.');
        }
        await tester.pumpWidget(const SizedBox());
        await draft.close();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
