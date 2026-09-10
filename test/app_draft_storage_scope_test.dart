import 'package:ui_lab_2_1/src/data/storage/draft_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/shared/local_draft_scope.dart';
import 'package:ui_lab_2_1/src/shell/app_shell.dart';

import 'support/storage/database_harness.dart';

void main() {
  testWidgets('pushed routes share durable drafts without a Work session', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final store = LocalDraftStore(database);
    await tester.pumpWidget(UiLabApp(draftStore: store));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(AppShell));
    expect(LocalDraftScope.maybeOf(context), same(store));
    DraftRepository? routeStore;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) {
          routeStore = LocalDraftScope.maybeOf(context);
          return const Scaffold(body: Text('Draft connection probe'));
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(routeStore, same(store));
    await tester.runAsync(() async {
      final draft = DraftAutosaveSession(
        store: routeStore!,
        organizationId: 'scope-test-org',
        domain: 'expenses/manual-entry',
        draftId: 'unfinished-expense',
        ownerId: 'scope-test-actor',
      );
      await draft.initialize();
      draft.replaceInput({'vendor': '  Partial vendor ', 'amount': '12.'});
      await draft.flush();
      await draft.close();
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await harness.close(database);
      final reopened = await harness.open();
      final recovered = LocalDraftStore(reopened);
      final row = await recovered.find(
        organizationId: 'scope-test-org',
        domain: 'expenses/manual-entry',
        draftId: 'unfinished-expense',
        ownerId: 'scope-test-actor',
      );
      expect(recovered.decode(row!), {
        'vendor': '  Partial vendor ',
        'amount': '12.',
      });
      expect(
        await recovered.list(
          organizationId: 'scope-test-org',
          domain: 'expenses/manual-entry',
          ownerId: 'another-actor',
        ),
        isEmpty,
      );
      await harness.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
