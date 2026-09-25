import '../storage/local_record_command.dart';
import '../storage/local_record_store.dart';
import 'inventory_ledger_contract.dart';
import 'stock_quantity.dart';

/// Inventory persistence foundation using the app's existing SQLite transaction
/// owner. UI and receipt confirmation adapters must resolve items/locations and
/// provide fresh access. No catalog row or expense is mutated by this boundary.
class SqliteInventoryLedger {
  const SqliteInventoryLedger({
    required this.records,
    required this.organizationId,
    required this.access,
    required this.resolveItem,
    required this.resolveLocation,
  });

  final LocalRecordStore records;
  final String organizationId;
  final InventoryLedgerAccess Function() access;
  final Future<InventoryLedgerItem?> Function(String) resolveItem;
  final Future<InventoryLedgerLocation?> Function(String) resolveLocation;
  static const balanceDomain = 'inventory.balance.v1';
  static const eventDomain = 'inventory.event.v1';

  Future<({InventoryLedgerBalance source, InventoryLedgerBalance destination})>
  transfer(
    InventoryTransferRequest request, {
    required DateTime occurredAt,
  }) async {
    if ([
          request.commandId,
          request.itemId,
          request.fromLocationId,
          request.toLocationId,
        ].any((v) => v.trim().isEmpty || v.length > 200) ||
        request.quantity.isZero ||
        request.fromLocationId == request.toLocationId ||
        request.expectedFromRevision < 0 ||
        request.expectedToRevision < 0) {
      throw ArgumentError(
        'Transfer needs distinct locations and valid quantity/revisions.',
      );
    }
    final grant = _authorize(request.fromLocationId, write: true);
    _unchanged(grant, request.toLocationId, write: true);
    final item = await resolveItem(request.itemId);
    final from = await resolveLocation(request.fromLocationId);
    final to = await resolveLocation(request.toLocationId);
    _unchanged(grant, request.fromLocationId, write: true);
    _unchanged(grant, request.toLocationId, write: true);
    if (item == null ||
        item.id != request.itemId ||
        item.stockUnit.trim().isEmpty ||
        item.label.trim().isEmpty ||
        from == null ||
        to == null ||
        from.id != request.fromLocationId ||
        to.id != request.toLocationId ||
        !from.active ||
        !to.active ||
        (!item.allowsFractional && !request.quantity.isWhole)) {
      throw StateError('Transfer item, locations or quantity are unavailable.');
    }
    final intent = <String, Object?>{
      'action': 'transfer',
      'itemId': item.id,
      'fromLocationId': from.id,
      'toLocationId': to.id,
      'stockUnit': item.stockUnit,
      'quantity': request.quantity.decimal,
      'actorId': grant.actorId,
      'expectedFromRevision': request.expectedFromRevision,
      'expectedToRevision': request.expectedToRevision,
    };
    final intentHash = payloadDigest(canonicalJson(intent));
    return records.database.transaction(() async {
      final prior = await records.read(
        organizationId: organizationId,
        domain: eventDomain,
        ownerIds: {organizationId},
        recordIds: {request.commandId},
      );
      if (prior.isNotEmpty) {
        final data = records.decode(prior.single);
        _unchanged(grant, from.id, write: true);
        _unchanged(grant, to.id, write: true);
        if (data['intentHash'] != intentHash) {
          throw const LocalRecordConflict(
            'This transfer command was used for different values.',
          );
        }
        return (
          source: InventoryLedgerBalance(
            itemId: item.id,
            locationId: from.id,
            stockUnit: item.stockUnit,
            quantity: StockQuantity.parse(data['fromAfter'] as String),
            revision: data['fromRevision'] as int,
          ),
          destination: InventoryLedgerBalance(
            itemId: item.id,
            locationId: to.id,
            stockUnit: item.stockUnit,
            quantity: StockQuantity.parse(data['toAfter'] as String),
            revision: data['toRevision'] as int,
          ),
        );
      }
      final source = await read(item.id, from.id);
      final destination = await read(item.id, to.id);
      if ((source?.revision ?? 0) != request.expectedFromRevision ||
          (destination?.revision ?? 0) != request.expectedToRevision ||
          (source != null && source.stockUnit != item.stockUnit) ||
          (destination != null && destination.stockUnit != item.stockUnit)) {
        throw const LocalRecordConflict(
          'Transfer stock changed. Reload both locations.',
        );
      }
      final fromBefore = source?.quantity ?? StockQuantity.parse('0');
      final toBefore = destination?.quantity ?? StockQuantity.parse('0');
      final fromAfter = fromBefore - request.quantity;
      final toAfter = toBefore + request.quantity;
      final fromRevision = request.expectedFromRevision + 1;
      final toRevision = request.expectedToRevision + 1;
      _unchanged(grant, from.id, write: true);
      _unchanged(grant, to.id, write: true);
      await records.commit(
        organizationId: organizationId,
        commandId: 'inventory:${request.commandId}',
        occurredAt: occurredAt,
        writes: [
          for (final side in [
            (from.id, fromAfter, request.expectedFromRevision),
            (to.id, toAfter, request.expectedToRevision),
          ])
            LocalRecordWrite(
              domain: balanceDomain,
              recordId: _id(item.id, side.$1),
              ownerId: organizationId,
              expectedRevision: side.$3,
              payload: {
                'itemId': item.id,
                'locationId': side.$1,
                'stockUnit': item.stockUnit,
                'quantity': side.$2.decimal,
              },
            ),
          LocalRecordWrite(
            domain: eventDomain,
            recordId: request.commandId,
            ownerId: organizationId,
            expectedRevision: 0,
            payload: {
              ...intent,
              'intentHash': intentHash,
              'fromBefore': fromBefore.decimal,
              'fromAfter': fromAfter.decimal,
              'toBefore': toBefore.decimal,
              'toAfter': toAfter.decimal,
              'fromRevision': fromRevision,
              'toRevision': toRevision,
              'itemLabelSnapshot': item.label,
              'fromLabelSnapshot': from.label,
              'toLabelSnapshot': to.label,
            },
          ),
        ],
      );
      return (
        source: InventoryLedgerBalance(
          itemId: item.id,
          locationId: from.id,
          stockUnit: item.stockUnit,
          quantity: fromAfter,
          revision: fromRevision,
        ),
        destination: InventoryLedgerBalance(
          itemId: item.id,
          locationId: to.id,
          stockUnit: item.stockUnit,
          quantity: toAfter,
          revision: toRevision,
        ),
      );
    });
  }

  String _id(String item, String location) =>
      'stock-${payloadDigest(canonicalJson([item, location]))}';

  InventoryLedgerAccess _authorize(String location, {required bool write}) {
    final grant = access();
    if (grant.organizationId != organizationId ||
        grant.actorId.trim().isEmpty ||
        grant.revision < 0 ||
        !grant.readableLocations.contains(location) ||
        (write && !grant.writableLocations.contains(location))) {
      throw StateError('Inventory access is unavailable for this location.');
    }
    return grant;
  }

  void _unchanged(
    InventoryLedgerAccess before,
    String location, {
    required bool write,
  }) {
    final now = _authorize(location, write: write);
    if (now.actorId != before.actorId || now.revision != before.revision) {
      throw StateError(
        'Inventory permission changed. Try again with current access.',
      );
    }
  }

  Future<InventoryLedgerBalance?> read(String itemId, String locationId) async {
    final grant = _authorize(locationId, write: false);
    final rows = await records.read(
      organizationId: organizationId,
      domain: balanceDomain,
      ownerIds: {organizationId},
      recordIds: {_id(itemId, locationId)},
    );
    _unchanged(grant, locationId, write: false);
    if (rows.isEmpty) return null;
    final row = rows.single;
    final data = records.decode(row);
    if (data['itemId'] != itemId ||
        data['locationId'] != locationId ||
        data['stockUnit'] is! String) {
      throw StateError('Stored inventory identity is inconsistent.');
    }
    return InventoryLedgerBalance(
      itemId: itemId,
      locationId: locationId,
      stockUnit: data['stockUnit'] as String,
      quantity: StockQuantity.parse(data['quantity'] as String),
      revision: row.revision,
    );
  }

  Future<InventoryLedgerBalance> apply(
    InventoryLedgerRequest request, {
    required DateTime occurredAt,
  }) async {
    if ([
          request.commandId,
          request.itemId,
          request.locationId,
        ].any((v) => v.trim().isEmpty || v.length > 200) ||
        request.quantity.isZero ||
        request.expectedRevision < 0 ||
        (request.sourceReference?.length ?? 0) > 500) {
      throw ArgumentError('Inventory command is incomplete or invalid.');
    }
    final grant = _authorize(request.locationId, write: true);
    final item = await resolveItem(request.itemId);
    final location = await resolveLocation(request.locationId);
    _unchanged(grant, request.locationId, write: true);
    if (item == null ||
        item.id != request.itemId ||
        item.stockUnit.trim().isEmpty ||
        item.label.trim().isEmpty ||
        location == null ||
        location.id != request.locationId ||
        !location.active ||
        (!item.allowsFractional && !request.quantity.isWhole)) {
      throw StateError(
        'The item, location or quantity cannot be used for this stock command.',
      );
    }
    final intent = <String, Object?>{
      'itemId': item.id,
      'locationId': location.id,
      'stockUnit': item.stockUnit,
      'quantity': request.quantity.decimal,
      'action': request.action.name,
      'expectedRevision': request.expectedRevision,
      'actorId': grant.actorId,
      'sourceReference': request.sourceReference,
    };
    final intentHash = payloadDigest(canonicalJson(intent));
    return records.database.transaction(() async {
      final prior = await records.read(
        organizationId: organizationId,
        domain: eventDomain,
        ownerIds: {organizationId},
        recordIds: {request.commandId},
      );
      if (prior.isNotEmpty) {
        final data = records.decode(prior.single);
        _unchanged(grant, location.id, write: true);
        if (data['intentHash'] != intentHash) {
          throw const LocalRecordConflict(
            'This stock command was used for different values.',
          );
        }
        return InventoryLedgerBalance(
          itemId: item.id,
          locationId: location.id,
          stockUnit: item.stockUnit,
          quantity: StockQuantity.parse(data['after'] as String),
          revision: data['balanceRevision'] as int,
        );
      }
      final current = await read(item.id, location.id);
      if ((current?.revision ?? 0) != request.expectedRevision ||
          (current != null && current.stockUnit != item.stockUnit)) {
        throw const LocalRecordConflict(
          'Stock changed or its unit needs migration. Reload before saving.',
        );
      }
      final before = current?.quantity ?? StockQuantity.parse('0');
      final after = request.action == InventoryLedgerAction.receive
          ? before + request.quantity
          : before - request.quantity;
      final nextRevision = request.expectedRevision + 1;
      _unchanged(grant, location.id, write: true);
      await records.commit(
        organizationId: organizationId,
        commandId: 'inventory:${request.commandId}',
        occurredAt: occurredAt,
        writes: [
          LocalRecordWrite(
            domain: balanceDomain,
            recordId: _id(item.id, location.id),
            ownerId: organizationId,
            expectedRevision: request.expectedRevision,
            payload: {
              'itemId': item.id,
              'locationId': location.id,
              'stockUnit': item.stockUnit,
              'quantity': after.decimal,
            },
          ),
          LocalRecordWrite(
            domain: eventDomain,
            recordId: request.commandId,
            ownerId: organizationId,
            expectedRevision: 0,
            payload: {
              ...intent,
              'intentHash': intentHash,
              'before': before.decimal,
              'after': after.decimal,
              'balanceRevision': nextRevision,
              'itemLabelSnapshot': item.label,
              'locationLabelSnapshot': location.label,
            },
          ),
        ],
      );
      return InventoryLedgerBalance(
        itemId: item.id,
        locationId: location.id,
        stockUnit: item.stockUnit,
        quantity: after,
        revision: nextRevision,
      );
    });
  }
}
