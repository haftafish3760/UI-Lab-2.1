import 'package:drift/drift.dart' show Variable;
import '../expenses/expense_ui_lab_policy.dart';
import '../storage/local_database.dart';
import '../storage/local_record_command.dart';
import '../storage/local_record_store.dart';
import 'models/work_contact_models.dart';
import 'models/work_models.dart';
import 'models/estimate_models.dart';
import 'employee_directory_demo.dart';
import 'vehicle_directory_demo.dart';
import 'work_contact_codec.dart';
import 'work_record_codec.dart';
import 'work_financial_codec.dart';
import '../prototype_financial_models.dart';

/// Owner-requested replacement of Work review data only, once before sessions
/// load. Startup invokes this in debug builds only. Expenses/evidence stay intact.
Future<void> loadRequestedWorkExamples(
  LocalDatabase database,
) => database.transaction(() async {
  const marker = 'owner-requested-work-examples-v2-2026-09-14';
  if (await (database.select(
        database.localMetadata,
      )..where((r) => r.metadataKey.equals(marker))).getSingleOrNull() !=
      null) {
    return;
  }
  const organization = expenseUiLabOrganizationId;
  final oldCommands = await database
      .customSelect(
        "SELECT DISTINCT command_id FROM local_record_revisions WHERE organization_id = ? AND domain LIKE 'work/%'",
        variables: [Variable.withString(organization)],
      )
      .get();
  for (final table in [
    'local_record_revisions',
    'local_records',
    'local_drafts',
  ]) {
    await database.customStatement(
      "DELETE FROM $table WHERE organization_id = ? AND domain LIKE 'work/%'",
      [organization],
    );
  }
  for (final command in oldCommands) {
    for (final table in ['local_change_outbox', 'local_commands']) {
      await database.customStatement(
        'DELETE FROM $table WHERE organization_id = ? AND command_id = ? AND NOT EXISTS '
        '(SELECT 1 FROM local_record_revisions WHERE organization_id = ? AND command_id = ?)',
        [
          organization,
          command.read<String>('command_id'),
          organization,
          command.read<String>('command_id'),
        ],
      );
    }
  }
  final store = LocalRecordStore(database);
  final writes = <LocalRecordWrite>[];
  Future<void> add(
    String domain,
    String id,
    String owner,
    Map<String, Object?> data,
  ) async {
    if ((await store.read(
      organizationId: organization,
      domain: domain,
      ownerIds: {owner},
      recordIds: {id},
    )).isNotEmpty) {
      return;
    }
    writes.add(
      LocalRecordWrite(
        domain: domain,
        recordId: id,
        ownerId: owner,
        expectedRevision: 0,
        payload: {
          ...data,
          if (domain.startsWith('work/')) ...{
            'mutationActor': expenseUiLabOwnerEmployeeId,
            'permissionRevision': marker,
          },
        },
      ),
    );
  }

  for (final employee in demoEmployeeDirectoryProfiles) {
    await add(
      'directory/employees',
      employee.id,
      organization,
      employee.toJson(),
    );
  }
  for (final vehicle in demoVehicleDirectoryProfiles) {
    await add('directory/vehicles', vehicle.id, organization, vehicle.toJson());
  }
  await add(
    'directory/company',
    'company',
    organization,
    encodeWorkCompanyProfile(
      demoWorkCompany.copyWith(
        companyName: 'Blue Ridge Service Company (Demo)',
      ),
    ),
  );
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day);
  const names = [
    'Avery Wilson',
    'Jordan Patel',
    'Morgan Reed',
    'Casey Brooks',
    'Riley Bennett',
    'Taylor Foster',
  ];
  const titles = [
    'Kitchen faucet replacement',
    'Outdoor lighting proposal',
    'Bathroom fan installation',
    'Scheduled heating inspection',
    'Completed drain repair',
    'Invoice for door repair',
  ];
  for (var i = 0; i < names.length; i++) {
    final customer = WorkCustomerProfile(
      id: 'review-v2-customer-$i',
      name: names[i],
      companyName: '',
      phone: '',
      email: '',
      preferredContact: 'Email',
      billingAddress: '${100 + i} Example Street',
      locations: [
        WorkServiceLocation(
          label: 'Home',
          address: '${100 + i} Example Street',
        ),
      ],
      notes: 'Editable review example; enter a real recipient before sharing.',
      linkedRecordCount: 1,
    );
    await add(
      'directory/customers',
      customer.id,
      organization,
      encodeWorkCustomerProfile(customer),
    );
    final kind = i < 3
        ? WorkRecordKind.estimate
        : i == 5
        ? WorkRecordKind.invoice
        : WorkRecordKind.job;
    final status = [
      WorkRecordStatus.draft,
      WorkRecordStatus.ready,
      WorkRecordStatus.accepted,
      WorkRecordStatus.scheduled,
      WorkRecordStatus.completed,
      WorkRecordStatus.due,
    ][i];
    final stage = i == 0
        ? EstimateStage.draft
        : i == 1
        ? EstimateStage.readyToSend
        : EstimateStage.approved;
    final record = WorkRecord(
      id: 'review-v2-$i',
      kind: kind,
      number:
          '${kind == WorkRecordKind.estimate
              ? 'Estimate'
              : kind == WorkRecordKind.job
              ? 'Job'
              : 'Invoice'} ${2001 + i}',
      title: titles[i],
      client: names[i],
      detail: 'Review example: ${titles[i].toLowerCase()}.',
      pricing: WorkPricingModel.flatRate,
      createdByEmployeeId: expenseUiLabOwnerEmployeeId,
      createdOn: day.add(Duration(hours: 8, minutes: i * 10)),
      status: status,
      estimateStage: kind == WorkRecordKind.estimate ? stage : null,
      estimateDates: kind == WorkRecordKind.estimate
          ? EstimateDates(
              createdOn: day,
              lastEditedOn: day.add(Duration(hours: 8, minutes: i * 10)),
              expiresOn: day.add(const Duration(days: 30)),
              proposedServiceOn: day.add(Duration(days: 3 + i, hours: 9)),
            )
          : null,
      customerSignature: i == 2
          ? WorkCustomerSignature(
              signedBy: names[i],
              signedOn: day,
              signedRevision: 1,
            )
          : null,
      scheduledStart: i == 3 ? day.add(const Duration(hours: 14)) : null,
      scheduledEnd: i == 3 ? day.add(const Duration(hours: 15)) : null,
      completedOn: i == 4 ? day.add(const Duration(hours: 10)) : null,
      issuedOn: i == 5 ? day : null,
      dueOn: i == 5 ? day.add(const Duration(days: 14)) : null,
      serviceLocation: customer.billingAddress,
      assignedEmployeeIds: i == 3 || i == 4
          ? [expenseUiLabOwnerEmployeeId]
          : const [],
      assignee: i == 3 || i == 4
          ? demoEmployeeDirectoryProfiles.first.name
          : null,
      items: [
        WorkLineItem(
          id: 'review-item-$i',
          type: WorkLineItemType.labor,
          name: titles[i],
          quantity: 1,
          unit: 'service',
          customerPrice: 150.0 + i * 50,
        ),
      ],
      total: 150.0 + i * 50,
      template: 'print-v1',
      terms: 'Review and enter your company terms before sending.',
    );
    await add(
      'work/records',
      record.id,
      record.createdByEmployeeId,
      encodeWorkRecord(record),
    );
    if (kind == WorkRecordKind.invoice) {
      final entry = PrototypeFinancialEntry(
        id: 'review-v2-invoice-issued',
        kind: PrototypeFinancialKind.invoiceIssued,
        occurredOn: record.issuedOn!,
        amountCents: (record.total * 100).round(),
        sourceId: record.number,
        note: 'Demo invoice issued for review',
      );
      await add(
        'work/ledger',
        entry.id,
        record.createdByEmployeeId,
        encodeFinancialEntry(entry),
      );
    }
  }
  await store.commit(
    organizationId: organization,
    commandId: marker,
    writes: writes,
    occurredAt: now.toUtc(),
  );
  await database
      .into(database.localMetadata)
      .insert(
        LocalMetadataCompanion.insert(
          metadataKey: marker,
          value:
              'Owner-authorized Work-only review replacement; other modules preserved.',
        ),
      );
});
