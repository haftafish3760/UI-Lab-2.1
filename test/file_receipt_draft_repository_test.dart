import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/file_receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';

void main() {
  group('FileReceiptDraftRepository', () {
    late Directory root;
    late Directory storage;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('ui-lab-receipt-drafts-');
      storage = Directory.fromUri(root.uri.resolve('private-records/'));
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test(
      'retains evidence and survives restart with checksum metadata',
      () async {
        final source = await _source(root, 'receipt.jpg', [1, 2, 3, 4]);
        final repository = await FileReceiptDraftRepository.open(storage);

        final created = await repository.create(
          draft: _draft('draft-restart'),
          evidence: [_photoImport(source)],
          context: _context(),
        );

        expect(created.lifecycle.revision, 1);
        expect(
          created.auditTrail.single.action,
          ReceiptDraftAuditAction.created,
        );
        expect(created.activeEvidence, hasLength(1));
        expect(created.activeEvidence.single.localPath, isNot(source.path));
        expect(
          await File(created.activeEvidence.single.localPath).readAsBytes(),
          [1, 2, 3, 4],
        );
        expect(created.activeEvidence.single.sha256, hasLength(64));

        final reopened = await FileReceiptDraftRepository.open(storage);
        final restored = await reopened.find(
          draftId: created.draftId,
          access: _companyAccess(),
        );
        expect(restored?.toJson(), created.toJson());
        expect(reopened.recoveredFromDamagedSnapshot, isFalse);
      },
    );

    test('same-content selections remain separate for human review', () async {
      final first = await _source(root, 'first.jpg', [7, 7, 7]);
      final second = await _source(root, 'second.jpg', [7, 7, 7]);
      final repository = await FileReceiptDraftRepository.open(storage);

      final created = await repository.create(
        draft: _draft('draft-same-content'),
        evidence: [_photoImport(first), _photoImport(second)],
        context: _context(),
      );

      expect(created.activeEvidence, hasLength(2));
      expect(created.activeEvidence.map((item) => item.originalName), [
        'first.jpg',
        'second.jpg',
      ]);
      expect(
        created.activeEvidence.map((item) => item.evidenceId).toSet(),
        hasLength(2),
      );
      expect(
        created.activeEvidence.map((item) => item.sha256).toSet(),
        hasLength(1),
      );
    });

    test(
      'removing evidence retains its audit reference and original file',
      () async {
        final first = await _source(root, 'first.jpg', [1, 1, 1]);
        final second = await _source(root, 'second.jpg', [2, 2, 2]);
        final third = await _source(root, 'third.pdf', [3, 3, 3]);
        final repository = await FileReceiptDraftRepository.open(storage);
        final created = await repository.create(
          draft: _draft('draft-evidence-update'),
          evidence: [_photoImport(first), _photoImport(second)],
          context: _context(),
        );
        final removedPath = created.activeEvidence.first.localPath;
        final retained = created.activeEvidence.last;
        final updatedAt = DateTime.utc(2026, 9, 1, 13);

        final updated = await repository.update(
          draft: created.copyWith(evidence: [retained]),
          addedEvidence: [
            ReceiptEvidenceImport(
              sourcePath: third.path,
              originalName: 'third.pdf',
              kind: ReceiptDraftEvidenceKind.pdf,
            ),
          ],
          expectedRevision: created.lifecycle.revision,
          context: _context(updatedAt),
        );

        expect(updated.lifecycle.revision, 2);
        expect(updated.activeEvidence.map((item) => item.originalName), [
          'second.jpg',
          'third.pdf',
        ]);
        final removed = updated.evidence.singleWhere(
          (item) => item.originalName == 'first.jpg',
        );
        expect(removed.state, ReceiptDraftEvidenceState.removed);
        expect(removed.removedAtUtc, updatedAt);
        expect(await File(removedPath).exists(), isTrue);
      },
    );

    test('stale updates fail without replacing the current draft', () async {
      final repository = await FileReceiptDraftRepository.open(storage);
      final created = await repository.create(
        draft: _draft('draft-conflict'),
        evidence: const [],
        context: _context(),
      );
      await repository.update(
        draft: created.copyWith(title: 'Current title'),
        addedEvidence: const [],
        expectedRevision: created.lifecycle.revision,
        context: _context(DateTime.utc(2026, 9, 1, 13)),
      );

      await expectLater(
        repository.update(
          draft: created.copyWith(title: 'Stale title'),
          addedEvidence: const [],
          expectedRevision: created.lifecycle.revision,
          context: _context(DateTime.utc(2026, 9, 1, 14)),
        ),
        throwsA(isA<ReceiptDraftRevisionConflictException>()),
      );
    });

    test(
      'submitted draft leaves active queries but remains auditable',
      () async {
        final repository = await FileReceiptDraftRepository.open(storage);
        final created = await repository.create(
          draft: _draft('draft-submit'),
          evidence: const [],
          context: _context(),
        );
        final submitted = await repository.submit(
          draftId: created.draftId,
          expenseId: 'expense-from-draft-submit',
          expectedRevision: created.lifecycle.revision,
          context: _context(DateTime.utc(2026, 9, 1, 15)),
        );

        expect(submitted.state, ReceiptDraftState.submitted);
        expect(submitted.submittedExpenseId, 'expense-from-draft-submit');
        expect(
          await repository.query(ReceiptDraftQuery(access: _companyAccess())),
          isEmpty,
        );
        expect(
          await repository.find(
            draftId: created.draftId,
            access: _companyAccess(),
          ),
          isNull,
        );
        expect(
          (await repository.find(
            draftId: created.draftId,
            access: _companyAccess(),
            includeClosed: true,
          ))?.auditTrail.last.action,
          ReceiptDraftAuditAction.submitted,
        );
      },
    );

    test('read scope excludes another employee and another company', () async {
      final repository = await FileReceiptDraftRepository.open(storage);
      await repository.create(
        draft: _draft('draft-alex', ownerEmployeeId: 'alex'),
        evidence: const [],
        context: _context(),
      );
      await repository.create(
        draft: _draft('draft-jordan', ownerEmployeeId: 'jordan'),
        evidence: const [],
        context: _context(),
      );
      await repository.create(
        draft: _draft(
          'draft-other-company',
          ownerEmployeeId: 'alex',
          organizationId: 'other-company',
        ),
        evidence: const [],
        context: _context(),
      );

      final own = await repository.query(
        ReceiptDraftQuery(
          access: ReceiptDraftAccess.own(
            organizationId: 'company-1',
            employeeId: 'alex',
          ),
        ),
      );
      expect(own.map((item) => item.draftId), ['draft-alex']);
      final company = await repository.query(
        ReceiptDraftQuery(access: _companyAccess()),
      );
      expect(company.map((item) => item.draftId).toSet(), {
        'draft-alex',
        'draft-jordan',
      });
    });

    test(
      'failed snapshot write retains no claimed record or new evidence',
      () async {
        final source = await _source(root, 'write-failure.jpg', [7, 8, 9]);
        final repository = await FileReceiptDraftRepository.open(
          storage,
          snapshotWriter: (target, bytes) async {
            throw const FileSystemException('simulated write failure');
          },
        );

        await expectLater(
          repository.create(
            draft: _draft('draft-write-failure'),
            evidence: [_photoImport(source)],
            context: _context(),
          ),
          throwsA(isA<ReceiptDraftStorageException>()),
        );
        expect(
          await repository.query(ReceiptDraftQuery(access: _companyAccess())),
          isEmpty,
        );
        final evidenceRoot = Directory.fromUri(
          storage.uri.resolve('evidence/'),
        );
        final retainedFiles = await evidenceRoot.exists()
            ? await evidenceRoot
                  .list(recursive: true)
                  .where((entity) => entity is File)
                  .toList()
            : const <FileSystemEntity>[];
        expect(retainedFiles, isEmpty);
      },
    );

    test('damaged newest snapshot recovers the prior valid draft', () async {
      final repository = await FileReceiptDraftRepository.open(storage);
      final created = await repository.create(
        draft: _draft('draft-recovery'),
        evidence: const [],
        context: _context(),
      );
      await repository.update(
        draft: created.copyWith(title: 'Newest title'),
        addedEvidence: const [],
        expectedRevision: created.lifecycle.revision,
        context: _context(DateTime.utc(2026, 9, 1, 13)),
      );
      await File.fromUri(
        storage.uri.resolve('receipt-drafts-1.json'),
      ).writeAsString('damaged');

      final recovered = await FileReceiptDraftRepository.open(storage);
      final draft = await recovered.find(
        draftId: created.draftId,
        access: _companyAccess(),
      );
      expect(recovered.recoveredFromDamagedSnapshot, isTrue);
      expect(draft?.title, 'Receipt draft');
      expect(draft?.lifecycle.revision, 1);
    });
  });
}

StoredReceiptDraft _draft(
  String id, {
  String ownerEmployeeId = 'alex',
  String organizationId = 'company-1',
}) {
  final timestamp = DateTime.utc(2026, 9, 1, 12);
  return StoredReceiptDraft(
    draftId: id,
    organizationId: organizationId,
    ownerEmployeeId: ownerEmployeeId,
    title: 'Receipt draft',
    expenseDate: DateTime(2026, 9, 1),
    evidence: const [],
    lifecycle: ReceiptDraftLifecycle(
      revision: 1,
      createdAtUtc: timestamp,
      updatedAtUtc: timestamp,
    ),
  );
}

ReceiptDraftAccess _companyAccess() => ReceiptDraftAccess.company(
  organizationId: 'company-1',
  employeeId: 'owner',
);

ReceiptDraftMutationContext _context([DateTime? occurredAtUtc]) =>
    ReceiptDraftMutationContext(
      actorEmployeeId: 'owner',
      permissionRevision: 'permission-revision-1',
      occurredAtUtc: occurredAtUtc ?? DateTime.utc(2026, 9, 1, 12),
    );

Future<File> _source(Directory root, String name, List<int> bytes) async {
  final folder = Directory.fromUri(root.uri.resolve('selected/'));
  await folder.create(recursive: true);
  return File.fromUri(
    folder.uri.resolve(name),
  ).writeAsBytes(bytes, flush: true);
}

ReceiptEvidenceImport _photoImport(File source) => ReceiptEvidenceImport(
  sourcePath: source.path,
  originalName: source.uri.pathSegments.last,
  kind: ReceiptDraftEvidenceKind.photo,
);
