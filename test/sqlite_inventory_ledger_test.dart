import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/inventory/inventory_ledger_contract.dart';
import 'package:ui_lab_2_1/src/data/inventory/sqlite_inventory_ledger.dart';
import 'package:ui_lab_2_1/src/data/inventory/stock_quantity.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_store.dart';

void main() {
  late Directory directory;
  late LocalDatabase database;
  late InventoryLedgerAccess grant;
  late SqliteInventoryLedger ledger;
  final time = DateTime.utc(2026, 9, 18);

  SqliteInventoryLedger connect() => SqliteInventoryLedger(
    records: LocalRecordStore(database),
    organizationId: 'company',
    access: () => grant,
    resolveItem: (id) async => id == 'canonical-tee'
        ? const InventoryLedgerItem(
            id: 'canonical-tee',
            label: 'Test tee',
            stockUnit: 'each',
            allowsFractional: false,
          )
        : id == 'canonical-wire'
        ? const InventoryLedgerItem(
            id: 'canonical-wire',
            label: 'Test wire',
            stockUnit: 'ft',
            allowsFractional: true,
          )
        : null,
    resolveLocation: (id) async => {'truck', 'warehouse'}.contains(id)
        ? InventoryLedgerLocation(id: id, label: id, active: true)
        : null,
  );

  InventoryLedgerRequest request(
    String command,
    String quantity,
    int revision, {
    String item = 'canonical-tee',
    String location = 'truck',
    InventoryLedgerAction action = InventoryLedgerAction.receive,
  }) => InventoryLedgerRequest(
    commandId: command,
    itemId: item,
    locationId: location,
    quantity: StockQuantity.parse(quantity),
    action: action,
    expectedRevision: revision,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inventory-ledger-test-');
    database = LocalDatabase.file(File('${directory.path}/app.sqlite'));
    grant = InventoryLedgerAccess(
      organizationId: 'company',
      actorId: 'owner',
      revision: 1,
      readableLocations: {'truck', 'warehouse'},
      writableLocations: {'truck', 'warehouse'},
    );
    ledger = connect();
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'same canonical stock persists once across retries and database reopen',
    () async {
      final command = request('add-ten', '10', 0);
      await ledger.apply(command, occurredAt: time);
      await ledger.apply(
        command,
        occurredAt: time.add(const Duration(days: 1)),
      );
      expect(
        (await ledger.read('canonical-tee', 'truck'))!.quantity.decimal,
        '10',
      );
      final events = await LocalRecordStore(database).read(
        organizationId: 'company',
        domain: SqliteInventoryLedger.eventDomain,
        ownerIds: {'company'},
      );
      expect(events, hasLength(1));
      await database.verifyIntegrity();
      await database.close();
      database = LocalDatabase.file(File('${directory.path}/app.sqlite'));
      ledger = connect();
      final recovered = await ledger.read('canonical-tee', 'truck');
      expect(recovered!.quantity.decimal, '10');
      expect(recovered.revision, 1);
      await ledger.apply(command, occurredAt: time);
      expect(
        (await ledger.read('canonical-tee', 'truck'))!.quantity.decimal,
        '10',
      );
    },
  );

  test(
    'locations stay separate and repeat additions share canonical balance',
    () async {
      await ledger.apply(request('first', '10', 0), occurredAt: time);
      await ledger.apply(
        request('second-trade-path', '3', 1),
        occurredAt: time,
      );
      await ledger.apply(
        request('warehouse-add', '4', 0, location: 'warehouse'),
        occurredAt: time,
      );
      expect(
        (await ledger.read('canonical-tee', 'truck'))!.quantity.decimal,
        '13',
      );
      expect(
        (await ledger.read('canonical-tee', 'warehouse'))!.quantity.decimal,
        '4',
      );
      final balances = await LocalRecordStore(database).read(
        organizationId: 'company',
        domain: SqliteInventoryLedger.balanceDomain,
        ownerIds: {'company'},
      );
      expect(balances, hasLength(2));
    },
  );

  test(
    'changed command and stale revision fail without changing stock',
    () async {
      await ledger.apply(request('first', '10', 0), occurredAt: time);
      await expectLater(
        ledger.apply(request('first', '11', 0), occurredAt: time),
        throwsA(isA<LocalRecordConflict>()),
      );
      await expectLater(
        ledger.apply(request('stale', '3', 0), occurredAt: time),
        throwsA(isA<LocalRecordConflict>()),
      );
      expect(
        (await ledger.read('canonical-tee', 'truck'))!.quantity.decimal,
        '10',
      );
    },
  );

  test(
    'exact decimal addition and consumption never use binary floats',
    () async {
      await ledger.apply(
        request('wire-a', '0.1', 0, item: 'canonical-wire'),
        occurredAt: time,
      );
      await ledger.apply(
        request('wire-b', '0.2', 1, item: 'canonical-wire'),
        occurredAt: time,
      );
      expect(
        (await ledger.read('canonical-wire', 'truck'))!.quantity.decimal,
        '0.3',
      );
      await ledger.apply(
        request(
          'wire-c',
          '0.3',
          2,
          item: 'canonical-wire',
          action: InventoryLedgerAction.consume,
        ),
        occurredAt: time,
      );
      expect(
        (await ledger.read('canonical-wire', 'truck'))!.quantity.decimal,
        '0',
      );
      await expectLater(
        ledger.apply(
          request(
            'overdraw',
            '0.1',
            3,
            item: 'canonical-wire',
            action: InventoryLedgerAction.consume,
          ),
          occurredAt: time,
        ),
        throwsFormatException,
      );
      expect((await ledger.read('canonical-wire', 'truck'))!.revision, 3);
    },
  );

  test(
    'failed event write rolls back balance, command and audit, then retry succeeds',
    () async {
      await ledger.apply(request('first', '10', 0), occurredAt: time);
      await database.customStatement("""
      CREATE TRIGGER reject_inventory_event BEFORE INSERT ON local_records
      WHEN NEW.domain = 'inventory.event.v1'
      BEGIN SELECT RAISE(ABORT, 'injected disk write failure'); END;
    """);
      final command = request('retry', '5', 1);
      await expectLater(
        ledger.apply(command, occurredAt: time),
        throwsA(anything),
      );
      expect(
        (await ledger.read('canonical-tee', 'truck'))!.quantity.decimal,
        '10',
      );
      final commands = await database
          .customSelect(
            "SELECT command_id FROM local_commands WHERE command_id='inventory:retry'",
          )
          .get();
      expect(commands, isEmpty);
      await database.verifyIntegrity();
      await database.customStatement('DROP TRIGGER reject_inventory_event');
      await ledger.apply(command, occurredAt: time);
      expect(
        (await ledger.read('canonical-tee', 'truck'))!.quantity.decimal,
        '15',
      );
    },
  );

  test(
    'denied scope, unknown references and fractional each cannot create stock',
    () async {
      await expectLater(
        ledger.apply(
          request('bad-item', '1', 0, item: 'unknown'),
          occurredAt: time,
        ),
        throwsStateError,
      );
      await expectLater(
        ledger.apply(request('bad-fraction', '0.5', 0), occurredAt: time),
        throwsStateError,
      );
      grant = InventoryLedgerAccess(
        organizationId: 'other-company',
        actorId: 'owner',
        revision: 2,
        readableLocations: {'truck'},
        writableLocations: {'truck'},
      );
      await expectLater(
        ledger.read('canonical-tee', 'truck'),
        throwsStateError,
      );
      await expectLater(
        ledger.apply(request('denied', '1', 0), occurredAt: time),
        throwsStateError,
      );
    },
  );

  test('permission changes during item resolution prevent write', () async {
    final guarded = SqliteInventoryLedger(
      records: LocalRecordStore(database),
      organizationId: 'company',
      access: () => grant,
      resolveItem: (id) async {
        grant = InventoryLedgerAccess(
          organizationId: 'company',
          actorId: 'owner',
          revision: 2,
          readableLocations: {'truck'},
          writableLocations: {},
        );
        return InventoryLedgerItem(
          id: id,
          label: 'Test',
          stockUnit: 'each',
          allowsFractional: false,
        );
      },
      resolveLocation: (id) async =>
          InventoryLedgerLocation(id: id, label: id, active: true),
    );
    await expectLater(
      guarded.apply(request('revoked', '1', 0), occurredAt: time),
      throwsStateError,
    );
    expect(await ledger.read('canonical-tee', 'truck'), isNull);
  });

  test(
    'transfer is atomic, conserves quantity and retries only once',
    () async {
      await ledger.apply(request('seed', '10', 0), occurredAt: time);
      await ledger.apply(
        request('seed-other', '3', 0, location: 'warehouse'),
        occurredAt: time,
      );
      final move = InventoryTransferRequest(
        commandId: 'move-four',
        itemId: 'canonical-tee',
        fromLocationId: 'truck',
        toLocationId: 'warehouse',
        quantity: StockQuantity.parse('4'),
        expectedFromRevision: 1,
        expectedToRevision: 1,
      );
      await database.customStatement("""
      CREATE TRIGGER reject_transfer BEFORE INSERT ON local_records
      WHEN NEW.domain = 'inventory.event.v1'
      BEGIN SELECT RAISE(ABORT, 'injected transfer failure'); END;
    """);
      await expectLater(
        ledger.transfer(move, occurredAt: time),
        throwsA(anything),
      );
      expect(
        (await ledger.read('canonical-tee', 'truck'))!.quantity.decimal,
        '10',
      );
      expect(
        (await ledger.read('canonical-tee', 'warehouse'))!.quantity.decimal,
        '3',
      );
      await database.customStatement('DROP TRIGGER reject_transfer');
      final result = await ledger.transfer(move, occurredAt: time);
      expect(result.source.quantity.decimal, '6');
      expect(result.destination.quantity.decimal, '7');
      await ledger.transfer(move, occurredAt: time);
      expect(
        (await ledger.read('canonical-tee', 'truck'))!.quantity.decimal,
        '6',
      );
      expect(
        (await ledger.read('canonical-tee', 'warehouse'))!.quantity.decimal,
        '7',
      );
      await database.verifyIntegrity();
    },
  );

  test(
    'transfer rejects overdraw and destination permission without partial effect',
    () async {
      await ledger.apply(request('seed', '2', 0), occurredAt: time);
      final move = InventoryTransferRequest(
        commandId: 'move-three',
        itemId: 'canonical-tee',
        fromLocationId: 'truck',
        toLocationId: 'warehouse',
        quantity: StockQuantity.parse('3'),
        expectedFromRevision: 1,
        expectedToRevision: 0,
      );
      await expectLater(
        ledger.transfer(move, occurredAt: time),
        throwsFormatException,
      );
      expect(await ledger.read('canonical-tee', 'warehouse'), isNull);
      grant = InventoryLedgerAccess(
        organizationId: 'company',
        actorId: 'owner',
        revision: 2,
        readableLocations: {'truck', 'warehouse'},
        writableLocations: {'truck'},
      );
      await expectLater(
        ledger.transfer(move, occurredAt: time),
        throwsStateError,
      );
      expect(
        (await ledger.read('canonical-tee', 'truck'))!.quantity.decimal,
        '2',
      );
    },
  );

  test(
    'simultaneous replay creates one event and one balance change',
    () async {
      final same = request('same', '10', 0);
      await Future.wait([
        ledger.apply(same, occurredAt: time),
        ledger.apply(same, occurredAt: time),
      ]);
      expect(
        (await ledger.read('canonical-tee', 'truck'))!.quantity.decimal,
        '10',
      );
      final events = await LocalRecordStore(database).read(
        organizationId: 'company',
        domain: SqliteInventoryLedger.eventDomain,
        ownerIds: {'company'},
      );
      expect(events, hasLength(1));
      await database.verifyIntegrity();
    },
  );

  test(
    'stock quantity rejects overflow, negatives and excessive precision',
    () {
      for (final input in [
        '-1',
        '1.0000001',
        'NaN',
        '1e3',
        '9223372036854.775808',
      ]) {
        expect(() => StockQuantity.parse(input), throwsFormatException);
      }
      expect(StockQuantity.parse('0.000001').decimal, '0.000001');
    },
  );
}
