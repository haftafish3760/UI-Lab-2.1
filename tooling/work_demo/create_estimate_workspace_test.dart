import 'package:ui_lab_2_1/src/data/work/invoice_collection_status.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_payment_balance.dart';
import 'populate_connected_work.dart';
import 'package:ui_lab_2_1/src/data/work/reusable_job_library.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/customer_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/customer_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_approval_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_signature_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';

/// Explicit developer tool, excluded from app entrypoints and packaged assets.
/// Always creates a new isolated installation; never accepts an existing database.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('create persistent connected Work demo through domain workflows', () async {
    final scenarios =
        jsonDecode(
              await File(
                'tooling/work_demo/estimate_scenarios.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    final root = Directory('output/work-demo');
    await root.create(recursive: true);
    final destination = await root.createTemp('work-workspace-');
    final workspaceId = destination.uri.pathSegments
        .where((part) => part.isNotEmpty)
        .last
        .toLowerCase();
    var persistence = await LocalPersistence.open(
      directory: destination,
      removeOwnerDemoData: false,
    );
    var directory = await openUiLabDirectory(persistence.database);
    var owner = await openUiLabWorkSession(persistence.database);
    WorkPersistenceSession? employee;
    try {
      expect(directory.customers, isEmpty);
      expect(owner.records, isEmpty);
      final clients = <WorkCustomerProfile>[];
      for (final raw in scenarios['clients'] as List) {
        final form = await directory.openCustomerDraft();
        final data = raw as Map<String, dynamic>;
        form.updateInput(
          CustomerDraftInput(
            customerId: 'demo-client-${clients.length + 1}',
            existingCustomer: null,
            baseRevision: 0,
            preferredContact: 'Email',
            name: data['name'],
            company: data['company'],
            phone: data['phone'],
            email: data['email'],
            billing: data['address'],
            notes: 'Fictional demo record. Do not send messages.',
            locationLabel: 'Work location',
            locationAddress: data['address'],
            accessNotes: data['access'],
          ),
        );
        final client = await form.confirm();
        expect(client, isNotNull, reason: directory.failureMessage);
        clients.add(client!);
        await form.session.close();
      }
      employee = await WorkPersistenceSession.open(
        SqliteWorkRepository(persistence.database),
        WorkSessionPermissions(
          organizationId: owner.permissions.organizationId,
          actorEmployeeId: 'jordan',
          permissionRevision: 'isolated-demo-employee-v1',
          visibleCreatorIds: {'jordan'},
          editableKinds: {WorkRecordKind.estimate},
        ),
      );
      final now = DateTime.now();
      var index = 0;
      for (final raw in scenarios['estimates'] as List) {
        final data = raw as Map<String, dynamic>;
        final actor = data['actor'] as String;
        final work = actor == 'jordan' ? employee : owner;
        final client = clients[data['client'] as int];
        final form = await work.openEstimateDraft(creatorId: actor);
        form.updateInput(
          EstimateDraftInput(
            creatorId: actor,
            number: 'Estimate ${3101 + index}',
            baseStorageRevision: 0,
            title: data['title'],
            discount: '0',
            tax: '0',
            terms:
                'Demo service terms: the listed work and price apply only to the described scope. Additional work requires customer approval.',
            client: client.name,
            customerSnapshot: client,
            pricing: WorkPricingModel.flatRate,
            template: 'Service standard',
            createdOn: now,
            items: const [],
            servicePrice: data['price'],
            baseRecord: null,
            estimateId: 'demo-estimate-${++index}',
            scope: data['description'],
            expiresOn: now.add(const Duration(days: 30)),
            followUpOn: now.add(const Duration(days: 3)),
            proposedServiceOn: null,
            pendingLineItems: const {},
            pendingPhotos: null,
            sitePhotos: const [],
          ),
        );
        final record = await form.confirm();
        expect(record, isNotNull, reason: work.failureMessage);
        await form.session.close();
        if (actor == 'jordan') {
          await expectLater(
            work.openEstimateApprovalDraft(record!.id),
            throwsStateError,
          );
          await expectLater(
            work.openEstimateSignatureDraft(record.id),
            throwsStateError,
          );
        } else if (data['approval'] == 'verbal') {
          final approval = await owner.openEstimateApprovalDraft(record!.id);
          approval.updateInput(
            EstimateApprovalInput(
              base: record,
              baseRevision: approval.input.baseRevision,
              name: client.name,
              method: CustomerApprovalMethod.verbal,
              accepted: true,
              note:
                  'Fictional demo: customer accepted the scope and price during a phone call. No real call occurred.',
            ),
          );
          expect(
            await approval.confirm(),
            isNotNull,
            reason: owner.failureMessage,
          );
          await approval.session.close();
        } else if (data['approval'] == 'signed') {
          final signature = await owner.openEstimateSignatureDraft(record!.id);
          signature.updateName('DEMO SIGNATURE — fictional customer');
          signature.updateInk(
            SignatureInk([
              [
                (0.1, 0.7),
                (0.2, 0.2),
                (0.3, 0.7),
                (0.4, 0.3),
                (0.5, 0.7),
                (0.8, 0.5),
              ],
            ]),
          );
          signature.setAccepted(true);
          expect(
            await signature.confirm(),
            isNotNull,
            reason: owner.failureMessage,
          );
          await signature.session.close();
        }
      }
      owner.dispose();
      owner = await openUiLabWorkSession(persistence.database);
      await populateConnectedWork(owner, clients, now);
      employee.dispose();
      employee = null;
      owner.dispose();
      directory.dispose();
      await persistence.close();
      persistence = await LocalPersistence.open(
        directory: destination,
        removeOwnerDemoData: false,
      );
      owner = await openUiLabWorkSession(persistence.database);
      directory = await openUiLabDirectory(persistence.database);
      expect(directory.customers.length, 3);
      expect(owner.records.length, 12);
      for (final entry in {
        WorkRecordKind.estimate: 4,
        WorkRecordKind.quote: 2,
        WorkRecordKind.job: 2,
        WorkRecordKind.invoice: 4,
      }.entries) {
        expect(
          owner.records.where((r) => r.kind == entry.key).length,
          entry.value,
        );
      }
      expect((await ReusableJobLibrary(owner).list()).length, 2);
      expect(
        owner.financialEntries
            .where((e) => e.kind == PrototypeFinancialKind.paymentReceived)
            .length,
        2,
      );
      expect(
        owner.records.where((r) => r.hasCurrentCustomerApproval).length,
        3,
      );
      expect(
        owner.records.where((r) => r.hasCurrentCustomerSignature).length,
        1,
      );
      expect(
        owner.records.where((r) => r.createdByEmployeeId == 'jordan').length,
        1,
      );
      final invoices = owner.records
          .where((r) => r.kind == WorkRecordKind.invoice)
          .toList();
      expect(
        invoices
            .map(
              (r) =>
                  invoiceCollectionStatus(r, owner.financialEntries, now: now),
            )
            .toSet(),
        {
          InvoiceCollectionStatus.draft,
          InvoiceCollectionStatus.overdue,
          InvoiceCollectionStatus.partiallyPaid,
          InvoiceCollectionStatus.paid,
        },
      );
      expect(
        invoiceBalanceCents(
          invoices.singleWhere((r) => r.id == 'demo-invoice-2'),
          owner.financialEntries,
        ),
        14000,
      );
      expect(
        invoiceBalanceCents(
          invoices.singleWhere((r) => r.id == 'demo-invoice-3'),
          owner.financialEntries,
        ),
        0,
      );
      expect(
        owner.records
            .where((r) => r.kind == WorkRecordKind.job)
            .every(
              (r) =>
                  r.scheduledStart != null &&
                  r.scheduledEnd!.isAfter(r.scheduledStart!),
            ),
        isTrue,
      );
      await persistence.database.verifyIntegrity();
      await File('${destination.path}/DEMO-WORKSPACE.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'purpose':
              'Isolated editable demonstration. Not production or customer data.',
          'workspaceId': workspaceId,
          'createdAt': now.toUtc().toIso8601String(),
          'clients': directory.customers.length,
          'reusableJobs': (await ReusableJobLibrary(owner).list()).length,
          'payments': owner.financialEntries
              .where((e) => e.kind == PrototypeFinancialKind.paymentReceived)
              .map(
                (e) => {
                  'invoice': e.sourceId,
                  'amountCents': e.amountCents,
                  'method': e.paymentMethod,
                },
              )
              .toList(),
          'records': owner.records
              .map(
                (r) => {
                  'id': r.id,
                  'kind': r.kind.name,
                  'status': r.status.name,
                  if (r.kind == WorkRecordKind.invoice)
                    'collectionStatus': invoiceCollectionStatus(
                      r,
                      owner.financialEntries,
                      now: now,
                    ).name,
                  if (r.scheduledStart != null)
                    'scheduledStart': r.scheduledStart!.toIso8601String(),
                  'title': r.title,
                  'creator': r.createdByEmployeeId,
                  'total': r.total,
                  'approved': r.hasCurrentCustomerApproval,
                  'signed': r.hasCurrentCustomerSignature,
                },
              )
              .toList(),
          'verified': [
            'durable reopen',
            'employee cannot approve or sign',
            'approval without signature',
            'fictional signature',
            'quote and estimate conversion to scheduled jobs',
            'direct estimate to invoice draft',
            'overdue, partially paid and paid invoice projections',
            'two reusable jobs survive reopening',
          ],
          'notVerified': [
            'device rendering',
            'phone installation',
            'production account permissions',
          ],
        }),
        flush: true,
      );
    } finally {
      employee?.dispose();
      owner.dispose();
      directory.dispose();
      await persistence.close();
    }
    // Publish only after successful validation and closing the database.
    // Reuse the existing review launcher; do not introduce another runtime.
    await File(
      '${destination.path}/review-workspace-id',
    ).writeAsString(workspaceId, flush: true);
    // Retained intentionally, unlike disposable test databases.
    stdout.writeln('DEMO_WORKSPACE=${destination.absolute.path}');
    stdout.writeln('WORK_REVIEW_WORKSPACE=$workspaceId');
  });
}
