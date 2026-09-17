import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_repository.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';

/// Deliberately has no database, Flutter controllers, or native media API.
class _PendingDraftRepository extends Fake implements DraftRepository {
  final acknowledged = Completer<int>();
  Map<String, Object?>? received;

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
  }) {
    received = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
    return acknowledged.future;
  }
}

void main() {
  test(
    'autosave waits for repository acknowledgement without a database',
    () async {
      final repository = _PendingDraftRepository();
      final session = DraftAutosaveSession(
        store: repository,
        organizationId: 'business',
        ownerId: 'owner',
        domain: 'independent-workflow',
        draftId: 'unfinished-work',
      );
      await session.initialize();
      final input = <String, Object?>{'amount': '12.', 'notes': ''};
      session.replaceInput(input);
      input['amount'] = 'mutated by a different presentation';
      await Future<void>.delayed(Duration.zero);
      expect(repository.received!['amount'], '12.');
      expect(session.state, DraftSaveState.saving);
      expect(session.savedRevision, 0);
      repository.acknowledged.complete(7);
      await session.flush();
      expect(session.savedRevision, 7);
      expect(session.state, DraftSaveState.savedLocally);

      final committed = Completer<int>();
      final pending = session.commitInput(
        expectedRevision: 7,
        input: {'amount': '12.', 'notes': 'workflow result'},
        commit: (prepared) => committed.future,
      );
      await Future<void>.delayed(Duration.zero);
      expect(session.input['notes'], '');
      expect(() => session.replaceInput({'amount': '99'}), throwsStateError);
      final failure = expectLater(pending, throwsStateError);
      committed.completeError(StateError('outer transaction rolled back'));
      await failure;
      expect(session.input['notes'], '');
      expect(session.savedRevision, 7);
      expect(session.isCommittingInput, isFalse);

      await session.commitInput(
        expectedRevision: 7,
        input: {'amount': '12.', 'notes': 'retried result'},
        commit: (prepared) async => 8,
      );
      expect(session.input['notes'], 'retried result');
      var staleCommitInvoked = false;
      await expectLater(
        session.commitInput(
          expectedRevision: 7,
          input: {'notes': 'stale'},
          commit: (_) async {
            staleCommitInvoked = true;
            return 9;
          },
        ),
        throwsA(isA<LocalRecordConflict>()),
      );
      expect(staleCommitInvoked, isFalse);
      expect(session.savedRevision, 8);
      await session.close();
    },
  );

  test(
    'confirmation awaits acknowledgement, freezes input and seals success',
    () async {
      final repository = _PendingDraftRepository();
      final session = DraftAutosaveSession(
        store: repository,
        organizationId: 'business',
        ownerId: 'owner',
        domain: 'independent-workflow',
        draftId: 'unfinished-work',
      );
      await session.initialize();
      session.replaceInput({'amount': '12.'});
      var calls = 0;
      final domainResult = Completer<bool>();
      final pending = session.confirm((checkpoint) {
        calls++;
        expect(checkpoint.domain, 'independent-workflow');
        expect(checkpoint.draftId, 'unfinished-work');
        expect(checkpoint.revision, 7);
        return domainResult.future;
      });
      await Future<void>.delayed(Duration.zero);
      expect(calls, 0);
      expect(() => session.replaceInput({'amount': '99'}), throwsStateError);
      expect(() => session.confirm((_) async => true), throwsStateError);
      repository.acknowledged.complete(7);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      domainResult.complete(false);
      expect(await pending, isFalse);
      expect(session.input['amount'], '12.');
      expect(session.isCommittingInput, isFalse);
      await expectLater(
        session.confirm((_) async => throw StateError('rollback')),
        throwsStateError,
      );
      expect(session.input['amount'], '12.');
      expect(await session.confirm((_) async => true), isTrue);
      expect(() => session.replaceInput({'amount': '99'}), throwsStateError);
      expect(() => session.confirm((_) async => true), throwsStateError);
      await session.close();
    },
  );

  test('failed acknowledgement never invokes confirmation', () async {
    final repository = _PendingDraftRepository();
    final session = DraftAutosaveSession(
      store: repository,
      organizationId: 'business',
      ownerId: 'owner',
      domain: 'independent-workflow',
      draftId: 'unfinished-work',
    );
    await session.initialize();
    session.replaceInput({'amount': '12.'});
    var invoked = false;
    final pending = session.confirm((_) async {
      invoked = true;
      return true;
    });
    final failure = expectLater(pending, throwsStateError);
    repository.acknowledged.completeError(StateError('disk write failed'));
    await failure;
    expect(invoked, isFalse);
    expect(session.input['amount'], '12.');
    expect(session.isCommittingInput, isFalse);
    await expectLater(session.close(), throwsStateError);
  });

  test(
    'expense and receipt data do not depend on screen-owned models or icons',
    () {
      final violations = <String>[];
      for (final root in ['lib/src/data/expenses', 'lib/src/data/receipts']) {
        for (final file in Directory(
          root,
        ).listSync(recursive: true).whereType<File>()) {
          if (file.path.endsWith('.dart') &&
              RegExp(
                r'''(?:import|export)\s+['"][^'"]*screens/''',
              ).hasMatch(file.readAsStringSync())) {
            violations.add(file.path);
          }
        }
      }
      final models = File(
        'lib/src/data/expenses/expense_workflow_models.dart',
      ).readAsStringSync();
      expect(violations, isEmpty);
      expect(models, isNot(contains('package:flutter/material.dart')));
      expect(models, isNot(contains('IconData')));
      expect(models, isNot(contains('Icons.')));
    },
  );

  test('saved preference models have no widget or screen dependencies', () {
    final violations = <String>[];
    for (final file in Directory(
      'lib/src/data/preferences',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      if (source.contains('BuildContext') ||
          source.contains('package:flutter/') ||
          source.contains('/screens/') ||
          source.contains('/shared/')) {
        violations.add(file.path);
      }
    }
    expect(violations, isEmpty);
  });

  test(
    'presentation does not construct draft sessions or transaction checkpoints',
    () {
      final violations = <String>[];
      final constructors = RegExp(
        r'(?:DraftAutosaveSession|LocalDraftCheckpoint)\s*\(',
      );
      for (final root in [
        'lib/src/screens',
        'lib/src/shared',
        'lib/src/shell',
      ]) {
        for (final file in Directory(
          root,
        ).listSync(recursive: true).whereType<File>()) {
          if (file.path.endsWith('.dart') &&
              constructors.hasMatch(file.readAsStringSync())) {
            violations.add(file.path);
          }
        }
      }
      expect(violations, isEmpty);
    },
  );

  test('presentation recovery contracts do not expose raw payload maps', () {
    final violations = <String>[];
    final rawRecovery = RegExp(
      r'Map<String, Object\?>\??\s+recoveryInput|ValueChanged<Map<String, Object\?>>\??\s+onDraftChanged',
    );
    for (final root in ['lib/src/screens', 'lib/src/shared', 'lib/src/shell']) {
      for (final file in Directory(
        root,
      ).listSync(recursive: true).whereType<File>()) {
        if (file.path.endsWith('.dart') &&
            rawRecovery.hasMatch(file.readAsStringSync())) {
          violations.add(file.path);
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('presentation does not import concrete storage or restore machinery', () {
    final violations = <String>[];
    final forbidden = RegExp(
      r'''(?:import|export)\s+['"][^'"]*(?:local_draft_store\.dart|local_app_preferences_store\.dart|local_database(?:\.g)?\.dart|local_restore_workflow\.dart|local_checkpoint_catalog\.dart|local_installation_selection\.dart|local_installation_switch_coordinator\.dart|prepared_local_restore\.dart|verified_local_snapshot_bundle\.dart|package:drift/|package:sqlite3/)''',
    );
    for (final root in ['lib/src/screens', 'lib/src/shared', 'lib/src/shell']) {
      for (final file in Directory(
        root,
      ).listSync(recursive: true).whereType<File>()) {
        if (file.path.endsWith('.dart') &&
            forbidden.hasMatch(file.readAsStringSync())) {
          violations.add(file.path);
        }
      }
    }
    // Keep the rule sensitive to aliases, export barrels and multiline imports.
    for (final directive in [
      "import 'package:drift/drift.dart' as sql;",
      "export '../data/storage/local_restore_workflow.dart';",
      "import\n '../data/storage/local_installation_selection.dart' show LocalInstallationSelection;",
    ]) {
      expect(forbidden.hasMatch(directive), isTrue, reason: directive);
    }
    expect(
      forbidden.hasMatch(
        "import '../data/storage/local_restore_controller.dart';",
      ),
      isFalse,
    );
    final app = File('lib/src/app.dart').readAsStringSync();
    expect(forbidden.hasMatch(app), isFalse);
    expect(app, isNot(contains('draftStore!.database')));
    expect(app, isNot(contains('createApplicationMediaCoordinator(')));
    expect(violations, isEmpty);
  });
  test(
    'customer document and portal transport remain independent of widgets',
    () {
      for (final path in [
        'lib/src/shared/documents/customer_document.dart',
        'lib/src/shared/documents/customer_portal_gateway.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('package:flutter/')), reason: path);
        expect(source, isNot(contains('/screens/')), reason: path);
      }
    },
  );
  test('restore presentation contract has no implementation dependencies', () {
    final contract = File(
      'lib/src/data/storage/local_restore_controller.dart',
    ).readAsStringSync();
    expect(
      RegExp(r'^(?:import|export|part)\s', multiLine: true).hasMatch(contract),
      isFalse,
      reason:
          'The controller and review facts must stay standalone Dart types.',
    );
  });
  test('Work data and generic autosave do not depend on presentation', () {
    final violations = <String>[];
    for (final file in Directory(
      'lib/src/data/work',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final line in file.readAsLinesSync()) {
        if ((line.startsWith('import ') || line.startsWith('export ')) &&
            line.contains('/screens/')) {
          violations.add(file.path);
        }
      }
    }
    expect(violations, isEmpty);
    final generic = File(
      'lib/src/data/storage/draft_autosave_session.dart',
    ).readAsStringSync();
    expect(generic, isNot(contains('work/estimate-editor')));
    expect(generic, isNot(contains('local_media_picker_request.dart')));
    expect(generic, isNot(contains('local_draft_store.dart')));
  });
}
