import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/file_receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';

void main() {
  group('AuthorizedReceiptDraftService', () {
    late Directory directory;
    late FileReceiptDraftRepository repository;
    late AuthorizedReceiptDraftService service;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'ui-lab-authorized-receipt-drafts-',
      );
      repository = await FileReceiptDraftRepository.open(directory);
      service = AuthorizedReceiptDraftService(repository);
    });

    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test('no read scope cannot query or open draft records', () async {
      final permissions = _permissions(readScope: null);

      await expectLater(
        service.query(permissions: permissions),
        throwsA(isA<ReceiptDraftPermissionDeniedException>()),
      );
      await expectLater(
        service.find(draftId: 'unknown', permissions: permissions),
        throwsA(isA<ReceiptDraftPermissionDeniedException>()),
      );
    });

    test('create requires the signed-in employee as owner', () async {
      await expectLater(
        service.create(
          draft: _draft('wrong-owner', ownerEmployeeId: 'jordan'),
          evidence: const [],
          permissions: _permissions(canCreate: true),
          occurredAtUtc: _time,
        ),
        throwsA(isA<ReceiptDraftPermissionDeniedException>()),
      );
      expect(
        await repository.query(
          ReceiptDraftQuery(
            access: ReceiptDraftAccess.company(
              organizationId: 'company-1',
              employeeId: 'owner',
            ),
          ),
        ),
        isEmpty,
      );
    });

    test('own scope cannot infer or edit another employee draft', () async {
      final jordan = await repository.create(
        draft: _draft('jordan-draft', ownerEmployeeId: 'jordan'),
        evidence: const [],
        context: _repositoryContext(),
      );
      final permissions = _permissions(readScope: ReceiptDraftReadScope.own);

      expect(await service.query(permissions: permissions), isEmpty);
      expect(
        await service.find(draftId: jordan.draftId, permissions: permissions),
        isNull,
      );
      await expectLater(
        service.update(
          draft: jordan.copyWith(title: 'Not allowed'),
          addedEvidence: const [],
          expectedRevision: jordan.lifecycle.revision,
          permissions: permissions,
          occurredAtUtc: _time.add(const Duration(hours: 1)),
        ),
        throwsA(isA<ReceiptDraftPermissionDeniedException>()),
      );
    });

    test('team scope needs separate team edit permission', () async {
      final jordan = await repository.create(
        draft: _draft('team-draft', ownerEmployeeId: 'jordan'),
        evidence: const [],
        context: _repositoryContext(),
      );
      final readOnlyTeam = _permissions(
        readScope: ReceiptDraftReadScope.team,
        teamEmployeeIds: {'jordan'},
      );
      expect(await service.query(permissions: readOnlyTeam), hasLength(1));
      await expectLater(
        service.update(
          draft: jordan.copyWith(title: 'Denied team edit'),
          addedEvidence: const [],
          expectedRevision: jordan.lifecycle.revision,
          permissions: readOnlyTeam,
          occurredAtUtc: _time.add(const Duration(hours: 1)),
        ),
        throwsA(isA<ReceiptDraftPermissionDeniedException>()),
      );

      final updated = await service.update(
        draft: jordan.copyWith(title: 'Authorized team edit'),
        addedEvidence: const [],
        expectedRevision: jordan.lifecycle.revision,
        permissions: _permissions(
          readScope: ReceiptDraftReadScope.team,
          teamEmployeeIds: {'jordan'},
          canEditTeam: true,
        ),
        occurredAtUtc: _time.add(const Duration(hours: 2)),
      );
      expect(updated.title, 'Authorized team edit');
      expect(updated.auditTrail.last.actorEmployeeId, 'alex');
      expect(updated.auditTrail.last.permissionRevision, 'permission-1');
    });

    test('submit and discard use independent permissions', () async {
      final created = await service.create(
        draft: _draft('close-draft'),
        evidence: const [],
        permissions: _permissions(canCreate: true),
        occurredAtUtc: _time,
      );
      await expectLater(
        service.submit(
          draftId: created.draftId,
          expenseId: 'expense-close-draft',
          expectedRevision: created.lifecycle.revision,
          permissions: _permissions(canEditOwn: true),
          occurredAtUtc: _time.add(const Duration(hours: 1)),
        ),
        throwsA(isA<ReceiptDraftPermissionDeniedException>()),
      );
      final submitted = await service.submit(
        draftId: created.draftId,
        expenseId: 'expense-close-draft',
        expectedRevision: created.lifecycle.revision,
        permissions: _permissions(canSubmitOwn: true),
        occurredAtUtc: _time.add(const Duration(hours: 2)),
      );
      expect(submitted.state, ReceiptDraftState.submitted);
    });
  });
}

final _time = DateTime.utc(2026, 9, 1, 12);

ReceiptDraftCommandPermissions _permissions({
  ReceiptDraftReadScope? readScope = ReceiptDraftReadScope.company,
  Set<String> teamEmployeeIds = const {},
  bool canCreate = false,
  bool canEditOwn = false,
  bool canEditTeam = false,
  bool canSubmitOwn = false,
}) => ReceiptDraftCommandPermissions(
  organizationId: 'company-1',
  actorEmployeeId: 'alex',
  permissionRevision: 'permission-1',
  readScope: readScope,
  teamEmployeeIds: teamEmployeeIds,
  canCreate: canCreate,
  canEditOwn: canEditOwn,
  canEditTeam: canEditTeam,
  canSubmitOwn: canSubmitOwn,
);

StoredReceiptDraft _draft(String id, {String ownerEmployeeId = 'alex'}) =>
    StoredReceiptDraft(
      draftId: id,
      organizationId: 'company-1',
      ownerEmployeeId: ownerEmployeeId,
      title: 'Receipt draft',
      expenseDate: DateTime(2026, 9, 1),
      evidence: const [],
      lifecycle: ReceiptDraftLifecycle(
        revision: 1,
        createdAtUtc: _time,
        updatedAtUtc: _time,
      ),
    );

ReceiptDraftMutationContext _repositoryContext() => ReceiptDraftMutationContext(
  actorEmployeeId: 'owner',
  permissionRevision: 'repository-fixture',
  occurredAtUtc: _time,
);
