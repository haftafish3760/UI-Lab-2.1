// Explicit host preparation only; reads owner-authorized external review data.
// Run with flutter test and REVIEW_INPUT / REVIEW_OUTPUT / REVIEW_ID defines.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';

void main() {
  test('prepare a new isolated durable invoice review workspace', () async {
    const input = String.fromEnvironment('REVIEW_INPUT');
    const output = String.fromEnvironment('REVIEW_OUTPUT');
    const id = String.fromEnvironment('REVIEW_ID');
    if (input.isEmpty ||
        output.isEmpty ||
        !RegExp(r'^[a-z0-9][a-z0-9-]{7,63}$').hasMatch(id)) {
      throw StateError('Explicit input, new output directory and ID required.');
    }
    if (await FileSystemEntity.type(output, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw StateError('Refusing to modify an existing destination.');
    }
    final rows = (jsonDecode(await File(input).readAsString()) as List)
        .map((value) => (value as Map).cast<String, Object?>())
        .toList();
    final ids = <String>{};
    for (final row in rows) {
      if (!ids.add(row['id'] as String) ||
          (row['totalCents'] as int) < 0 ||
          (row['paidCents'] as int) < 0 ||
          (row['paidCents'] as int) > (row['totalCents'] as int)) {
        throw StateError('Invalid or duplicate review input.');
      }
    }
    await Directory(output).create(recursive: true);
    final database = LocalDatabase.file(File('$output/maintainiac.sqlite'));
    try {
      final repository = SqliteWorkRepository(database);
      await database.verifyIntegrity();
      for (final row in rows) {
        final recordId = row['id'] as String;
        final issued = DateTime.parse(row['issuedOn'] as String);
        await repository.commit(
          organizationId: expenseUiLabOrganizationId,
          commandId: 'review-create-$recordId',
          actorEmployeeId: expenseUiLabOwnerEmployeeId,
          permissionRevision: 'isolated-review-1',
          occurredAt: issued,
          mutations: [
            WorkRecordMutation(
              expectedStorageRevision: 0,
              record: WorkRecord(
                id: recordId,
                kind: WorkRecordKind.invoice,
                number: row['number'] as String,
                title: row['title'] as String,
                client: row['client'] as String,
                detail: row['detail'] as String,
                pricing: WorkPricingModel.flatRate,
                total: (row['totalCents'] as int) / 100,
                status: WorkRecordStatus.values.byName(row['status'] as String),
                createdByEmployeeId: expenseUiLabOwnerEmployeeId,
                createdOn: issued,
                issuedOn: issued,
                dueOn: DateTime.parse(row['dueOn'] as String),
              ),
            ),
          ],
          financialEntries: [
            if ((row['paidCents'] as int) > 0)
              PrototypeFinancialEntry(
                id: 'review-payment-$recordId',
                kind: PrototypeFinancialKind.paymentReceived,
                occurredOn: issued,
                amountCents: row['paidCents'] as int,
                sourceId: recordId,
                paymentMethod: 'cash',
              ),
          ],
        );
      }
      await database.verifyIntegrity();
    } finally {
      await database.close();
    }
    await File('$output/review-workspace-id').writeAsString(id, flush: true);
  });
}
