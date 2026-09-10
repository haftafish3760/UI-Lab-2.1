// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class LocalRecords extends Table with TableInfo<LocalRecords, LocalRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalRecords(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(organization_id) > 0)',
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(domain) > 0)',
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(record_id) > 0)',
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(owner_id) > 0)',
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (revision > 0)',
  );
  static const VerificationMeta _payloadVersionMeta = const VerificationMeta(
    'payloadVersion',
  );
  late final GeneratedColumn<int> payloadVersion = GeneratedColumn<int>(
    'payload_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (payload_version > 0)',
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(payload))',
  );
  static const VerificationMeta _updatedAtUsMeta = const VerificationMeta(
    'updatedAtUs',
  );
  late final GeneratedColumn<int> updatedAtUs = GeneratedColumn<int>(
    'updated_at_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    domain,
    recordId,
    ownerId,
    revision,
    payloadVersion,
    payload,
    updatedAtUs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('payload_version')) {
      context.handle(
        _payloadVersionMeta,
        payloadVersion.isAcceptableOrUnknown(
          data['payload_version']!,
          _payloadVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadVersionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at_us')) {
      context.handle(
        _updatedAtUsMeta,
        updatedAtUs.isAcceptableOrUnknown(
          data['updated_at_us']!,
          _updatedAtUsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId, domain, recordId};
  @override
  LocalRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRecord(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      payloadVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payload_version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAtUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_us'],
      )!,
    );
  }

  @override
  LocalRecords createAlias(String alias) {
    return LocalRecords(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(organization_id, domain, record_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LocalRecord extends DataClass implements Insertable<LocalRecord> {
  final String organizationId;
  final String domain;
  final String recordId;
  final String ownerId;
  final int revision;
  final int payloadVersion;
  final String payload;
  final int updatedAtUs;
  const LocalRecord({
    required this.organizationId,
    required this.domain,
    required this.recordId,
    required this.ownerId,
    required this.revision,
    required this.payloadVersion,
    required this.payload,
    required this.updatedAtUs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['domain'] = Variable<String>(domain);
    map['record_id'] = Variable<String>(recordId);
    map['owner_id'] = Variable<String>(ownerId);
    map['revision'] = Variable<int>(revision);
    map['payload_version'] = Variable<int>(payloadVersion);
    map['payload'] = Variable<String>(payload);
    map['updated_at_us'] = Variable<int>(updatedAtUs);
    return map;
  }

  LocalRecordsCompanion toCompanion(bool nullToAbsent) {
    return LocalRecordsCompanion(
      organizationId: Value(organizationId),
      domain: Value(domain),
      recordId: Value(recordId),
      ownerId: Value(ownerId),
      revision: Value(revision),
      payloadVersion: Value(payloadVersion),
      payload: Value(payload),
      updatedAtUs: Value(updatedAtUs),
    );
  }

  factory LocalRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRecord(
      organizationId: serializer.fromJson<String>(json['organization_id']),
      domain: serializer.fromJson<String>(json['domain']),
      recordId: serializer.fromJson<String>(json['record_id']),
      ownerId: serializer.fromJson<String>(json['owner_id']),
      revision: serializer.fromJson<int>(json['revision']),
      payloadVersion: serializer.fromJson<int>(json['payload_version']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAtUs: serializer.fromJson<int>(json['updated_at_us']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organization_id': serializer.toJson<String>(organizationId),
      'domain': serializer.toJson<String>(domain),
      'record_id': serializer.toJson<String>(recordId),
      'owner_id': serializer.toJson<String>(ownerId),
      'revision': serializer.toJson<int>(revision),
      'payload_version': serializer.toJson<int>(payloadVersion),
      'payload': serializer.toJson<String>(payload),
      'updated_at_us': serializer.toJson<int>(updatedAtUs),
    };
  }

  LocalRecord copyWith({
    String? organizationId,
    String? domain,
    String? recordId,
    String? ownerId,
    int? revision,
    int? payloadVersion,
    String? payload,
    int? updatedAtUs,
  }) => LocalRecord(
    organizationId: organizationId ?? this.organizationId,
    domain: domain ?? this.domain,
    recordId: recordId ?? this.recordId,
    ownerId: ownerId ?? this.ownerId,
    revision: revision ?? this.revision,
    payloadVersion: payloadVersion ?? this.payloadVersion,
    payload: payload ?? this.payload,
    updatedAtUs: updatedAtUs ?? this.updatedAtUs,
  );
  LocalRecord copyWithCompanion(LocalRecordsCompanion data) {
    return LocalRecord(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      domain: data.domain.present ? data.domain.value : this.domain,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      revision: data.revision.present ? data.revision.value : this.revision,
      payloadVersion: data.payloadVersion.present
          ? data.payloadVersion.value
          : this.payloadVersion,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAtUs: data.updatedAtUs.present
          ? data.updatedAtUs.value
          : this.updatedAtUs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecord(')
          ..write('organizationId: $organizationId, ')
          ..write('domain: $domain, ')
          ..write('recordId: $recordId, ')
          ..write('ownerId: $ownerId, ')
          ..write('revision: $revision, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('payload: $payload, ')
          ..write('updatedAtUs: $updatedAtUs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    organizationId,
    domain,
    recordId,
    ownerId,
    revision,
    payloadVersion,
    payload,
    updatedAtUs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRecord &&
          other.organizationId == this.organizationId &&
          other.domain == this.domain &&
          other.recordId == this.recordId &&
          other.ownerId == this.ownerId &&
          other.revision == this.revision &&
          other.payloadVersion == this.payloadVersion &&
          other.payload == this.payload &&
          other.updatedAtUs == this.updatedAtUs);
}

class LocalRecordsCompanion extends UpdateCompanion<LocalRecord> {
  final Value<String> organizationId;
  final Value<String> domain;
  final Value<String> recordId;
  final Value<String> ownerId;
  final Value<int> revision;
  final Value<int> payloadVersion;
  final Value<String> payload;
  final Value<int> updatedAtUs;
  final Value<int> rowid;
  const LocalRecordsCompanion({
    this.organizationId = const Value.absent(),
    this.domain = const Value.absent(),
    this.recordId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.revision = const Value.absent(),
    this.payloadVersion = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAtUs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRecordsCompanion.insert({
    required String organizationId,
    required String domain,
    required String recordId,
    required String ownerId,
    required int revision,
    required int payloadVersion,
    required String payload,
    required int updatedAtUs,
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       domain = Value(domain),
       recordId = Value(recordId),
       ownerId = Value(ownerId),
       revision = Value(revision),
       payloadVersion = Value(payloadVersion),
       payload = Value(payload),
       updatedAtUs = Value(updatedAtUs);
  static Insertable<LocalRecord> custom({
    Expression<String>? organizationId,
    Expression<String>? domain,
    Expression<String>? recordId,
    Expression<String>? ownerId,
    Expression<int>? revision,
    Expression<int>? payloadVersion,
    Expression<String>? payload,
    Expression<int>? updatedAtUs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (domain != null) 'domain': domain,
      if (recordId != null) 'record_id': recordId,
      if (ownerId != null) 'owner_id': ownerId,
      if (revision != null) 'revision': revision,
      if (payloadVersion != null) 'payload_version': payloadVersion,
      if (payload != null) 'payload': payload,
      if (updatedAtUs != null) 'updated_at_us': updatedAtUs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRecordsCompanion copyWith({
    Value<String>? organizationId,
    Value<String>? domain,
    Value<String>? recordId,
    Value<String>? ownerId,
    Value<int>? revision,
    Value<int>? payloadVersion,
    Value<String>? payload,
    Value<int>? updatedAtUs,
    Value<int>? rowid,
  }) {
    return LocalRecordsCompanion(
      organizationId: organizationId ?? this.organizationId,
      domain: domain ?? this.domain,
      recordId: recordId ?? this.recordId,
      ownerId: ownerId ?? this.ownerId,
      revision: revision ?? this.revision,
      payloadVersion: payloadVersion ?? this.payloadVersion,
      payload: payload ?? this.payload,
      updatedAtUs: updatedAtUs ?? this.updatedAtUs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (payloadVersion.present) {
      map['payload_version'] = Variable<int>(payloadVersion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAtUs.present) {
      map['updated_at_us'] = Variable<int>(updatedAtUs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecordsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('domain: $domain, ')
          ..write('recordId: $recordId, ')
          ..write('ownerId: $ownerId, ')
          ..write('revision: $revision, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('payload: $payload, ')
          ..write('updatedAtUs: $updatedAtUs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LocalCommands extends Table with TableInfo<LocalCommands, LocalCommand> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalCommands(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _commandIdMeta = const VerificationMeta(
    'commandId',
  );
  late final GeneratedColumn<String> commandId = GeneratedColumn<String>(
    'command_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(command_id) > 0)',
  );
  static const VerificationMeta _requestHashMeta = const VerificationMeta(
    'requestHash',
  );
  late final GeneratedColumn<String> requestHash = GeneratedColumn<String>(
    'request_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _committedAtUsMeta = const VerificationMeta(
    'committedAtUs',
  );
  late final GeneratedColumn<int> committedAtUs = GeneratedColumn<int>(
    'committed_at_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    commandId,
    requestHash,
    committedAtUs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_commands';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCommand> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('command_id')) {
      context.handle(
        _commandIdMeta,
        commandId.isAcceptableOrUnknown(data['command_id']!, _commandIdMeta),
      );
    } else if (isInserting) {
      context.missing(_commandIdMeta);
    }
    if (data.containsKey('request_hash')) {
      context.handle(
        _requestHashMeta,
        requestHash.isAcceptableOrUnknown(
          data['request_hash']!,
          _requestHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestHashMeta);
    }
    if (data.containsKey('committed_at_us')) {
      context.handle(
        _committedAtUsMeta,
        committedAtUs.isAcceptableOrUnknown(
          data['committed_at_us']!,
          _committedAtUsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_committedAtUsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId, commandId};
  @override
  LocalCommand map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCommand(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      commandId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command_id'],
      )!,
      requestHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_hash'],
      )!,
      committedAtUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}committed_at_us'],
      )!,
    );
  }

  @override
  LocalCommands createAlias(String alias) {
    return LocalCommands(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(organization_id, command_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LocalCommand extends DataClass implements Insertable<LocalCommand> {
  final String organizationId;
  final String commandId;
  final String requestHash;
  final int committedAtUs;
  const LocalCommand({
    required this.organizationId,
    required this.commandId,
    required this.requestHash,
    required this.committedAtUs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['command_id'] = Variable<String>(commandId);
    map['request_hash'] = Variable<String>(requestHash);
    map['committed_at_us'] = Variable<int>(committedAtUs);
    return map;
  }

  LocalCommandsCompanion toCompanion(bool nullToAbsent) {
    return LocalCommandsCompanion(
      organizationId: Value(organizationId),
      commandId: Value(commandId),
      requestHash: Value(requestHash),
      committedAtUs: Value(committedAtUs),
    );
  }

  factory LocalCommand.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCommand(
      organizationId: serializer.fromJson<String>(json['organization_id']),
      commandId: serializer.fromJson<String>(json['command_id']),
      requestHash: serializer.fromJson<String>(json['request_hash']),
      committedAtUs: serializer.fromJson<int>(json['committed_at_us']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organization_id': serializer.toJson<String>(organizationId),
      'command_id': serializer.toJson<String>(commandId),
      'request_hash': serializer.toJson<String>(requestHash),
      'committed_at_us': serializer.toJson<int>(committedAtUs),
    };
  }

  LocalCommand copyWith({
    String? organizationId,
    String? commandId,
    String? requestHash,
    int? committedAtUs,
  }) => LocalCommand(
    organizationId: organizationId ?? this.organizationId,
    commandId: commandId ?? this.commandId,
    requestHash: requestHash ?? this.requestHash,
    committedAtUs: committedAtUs ?? this.committedAtUs,
  );
  LocalCommand copyWithCompanion(LocalCommandsCompanion data) {
    return LocalCommand(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      commandId: data.commandId.present ? data.commandId.value : this.commandId,
      requestHash: data.requestHash.present
          ? data.requestHash.value
          : this.requestHash,
      committedAtUs: data.committedAtUs.present
          ? data.committedAtUs.value
          : this.committedAtUs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCommand(')
          ..write('organizationId: $organizationId, ')
          ..write('commandId: $commandId, ')
          ..write('requestHash: $requestHash, ')
          ..write('committedAtUs: $committedAtUs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(organizationId, commandId, requestHash, committedAtUs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCommand &&
          other.organizationId == this.organizationId &&
          other.commandId == this.commandId &&
          other.requestHash == this.requestHash &&
          other.committedAtUs == this.committedAtUs);
}

class LocalCommandsCompanion extends UpdateCompanion<LocalCommand> {
  final Value<String> organizationId;
  final Value<String> commandId;
  final Value<String> requestHash;
  final Value<int> committedAtUs;
  final Value<int> rowid;
  const LocalCommandsCompanion({
    this.organizationId = const Value.absent(),
    this.commandId = const Value.absent(),
    this.requestHash = const Value.absent(),
    this.committedAtUs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCommandsCompanion.insert({
    required String organizationId,
    required String commandId,
    required String requestHash,
    required int committedAtUs,
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       commandId = Value(commandId),
       requestHash = Value(requestHash),
       committedAtUs = Value(committedAtUs);
  static Insertable<LocalCommand> custom({
    Expression<String>? organizationId,
    Expression<String>? commandId,
    Expression<String>? requestHash,
    Expression<int>? committedAtUs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (commandId != null) 'command_id': commandId,
      if (requestHash != null) 'request_hash': requestHash,
      if (committedAtUs != null) 'committed_at_us': committedAtUs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCommandsCompanion copyWith({
    Value<String>? organizationId,
    Value<String>? commandId,
    Value<String>? requestHash,
    Value<int>? committedAtUs,
    Value<int>? rowid,
  }) {
    return LocalCommandsCompanion(
      organizationId: organizationId ?? this.organizationId,
      commandId: commandId ?? this.commandId,
      requestHash: requestHash ?? this.requestHash,
      committedAtUs: committedAtUs ?? this.committedAtUs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (commandId.present) {
      map['command_id'] = Variable<String>(commandId.value);
    }
    if (requestHash.present) {
      map['request_hash'] = Variable<String>(requestHash.value);
    }
    if (committedAtUs.present) {
      map['committed_at_us'] = Variable<int>(committedAtUs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCommandsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('commandId: $commandId, ')
          ..write('requestHash: $requestHash, ')
          ..write('committedAtUs: $committedAtUs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LocalRecordRevisions extends Table
    with TableInfo<LocalRecordRevisions, LocalRecordRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalRecordRevisions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (revision > 0)',
  );
  static const VerificationMeta _commandIdMeta = const VerificationMeta(
    'commandId',
  );
  late final GeneratedColumn<String> commandId = GeneratedColumn<String>(
    'command_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _payloadVersionMeta = const VerificationMeta(
    'payloadVersion',
  );
  late final GeneratedColumn<int> payloadVersion = GeneratedColumn<int>(
    'payload_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (payload_version > 0)',
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(payload))',
  );
  static const VerificationMeta _payloadHashMeta = const VerificationMeta(
    'payloadHash',
  );
  late final GeneratedColumn<String> payloadHash = GeneratedColumn<String>(
    'payload_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtUsMeta = const VerificationMeta(
    'updatedAtUs',
  );
  late final GeneratedColumn<int> updatedAtUs = GeneratedColumn<int>(
    'updated_at_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    domain,
    recordId,
    revision,
    commandId,
    ownerId,
    payloadVersion,
    payload,
    payloadHash,
    updatedAtUs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_record_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalRecordRevision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('command_id')) {
      context.handle(
        _commandIdMeta,
        commandId.isAcceptableOrUnknown(data['command_id']!, _commandIdMeta),
      );
    } else if (isInserting) {
      context.missing(_commandIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('payload_version')) {
      context.handle(
        _payloadVersionMeta,
        payloadVersion.isAcceptableOrUnknown(
          data['payload_version']!,
          _payloadVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadVersionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('payload_hash')) {
      context.handle(
        _payloadHashMeta,
        payloadHash.isAcceptableOrUnknown(
          data['payload_hash']!,
          _payloadHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadHashMeta);
    }
    if (data.containsKey('updated_at_us')) {
      context.handle(
        _updatedAtUsMeta,
        updatedAtUs.isAcceptableOrUnknown(
          data['updated_at_us']!,
          _updatedAtUsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    organizationId,
    domain,
    recordId,
    revision,
  };
  @override
  LocalRecordRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRecordRevision(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      commandId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command_id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      payloadVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payload_version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      payloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_hash'],
      )!,
      updatedAtUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_us'],
      )!,
    );
  }

  @override
  LocalRecordRevisions createAlias(String alias) {
    return LocalRecordRevisions(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(organization_id, domain, record_id, revision)',
    'FOREIGN KEY(organization_id, domain, record_id)REFERENCES local_records(organization_id, domain, record_id)',
    'FOREIGN KEY(organization_id, command_id)REFERENCES local_commands(organization_id, command_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LocalRecordRevision extends DataClass
    implements Insertable<LocalRecordRevision> {
  final String organizationId;
  final String domain;
  final String recordId;
  final int revision;
  final String commandId;
  final String ownerId;
  final int payloadVersion;
  final String payload;
  final String payloadHash;
  final int updatedAtUs;
  const LocalRecordRevision({
    required this.organizationId,
    required this.domain,
    required this.recordId,
    required this.revision,
    required this.commandId,
    required this.ownerId,
    required this.payloadVersion,
    required this.payload,
    required this.payloadHash,
    required this.updatedAtUs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['domain'] = Variable<String>(domain);
    map['record_id'] = Variable<String>(recordId);
    map['revision'] = Variable<int>(revision);
    map['command_id'] = Variable<String>(commandId);
    map['owner_id'] = Variable<String>(ownerId);
    map['payload_version'] = Variable<int>(payloadVersion);
    map['payload'] = Variable<String>(payload);
    map['payload_hash'] = Variable<String>(payloadHash);
    map['updated_at_us'] = Variable<int>(updatedAtUs);
    return map;
  }

  LocalRecordRevisionsCompanion toCompanion(bool nullToAbsent) {
    return LocalRecordRevisionsCompanion(
      organizationId: Value(organizationId),
      domain: Value(domain),
      recordId: Value(recordId),
      revision: Value(revision),
      commandId: Value(commandId),
      ownerId: Value(ownerId),
      payloadVersion: Value(payloadVersion),
      payload: Value(payload),
      payloadHash: Value(payloadHash),
      updatedAtUs: Value(updatedAtUs),
    );
  }

  factory LocalRecordRevision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRecordRevision(
      organizationId: serializer.fromJson<String>(json['organization_id']),
      domain: serializer.fromJson<String>(json['domain']),
      recordId: serializer.fromJson<String>(json['record_id']),
      revision: serializer.fromJson<int>(json['revision']),
      commandId: serializer.fromJson<String>(json['command_id']),
      ownerId: serializer.fromJson<String>(json['owner_id']),
      payloadVersion: serializer.fromJson<int>(json['payload_version']),
      payload: serializer.fromJson<String>(json['payload']),
      payloadHash: serializer.fromJson<String>(json['payload_hash']),
      updatedAtUs: serializer.fromJson<int>(json['updated_at_us']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organization_id': serializer.toJson<String>(organizationId),
      'domain': serializer.toJson<String>(domain),
      'record_id': serializer.toJson<String>(recordId),
      'revision': serializer.toJson<int>(revision),
      'command_id': serializer.toJson<String>(commandId),
      'owner_id': serializer.toJson<String>(ownerId),
      'payload_version': serializer.toJson<int>(payloadVersion),
      'payload': serializer.toJson<String>(payload),
      'payload_hash': serializer.toJson<String>(payloadHash),
      'updated_at_us': serializer.toJson<int>(updatedAtUs),
    };
  }

  LocalRecordRevision copyWith({
    String? organizationId,
    String? domain,
    String? recordId,
    int? revision,
    String? commandId,
    String? ownerId,
    int? payloadVersion,
    String? payload,
    String? payloadHash,
    int? updatedAtUs,
  }) => LocalRecordRevision(
    organizationId: organizationId ?? this.organizationId,
    domain: domain ?? this.domain,
    recordId: recordId ?? this.recordId,
    revision: revision ?? this.revision,
    commandId: commandId ?? this.commandId,
    ownerId: ownerId ?? this.ownerId,
    payloadVersion: payloadVersion ?? this.payloadVersion,
    payload: payload ?? this.payload,
    payloadHash: payloadHash ?? this.payloadHash,
    updatedAtUs: updatedAtUs ?? this.updatedAtUs,
  );
  LocalRecordRevision copyWithCompanion(LocalRecordRevisionsCompanion data) {
    return LocalRecordRevision(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      domain: data.domain.present ? data.domain.value : this.domain,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      revision: data.revision.present ? data.revision.value : this.revision,
      commandId: data.commandId.present ? data.commandId.value : this.commandId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      payloadVersion: data.payloadVersion.present
          ? data.payloadVersion.value
          : this.payloadVersion,
      payload: data.payload.present ? data.payload.value : this.payload,
      payloadHash: data.payloadHash.present
          ? data.payloadHash.value
          : this.payloadHash,
      updatedAtUs: data.updatedAtUs.present
          ? data.updatedAtUs.value
          : this.updatedAtUs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecordRevision(')
          ..write('organizationId: $organizationId, ')
          ..write('domain: $domain, ')
          ..write('recordId: $recordId, ')
          ..write('revision: $revision, ')
          ..write('commandId: $commandId, ')
          ..write('ownerId: $ownerId, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('payload: $payload, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('updatedAtUs: $updatedAtUs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    organizationId,
    domain,
    recordId,
    revision,
    commandId,
    ownerId,
    payloadVersion,
    payload,
    payloadHash,
    updatedAtUs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRecordRevision &&
          other.organizationId == this.organizationId &&
          other.domain == this.domain &&
          other.recordId == this.recordId &&
          other.revision == this.revision &&
          other.commandId == this.commandId &&
          other.ownerId == this.ownerId &&
          other.payloadVersion == this.payloadVersion &&
          other.payload == this.payload &&
          other.payloadHash == this.payloadHash &&
          other.updatedAtUs == this.updatedAtUs);
}

class LocalRecordRevisionsCompanion
    extends UpdateCompanion<LocalRecordRevision> {
  final Value<String> organizationId;
  final Value<String> domain;
  final Value<String> recordId;
  final Value<int> revision;
  final Value<String> commandId;
  final Value<String> ownerId;
  final Value<int> payloadVersion;
  final Value<String> payload;
  final Value<String> payloadHash;
  final Value<int> updatedAtUs;
  final Value<int> rowid;
  const LocalRecordRevisionsCompanion({
    this.organizationId = const Value.absent(),
    this.domain = const Value.absent(),
    this.recordId = const Value.absent(),
    this.revision = const Value.absent(),
    this.commandId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.payloadVersion = const Value.absent(),
    this.payload = const Value.absent(),
    this.payloadHash = const Value.absent(),
    this.updatedAtUs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRecordRevisionsCompanion.insert({
    required String organizationId,
    required String domain,
    required String recordId,
    required int revision,
    required String commandId,
    required String ownerId,
    required int payloadVersion,
    required String payload,
    required String payloadHash,
    required int updatedAtUs,
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       domain = Value(domain),
       recordId = Value(recordId),
       revision = Value(revision),
       commandId = Value(commandId),
       ownerId = Value(ownerId),
       payloadVersion = Value(payloadVersion),
       payload = Value(payload),
       payloadHash = Value(payloadHash),
       updatedAtUs = Value(updatedAtUs);
  static Insertable<LocalRecordRevision> custom({
    Expression<String>? organizationId,
    Expression<String>? domain,
    Expression<String>? recordId,
    Expression<int>? revision,
    Expression<String>? commandId,
    Expression<String>? ownerId,
    Expression<int>? payloadVersion,
    Expression<String>? payload,
    Expression<String>? payloadHash,
    Expression<int>? updatedAtUs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (domain != null) 'domain': domain,
      if (recordId != null) 'record_id': recordId,
      if (revision != null) 'revision': revision,
      if (commandId != null) 'command_id': commandId,
      if (ownerId != null) 'owner_id': ownerId,
      if (payloadVersion != null) 'payload_version': payloadVersion,
      if (payload != null) 'payload': payload,
      if (payloadHash != null) 'payload_hash': payloadHash,
      if (updatedAtUs != null) 'updated_at_us': updatedAtUs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRecordRevisionsCompanion copyWith({
    Value<String>? organizationId,
    Value<String>? domain,
    Value<String>? recordId,
    Value<int>? revision,
    Value<String>? commandId,
    Value<String>? ownerId,
    Value<int>? payloadVersion,
    Value<String>? payload,
    Value<String>? payloadHash,
    Value<int>? updatedAtUs,
    Value<int>? rowid,
  }) {
    return LocalRecordRevisionsCompanion(
      organizationId: organizationId ?? this.organizationId,
      domain: domain ?? this.domain,
      recordId: recordId ?? this.recordId,
      revision: revision ?? this.revision,
      commandId: commandId ?? this.commandId,
      ownerId: ownerId ?? this.ownerId,
      payloadVersion: payloadVersion ?? this.payloadVersion,
      payload: payload ?? this.payload,
      payloadHash: payloadHash ?? this.payloadHash,
      updatedAtUs: updatedAtUs ?? this.updatedAtUs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (commandId.present) {
      map['command_id'] = Variable<String>(commandId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (payloadVersion.present) {
      map['payload_version'] = Variable<int>(payloadVersion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (payloadHash.present) {
      map['payload_hash'] = Variable<String>(payloadHash.value);
    }
    if (updatedAtUs.present) {
      map['updated_at_us'] = Variable<int>(updatedAtUs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecordRevisionsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('domain: $domain, ')
          ..write('recordId: $recordId, ')
          ..write('revision: $revision, ')
          ..write('commandId: $commandId, ')
          ..write('ownerId: $ownerId, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('payload: $payload, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('updatedAtUs: $updatedAtUs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LocalChangeOutbox extends Table
    with TableInfo<LocalChangeOutbox, LocalChangeOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalChangeOutbox(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _commandIdMeta = const VerificationMeta(
    'commandId',
  );
  late final GeneratedColumn<String> commandId = GeneratedColumn<String>(
    'command_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'local\' CHECK (state IN (\'local\', \'pending\', \'acknowledged\', \'conflict\', \'rejected\'))',
    defaultValue: const CustomExpression('\'local\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sequence,
    organizationId,
    commandId,
    state,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_change_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalChangeOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('command_id')) {
      context.handle(
        _commandIdMeta,
        commandId.isAcceptableOrUnknown(data['command_id']!, _commandIdMeta),
      );
    } else if (isInserting) {
      context.missing(_commandIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sequence};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {organizationId, commandId},
  ];
  @override
  LocalChangeOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalChangeOutboxData(
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      commandId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  LocalChangeOutbox createAlias(String alias) {
    return LocalChangeOutbox(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(organization_id, command_id)',
    'FOREIGN KEY(organization_id, command_id)REFERENCES local_commands(organization_id, command_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LocalChangeOutboxData extends DataClass
    implements Insertable<LocalChangeOutboxData> {
  final int sequence;
  final String organizationId;
  final String commandId;
  final String state;
  const LocalChangeOutboxData({
    required this.sequence,
    required this.organizationId,
    required this.commandId,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sequence'] = Variable<int>(sequence);
    map['organization_id'] = Variable<String>(organizationId);
    map['command_id'] = Variable<String>(commandId);
    map['state'] = Variable<String>(state);
    return map;
  }

  LocalChangeOutboxCompanion toCompanion(bool nullToAbsent) {
    return LocalChangeOutboxCompanion(
      sequence: Value(sequence),
      organizationId: Value(organizationId),
      commandId: Value(commandId),
      state: Value(state),
    );
  }

  factory LocalChangeOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalChangeOutboxData(
      sequence: serializer.fromJson<int>(json['sequence']),
      organizationId: serializer.fromJson<String>(json['organization_id']),
      commandId: serializer.fromJson<String>(json['command_id']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sequence': serializer.toJson<int>(sequence),
      'organization_id': serializer.toJson<String>(organizationId),
      'command_id': serializer.toJson<String>(commandId),
      'state': serializer.toJson<String>(state),
    };
  }

  LocalChangeOutboxData copyWith({
    int? sequence,
    String? organizationId,
    String? commandId,
    String? state,
  }) => LocalChangeOutboxData(
    sequence: sequence ?? this.sequence,
    organizationId: organizationId ?? this.organizationId,
    commandId: commandId ?? this.commandId,
    state: state ?? this.state,
  );
  LocalChangeOutboxData copyWithCompanion(LocalChangeOutboxCompanion data) {
    return LocalChangeOutboxData(
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      commandId: data.commandId.present ? data.commandId.value : this.commandId,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalChangeOutboxData(')
          ..write('sequence: $sequence, ')
          ..write('organizationId: $organizationId, ')
          ..write('commandId: $commandId, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sequence, organizationId, commandId, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalChangeOutboxData &&
          other.sequence == this.sequence &&
          other.organizationId == this.organizationId &&
          other.commandId == this.commandId &&
          other.state == this.state);
}

class LocalChangeOutboxCompanion
    extends UpdateCompanion<LocalChangeOutboxData> {
  final Value<int> sequence;
  final Value<String> organizationId;
  final Value<String> commandId;
  final Value<String> state;
  const LocalChangeOutboxCompanion({
    this.sequence = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.commandId = const Value.absent(),
    this.state = const Value.absent(),
  });
  LocalChangeOutboxCompanion.insert({
    this.sequence = const Value.absent(),
    required String organizationId,
    required String commandId,
    this.state = const Value.absent(),
  }) : organizationId = Value(organizationId),
       commandId = Value(commandId);
  static Insertable<LocalChangeOutboxData> custom({
    Expression<int>? sequence,
    Expression<String>? organizationId,
    Expression<String>? commandId,
    Expression<String>? state,
  }) {
    return RawValuesInsertable({
      if (sequence != null) 'sequence': sequence,
      if (organizationId != null) 'organization_id': organizationId,
      if (commandId != null) 'command_id': commandId,
      if (state != null) 'state': state,
    });
  }

  LocalChangeOutboxCompanion copyWith({
    Value<int>? sequence,
    Value<String>? organizationId,
    Value<String>? commandId,
    Value<String>? state,
  }) {
    return LocalChangeOutboxCompanion(
      sequence: sequence ?? this.sequence,
      organizationId: organizationId ?? this.organizationId,
      commandId: commandId ?? this.commandId,
      state: state ?? this.state,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (commandId.present) {
      map['command_id'] = Variable<String>(commandId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalChangeOutboxCompanion(')
          ..write('sequence: $sequence, ')
          ..write('organizationId: $organizationId, ')
          ..write('commandId: $commandId, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }
}

class LocalDrafts extends Table with TableInfo<LocalDrafts, LocalDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalDrafts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _draftIdMeta = const VerificationMeta(
    'draftId',
  );
  late final GeneratedColumn<String> draftId = GeneratedColumn<String>(
    'draft_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (revision > 0)',
  );
  static const VerificationMeta _payloadVersionMeta = const VerificationMeta(
    'payloadVersion',
  );
  late final GeneratedColumn<int> payloadVersion = GeneratedColumn<int>(
    'payload_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (payload_version > 0)',
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(payload))',
  );
  static const VerificationMeta _updatedAtUsMeta = const VerificationMeta(
    'updatedAtUs',
  );
  late final GeneratedColumn<int> updatedAtUs = GeneratedColumn<int>(
    'updated_at_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    domain,
    draftId,
    ownerId,
    revision,
    payloadVersion,
    payload,
    updatedAtUs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('draft_id')) {
      context.handle(
        _draftIdMeta,
        draftId.isAcceptableOrUnknown(data['draft_id']!, _draftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_draftIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('payload_version')) {
      context.handle(
        _payloadVersionMeta,
        payloadVersion.isAcceptableOrUnknown(
          data['payload_version']!,
          _payloadVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadVersionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at_us')) {
      context.handle(
        _updatedAtUsMeta,
        updatedAtUs.isAcceptableOrUnknown(
          data['updated_at_us']!,
          _updatedAtUsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId, domain, draftId};
  @override
  LocalDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDraft(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      draftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      payloadVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payload_version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAtUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_us'],
      )!,
    );
  }

  @override
  LocalDrafts createAlias(String alias) {
    return LocalDrafts(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(organization_id, domain, draft_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LocalDraft extends DataClass implements Insertable<LocalDraft> {
  final String organizationId;
  final String domain;
  final String draftId;
  final String ownerId;
  final int revision;
  final int payloadVersion;
  final String payload;
  final int updatedAtUs;
  const LocalDraft({
    required this.organizationId,
    required this.domain,
    required this.draftId,
    required this.ownerId,
    required this.revision,
    required this.payloadVersion,
    required this.payload,
    required this.updatedAtUs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['domain'] = Variable<String>(domain);
    map['draft_id'] = Variable<String>(draftId);
    map['owner_id'] = Variable<String>(ownerId);
    map['revision'] = Variable<int>(revision);
    map['payload_version'] = Variable<int>(payloadVersion);
    map['payload'] = Variable<String>(payload);
    map['updated_at_us'] = Variable<int>(updatedAtUs);
    return map;
  }

  LocalDraftsCompanion toCompanion(bool nullToAbsent) {
    return LocalDraftsCompanion(
      organizationId: Value(organizationId),
      domain: Value(domain),
      draftId: Value(draftId),
      ownerId: Value(ownerId),
      revision: Value(revision),
      payloadVersion: Value(payloadVersion),
      payload: Value(payload),
      updatedAtUs: Value(updatedAtUs),
    );
  }

  factory LocalDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDraft(
      organizationId: serializer.fromJson<String>(json['organization_id']),
      domain: serializer.fromJson<String>(json['domain']),
      draftId: serializer.fromJson<String>(json['draft_id']),
      ownerId: serializer.fromJson<String>(json['owner_id']),
      revision: serializer.fromJson<int>(json['revision']),
      payloadVersion: serializer.fromJson<int>(json['payload_version']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAtUs: serializer.fromJson<int>(json['updated_at_us']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organization_id': serializer.toJson<String>(organizationId),
      'domain': serializer.toJson<String>(domain),
      'draft_id': serializer.toJson<String>(draftId),
      'owner_id': serializer.toJson<String>(ownerId),
      'revision': serializer.toJson<int>(revision),
      'payload_version': serializer.toJson<int>(payloadVersion),
      'payload': serializer.toJson<String>(payload),
      'updated_at_us': serializer.toJson<int>(updatedAtUs),
    };
  }

  LocalDraft copyWith({
    String? organizationId,
    String? domain,
    String? draftId,
    String? ownerId,
    int? revision,
    int? payloadVersion,
    String? payload,
    int? updatedAtUs,
  }) => LocalDraft(
    organizationId: organizationId ?? this.organizationId,
    domain: domain ?? this.domain,
    draftId: draftId ?? this.draftId,
    ownerId: ownerId ?? this.ownerId,
    revision: revision ?? this.revision,
    payloadVersion: payloadVersion ?? this.payloadVersion,
    payload: payload ?? this.payload,
    updatedAtUs: updatedAtUs ?? this.updatedAtUs,
  );
  LocalDraft copyWithCompanion(LocalDraftsCompanion data) {
    return LocalDraft(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      domain: data.domain.present ? data.domain.value : this.domain,
      draftId: data.draftId.present ? data.draftId.value : this.draftId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      revision: data.revision.present ? data.revision.value : this.revision,
      payloadVersion: data.payloadVersion.present
          ? data.payloadVersion.value
          : this.payloadVersion,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAtUs: data.updatedAtUs.present
          ? data.updatedAtUs.value
          : this.updatedAtUs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDraft(')
          ..write('organizationId: $organizationId, ')
          ..write('domain: $domain, ')
          ..write('draftId: $draftId, ')
          ..write('ownerId: $ownerId, ')
          ..write('revision: $revision, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('payload: $payload, ')
          ..write('updatedAtUs: $updatedAtUs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    organizationId,
    domain,
    draftId,
    ownerId,
    revision,
    payloadVersion,
    payload,
    updatedAtUs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDraft &&
          other.organizationId == this.organizationId &&
          other.domain == this.domain &&
          other.draftId == this.draftId &&
          other.ownerId == this.ownerId &&
          other.revision == this.revision &&
          other.payloadVersion == this.payloadVersion &&
          other.payload == this.payload &&
          other.updatedAtUs == this.updatedAtUs);
}

class LocalDraftsCompanion extends UpdateCompanion<LocalDraft> {
  final Value<String> organizationId;
  final Value<String> domain;
  final Value<String> draftId;
  final Value<String> ownerId;
  final Value<int> revision;
  final Value<int> payloadVersion;
  final Value<String> payload;
  final Value<int> updatedAtUs;
  final Value<int> rowid;
  const LocalDraftsCompanion({
    this.organizationId = const Value.absent(),
    this.domain = const Value.absent(),
    this.draftId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.revision = const Value.absent(),
    this.payloadVersion = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAtUs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDraftsCompanion.insert({
    required String organizationId,
    required String domain,
    required String draftId,
    required String ownerId,
    required int revision,
    required int payloadVersion,
    required String payload,
    required int updatedAtUs,
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       domain = Value(domain),
       draftId = Value(draftId),
       ownerId = Value(ownerId),
       revision = Value(revision),
       payloadVersion = Value(payloadVersion),
       payload = Value(payload),
       updatedAtUs = Value(updatedAtUs);
  static Insertable<LocalDraft> custom({
    Expression<String>? organizationId,
    Expression<String>? domain,
    Expression<String>? draftId,
    Expression<String>? ownerId,
    Expression<int>? revision,
    Expression<int>? payloadVersion,
    Expression<String>? payload,
    Expression<int>? updatedAtUs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (domain != null) 'domain': domain,
      if (draftId != null) 'draft_id': draftId,
      if (ownerId != null) 'owner_id': ownerId,
      if (revision != null) 'revision': revision,
      if (payloadVersion != null) 'payload_version': payloadVersion,
      if (payload != null) 'payload': payload,
      if (updatedAtUs != null) 'updated_at_us': updatedAtUs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDraftsCompanion copyWith({
    Value<String>? organizationId,
    Value<String>? domain,
    Value<String>? draftId,
    Value<String>? ownerId,
    Value<int>? revision,
    Value<int>? payloadVersion,
    Value<String>? payload,
    Value<int>? updatedAtUs,
    Value<int>? rowid,
  }) {
    return LocalDraftsCompanion(
      organizationId: organizationId ?? this.organizationId,
      domain: domain ?? this.domain,
      draftId: draftId ?? this.draftId,
      ownerId: ownerId ?? this.ownerId,
      revision: revision ?? this.revision,
      payloadVersion: payloadVersion ?? this.payloadVersion,
      payload: payload ?? this.payload,
      updatedAtUs: updatedAtUs ?? this.updatedAtUs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (draftId.present) {
      map['draft_id'] = Variable<String>(draftId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (payloadVersion.present) {
      map['payload_version'] = Variable<int>(payloadVersion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAtUs.present) {
      map['updated_at_us'] = Variable<int>(updatedAtUs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDraftsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('domain: $domain, ')
          ..write('draftId: $draftId, ')
          ..write('ownerId: $ownerId, ')
          ..write('revision: $revision, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('payload: $payload, ')
          ..write('updatedAtUs: $updatedAtUs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LocalMetadata extends Table
    with TableInfo<LocalMetadata, LocalMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalMetadata(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _metadataKeyMeta = const VerificationMeta(
    'metadataKey',
  );
  late final GeneratedColumn<String> metadataKey = GeneratedColumn<String>(
    'metadata_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [metadataKey, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('metadata_key')) {
      context.handle(
        _metadataKeyMeta,
        metadataKey.isAcceptableOrUnknown(
          data['metadata_key']!,
          _metadataKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataKeyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {metadataKey};
  @override
  LocalMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMetadataData(
      metadataKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  LocalMetadata createAlias(String alias) {
    return LocalMetadata(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class LocalMetadataData extends DataClass
    implements Insertable<LocalMetadataData> {
  final String metadataKey;
  final String value;
  const LocalMetadataData({required this.metadataKey, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['metadata_key'] = Variable<String>(metadataKey);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalMetadataCompanion toCompanion(bool nullToAbsent) {
    return LocalMetadataCompanion(
      metadataKey: Value(metadataKey),
      value: Value(value),
    );
  }

  factory LocalMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMetadataData(
      metadataKey: serializer.fromJson<String>(json['metadata_key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'metadata_key': serializer.toJson<String>(metadataKey),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalMetadataData copyWith({String? metadataKey, String? value}) =>
      LocalMetadataData(
        metadataKey: metadataKey ?? this.metadataKey,
        value: value ?? this.value,
      );
  LocalMetadataData copyWithCompanion(LocalMetadataCompanion data) {
    return LocalMetadataData(
      metadataKey: data.metadataKey.present
          ? data.metadataKey.value
          : this.metadataKey,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMetadataData(')
          ..write('metadataKey: $metadataKey, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(metadataKey, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMetadataData &&
          other.metadataKey == this.metadataKey &&
          other.value == this.value);
}

class LocalMetadataCompanion extends UpdateCompanion<LocalMetadataData> {
  final Value<String> metadataKey;
  final Value<String> value;
  final Value<int> rowid;
  const LocalMetadataCompanion({
    this.metadataKey = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMetadataCompanion.insert({
    required String metadataKey,
    required String value,
    this.rowid = const Value.absent(),
  }) : metadataKey = Value(metadataKey),
       value = Value(value);
  static Insertable<LocalMetadataData> custom({
    Expression<String>? metadataKey,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (metadataKey != null) 'metadata_key': metadataKey,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMetadataCompanion copyWith({
    Value<String>? metadataKey,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalMetadataCompanion(
      metadataKey: metadataKey ?? this.metadataKey,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (metadataKey.present) {
      map['metadata_key'] = Variable<String>(metadataKey.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMetadataCompanion(')
          ..write('metadataKey: $metadataKey, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final LocalRecords localRecords = LocalRecords(this);
  late final Index localRecordsOwner = Index(
    'local_records_owner',
    'CREATE INDEX local_records_owner ON local_records (organization_id, domain, owner_id, updated_at_us)',
  );
  late final LocalCommands localCommands = LocalCommands(this);
  late final LocalRecordRevisions localRecordRevisions = LocalRecordRevisions(
    this,
  );
  late final LocalChangeOutbox localChangeOutbox = LocalChangeOutbox(this);
  late final LocalDrafts localDrafts = LocalDrafts(this);
  late final LocalMetadata localMetadata = LocalMetadata(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localRecords,
    localRecordsOwner,
    localCommands,
    localRecordRevisions,
    localChangeOutbox,
    localDrafts,
    localMetadata,
  ];
}

typedef $LocalRecordsCreateCompanionBuilder =
    LocalRecordsCompanion Function({
      required String organizationId,
      required String domain,
      required String recordId,
      required String ownerId,
      required int revision,
      required int payloadVersion,
      required String payload,
      required int updatedAtUs,
      Value<int> rowid,
    });
typedef $LocalRecordsUpdateCompanionBuilder =
    LocalRecordsCompanion Function({
      Value<String> organizationId,
      Value<String> domain,
      Value<String> recordId,
      Value<String> ownerId,
      Value<int> revision,
      Value<int> payloadVersion,
      Value<String> payload,
      Value<int> updatedAtUs,
      Value<int> rowid,
    });

class $LocalRecordsFilterComposer
    extends Composer<_$LocalDatabase, LocalRecords> {
  $LocalRecordsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUs => $composableBuilder(
    column: $table.updatedAtUs,
    builder: (column) => ColumnFilters(column),
  );
}

class $LocalRecordsOrderingComposer
    extends Composer<_$LocalDatabase, LocalRecords> {
  $LocalRecordsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUs => $composableBuilder(
    column: $table.updatedAtUs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LocalRecordsAnnotationComposer
    extends Composer<_$LocalDatabase, LocalRecords> {
  $LocalRecordsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get updatedAtUs => $composableBuilder(
    column: $table.updatedAtUs,
    builder: (column) => column,
  );
}

class $LocalRecordsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          LocalRecords,
          LocalRecord,
          $LocalRecordsFilterComposer,
          $LocalRecordsOrderingComposer,
          $LocalRecordsAnnotationComposer,
          $LocalRecordsCreateCompanionBuilder,
          $LocalRecordsUpdateCompanionBuilder,
          (
            LocalRecord,
            BaseReferences<_$LocalDatabase, LocalRecords, LocalRecord>,
          ),
          LocalRecord,
          PrefetchHooks Function()
        > {
  $LocalRecordsTableManager(_$LocalDatabase db, LocalRecords table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LocalRecordsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LocalRecordsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LocalRecordsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> payloadVersion = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> updatedAtUs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRecordsCompanion(
                organizationId: organizationId,
                domain: domain,
                recordId: recordId,
                ownerId: ownerId,
                revision: revision,
                payloadVersion: payloadVersion,
                payload: payload,
                updatedAtUs: updatedAtUs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                required String domain,
                required String recordId,
                required String ownerId,
                required int revision,
                required int payloadVersion,
                required String payload,
                required int updatedAtUs,
                Value<int> rowid = const Value.absent(),
              }) => LocalRecordsCompanion.insert(
                organizationId: organizationId,
                domain: domain,
                recordId: recordId,
                ownerId: ownerId,
                revision: revision,
                payloadVersion: payloadVersion,
                payload: payload,
                updatedAtUs: updatedAtUs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<LocalRecords, LocalRecord>(table),
                  BaseReferences<_$LocalDatabase, LocalRecords, LocalRecord>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $LocalRecordsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      LocalRecords,
      LocalRecord,
      $LocalRecordsFilterComposer,
      $LocalRecordsOrderingComposer,
      $LocalRecordsAnnotationComposer,
      $LocalRecordsCreateCompanionBuilder,
      $LocalRecordsUpdateCompanionBuilder,
      (LocalRecord, BaseReferences<_$LocalDatabase, LocalRecords, LocalRecord>),
      LocalRecord,
      PrefetchHooks Function()
    >;
typedef $LocalCommandsCreateCompanionBuilder =
    LocalCommandsCompanion Function({
      required String organizationId,
      required String commandId,
      required String requestHash,
      required int committedAtUs,
      Value<int> rowid,
    });
typedef $LocalCommandsUpdateCompanionBuilder =
    LocalCommandsCompanion Function({
      Value<String> organizationId,
      Value<String> commandId,
      Value<String> requestHash,
      Value<int> committedAtUs,
      Value<int> rowid,
    });

class $LocalCommandsFilterComposer
    extends Composer<_$LocalDatabase, LocalCommands> {
  $LocalCommandsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commandId => $composableBuilder(
    column: $table.commandId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestHash => $composableBuilder(
    column: $table.requestHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get committedAtUs => $composableBuilder(
    column: $table.committedAtUs,
    builder: (column) => ColumnFilters(column),
  );
}

class $LocalCommandsOrderingComposer
    extends Composer<_$LocalDatabase, LocalCommands> {
  $LocalCommandsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commandId => $composableBuilder(
    column: $table.commandId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestHash => $composableBuilder(
    column: $table.requestHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get committedAtUs => $composableBuilder(
    column: $table.committedAtUs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LocalCommandsAnnotationComposer
    extends Composer<_$LocalDatabase, LocalCommands> {
  $LocalCommandsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commandId =>
      $composableBuilder(column: $table.commandId, builder: (column) => column);

  GeneratedColumn<String> get requestHash => $composableBuilder(
    column: $table.requestHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get committedAtUs => $composableBuilder(
    column: $table.committedAtUs,
    builder: (column) => column,
  );
}

class $LocalCommandsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          LocalCommands,
          LocalCommand,
          $LocalCommandsFilterComposer,
          $LocalCommandsOrderingComposer,
          $LocalCommandsAnnotationComposer,
          $LocalCommandsCreateCompanionBuilder,
          $LocalCommandsUpdateCompanionBuilder,
          (
            LocalCommand,
            BaseReferences<_$LocalDatabase, LocalCommands, LocalCommand>,
          ),
          LocalCommand,
          PrefetchHooks Function()
        > {
  $LocalCommandsTableManager(_$LocalDatabase db, LocalCommands table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LocalCommandsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LocalCommandsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LocalCommandsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<String> commandId = const Value.absent(),
                Value<String> requestHash = const Value.absent(),
                Value<int> committedAtUs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCommandsCompanion(
                organizationId: organizationId,
                commandId: commandId,
                requestHash: requestHash,
                committedAtUs: committedAtUs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                required String commandId,
                required String requestHash,
                required int committedAtUs,
                Value<int> rowid = const Value.absent(),
              }) => LocalCommandsCompanion.insert(
                organizationId: organizationId,
                commandId: commandId,
                requestHash: requestHash,
                committedAtUs: committedAtUs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<LocalCommands, LocalCommand>(table),
                  BaseReferences<_$LocalDatabase, LocalCommands, LocalCommand>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $LocalCommandsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      LocalCommands,
      LocalCommand,
      $LocalCommandsFilterComposer,
      $LocalCommandsOrderingComposer,
      $LocalCommandsAnnotationComposer,
      $LocalCommandsCreateCompanionBuilder,
      $LocalCommandsUpdateCompanionBuilder,
      (
        LocalCommand,
        BaseReferences<_$LocalDatabase, LocalCommands, LocalCommand>,
      ),
      LocalCommand,
      PrefetchHooks Function()
    >;
typedef $LocalRecordRevisionsCreateCompanionBuilder =
    LocalRecordRevisionsCompanion Function({
      required String organizationId,
      required String domain,
      required String recordId,
      required int revision,
      required String commandId,
      required String ownerId,
      required int payloadVersion,
      required String payload,
      required String payloadHash,
      required int updatedAtUs,
      Value<int> rowid,
    });
typedef $LocalRecordRevisionsUpdateCompanionBuilder =
    LocalRecordRevisionsCompanion Function({
      Value<String> organizationId,
      Value<String> domain,
      Value<String> recordId,
      Value<int> revision,
      Value<String> commandId,
      Value<String> ownerId,
      Value<int> payloadVersion,
      Value<String> payload,
      Value<String> payloadHash,
      Value<int> updatedAtUs,
      Value<int> rowid,
    });

class $LocalRecordRevisionsFilterComposer
    extends Composer<_$LocalDatabase, LocalRecordRevisions> {
  $LocalRecordRevisionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commandId => $composableBuilder(
    column: $table.commandId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUs => $composableBuilder(
    column: $table.updatedAtUs,
    builder: (column) => ColumnFilters(column),
  );
}

class $LocalRecordRevisionsOrderingComposer
    extends Composer<_$LocalDatabase, LocalRecordRevisions> {
  $LocalRecordRevisionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commandId => $composableBuilder(
    column: $table.commandId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUs => $composableBuilder(
    column: $table.updatedAtUs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LocalRecordRevisionsAnnotationComposer
    extends Composer<_$LocalDatabase, LocalRecordRevisions> {
  $LocalRecordRevisionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get commandId =>
      $composableBuilder(column: $table.commandId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUs => $composableBuilder(
    column: $table.updatedAtUs,
    builder: (column) => column,
  );
}

class $LocalRecordRevisionsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          LocalRecordRevisions,
          LocalRecordRevision,
          $LocalRecordRevisionsFilterComposer,
          $LocalRecordRevisionsOrderingComposer,
          $LocalRecordRevisionsAnnotationComposer,
          $LocalRecordRevisionsCreateCompanionBuilder,
          $LocalRecordRevisionsUpdateCompanionBuilder,
          (
            LocalRecordRevision,
            BaseReferences<
              _$LocalDatabase,
              LocalRecordRevisions,
              LocalRecordRevision
            >,
          ),
          LocalRecordRevision,
          PrefetchHooks Function()
        > {
  $LocalRecordRevisionsTableManager(
    _$LocalDatabase db,
    LocalRecordRevisions table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LocalRecordRevisionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LocalRecordRevisionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LocalRecordRevisionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> commandId = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<int> payloadVersion = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> payloadHash = const Value.absent(),
                Value<int> updatedAtUs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRecordRevisionsCompanion(
                organizationId: organizationId,
                domain: domain,
                recordId: recordId,
                revision: revision,
                commandId: commandId,
                ownerId: ownerId,
                payloadVersion: payloadVersion,
                payload: payload,
                payloadHash: payloadHash,
                updatedAtUs: updatedAtUs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                required String domain,
                required String recordId,
                required int revision,
                required String commandId,
                required String ownerId,
                required int payloadVersion,
                required String payload,
                required String payloadHash,
                required int updatedAtUs,
                Value<int> rowid = const Value.absent(),
              }) => LocalRecordRevisionsCompanion.insert(
                organizationId: organizationId,
                domain: domain,
                recordId: recordId,
                revision: revision,
                commandId: commandId,
                ownerId: ownerId,
                payloadVersion: payloadVersion,
                payload: payload,
                payloadHash: payloadHash,
                updatedAtUs: updatedAtUs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<LocalRecordRevisions, LocalRecordRevision>(table),
                  BaseReferences<
                    _$LocalDatabase,
                    LocalRecordRevisions,
                    LocalRecordRevision
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $LocalRecordRevisionsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      LocalRecordRevisions,
      LocalRecordRevision,
      $LocalRecordRevisionsFilterComposer,
      $LocalRecordRevisionsOrderingComposer,
      $LocalRecordRevisionsAnnotationComposer,
      $LocalRecordRevisionsCreateCompanionBuilder,
      $LocalRecordRevisionsUpdateCompanionBuilder,
      (
        LocalRecordRevision,
        BaseReferences<
          _$LocalDatabase,
          LocalRecordRevisions,
          LocalRecordRevision
        >,
      ),
      LocalRecordRevision,
      PrefetchHooks Function()
    >;
typedef $LocalChangeOutboxCreateCompanionBuilder =
    LocalChangeOutboxCompanion Function({
      Value<int> sequence,
      required String organizationId,
      required String commandId,
      Value<String> state,
    });
typedef $LocalChangeOutboxUpdateCompanionBuilder =
    LocalChangeOutboxCompanion Function({
      Value<int> sequence,
      Value<String> organizationId,
      Value<String> commandId,
      Value<String> state,
    });

class $LocalChangeOutboxFilterComposer
    extends Composer<_$LocalDatabase, LocalChangeOutbox> {
  $LocalChangeOutboxFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commandId => $composableBuilder(
    column: $table.commandId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );
}

class $LocalChangeOutboxOrderingComposer
    extends Composer<_$LocalDatabase, LocalChangeOutbox> {
  $LocalChangeOutboxOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commandId => $composableBuilder(
    column: $table.commandId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LocalChangeOutboxAnnotationComposer
    extends Composer<_$LocalDatabase, LocalChangeOutbox> {
  $LocalChangeOutboxAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commandId =>
      $composableBuilder(column: $table.commandId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $LocalChangeOutboxTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          LocalChangeOutbox,
          LocalChangeOutboxData,
          $LocalChangeOutboxFilterComposer,
          $LocalChangeOutboxOrderingComposer,
          $LocalChangeOutboxAnnotationComposer,
          $LocalChangeOutboxCreateCompanionBuilder,
          $LocalChangeOutboxUpdateCompanionBuilder,
          (
            LocalChangeOutboxData,
            BaseReferences<
              _$LocalDatabase,
              LocalChangeOutbox,
              LocalChangeOutboxData
            >,
          ),
          LocalChangeOutboxData,
          PrefetchHooks Function()
        > {
  $LocalChangeOutboxTableManager(_$LocalDatabase db, LocalChangeOutbox table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LocalChangeOutboxFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LocalChangeOutboxOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LocalChangeOutboxAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                Value<String> organizationId = const Value.absent(),
                Value<String> commandId = const Value.absent(),
                Value<String> state = const Value.absent(),
              }) => LocalChangeOutboxCompanion(
                sequence: sequence,
                organizationId: organizationId,
                commandId: commandId,
                state: state,
              ),
          createCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                required String organizationId,
                required String commandId,
                Value<String> state = const Value.absent(),
              }) => LocalChangeOutboxCompanion.insert(
                sequence: sequence,
                organizationId: organizationId,
                commandId: commandId,
                state: state,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<LocalChangeOutbox, LocalChangeOutboxData>(table),
                  BaseReferences<
                    _$LocalDatabase,
                    LocalChangeOutbox,
                    LocalChangeOutboxData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $LocalChangeOutboxProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      LocalChangeOutbox,
      LocalChangeOutboxData,
      $LocalChangeOutboxFilterComposer,
      $LocalChangeOutboxOrderingComposer,
      $LocalChangeOutboxAnnotationComposer,
      $LocalChangeOutboxCreateCompanionBuilder,
      $LocalChangeOutboxUpdateCompanionBuilder,
      (
        LocalChangeOutboxData,
        BaseReferences<
          _$LocalDatabase,
          LocalChangeOutbox,
          LocalChangeOutboxData
        >,
      ),
      LocalChangeOutboxData,
      PrefetchHooks Function()
    >;
typedef $LocalDraftsCreateCompanionBuilder =
    LocalDraftsCompanion Function({
      required String organizationId,
      required String domain,
      required String draftId,
      required String ownerId,
      required int revision,
      required int payloadVersion,
      required String payload,
      required int updatedAtUs,
      Value<int> rowid,
    });
typedef $LocalDraftsUpdateCompanionBuilder =
    LocalDraftsCompanion Function({
      Value<String> organizationId,
      Value<String> domain,
      Value<String> draftId,
      Value<String> ownerId,
      Value<int> revision,
      Value<int> payloadVersion,
      Value<String> payload,
      Value<int> updatedAtUs,
      Value<int> rowid,
    });

class $LocalDraftsFilterComposer
    extends Composer<_$LocalDatabase, LocalDrafts> {
  $LocalDraftsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftId => $composableBuilder(
    column: $table.draftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUs => $composableBuilder(
    column: $table.updatedAtUs,
    builder: (column) => ColumnFilters(column),
  );
}

class $LocalDraftsOrderingComposer
    extends Composer<_$LocalDatabase, LocalDrafts> {
  $LocalDraftsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftId => $composableBuilder(
    column: $table.draftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUs => $composableBuilder(
    column: $table.updatedAtUs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LocalDraftsAnnotationComposer
    extends Composer<_$LocalDatabase, LocalDrafts> {
  $LocalDraftsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get draftId =>
      $composableBuilder(column: $table.draftId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get updatedAtUs => $composableBuilder(
    column: $table.updatedAtUs,
    builder: (column) => column,
  );
}

class $LocalDraftsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          LocalDrafts,
          LocalDraft,
          $LocalDraftsFilterComposer,
          $LocalDraftsOrderingComposer,
          $LocalDraftsAnnotationComposer,
          $LocalDraftsCreateCompanionBuilder,
          $LocalDraftsUpdateCompanionBuilder,
          (
            LocalDraft,
            BaseReferences<_$LocalDatabase, LocalDrafts, LocalDraft>,
          ),
          LocalDraft,
          PrefetchHooks Function()
        > {
  $LocalDraftsTableManager(_$LocalDatabase db, LocalDrafts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LocalDraftsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LocalDraftsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LocalDraftsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<String> draftId = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> payloadVersion = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> updatedAtUs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDraftsCompanion(
                organizationId: organizationId,
                domain: domain,
                draftId: draftId,
                ownerId: ownerId,
                revision: revision,
                payloadVersion: payloadVersion,
                payload: payload,
                updatedAtUs: updatedAtUs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                required String domain,
                required String draftId,
                required String ownerId,
                required int revision,
                required int payloadVersion,
                required String payload,
                required int updatedAtUs,
                Value<int> rowid = const Value.absent(),
              }) => LocalDraftsCompanion.insert(
                organizationId: organizationId,
                domain: domain,
                draftId: draftId,
                ownerId: ownerId,
                revision: revision,
                payloadVersion: payloadVersion,
                payload: payload,
                updatedAtUs: updatedAtUs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<LocalDrafts, LocalDraft>(table),
                  BaseReferences<_$LocalDatabase, LocalDrafts, LocalDraft>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $LocalDraftsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      LocalDrafts,
      LocalDraft,
      $LocalDraftsFilterComposer,
      $LocalDraftsOrderingComposer,
      $LocalDraftsAnnotationComposer,
      $LocalDraftsCreateCompanionBuilder,
      $LocalDraftsUpdateCompanionBuilder,
      (LocalDraft, BaseReferences<_$LocalDatabase, LocalDrafts, LocalDraft>),
      LocalDraft,
      PrefetchHooks Function()
    >;
typedef $LocalMetadataCreateCompanionBuilder =
    LocalMetadataCompanion Function({
      required String metadataKey,
      required String value,
      Value<int> rowid,
    });
typedef $LocalMetadataUpdateCompanionBuilder =
    LocalMetadataCompanion Function({
      Value<String> metadataKey,
      Value<String> value,
      Value<int> rowid,
    });

class $LocalMetadataFilterComposer
    extends Composer<_$LocalDatabase, LocalMetadata> {
  $LocalMetadataFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get metadataKey => $composableBuilder(
    column: $table.metadataKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $LocalMetadataOrderingComposer
    extends Composer<_$LocalDatabase, LocalMetadata> {
  $LocalMetadataOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get metadataKey => $composableBuilder(
    column: $table.metadataKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LocalMetadataAnnotationComposer
    extends Composer<_$LocalDatabase, LocalMetadata> {
  $LocalMetadataAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get metadataKey => $composableBuilder(
    column: $table.metadataKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $LocalMetadataTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          LocalMetadata,
          LocalMetadataData,
          $LocalMetadataFilterComposer,
          $LocalMetadataOrderingComposer,
          $LocalMetadataAnnotationComposer,
          $LocalMetadataCreateCompanionBuilder,
          $LocalMetadataUpdateCompanionBuilder,
          (
            LocalMetadataData,
            BaseReferences<_$LocalDatabase, LocalMetadata, LocalMetadataData>,
          ),
          LocalMetadataData,
          PrefetchHooks Function()
        > {
  $LocalMetadataTableManager(_$LocalDatabase db, LocalMetadata table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LocalMetadataFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LocalMetadataOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LocalMetadataAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> metadataKey = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMetadataCompanion(
                metadataKey: metadataKey,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String metadataKey,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => LocalMetadataCompanion.insert(
                metadataKey: metadataKey,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<LocalMetadata, LocalMetadataData>(table),
                  BaseReferences<
                    _$LocalDatabase,
                    LocalMetadata,
                    LocalMetadataData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $LocalMetadataProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      LocalMetadata,
      LocalMetadataData,
      $LocalMetadataFilterComposer,
      $LocalMetadataOrderingComposer,
      $LocalMetadataAnnotationComposer,
      $LocalMetadataCreateCompanionBuilder,
      $LocalMetadataUpdateCompanionBuilder,
      (
        LocalMetadataData,
        BaseReferences<_$LocalDatabase, LocalMetadata, LocalMetadataData>,
      ),
      LocalMetadataData,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $LocalRecordsTableManager get localRecords =>
      $LocalRecordsTableManager(_db, _db.localRecords);
  $LocalCommandsTableManager get localCommands =>
      $LocalCommandsTableManager(_db, _db.localCommands);
  $LocalRecordRevisionsTableManager get localRecordRevisions =>
      $LocalRecordRevisionsTableManager(_db, _db.localRecordRevisions);
  $LocalChangeOutboxTableManager get localChangeOutbox =>
      $LocalChangeOutboxTableManager(_db, _db.localChangeOutbox);
  $LocalDraftsTableManager get localDrafts =>
      $LocalDraftsTableManager(_db, _db.localDrafts);
  $LocalMetadataTableManager get localMetadata =>
      $LocalMetadataTableManager(_db, _db.localMetadata);
}
