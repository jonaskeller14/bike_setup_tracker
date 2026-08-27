// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ComponentsTable extends Components
    with TableInfo<$ComponentsTable, ComponentDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComponentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> lastModified =
      GeneratedColumn<DateTime>(
        'last_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ComponentsTable.$converterlastModified);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ComponentType, String>
  componentType = GeneratedColumn<String>(
    'component_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ComponentType>($ComponentsTable.$convertercomponentType);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _initialDistanceMeta = const VerificationMeta(
    'initialDistance',
  );
  @override
  late final GeneratedColumn<double> initialDistance = GeneratedColumn<double>(
    'initial_distance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _initialElevationGainMeta =
      const VerificationMeta('initialElevationGain');
  @override
  late final GeneratedColumn<double> initialElevationGain =
      GeneratedColumn<double>(
        'initial_elevation_gain',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> initialMovingTime =
      GeneratedColumn<int>(
        'initial_moving_time',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<Duration>($ComponentsTable.$converterinitialMovingTime);
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int>
  initialElapsedTime = GeneratedColumn<int>(
    'initial_elapsed_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  ).withConverter<Duration>($ComponentsTable.$converterinitialElapsedTime);
  static const VerificationMeta _initialActivityCountMeta =
      const VerificationMeta('initialActivityCount');
  @override
  late final GeneratedColumn<int> initialActivityCount = GeneratedColumn<int>(
    'initial_activity_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isDeleted,
    lastModified,
    name,
    componentType,
    notes,
    orderIndex,
    initialDistance,
    initialElevationGain,
    initialMovingTime,
    initialElapsedTime,
    initialActivityCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'components';
  @override
  VerificationContext validateIntegrity(
    Insertable<ComponentDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('initial_distance')) {
      context.handle(
        _initialDistanceMeta,
        initialDistance.isAcceptableOrUnknown(
          data['initial_distance']!,
          _initialDistanceMeta,
        ),
      );
    }
    if (data.containsKey('initial_elevation_gain')) {
      context.handle(
        _initialElevationGainMeta,
        initialElevationGain.isAcceptableOrUnknown(
          data['initial_elevation_gain']!,
          _initialElevationGainMeta,
        ),
      );
    }
    if (data.containsKey('initial_activity_count')) {
      context.handle(
        _initialActivityCountMeta,
        initialActivityCount.isAcceptableOrUnknown(
          data['initial_activity_count']!,
          _initialActivityCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ComponentDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ComponentDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastModified: $ComponentsTable.$converterlastModified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_modified'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      componentType: $ComponentsTable.$convertercomponentType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}component_type'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      initialDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_distance'],
      )!,
      initialElevationGain: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_elevation_gain'],
      )!,
      initialMovingTime: $ComponentsTable.$converterinitialMovingTime.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}initial_moving_time'],
        )!,
      ),
      initialElapsedTime: $ComponentsTable.$converterinitialElapsedTime.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}initial_elapsed_time'],
        )!,
      ),
      initialActivityCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_activity_count'],
      )!,
    );
  }

  @override
  $ComponentsTable createAlias(String alias) {
    return $ComponentsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterlastModified =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<ComponentType, String, String>
  $convertercomponentType = const EnumNameConverter(ComponentType.values);
  static TypeConverter<Duration, int> $converterinitialMovingTime =
      const DurationConverter();
  static TypeConverter<Duration, int> $converterinitialElapsedTime =
      const DurationConverter();
}

class ComponentDb extends DataClass implements Insertable<ComponentDb> {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final ComponentType componentType;
  final String? notes;
  final int orderIndex;
  final double initialDistance;
  final double initialElevationGain;
  final Duration initialMovingTime;
  final Duration initialElapsedTime;
  final int initialActivityCount;
  const ComponentDb({
    required this.id,
    required this.isDeleted,
    required this.lastModified,
    required this.name,
    required this.componentType,
    this.notes,
    required this.orderIndex,
    required this.initialDistance,
    required this.initialElevationGain,
    required this.initialMovingTime,
    required this.initialElapsedTime,
    required this.initialActivityCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_deleted'] = Variable<bool>(isDeleted);
    {
      map['last_modified'] = Variable<DateTime>(
        $ComponentsTable.$converterlastModified.toSql(lastModified),
      );
    }
    map['name'] = Variable<String>(name);
    {
      map['component_type'] = Variable<String>(
        $ComponentsTable.$convertercomponentType.toSql(componentType),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['order_index'] = Variable<int>(orderIndex);
    map['initial_distance'] = Variable<double>(initialDistance);
    map['initial_elevation_gain'] = Variable<double>(initialElevationGain);
    {
      map['initial_moving_time'] = Variable<int>(
        $ComponentsTable.$converterinitialMovingTime.toSql(initialMovingTime),
      );
    }
    {
      map['initial_elapsed_time'] = Variable<int>(
        $ComponentsTable.$converterinitialElapsedTime.toSql(initialElapsedTime),
      );
    }
    map['initial_activity_count'] = Variable<int>(initialActivityCount);
    return map;
  }

  ComponentsCompanion toCompanion(bool nullToAbsent) {
    return ComponentsCompanion(
      id: Value(id),
      isDeleted: Value(isDeleted),
      lastModified: Value(lastModified),
      name: Value(name),
      componentType: Value(componentType),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      orderIndex: Value(orderIndex),
      initialDistance: Value(initialDistance),
      initialElevationGain: Value(initialElevationGain),
      initialMovingTime: Value(initialMovingTime),
      initialElapsedTime: Value(initialElapsedTime),
      initialActivityCount: Value(initialActivityCount),
    );
  }

  factory ComponentDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ComponentDb(
      id: serializer.fromJson<String>(json['id']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      name: serializer.fromJson<String>(json['name']),
      componentType: $ComponentsTable.$convertercomponentType.fromJson(
        serializer.fromJson<String>(json['componentType']),
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      initialDistance: serializer.fromJson<double>(json['initialDistance']),
      initialElevationGain: serializer.fromJson<double>(
        json['initialElevationGain'],
      ),
      initialMovingTime: serializer.fromJson<Duration>(
        json['initialMovingTime'],
      ),
      initialElapsedTime: serializer.fromJson<Duration>(
        json['initialElapsedTime'],
      ),
      initialActivityCount: serializer.fromJson<int>(
        json['initialActivityCount'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'name': serializer.toJson<String>(name),
      'componentType': serializer.toJson<String>(
        $ComponentsTable.$convertercomponentType.toJson(componentType),
      ),
      'notes': serializer.toJson<String?>(notes),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'initialDistance': serializer.toJson<double>(initialDistance),
      'initialElevationGain': serializer.toJson<double>(initialElevationGain),
      'initialMovingTime': serializer.toJson<Duration>(initialMovingTime),
      'initialElapsedTime': serializer.toJson<Duration>(initialElapsedTime),
      'initialActivityCount': serializer.toJson<int>(initialActivityCount),
    };
  }

  ComponentDb copyWith({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    String? name,
    ComponentType? componentType,
    Value<String?> notes = const Value.absent(),
    int? orderIndex,
    double? initialDistance,
    double? initialElevationGain,
    Duration? initialMovingTime,
    Duration? initialElapsedTime,
    int? initialActivityCount,
  }) => ComponentDb(
    id: id ?? this.id,
    isDeleted: isDeleted ?? this.isDeleted,
    lastModified: lastModified ?? this.lastModified,
    name: name ?? this.name,
    componentType: componentType ?? this.componentType,
    notes: notes.present ? notes.value : this.notes,
    orderIndex: orderIndex ?? this.orderIndex,
    initialDistance: initialDistance ?? this.initialDistance,
    initialElevationGain: initialElevationGain ?? this.initialElevationGain,
    initialMovingTime: initialMovingTime ?? this.initialMovingTime,
    initialElapsedTime: initialElapsedTime ?? this.initialElapsedTime,
    initialActivityCount: initialActivityCount ?? this.initialActivityCount,
  );
  ComponentDb copyWithCompanion(ComponentsCompanion data) {
    return ComponentDb(
      id: data.id.present ? data.id.value : this.id,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      name: data.name.present ? data.name.value : this.name,
      componentType: data.componentType.present
          ? data.componentType.value
          : this.componentType,
      notes: data.notes.present ? data.notes.value : this.notes,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      initialDistance: data.initialDistance.present
          ? data.initialDistance.value
          : this.initialDistance,
      initialElevationGain: data.initialElevationGain.present
          ? data.initialElevationGain.value
          : this.initialElevationGain,
      initialMovingTime: data.initialMovingTime.present
          ? data.initialMovingTime.value
          : this.initialMovingTime,
      initialElapsedTime: data.initialElapsedTime.present
          ? data.initialElapsedTime.value
          : this.initialElapsedTime,
      initialActivityCount: data.initialActivityCount.present
          ? data.initialActivityCount.value
          : this.initialActivityCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ComponentDb(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('componentType: $componentType, ')
          ..write('notes: $notes, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('initialDistance: $initialDistance, ')
          ..write('initialElevationGain: $initialElevationGain, ')
          ..write('initialMovingTime: $initialMovingTime, ')
          ..write('initialElapsedTime: $initialElapsedTime, ')
          ..write('initialActivityCount: $initialActivityCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isDeleted,
    lastModified,
    name,
    componentType,
    notes,
    orderIndex,
    initialDistance,
    initialElevationGain,
    initialMovingTime,
    initialElapsedTime,
    initialActivityCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ComponentDb &&
          other.id == this.id &&
          other.isDeleted == this.isDeleted &&
          other.lastModified == this.lastModified &&
          other.name == this.name &&
          other.componentType == this.componentType &&
          other.notes == this.notes &&
          other.orderIndex == this.orderIndex &&
          other.initialDistance == this.initialDistance &&
          other.initialElevationGain == this.initialElevationGain &&
          other.initialMovingTime == this.initialMovingTime &&
          other.initialElapsedTime == this.initialElapsedTime &&
          other.initialActivityCount == this.initialActivityCount);
}

class ComponentsCompanion extends UpdateCompanion<ComponentDb> {
  final Value<String> id;
  final Value<bool> isDeleted;
  final Value<DateTime> lastModified;
  final Value<String> name;
  final Value<ComponentType> componentType;
  final Value<String?> notes;
  final Value<int> orderIndex;
  final Value<double> initialDistance;
  final Value<double> initialElevationGain;
  final Value<Duration> initialMovingTime;
  final Value<Duration> initialElapsedTime;
  final Value<int> initialActivityCount;
  final Value<int> rowid;
  const ComponentsCompanion({
    this.id = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.name = const Value.absent(),
    this.componentType = const Value.absent(),
    this.notes = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.initialDistance = const Value.absent(),
    this.initialElevationGain = const Value.absent(),
    this.initialMovingTime = const Value.absent(),
    this.initialElapsedTime = const Value.absent(),
    this.initialActivityCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComponentsCompanion.insert({
    required String id,
    this.isDeleted = const Value.absent(),
    required DateTime lastModified,
    required String name,
    required ComponentType componentType,
    this.notes = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.initialDistance = const Value.absent(),
    this.initialElevationGain = const Value.absent(),
    this.initialMovingTime = const Value.absent(),
    this.initialElapsedTime = const Value.absent(),
    this.initialActivityCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lastModified = Value(lastModified),
       name = Value(name),
       componentType = Value(componentType);
  static Insertable<ComponentDb> custom({
    Expression<String>? id,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastModified,
    Expression<String>? name,
    Expression<String>? componentType,
    Expression<String>? notes,
    Expression<int>? orderIndex,
    Expression<double>? initialDistance,
    Expression<double>? initialElevationGain,
    Expression<int>? initialMovingTime,
    Expression<int>? initialElapsedTime,
    Expression<int>? initialActivityCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastModified != null) 'last_modified': lastModified,
      if (name != null) 'name': name,
      if (componentType != null) 'component_type': componentType,
      if (notes != null) 'notes': notes,
      if (orderIndex != null) 'order_index': orderIndex,
      if (initialDistance != null) 'initial_distance': initialDistance,
      if (initialElevationGain != null)
        'initial_elevation_gain': initialElevationGain,
      if (initialMovingTime != null) 'initial_moving_time': initialMovingTime,
      if (initialElapsedTime != null)
        'initial_elapsed_time': initialElapsedTime,
      if (initialActivityCount != null)
        'initial_activity_count': initialActivityCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComponentsCompanion copyWith({
    Value<String>? id,
    Value<bool>? isDeleted,
    Value<DateTime>? lastModified,
    Value<String>? name,
    Value<ComponentType>? componentType,
    Value<String?>? notes,
    Value<int>? orderIndex,
    Value<double>? initialDistance,
    Value<double>? initialElevationGain,
    Value<Duration>? initialMovingTime,
    Value<Duration>? initialElapsedTime,
    Value<int>? initialActivityCount,
    Value<int>? rowid,
  }) {
    return ComponentsCompanion(
      id: id ?? this.id,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
      name: name ?? this.name,
      componentType: componentType ?? this.componentType,
      notes: notes ?? this.notes,
      orderIndex: orderIndex ?? this.orderIndex,
      initialDistance: initialDistance ?? this.initialDistance,
      initialElevationGain: initialElevationGain ?? this.initialElevationGain,
      initialMovingTime: initialMovingTime ?? this.initialMovingTime,
      initialElapsedTime: initialElapsedTime ?? this.initialElapsedTime,
      initialActivityCount: initialActivityCount ?? this.initialActivityCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(
        $ComponentsTable.$converterlastModified.toSql(lastModified.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (componentType.present) {
      map['component_type'] = Variable<String>(
        $ComponentsTable.$convertercomponentType.toSql(componentType.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (initialDistance.present) {
      map['initial_distance'] = Variable<double>(initialDistance.value);
    }
    if (initialElevationGain.present) {
      map['initial_elevation_gain'] = Variable<double>(
        initialElevationGain.value,
      );
    }
    if (initialMovingTime.present) {
      map['initial_moving_time'] = Variable<int>(
        $ComponentsTable.$converterinitialMovingTime.toSql(
          initialMovingTime.value,
        ),
      );
    }
    if (initialElapsedTime.present) {
      map['initial_elapsed_time'] = Variable<int>(
        $ComponentsTable.$converterinitialElapsedTime.toSql(
          initialElapsedTime.value,
        ),
      );
    }
    if (initialActivityCount.present) {
      map['initial_activity_count'] = Variable<int>(initialActivityCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComponentsCompanion(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('componentType: $componentType, ')
          ..write('notes: $notes, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('initialDistance: $initialDistance, ')
          ..write('initialElevationGain: $initialElevationGain, ')
          ..write('initialMovingTime: $initialMovingTime, ')
          ..write('initialElapsedTime: $initialElapsedTime, ')
          ..write('initialActivityCount: $initialActivityCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BikesTable extends Bikes with TableInfo<$BikesTable, BikeDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BikesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> lastModified =
      GeneratedColumn<DateTime>(
        'last_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BikesTable.$converterlastModified);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personMeta = const VerificationMeta('person');
  @override
  late final GeneratedColumn<String> person = GeneratedColumn<String>(
    'person',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stravaGearMeta = const VerificationMeta(
    'stravaGear',
  );
  @override
  late final GeneratedColumn<String> stravaGear = GeneratedColumn<String>(
    'strava_gear',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isDeleted,
    lastModified,
    name,
    notes,
    person,
    stravaGear,
    orderIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bikes';
  @override
  VerificationContext validateIntegrity(
    Insertable<BikeDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('person')) {
      context.handle(
        _personMeta,
        person.isAcceptableOrUnknown(data['person']!, _personMeta),
      );
    }
    if (data.containsKey('strava_gear')) {
      context.handle(
        _stravaGearMeta,
        stravaGear.isAcceptableOrUnknown(data['strava_gear']!, _stravaGearMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BikeDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BikeDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastModified: $BikesTable.$converterlastModified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_modified'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      person: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person'],
      ),
      stravaGear: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strava_gear'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $BikesTable createAlias(String alias) {
    return $BikesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterlastModified =
      const UtcDateTimeConverter();
}

class BikeDb extends DataClass implements Insertable<BikeDb> {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final String? person;
  final String? stravaGear;
  final int orderIndex;
  const BikeDb({
    required this.id,
    required this.isDeleted,
    required this.lastModified,
    required this.name,
    this.notes,
    this.person,
    this.stravaGear,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_deleted'] = Variable<bool>(isDeleted);
    {
      map['last_modified'] = Variable<DateTime>(
        $BikesTable.$converterlastModified.toSql(lastModified),
      );
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || person != null) {
      map['person'] = Variable<String>(person);
    }
    if (!nullToAbsent || stravaGear != null) {
      map['strava_gear'] = Variable<String>(stravaGear);
    }
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  BikesCompanion toCompanion(bool nullToAbsent) {
    return BikesCompanion(
      id: Value(id),
      isDeleted: Value(isDeleted),
      lastModified: Value(lastModified),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      person: person == null && nullToAbsent
          ? const Value.absent()
          : Value(person),
      stravaGear: stravaGear == null && nullToAbsent
          ? const Value.absent()
          : Value(stravaGear),
      orderIndex: Value(orderIndex),
    );
  }

  factory BikeDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BikeDb(
      id: serializer.fromJson<String>(json['id']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      person: serializer.fromJson<String?>(json['person']),
      stravaGear: serializer.fromJson<String?>(json['stravaGear']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'person': serializer.toJson<String?>(person),
      'stravaGear': serializer.toJson<String?>(stravaGear),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  BikeDb copyWith({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    String? name,
    Value<String?> notes = const Value.absent(),
    Value<String?> person = const Value.absent(),
    Value<String?> stravaGear = const Value.absent(),
    int? orderIndex,
  }) => BikeDb(
    id: id ?? this.id,
    isDeleted: isDeleted ?? this.isDeleted,
    lastModified: lastModified ?? this.lastModified,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    person: person.present ? person.value : this.person,
    stravaGear: stravaGear.present ? stravaGear.value : this.stravaGear,
    orderIndex: orderIndex ?? this.orderIndex,
  );
  BikeDb copyWithCompanion(BikesCompanion data) {
    return BikeDb(
      id: data.id.present ? data.id.value : this.id,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      person: data.person.present ? data.person.value : this.person,
      stravaGear: data.stravaGear.present
          ? data.stravaGear.value
          : this.stravaGear,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BikeDb(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('person: $person, ')
          ..write('stravaGear: $stravaGear, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isDeleted,
    lastModified,
    name,
    notes,
    person,
    stravaGear,
    orderIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BikeDb &&
          other.id == this.id &&
          other.isDeleted == this.isDeleted &&
          other.lastModified == this.lastModified &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.person == this.person &&
          other.stravaGear == this.stravaGear &&
          other.orderIndex == this.orderIndex);
}

class BikesCompanion extends UpdateCompanion<BikeDb> {
  final Value<String> id;
  final Value<bool> isDeleted;
  final Value<DateTime> lastModified;
  final Value<String> name;
  final Value<String?> notes;
  final Value<String?> person;
  final Value<String?> stravaGear;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const BikesCompanion({
    this.id = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.person = const Value.absent(),
    this.stravaGear = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BikesCompanion.insert({
    required String id,
    this.isDeleted = const Value.absent(),
    required DateTime lastModified,
    required String name,
    this.notes = const Value.absent(),
    this.person = const Value.absent(),
    this.stravaGear = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lastModified = Value(lastModified),
       name = Value(name);
  static Insertable<BikeDb> custom({
    Expression<String>? id,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastModified,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<String>? person,
    Expression<String>? stravaGear,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastModified != null) 'last_modified': lastModified,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (person != null) 'person': person,
      if (stravaGear != null) 'strava_gear': stravaGear,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BikesCompanion copyWith({
    Value<String>? id,
    Value<bool>? isDeleted,
    Value<DateTime>? lastModified,
    Value<String>? name,
    Value<String?>? notes,
    Value<String?>? person,
    Value<String?>? stravaGear,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return BikesCompanion(
      id: id ?? this.id,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      person: person ?? this.person,
      stravaGear: stravaGear ?? this.stravaGear,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(
        $BikesTable.$converterlastModified.toSql(lastModified.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (person.present) {
      map['person'] = Variable<String>(person.value);
    }
    if (stravaGear.present) {
      map['strava_gear'] = Variable<String>(stravaGear.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BikesCompanion(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('person: $person, ')
          ..write('stravaGear: $stravaGear, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskRulesTable extends TaskRules
    with TableInfo<$TaskRulesTable, TaskRuleDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> lastModified =
      GeneratedColumn<DateTime>(
        'last_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($TaskRulesTable.$converterlastModified);
  static const VerificationMeta _componentIdMeta = const VerificationMeta(
    'componentId',
  );
  @override
  late final GeneratedColumn<String> componentId = GeneratedColumn<String>(
    'component_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES components (id)',
    ),
  );
  static const VerificationMeta _bikeIdMeta = const VerificationMeta('bikeId');
  @override
  late final GeneratedColumn<String> bikeId = GeneratedColumn<String>(
    'bike_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bikes (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskPriority, String> priority =
      GeneratedColumn<String>(
        'priority',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('medium'),
      ).withConverter<TaskPriority>($TaskRulesTable.$converterpriority);
  @override
  late final GeneratedColumnWithTypeConverter<Set<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<Set<String>>($TaskRulesTable.$convertertags);
  static const VerificationMeta _intervalMeta = const VerificationMeta(
    'interval',
  );
  @override
  late final GeneratedColumn<String> interval = GeneratedColumn<String>(
    'interval',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _delayMeta = const VerificationMeta('delay');
  @override
  late final GeneratedColumn<String> delay = GeneratedColumn<String>(
    'delay',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatMeta = const VerificationMeta('repeat');
  @override
  late final GeneratedColumn<bool> repeat = GeneratedColumn<bool>(
    'repeat',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("repeat" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isDeleted,
    lastModified,
    componentId,
    bikeId,
    name,
    notes,
    priority,
    tags,
    interval,
    delay,
    repeat,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRuleDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('component_id')) {
      context.handle(
        _componentIdMeta,
        componentId.isAcceptableOrUnknown(
          data['component_id']!,
          _componentIdMeta,
        ),
      );
    }
    if (data.containsKey('bike_id')) {
      context.handle(
        _bikeIdMeta,
        bikeId.isAcceptableOrUnknown(data['bike_id']!, _bikeIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('interval')) {
      context.handle(
        _intervalMeta,
        interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta),
      );
    }
    if (data.containsKey('delay')) {
      context.handle(
        _delayMeta,
        delay.isAcceptableOrUnknown(data['delay']!, _delayMeta),
      );
    }
    if (data.containsKey('repeat')) {
      context.handle(
        _repeatMeta,
        repeat.isAcceptableOrUnknown(data['repeat']!, _repeatMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRuleDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRuleDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastModified: $TaskRulesTable.$converterlastModified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_modified'],
        )!,
      ),
      componentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_id'],
      ),
      bikeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bike_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      priority: $TaskRulesTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}priority'],
        )!,
      ),
      tags: $TaskRulesTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      interval: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interval'],
      ),
      delay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delay'],
      ),
      repeat: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}repeat'],
      )!,
    );
  }

  @override
  $TaskRulesTable createAlias(String alias) {
    return $TaskRulesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterlastModified =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<TaskPriority, String, String> $converterpriority =
      const EnumNameConverter<TaskPriority>(TaskPriority.values);
  static TypeConverter<Set<String>, String> $convertertags =
      const StringListConverter();
}

class TaskRuleDb extends DataClass implements Insertable<TaskRuleDb> {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String? componentId;
  final String? bikeId;
  final String name;
  final String? notes;
  final TaskPriority priority;
  final Set<String> tags;
  final String? interval;
  final String? delay;
  final bool repeat;
  const TaskRuleDb({
    required this.id,
    required this.isDeleted,
    required this.lastModified,
    this.componentId,
    this.bikeId,
    required this.name,
    this.notes,
    required this.priority,
    required this.tags,
    this.interval,
    this.delay,
    required this.repeat,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_deleted'] = Variable<bool>(isDeleted);
    {
      map['last_modified'] = Variable<DateTime>(
        $TaskRulesTable.$converterlastModified.toSql(lastModified),
      );
    }
    if (!nullToAbsent || componentId != null) {
      map['component_id'] = Variable<String>(componentId);
    }
    if (!nullToAbsent || bikeId != null) {
      map['bike_id'] = Variable<String>(bikeId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['priority'] = Variable<String>(
        $TaskRulesTable.$converterpriority.toSql(priority),
      );
    }
    {
      map['tags'] = Variable<String>(
        $TaskRulesTable.$convertertags.toSql(tags),
      );
    }
    if (!nullToAbsent || interval != null) {
      map['interval'] = Variable<String>(interval);
    }
    if (!nullToAbsent || delay != null) {
      map['delay'] = Variable<String>(delay);
    }
    map['repeat'] = Variable<bool>(repeat);
    return map;
  }

  TaskRulesCompanion toCompanion(bool nullToAbsent) {
    return TaskRulesCompanion(
      id: Value(id),
      isDeleted: Value(isDeleted),
      lastModified: Value(lastModified),
      componentId: componentId == null && nullToAbsent
          ? const Value.absent()
          : Value(componentId),
      bikeId: bikeId == null && nullToAbsent
          ? const Value.absent()
          : Value(bikeId),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      priority: Value(priority),
      tags: Value(tags),
      interval: interval == null && nullToAbsent
          ? const Value.absent()
          : Value(interval),
      delay: delay == null && nullToAbsent
          ? const Value.absent()
          : Value(delay),
      repeat: Value(repeat),
    );
  }

  factory TaskRuleDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRuleDb(
      id: serializer.fromJson<String>(json['id']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      componentId: serializer.fromJson<String?>(json['componentId']),
      bikeId: serializer.fromJson<String?>(json['bikeId']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      priority: $TaskRulesTable.$converterpriority.fromJson(
        serializer.fromJson<String>(json['priority']),
      ),
      tags: serializer.fromJson<Set<String>>(json['tags']),
      interval: serializer.fromJson<String?>(json['interval']),
      delay: serializer.fromJson<String?>(json['delay']),
      repeat: serializer.fromJson<bool>(json['repeat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'componentId': serializer.toJson<String?>(componentId),
      'bikeId': serializer.toJson<String?>(bikeId),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'priority': serializer.toJson<String>(
        $TaskRulesTable.$converterpriority.toJson(priority),
      ),
      'tags': serializer.toJson<Set<String>>(tags),
      'interval': serializer.toJson<String?>(interval),
      'delay': serializer.toJson<String?>(delay),
      'repeat': serializer.toJson<bool>(repeat),
    };
  }

  TaskRuleDb copyWith({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    Value<String?> componentId = const Value.absent(),
    Value<String?> bikeId = const Value.absent(),
    String? name,
    Value<String?> notes = const Value.absent(),
    TaskPriority? priority,
    Set<String>? tags,
    Value<String?> interval = const Value.absent(),
    Value<String?> delay = const Value.absent(),
    bool? repeat,
  }) => TaskRuleDb(
    id: id ?? this.id,
    isDeleted: isDeleted ?? this.isDeleted,
    lastModified: lastModified ?? this.lastModified,
    componentId: componentId.present ? componentId.value : this.componentId,
    bikeId: bikeId.present ? bikeId.value : this.bikeId,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    priority: priority ?? this.priority,
    tags: tags ?? this.tags,
    interval: interval.present ? interval.value : this.interval,
    delay: delay.present ? delay.value : this.delay,
    repeat: repeat ?? this.repeat,
  );
  TaskRuleDb copyWithCompanion(TaskRulesCompanion data) {
    return TaskRuleDb(
      id: data.id.present ? data.id.value : this.id,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      componentId: data.componentId.present
          ? data.componentId.value
          : this.componentId,
      bikeId: data.bikeId.present ? data.bikeId.value : this.bikeId,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      priority: data.priority.present ? data.priority.value : this.priority,
      tags: data.tags.present ? data.tags.value : this.tags,
      interval: data.interval.present ? data.interval.value : this.interval,
      delay: data.delay.present ? data.delay.value : this.delay,
      repeat: data.repeat.present ? data.repeat.value : this.repeat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRuleDb(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('componentId: $componentId, ')
          ..write('bikeId: $bikeId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('priority: $priority, ')
          ..write('tags: $tags, ')
          ..write('interval: $interval, ')
          ..write('delay: $delay, ')
          ..write('repeat: $repeat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isDeleted,
    lastModified,
    componentId,
    bikeId,
    name,
    notes,
    priority,
    tags,
    interval,
    delay,
    repeat,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRuleDb &&
          other.id == this.id &&
          other.isDeleted == this.isDeleted &&
          other.lastModified == this.lastModified &&
          other.componentId == this.componentId &&
          other.bikeId == this.bikeId &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.priority == this.priority &&
          other.tags == this.tags &&
          other.interval == this.interval &&
          other.delay == this.delay &&
          other.repeat == this.repeat);
}

class TaskRulesCompanion extends UpdateCompanion<TaskRuleDb> {
  final Value<String> id;
  final Value<bool> isDeleted;
  final Value<DateTime> lastModified;
  final Value<String?> componentId;
  final Value<String?> bikeId;
  final Value<String> name;
  final Value<String?> notes;
  final Value<TaskPriority> priority;
  final Value<Set<String>> tags;
  final Value<String?> interval;
  final Value<String?> delay;
  final Value<bool> repeat;
  final Value<int> rowid;
  const TaskRulesCompanion({
    this.id = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.componentId = const Value.absent(),
    this.bikeId = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.priority = const Value.absent(),
    this.tags = const Value.absent(),
    this.interval = const Value.absent(),
    this.delay = const Value.absent(),
    this.repeat = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskRulesCompanion.insert({
    required String id,
    this.isDeleted = const Value.absent(),
    required DateTime lastModified,
    this.componentId = const Value.absent(),
    this.bikeId = const Value.absent(),
    required String name,
    this.notes = const Value.absent(),
    this.priority = const Value.absent(),
    this.tags = const Value.absent(),
    this.interval = const Value.absent(),
    this.delay = const Value.absent(),
    this.repeat = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lastModified = Value(lastModified),
       name = Value(name);
  static Insertable<TaskRuleDb> custom({
    Expression<String>? id,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastModified,
    Expression<String>? componentId,
    Expression<String>? bikeId,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<String>? priority,
    Expression<String>? tags,
    Expression<String>? interval,
    Expression<String>? delay,
    Expression<bool>? repeat,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastModified != null) 'last_modified': lastModified,
      if (componentId != null) 'component_id': componentId,
      if (bikeId != null) 'bike_id': bikeId,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (priority != null) 'priority': priority,
      if (tags != null) 'tags': tags,
      if (interval != null) 'interval': interval,
      if (delay != null) 'delay': delay,
      if (repeat != null) 'repeat': repeat,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskRulesCompanion copyWith({
    Value<String>? id,
    Value<bool>? isDeleted,
    Value<DateTime>? lastModified,
    Value<String?>? componentId,
    Value<String?>? bikeId,
    Value<String>? name,
    Value<String?>? notes,
    Value<TaskPriority>? priority,
    Value<Set<String>>? tags,
    Value<String?>? interval,
    Value<String?>? delay,
    Value<bool>? repeat,
    Value<int>? rowid,
  }) {
    return TaskRulesCompanion(
      id: id ?? this.id,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
      componentId: componentId ?? this.componentId,
      bikeId: bikeId ?? this.bikeId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      interval: interval ?? this.interval,
      delay: delay ?? this.delay,
      repeat: repeat ?? this.repeat,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(
        $TaskRulesTable.$converterlastModified.toSql(lastModified.value),
      );
    }
    if (componentId.present) {
      map['component_id'] = Variable<String>(componentId.value);
    }
    if (bikeId.present) {
      map['bike_id'] = Variable<String>(bikeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(
        $TaskRulesTable.$converterpriority.toSql(priority.value),
      );
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $TaskRulesTable.$convertertags.toSql(tags.value),
      );
    }
    if (interval.present) {
      map['interval'] = Variable<String>(interval.value);
    }
    if (delay.present) {
      map['delay'] = Variable<String>(delay.value);
    }
    if (repeat.present) {
      map['repeat'] = Variable<bool>(repeat.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRulesCompanion(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('componentId: $componentId, ')
          ..write('bikeId: $bikeId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('priority: $priority, ')
          ..write('tags: $tags, ')
          ..write('interval: $interval, ')
          ..write('delay: $delay, ')
          ..write('repeat: $repeat, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskEntriesTable extends TaskEntries
    with TableInfo<$TaskEntriesTable, TaskEntryDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> lastModified =
      GeneratedColumn<DateTime>(
        'last_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($TaskEntriesTable.$converterlastModified);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> dateTimeUTC =
      GeneratedColumn<DateTime>(
        'date_time_u_t_c',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($TaskEntriesTable.$converterdateTimeUTC);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime>
  dateTimeLocal = GeneratedColumn<DateTime>(
    'date_time_local',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($TaskEntriesTable.$converterdateTimeLocal);
  static const VerificationMeta _taskRuleMeta = const VerificationMeta(
    'taskRule',
  );
  @override
  late final GeneratedColumn<String> taskRule = GeneratedColumn<String>(
    'task_rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES task_rules (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _componentIdMeta = const VerificationMeta(
    'componentId',
  );
  @override
  late final GeneratedColumn<String> componentId = GeneratedColumn<String>(
    'component_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES components (id)',
    ),
  );
  static const VerificationMeta _bikeIdMeta = const VerificationMeta('bikeId');
  @override
  late final GeneratedColumn<String> bikeId = GeneratedColumn<String>(
    'bike_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bikes (id)',
    ),
  );
  static const VerificationMeta _snapshotMeta = const VerificationMeta(
    'snapshot',
  );
  @override
  late final GeneratedColumn<String> snapshot = GeneratedColumn<String>(
    'snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isDeleted,
    lastModified,
    name,
    notes,
    dateTimeUTC,
    dateTimeLocal,
    taskRule,
    componentId,
    bikeId,
    snapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskEntryDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('task_rule')) {
      context.handle(
        _taskRuleMeta,
        taskRule.isAcceptableOrUnknown(data['task_rule']!, _taskRuleMeta),
      );
    } else if (isInserting) {
      context.missing(_taskRuleMeta);
    }
    if (data.containsKey('component_id')) {
      context.handle(
        _componentIdMeta,
        componentId.isAcceptableOrUnknown(
          data['component_id']!,
          _componentIdMeta,
        ),
      );
    }
    if (data.containsKey('bike_id')) {
      context.handle(
        _bikeIdMeta,
        bikeId.isAcceptableOrUnknown(data['bike_id']!, _bikeIdMeta),
      );
    }
    if (data.containsKey('snapshot')) {
      context.handle(
        _snapshotMeta,
        snapshot.isAcceptableOrUnknown(data['snapshot']!, _snapshotMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskEntryDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskEntryDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastModified: $TaskEntriesTable.$converterlastModified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_modified'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      dateTimeUTC: $TaskEntriesTable.$converterdateTimeUTC.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}date_time_u_t_c'],
        )!,
      ),
      dateTimeLocal: $TaskEntriesTable.$converterdateTimeLocal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}date_time_local'],
        )!,
      ),
      taskRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_rule'],
      )!,
      componentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_id'],
      ),
      bikeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bike_id'],
      ),
      snapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot'],
      ),
    );
  }

  @override
  $TaskEntriesTable createAlias(String alias) {
    return $TaskEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterlastModified =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterdateTimeUTC =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterdateTimeLocal =
      const LocalFloatingDateTimeConverter();
}

class TaskEntryDb extends DataClass implements Insertable<TaskEntryDb> {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;
  final String taskRule;
  final String? componentId;
  final String? bikeId;
  final String? snapshot;
  const TaskEntryDb({
    required this.id,
    required this.isDeleted,
    required this.lastModified,
    required this.name,
    this.notes,
    required this.dateTimeUTC,
    required this.dateTimeLocal,
    required this.taskRule,
    this.componentId,
    this.bikeId,
    this.snapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_deleted'] = Variable<bool>(isDeleted);
    {
      map['last_modified'] = Variable<DateTime>(
        $TaskEntriesTable.$converterlastModified.toSql(lastModified),
      );
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['date_time_u_t_c'] = Variable<DateTime>(
        $TaskEntriesTable.$converterdateTimeUTC.toSql(dateTimeUTC),
      );
    }
    {
      map['date_time_local'] = Variable<DateTime>(
        $TaskEntriesTable.$converterdateTimeLocal.toSql(dateTimeLocal),
      );
    }
    map['task_rule'] = Variable<String>(taskRule);
    if (!nullToAbsent || componentId != null) {
      map['component_id'] = Variable<String>(componentId);
    }
    if (!nullToAbsent || bikeId != null) {
      map['bike_id'] = Variable<String>(bikeId);
    }
    if (!nullToAbsent || snapshot != null) {
      map['snapshot'] = Variable<String>(snapshot);
    }
    return map;
  }

  TaskEntriesCompanion toCompanion(bool nullToAbsent) {
    return TaskEntriesCompanion(
      id: Value(id),
      isDeleted: Value(isDeleted),
      lastModified: Value(lastModified),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      dateTimeUTC: Value(dateTimeUTC),
      dateTimeLocal: Value(dateTimeLocal),
      taskRule: Value(taskRule),
      componentId: componentId == null && nullToAbsent
          ? const Value.absent()
          : Value(componentId),
      bikeId: bikeId == null && nullToAbsent
          ? const Value.absent()
          : Value(bikeId),
      snapshot: snapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(snapshot),
    );
  }

  factory TaskEntryDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskEntryDb(
      id: serializer.fromJson<String>(json['id']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      dateTimeUTC: serializer.fromJson<DateTime>(json['dateTimeUTC']),
      dateTimeLocal: serializer.fromJson<DateTime>(json['dateTimeLocal']),
      taskRule: serializer.fromJson<String>(json['taskRule']),
      componentId: serializer.fromJson<String?>(json['componentId']),
      bikeId: serializer.fromJson<String?>(json['bikeId']),
      snapshot: serializer.fromJson<String?>(json['snapshot']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'dateTimeUTC': serializer.toJson<DateTime>(dateTimeUTC),
      'dateTimeLocal': serializer.toJson<DateTime>(dateTimeLocal),
      'taskRule': serializer.toJson<String>(taskRule),
      'componentId': serializer.toJson<String?>(componentId),
      'bikeId': serializer.toJson<String?>(bikeId),
      'snapshot': serializer.toJson<String?>(snapshot),
    };
  }

  TaskEntryDb copyWith({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    String? name,
    Value<String?> notes = const Value.absent(),
    DateTime? dateTimeUTC,
    DateTime? dateTimeLocal,
    String? taskRule,
    Value<String?> componentId = const Value.absent(),
    Value<String?> bikeId = const Value.absent(),
    Value<String?> snapshot = const Value.absent(),
  }) => TaskEntryDb(
    id: id ?? this.id,
    isDeleted: isDeleted ?? this.isDeleted,
    lastModified: lastModified ?? this.lastModified,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    dateTimeUTC: dateTimeUTC ?? this.dateTimeUTC,
    dateTimeLocal: dateTimeLocal ?? this.dateTimeLocal,
    taskRule: taskRule ?? this.taskRule,
    componentId: componentId.present ? componentId.value : this.componentId,
    bikeId: bikeId.present ? bikeId.value : this.bikeId,
    snapshot: snapshot.present ? snapshot.value : this.snapshot,
  );
  TaskEntryDb copyWithCompanion(TaskEntriesCompanion data) {
    return TaskEntryDb(
      id: data.id.present ? data.id.value : this.id,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      dateTimeUTC: data.dateTimeUTC.present
          ? data.dateTimeUTC.value
          : this.dateTimeUTC,
      dateTimeLocal: data.dateTimeLocal.present
          ? data.dateTimeLocal.value
          : this.dateTimeLocal,
      taskRule: data.taskRule.present ? data.taskRule.value : this.taskRule,
      componentId: data.componentId.present
          ? data.componentId.value
          : this.componentId,
      bikeId: data.bikeId.present ? data.bikeId.value : this.bikeId,
      snapshot: data.snapshot.present ? data.snapshot.value : this.snapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskEntryDb(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('dateTimeUTC: $dateTimeUTC, ')
          ..write('dateTimeLocal: $dateTimeLocal, ')
          ..write('taskRule: $taskRule, ')
          ..write('componentId: $componentId, ')
          ..write('bikeId: $bikeId, ')
          ..write('snapshot: $snapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isDeleted,
    lastModified,
    name,
    notes,
    dateTimeUTC,
    dateTimeLocal,
    taskRule,
    componentId,
    bikeId,
    snapshot,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskEntryDb &&
          other.id == this.id &&
          other.isDeleted == this.isDeleted &&
          other.lastModified == this.lastModified &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.dateTimeUTC == this.dateTimeUTC &&
          other.dateTimeLocal == this.dateTimeLocal &&
          other.taskRule == this.taskRule &&
          other.componentId == this.componentId &&
          other.bikeId == this.bikeId &&
          other.snapshot == this.snapshot);
}

class TaskEntriesCompanion extends UpdateCompanion<TaskEntryDb> {
  final Value<String> id;
  final Value<bool> isDeleted;
  final Value<DateTime> lastModified;
  final Value<String> name;
  final Value<String?> notes;
  final Value<DateTime> dateTimeUTC;
  final Value<DateTime> dateTimeLocal;
  final Value<String> taskRule;
  final Value<String?> componentId;
  final Value<String?> bikeId;
  final Value<String?> snapshot;
  final Value<int> rowid;
  const TaskEntriesCompanion({
    this.id = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.dateTimeUTC = const Value.absent(),
    this.dateTimeLocal = const Value.absent(),
    this.taskRule = const Value.absent(),
    this.componentId = const Value.absent(),
    this.bikeId = const Value.absent(),
    this.snapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskEntriesCompanion.insert({
    required String id,
    this.isDeleted = const Value.absent(),
    required DateTime lastModified,
    required String name,
    this.notes = const Value.absent(),
    required DateTime dateTimeUTC,
    required DateTime dateTimeLocal,
    required String taskRule,
    this.componentId = const Value.absent(),
    this.bikeId = const Value.absent(),
    this.snapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lastModified = Value(lastModified),
       name = Value(name),
       dateTimeUTC = Value(dateTimeUTC),
       dateTimeLocal = Value(dateTimeLocal),
       taskRule = Value(taskRule);
  static Insertable<TaskEntryDb> custom({
    Expression<String>? id,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastModified,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<DateTime>? dateTimeUTC,
    Expression<DateTime>? dateTimeLocal,
    Expression<String>? taskRule,
    Expression<String>? componentId,
    Expression<String>? bikeId,
    Expression<String>? snapshot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastModified != null) 'last_modified': lastModified,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (dateTimeUTC != null) 'date_time_u_t_c': dateTimeUTC,
      if (dateTimeLocal != null) 'date_time_local': dateTimeLocal,
      if (taskRule != null) 'task_rule': taskRule,
      if (componentId != null) 'component_id': componentId,
      if (bikeId != null) 'bike_id': bikeId,
      if (snapshot != null) 'snapshot': snapshot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskEntriesCompanion copyWith({
    Value<String>? id,
    Value<bool>? isDeleted,
    Value<DateTime>? lastModified,
    Value<String>? name,
    Value<String?>? notes,
    Value<DateTime>? dateTimeUTC,
    Value<DateTime>? dateTimeLocal,
    Value<String>? taskRule,
    Value<String?>? componentId,
    Value<String?>? bikeId,
    Value<String?>? snapshot,
    Value<int>? rowid,
  }) {
    return TaskEntriesCompanion(
      id: id ?? this.id,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      dateTimeUTC: dateTimeUTC ?? this.dateTimeUTC,
      dateTimeLocal: dateTimeLocal ?? this.dateTimeLocal,
      taskRule: taskRule ?? this.taskRule,
      componentId: componentId ?? this.componentId,
      bikeId: bikeId ?? this.bikeId,
      snapshot: snapshot ?? this.snapshot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(
        $TaskEntriesTable.$converterlastModified.toSql(lastModified.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (dateTimeUTC.present) {
      map['date_time_u_t_c'] = Variable<DateTime>(
        $TaskEntriesTable.$converterdateTimeUTC.toSql(dateTimeUTC.value),
      );
    }
    if (dateTimeLocal.present) {
      map['date_time_local'] = Variable<DateTime>(
        $TaskEntriesTable.$converterdateTimeLocal.toSql(dateTimeLocal.value),
      );
    }
    if (taskRule.present) {
      map['task_rule'] = Variable<String>(taskRule.value);
    }
    if (componentId.present) {
      map['component_id'] = Variable<String>(componentId.value);
    }
    if (bikeId.present) {
      map['bike_id'] = Variable<String>(bikeId.value);
    }
    if (snapshot.present) {
      map['snapshot'] = Variable<String>(snapshot.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskEntriesCompanion(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('dateTimeUTC: $dateTimeUTC, ')
          ..write('dateTimeLocal: $dateTimeLocal, ')
          ..write('taskRule: $taskRule, ')
          ..write('componentId: $componentId, ')
          ..write('bikeId: $bikeId, ')
          ..write('snapshot: $snapshot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonsTable extends Persons with TableInfo<$PersonsTable, PersonDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> lastModified =
      GeneratedColumn<DateTime>(
        'last_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PersonsTable.$converterlastModified);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stravaAthleteMeta = const VerificationMeta(
    'stravaAthlete',
  );
  @override
  late final GeneratedColumn<int> stravaAthlete = GeneratedColumn<int>(
    'strava_athlete',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isDeleted,
    lastModified,
    name,
    notes,
    stravaAthlete,
    orderIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('strava_athlete')) {
      context.handle(
        _stravaAthleteMeta,
        stravaAthlete.isAcceptableOrUnknown(
          data['strava_athlete']!,
          _stravaAthleteMeta,
        ),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastModified: $PersonsTable.$converterlastModified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_modified'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      stravaAthlete: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}strava_athlete'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterlastModified =
      const UtcDateTimeConverter();
}

class PersonDb extends DataClass implements Insertable<PersonDb> {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final int? stravaAthlete;
  final int orderIndex;
  const PersonDb({
    required this.id,
    required this.isDeleted,
    required this.lastModified,
    required this.name,
    this.notes,
    this.stravaAthlete,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_deleted'] = Variable<bool>(isDeleted);
    {
      map['last_modified'] = Variable<DateTime>(
        $PersonsTable.$converterlastModified.toSql(lastModified),
      );
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || stravaAthlete != null) {
      map['strava_athlete'] = Variable<int>(stravaAthlete);
    }
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      id: Value(id),
      isDeleted: Value(isDeleted),
      lastModified: Value(lastModified),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      stravaAthlete: stravaAthlete == null && nullToAbsent
          ? const Value.absent()
          : Value(stravaAthlete),
      orderIndex: Value(orderIndex),
    );
  }

  factory PersonDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonDb(
      id: serializer.fromJson<String>(json['id']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      stravaAthlete: serializer.fromJson<int?>(json['stravaAthlete']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'stravaAthlete': serializer.toJson<int?>(stravaAthlete),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  PersonDb copyWith({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    String? name,
    Value<String?> notes = const Value.absent(),
    Value<int?> stravaAthlete = const Value.absent(),
    int? orderIndex,
  }) => PersonDb(
    id: id ?? this.id,
    isDeleted: isDeleted ?? this.isDeleted,
    lastModified: lastModified ?? this.lastModified,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    stravaAthlete: stravaAthlete.present
        ? stravaAthlete.value
        : this.stravaAthlete,
    orderIndex: orderIndex ?? this.orderIndex,
  );
  PersonDb copyWithCompanion(PersonsCompanion data) {
    return PersonDb(
      id: data.id.present ? data.id.value : this.id,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      stravaAthlete: data.stravaAthlete.present
          ? data.stravaAthlete.value
          : this.stravaAthlete,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonDb(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('stravaAthlete: $stravaAthlete, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isDeleted,
    lastModified,
    name,
    notes,
    stravaAthlete,
    orderIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonDb &&
          other.id == this.id &&
          other.isDeleted == this.isDeleted &&
          other.lastModified == this.lastModified &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.stravaAthlete == this.stravaAthlete &&
          other.orderIndex == this.orderIndex);
}

class PersonsCompanion extends UpdateCompanion<PersonDb> {
  final Value<String> id;
  final Value<bool> isDeleted;
  final Value<DateTime> lastModified;
  final Value<String> name;
  final Value<String?> notes;
  final Value<int?> stravaAthlete;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const PersonsCompanion({
    this.id = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.stravaAthlete = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonsCompanion.insert({
    required String id,
    this.isDeleted = const Value.absent(),
    required DateTime lastModified,
    required String name,
    this.notes = const Value.absent(),
    this.stravaAthlete = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lastModified = Value(lastModified),
       name = Value(name);
  static Insertable<PersonDb> custom({
    Expression<String>? id,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastModified,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<int>? stravaAthlete,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastModified != null) 'last_modified': lastModified,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (stravaAthlete != null) 'strava_athlete': stravaAthlete,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonsCompanion copyWith({
    Value<String>? id,
    Value<bool>? isDeleted,
    Value<DateTime>? lastModified,
    Value<String>? name,
    Value<String?>? notes,
    Value<int?>? stravaAthlete,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return PersonsCompanion(
      id: id ?? this.id,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      stravaAthlete: stravaAthlete ?? this.stravaAthlete,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(
        $PersonsTable.$converterlastModified.toSql(lastModified.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (stravaAthlete.present) {
      map['strava_athlete'] = Variable<int>(stravaAthlete.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('stravaAthlete: $stravaAthlete, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdjustmentsTable extends Adjustments
    with TableInfo<$AdjustmentsTable, AdjustmentDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdjustmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _componentIdMeta = const VerificationMeta(
    'componentId',
  );
  @override
  late final GeneratedColumn<String> componentId = GeneratedColumn<String>(
    'component_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES components (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES persons (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AdjustmentType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AdjustmentType>($AdjustmentsTable.$convertertype);
  static const VerificationMeta _jsonPayloadMeta = const VerificationMeta(
    'jsonPayload',
  );
  @override
  late final GeneratedColumn<String> jsonPayload = GeneratedColumn<String>(
    'json_payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    componentId,
    personId,
    orderIndex,
    name,
    notes,
    unit,
    type,
    jsonPayload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adjustments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdjustmentDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('component_id')) {
      context.handle(
        _componentIdMeta,
        componentId.isAcceptableOrUnknown(
          data['component_id']!,
          _componentIdMeta,
        ),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('json_payload')) {
      context.handle(
        _jsonPayloadMeta,
        jsonPayload.isAcceptableOrUnknown(
          data['json_payload']!,
          _jsonPayloadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdjustmentDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdjustmentDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      componentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_id'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      type: $AdjustmentsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      jsonPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_payload'],
      ),
    );
  }

  @override
  $AdjustmentsTable createAlias(String alias) {
    return $AdjustmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AdjustmentType, String, String> $convertertype =
      const EnumNameConverter<AdjustmentType>(AdjustmentType.values);
}

class AdjustmentDb extends DataClass implements Insertable<AdjustmentDb> {
  final String id;
  final String? componentId;
  final String? personId;
  final int orderIndex;
  final String name;
  final String? notes;
  final String? unit;
  final AdjustmentType type;
  final String? jsonPayload;
  const AdjustmentDb({
    required this.id,
    this.componentId,
    this.personId,
    required this.orderIndex,
    required this.name,
    this.notes,
    this.unit,
    required this.type,
    this.jsonPayload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || componentId != null) {
      map['component_id'] = Variable<String>(componentId);
    }
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<String>(personId);
    }
    map['order_index'] = Variable<int>(orderIndex);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    {
      map['type'] = Variable<String>(
        $AdjustmentsTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || jsonPayload != null) {
      map['json_payload'] = Variable<String>(jsonPayload);
    }
    return map;
  }

  AdjustmentsCompanion toCompanion(bool nullToAbsent) {
    return AdjustmentsCompanion(
      id: Value(id),
      componentId: componentId == null && nullToAbsent
          ? const Value.absent()
          : Value(componentId),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      orderIndex: Value(orderIndex),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      type: Value(type),
      jsonPayload: jsonPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(jsonPayload),
    );
  }

  factory AdjustmentDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdjustmentDb(
      id: serializer.fromJson<String>(json['id']),
      componentId: serializer.fromJson<String?>(json['componentId']),
      personId: serializer.fromJson<String?>(json['personId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      unit: serializer.fromJson<String?>(json['unit']),
      type: $AdjustmentsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      jsonPayload: serializer.fromJson<String?>(json['jsonPayload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'componentId': serializer.toJson<String?>(componentId),
      'personId': serializer.toJson<String?>(personId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'unit': serializer.toJson<String?>(unit),
      'type': serializer.toJson<String>(
        $AdjustmentsTable.$convertertype.toJson(type),
      ),
      'jsonPayload': serializer.toJson<String?>(jsonPayload),
    };
  }

  AdjustmentDb copyWith({
    String? id,
    Value<String?> componentId = const Value.absent(),
    Value<String?> personId = const Value.absent(),
    int? orderIndex,
    String? name,
    Value<String?> notes = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    AdjustmentType? type,
    Value<String?> jsonPayload = const Value.absent(),
  }) => AdjustmentDb(
    id: id ?? this.id,
    componentId: componentId.present ? componentId.value : this.componentId,
    personId: personId.present ? personId.value : this.personId,
    orderIndex: orderIndex ?? this.orderIndex,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    unit: unit.present ? unit.value : this.unit,
    type: type ?? this.type,
    jsonPayload: jsonPayload.present ? jsonPayload.value : this.jsonPayload,
  );
  AdjustmentDb copyWithCompanion(AdjustmentsCompanion data) {
    return AdjustmentDb(
      id: data.id.present ? data.id.value : this.id,
      componentId: data.componentId.present
          ? data.componentId.value
          : this.componentId,
      personId: data.personId.present ? data.personId.value : this.personId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      unit: data.unit.present ? data.unit.value : this.unit,
      type: data.type.present ? data.type.value : this.type,
      jsonPayload: data.jsonPayload.present
          ? data.jsonPayload.value
          : this.jsonPayload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdjustmentDb(')
          ..write('id: $id, ')
          ..write('componentId: $componentId, ')
          ..write('personId: $personId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('unit: $unit, ')
          ..write('type: $type, ')
          ..write('jsonPayload: $jsonPayload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    componentId,
    personId,
    orderIndex,
    name,
    notes,
    unit,
    type,
    jsonPayload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdjustmentDb &&
          other.id == this.id &&
          other.componentId == this.componentId &&
          other.personId == this.personId &&
          other.orderIndex == this.orderIndex &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.unit == this.unit &&
          other.type == this.type &&
          other.jsonPayload == this.jsonPayload);
}

class AdjustmentsCompanion extends UpdateCompanion<AdjustmentDb> {
  final Value<String> id;
  final Value<String?> componentId;
  final Value<String?> personId;
  final Value<int> orderIndex;
  final Value<String> name;
  final Value<String?> notes;
  final Value<String?> unit;
  final Value<AdjustmentType> type;
  final Value<String?> jsonPayload;
  final Value<int> rowid;
  const AdjustmentsCompanion({
    this.id = const Value.absent(),
    this.componentId = const Value.absent(),
    this.personId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.unit = const Value.absent(),
    this.type = const Value.absent(),
    this.jsonPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdjustmentsCompanion.insert({
    required String id,
    this.componentId = const Value.absent(),
    this.personId = const Value.absent(),
    required int orderIndex,
    required String name,
    this.notes = const Value.absent(),
    this.unit = const Value.absent(),
    required AdjustmentType type,
    this.jsonPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderIndex = Value(orderIndex),
       name = Value(name),
       type = Value(type);
  static Insertable<AdjustmentDb> custom({
    Expression<String>? id,
    Expression<String>? componentId,
    Expression<String>? personId,
    Expression<int>? orderIndex,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<String>? unit,
    Expression<String>? type,
    Expression<String>? jsonPayload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (componentId != null) 'component_id': componentId,
      if (personId != null) 'person_id': personId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (unit != null) 'unit': unit,
      if (type != null) 'type': type,
      if (jsonPayload != null) 'json_payload': jsonPayload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdjustmentsCompanion copyWith({
    Value<String>? id,
    Value<String?>? componentId,
    Value<String?>? personId,
    Value<int>? orderIndex,
    Value<String>? name,
    Value<String?>? notes,
    Value<String?>? unit,
    Value<AdjustmentType>? type,
    Value<String?>? jsonPayload,
    Value<int>? rowid,
  }) {
    return AdjustmentsCompanion(
      id: id ?? this.id,
      componentId: componentId ?? this.componentId,
      personId: personId ?? this.personId,
      orderIndex: orderIndex ?? this.orderIndex,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      jsonPayload: jsonPayload ?? this.jsonPayload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (componentId.present) {
      map['component_id'] = Variable<String>(componentId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AdjustmentsTable.$convertertype.toSql(type.value),
      );
    }
    if (jsonPayload.present) {
      map['json_payload'] = Variable<String>(jsonPayload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdjustmentsCompanion(')
          ..write('id: $id, ')
          ..write('componentId: $componentId, ')
          ..write('personId: $personId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('unit: $unit, ')
          ..write('type: $type, ')
          ..write('jsonPayload: $jsonPayload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstallationsTable extends Installations
    with TableInfo<$InstallationsTable, InstallationDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _componentIdMeta = const VerificationMeta(
    'componentId',
  );
  @override
  late final GeneratedColumn<String> componentId = GeneratedColumn<String>(
    'component_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES components (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _parentMeta = const VerificationMeta('parent');
  @override
  late final GeneratedColumn<String> parent = GeneratedColumn<String>(
    'parent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<InstallationParentType, String>
  parentType =
      GeneratedColumn<String>(
        'parent_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('bike'),
      ).withConverter<InstallationParentType>(
        $InstallationsTable.$converterparentType,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> dateTimeUTC =
      GeneratedColumn<DateTime>(
        'date_time_u_t_c',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($InstallationsTable.$converterdateTimeUTC);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime>
  dateTimeLocal = GeneratedColumn<DateTime>(
    'date_time_local',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($InstallationsTable.$converterdateTimeLocal);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    componentId,
    parent,
    parentType,
    dateTimeUTC,
    dateTimeLocal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installations';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstallationDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('component_id')) {
      context.handle(
        _componentIdMeta,
        componentId.isAcceptableOrUnknown(
          data['component_id']!,
          _componentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_componentIdMeta);
    }
    if (data.containsKey('parent')) {
      context.handle(
        _parentMeta,
        parent.isAcceptableOrUnknown(data['parent']!, _parentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstallationDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallationDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      componentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_id'],
      )!,
      parent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent'],
      ),
      parentType: $InstallationsTable.$converterparentType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}parent_type'],
        )!,
      ),
      dateTimeUTC: $InstallationsTable.$converterdateTimeUTC.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}date_time_u_t_c'],
        )!,
      ),
      dateTimeLocal: $InstallationsTable.$converterdateTimeLocal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}date_time_local'],
        )!,
      ),
    );
  }

  @override
  $InstallationsTable createAlias(String alias) {
    return $InstallationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<InstallationParentType, String, String>
  $converterparentType = const EnumNameConverter(InstallationParentType.values);
  static TypeConverter<DateTime, DateTime> $converterdateTimeUTC =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterdateTimeLocal =
      const LocalFloatingDateTimeConverter();
}

class InstallationDb extends DataClass implements Insertable<InstallationDb> {
  final String id;
  final String componentId;
  final String? parent;
  final InstallationParentType parentType;
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;
  const InstallationDb({
    required this.id,
    required this.componentId,
    this.parent,
    required this.parentType,
    required this.dateTimeUTC,
    required this.dateTimeLocal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['component_id'] = Variable<String>(componentId);
    if (!nullToAbsent || parent != null) {
      map['parent'] = Variable<String>(parent);
    }
    {
      map['parent_type'] = Variable<String>(
        $InstallationsTable.$converterparentType.toSql(parentType),
      );
    }
    {
      map['date_time_u_t_c'] = Variable<DateTime>(
        $InstallationsTable.$converterdateTimeUTC.toSql(dateTimeUTC),
      );
    }
    {
      map['date_time_local'] = Variable<DateTime>(
        $InstallationsTable.$converterdateTimeLocal.toSql(dateTimeLocal),
      );
    }
    return map;
  }

  InstallationsCompanion toCompanion(bool nullToAbsent) {
    return InstallationsCompanion(
      id: Value(id),
      componentId: Value(componentId),
      parent: parent == null && nullToAbsent
          ? const Value.absent()
          : Value(parent),
      parentType: Value(parentType),
      dateTimeUTC: Value(dateTimeUTC),
      dateTimeLocal: Value(dateTimeLocal),
    );
  }

  factory InstallationDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallationDb(
      id: serializer.fromJson<String>(json['id']),
      componentId: serializer.fromJson<String>(json['componentId']),
      parent: serializer.fromJson<String?>(json['parent']),
      parentType: $InstallationsTable.$converterparentType.fromJson(
        serializer.fromJson<String>(json['parentType']),
      ),
      dateTimeUTC: serializer.fromJson<DateTime>(json['dateTimeUTC']),
      dateTimeLocal: serializer.fromJson<DateTime>(json['dateTimeLocal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'componentId': serializer.toJson<String>(componentId),
      'parent': serializer.toJson<String?>(parent),
      'parentType': serializer.toJson<String>(
        $InstallationsTable.$converterparentType.toJson(parentType),
      ),
      'dateTimeUTC': serializer.toJson<DateTime>(dateTimeUTC),
      'dateTimeLocal': serializer.toJson<DateTime>(dateTimeLocal),
    };
  }

  InstallationDb copyWith({
    String? id,
    String? componentId,
    Value<String?> parent = const Value.absent(),
    InstallationParentType? parentType,
    DateTime? dateTimeUTC,
    DateTime? dateTimeLocal,
  }) => InstallationDb(
    id: id ?? this.id,
    componentId: componentId ?? this.componentId,
    parent: parent.present ? parent.value : this.parent,
    parentType: parentType ?? this.parentType,
    dateTimeUTC: dateTimeUTC ?? this.dateTimeUTC,
    dateTimeLocal: dateTimeLocal ?? this.dateTimeLocal,
  );
  InstallationDb copyWithCompanion(InstallationsCompanion data) {
    return InstallationDb(
      id: data.id.present ? data.id.value : this.id,
      componentId: data.componentId.present
          ? data.componentId.value
          : this.componentId,
      parent: data.parent.present ? data.parent.value : this.parent,
      parentType: data.parentType.present
          ? data.parentType.value
          : this.parentType,
      dateTimeUTC: data.dateTimeUTC.present
          ? data.dateTimeUTC.value
          : this.dateTimeUTC,
      dateTimeLocal: data.dateTimeLocal.present
          ? data.dateTimeLocal.value
          : this.dateTimeLocal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallationDb(')
          ..write('id: $id, ')
          ..write('componentId: $componentId, ')
          ..write('parent: $parent, ')
          ..write('parentType: $parentType, ')
          ..write('dateTimeUTC: $dateTimeUTC, ')
          ..write('dateTimeLocal: $dateTimeLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    componentId,
    parent,
    parentType,
    dateTimeUTC,
    dateTimeLocal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallationDb &&
          other.id == this.id &&
          other.componentId == this.componentId &&
          other.parent == this.parent &&
          other.parentType == this.parentType &&
          other.dateTimeUTC == this.dateTimeUTC &&
          other.dateTimeLocal == this.dateTimeLocal);
}

class InstallationsCompanion extends UpdateCompanion<InstallationDb> {
  final Value<String> id;
  final Value<String> componentId;
  final Value<String?> parent;
  final Value<InstallationParentType> parentType;
  final Value<DateTime> dateTimeUTC;
  final Value<DateTime> dateTimeLocal;
  final Value<int> rowid;
  const InstallationsCompanion({
    this.id = const Value.absent(),
    this.componentId = const Value.absent(),
    this.parent = const Value.absent(),
    this.parentType = const Value.absent(),
    this.dateTimeUTC = const Value.absent(),
    this.dateTimeLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstallationsCompanion.insert({
    required String id,
    required String componentId,
    this.parent = const Value.absent(),
    this.parentType = const Value.absent(),
    required DateTime dateTimeUTC,
    required DateTime dateTimeLocal,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       componentId = Value(componentId),
       dateTimeUTC = Value(dateTimeUTC),
       dateTimeLocal = Value(dateTimeLocal);
  static Insertable<InstallationDb> custom({
    Expression<String>? id,
    Expression<String>? componentId,
    Expression<String>? parent,
    Expression<String>? parentType,
    Expression<DateTime>? dateTimeUTC,
    Expression<DateTime>? dateTimeLocal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (componentId != null) 'component_id': componentId,
      if (parent != null) 'parent': parent,
      if (parentType != null) 'parent_type': parentType,
      if (dateTimeUTC != null) 'date_time_u_t_c': dateTimeUTC,
      if (dateTimeLocal != null) 'date_time_local': dateTimeLocal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstallationsCompanion copyWith({
    Value<String>? id,
    Value<String>? componentId,
    Value<String?>? parent,
    Value<InstallationParentType>? parentType,
    Value<DateTime>? dateTimeUTC,
    Value<DateTime>? dateTimeLocal,
    Value<int>? rowid,
  }) {
    return InstallationsCompanion(
      id: id ?? this.id,
      componentId: componentId ?? this.componentId,
      parent: parent ?? this.parent,
      parentType: parentType ?? this.parentType,
      dateTimeUTC: dateTimeUTC ?? this.dateTimeUTC,
      dateTimeLocal: dateTimeLocal ?? this.dateTimeLocal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (componentId.present) {
      map['component_id'] = Variable<String>(componentId.value);
    }
    if (parent.present) {
      map['parent'] = Variable<String>(parent.value);
    }
    if (parentType.present) {
      map['parent_type'] = Variable<String>(
        $InstallationsTable.$converterparentType.toSql(parentType.value),
      );
    }
    if (dateTimeUTC.present) {
      map['date_time_u_t_c'] = Variable<DateTime>(
        $InstallationsTable.$converterdateTimeUTC.toSql(dateTimeUTC.value),
      );
    }
    if (dateTimeLocal.present) {
      map['date_time_local'] = Variable<DateTime>(
        $InstallationsTable.$converterdateTimeLocal.toSql(dateTimeLocal.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstallationsCompanion(')
          ..write('id: $id, ')
          ..write('componentId: $componentId, ')
          ..write('parent: $parent, ')
          ..write('parentType: $parentType, ')
          ..write('dateTimeUTC: $dateTimeUTC, ')
          ..write('dateTimeLocal: $dateTimeLocal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetupsTable extends Setups with TableInfo<$SetupsTable, SetupDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bikeIdMeta = const VerificationMeta('bikeId');
  @override
  late final GeneratedColumn<String> bikeId = GeneratedColumn<String>(
    'bike_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bikes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES persons (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> lastModified =
      GeneratedColumn<DateTime>(
        'last_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SetupsTable.$converterlastModified);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> datetime =
      GeneratedColumn<DateTime>(
        'datetime',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SetupsTable.$converterdatetime);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime>
  datetimeLocal = GeneratedColumn<DateTime>(
    'datetime_local',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($SetupsTable.$converterdatetimeLocal);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Set<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Set<String>>($SetupsTable.$convertertags);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> images =
      GeneratedColumn<String>(
        'images',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($SetupsTable.$converterimages);
  @override
  late final GeneratedColumnWithTypeConverter<ContextPosition?, String>
  position = GeneratedColumn<String>(
    'position',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ContextPosition?>($SetupsTable.$converterpositionn);
  @override
  late final GeneratedColumnWithTypeConverter<geo.Placemark?, String> place =
      GeneratedColumn<String>(
        'place',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<geo.Placemark?>($SetupsTable.$converterplacen);
  @override
  late final GeneratedColumnWithTypeConverter<ContextWeather?, String> weather =
      GeneratedColumn<String>(
        'weather',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ContextWeather?>($SetupsTable.$converterweathern);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bikeId,
    personId,
    isDeleted,
    lastModified,
    name,
    datetime,
    datetimeLocal,
    notes,
    tags,
    images,
    position,
    place,
    weather,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setups';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetupDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bike_id')) {
      context.handle(
        _bikeIdMeta,
        bikeId.isAcceptableOrUnknown(data['bike_id']!, _bikeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bikeIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetupDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetupDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bikeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bike_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastModified: $SetupsTable.$converterlastModified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_modified'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      datetime: $SetupsTable.$converterdatetime.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}datetime'],
        )!,
      ),
      datetimeLocal: $SetupsTable.$converterdatetimeLocal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}datetime_local'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      tags: $SetupsTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      images: $SetupsTable.$converterimages.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}images'],
        )!,
      ),
      position: $SetupsTable.$converterpositionn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}position'],
        ),
      ),
      place: $SetupsTable.$converterplacen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}place'],
        ),
      ),
      weather: $SetupsTable.$converterweathern.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}weather'],
        ),
      ),
    );
  }

  @override
  $SetupsTable createAlias(String alias) {
    return $SetupsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterlastModified =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterdatetime =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterdatetimeLocal =
      const LocalFloatingDateTimeConverter();
  static TypeConverter<Set<String>, String> $convertertags =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterimages =
      const StringListOrderedConverter();
  static TypeConverter<ContextPosition, String> $converterposition =
      const ContextPositionConverter();
  static TypeConverter<ContextPosition?, String?> $converterpositionn =
      NullAwareTypeConverter.wrap($converterposition);
  static TypeConverter<geo.Placemark, String> $converterplace =
      const PlacemarkConverter();
  static TypeConverter<geo.Placemark?, String?> $converterplacen =
      NullAwareTypeConverter.wrap($converterplace);
  static TypeConverter<ContextWeather, String> $converterweather =
      const WeatherConverter();
  static TypeConverter<ContextWeather?, String?> $converterweathern =
      NullAwareTypeConverter.wrap($converterweather);
}

class SetupDb extends DataClass implements Insertable<SetupDb> {
  final String id;
  final String bikeId;
  final String? personId;
  final bool isDeleted;
  final DateTime lastModified;
  final String? name;
  final DateTime datetime;
  final DateTime datetimeLocal;
  final String? notes;
  final Set<String> tags;
  final List<String> images;
  final ContextPosition? position;
  final geo.Placemark? place;
  final ContextWeather? weather;
  const SetupDb({
    required this.id,
    required this.bikeId,
    this.personId,
    required this.isDeleted,
    required this.lastModified,
    this.name,
    required this.datetime,
    required this.datetimeLocal,
    this.notes,
    required this.tags,
    required this.images,
    this.position,
    this.place,
    this.weather,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bike_id'] = Variable<String>(bikeId);
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<String>(personId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    {
      map['last_modified'] = Variable<DateTime>(
        $SetupsTable.$converterlastModified.toSql(lastModified),
      );
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    {
      map['datetime'] = Variable<DateTime>(
        $SetupsTable.$converterdatetime.toSql(datetime),
      );
    }
    {
      map['datetime_local'] = Variable<DateTime>(
        $SetupsTable.$converterdatetimeLocal.toSql(datetimeLocal),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['tags'] = Variable<String>($SetupsTable.$convertertags.toSql(tags));
    }
    {
      map['images'] = Variable<String>(
        $SetupsTable.$converterimages.toSql(images),
      );
    }
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<String>(
        $SetupsTable.$converterpositionn.toSql(position),
      );
    }
    if (!nullToAbsent || place != null) {
      map['place'] = Variable<String>(
        $SetupsTable.$converterplacen.toSql(place),
      );
    }
    if (!nullToAbsent || weather != null) {
      map['weather'] = Variable<String>(
        $SetupsTable.$converterweathern.toSql(weather),
      );
    }
    return map;
  }

  SetupsCompanion toCompanion(bool nullToAbsent) {
    return SetupsCompanion(
      id: Value(id),
      bikeId: Value(bikeId),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      isDeleted: Value(isDeleted),
      lastModified: Value(lastModified),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      datetime: Value(datetime),
      datetimeLocal: Value(datetimeLocal),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      tags: Value(tags),
      images: Value(images),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
      place: place == null && nullToAbsent
          ? const Value.absent()
          : Value(place),
      weather: weather == null && nullToAbsent
          ? const Value.absent()
          : Value(weather),
    );
  }

  factory SetupDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetupDb(
      id: serializer.fromJson<String>(json['id']),
      bikeId: serializer.fromJson<String>(json['bikeId']),
      personId: serializer.fromJson<String?>(json['personId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      name: serializer.fromJson<String?>(json['name']),
      datetime: serializer.fromJson<DateTime>(json['datetime']),
      datetimeLocal: serializer.fromJson<DateTime>(json['datetimeLocal']),
      notes: serializer.fromJson<String?>(json['notes']),
      tags: serializer.fromJson<Set<String>>(json['tags']),
      images: serializer.fromJson<List<String>>(json['images']),
      position: serializer.fromJson<ContextPosition?>(json['position']),
      place: serializer.fromJson<geo.Placemark?>(json['place']),
      weather: serializer.fromJson<ContextWeather?>(json['weather']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bikeId': serializer.toJson<String>(bikeId),
      'personId': serializer.toJson<String?>(personId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'name': serializer.toJson<String?>(name),
      'datetime': serializer.toJson<DateTime>(datetime),
      'datetimeLocal': serializer.toJson<DateTime>(datetimeLocal),
      'notes': serializer.toJson<String?>(notes),
      'tags': serializer.toJson<Set<String>>(tags),
      'images': serializer.toJson<List<String>>(images),
      'position': serializer.toJson<ContextPosition?>(position),
      'place': serializer.toJson<geo.Placemark?>(place),
      'weather': serializer.toJson<ContextWeather?>(weather),
    };
  }

  SetupDb copyWith({
    String? id,
    String? bikeId,
    Value<String?> personId = const Value.absent(),
    bool? isDeleted,
    DateTime? lastModified,
    Value<String?> name = const Value.absent(),
    DateTime? datetime,
    DateTime? datetimeLocal,
    Value<String?> notes = const Value.absent(),
    Set<String>? tags,
    List<String>? images,
    Value<ContextPosition?> position = const Value.absent(),
    Value<geo.Placemark?> place = const Value.absent(),
    Value<ContextWeather?> weather = const Value.absent(),
  }) => SetupDb(
    id: id ?? this.id,
    bikeId: bikeId ?? this.bikeId,
    personId: personId.present ? personId.value : this.personId,
    isDeleted: isDeleted ?? this.isDeleted,
    lastModified: lastModified ?? this.lastModified,
    name: name.present ? name.value : this.name,
    datetime: datetime ?? this.datetime,
    datetimeLocal: datetimeLocal ?? this.datetimeLocal,
    notes: notes.present ? notes.value : this.notes,
    tags: tags ?? this.tags,
    images: images ?? this.images,
    position: position.present ? position.value : this.position,
    place: place.present ? place.value : this.place,
    weather: weather.present ? weather.value : this.weather,
  );
  SetupDb copyWithCompanion(SetupsCompanion data) {
    return SetupDb(
      id: data.id.present ? data.id.value : this.id,
      bikeId: data.bikeId.present ? data.bikeId.value : this.bikeId,
      personId: data.personId.present ? data.personId.value : this.personId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      name: data.name.present ? data.name.value : this.name,
      datetime: data.datetime.present ? data.datetime.value : this.datetime,
      datetimeLocal: data.datetimeLocal.present
          ? data.datetimeLocal.value
          : this.datetimeLocal,
      notes: data.notes.present ? data.notes.value : this.notes,
      tags: data.tags.present ? data.tags.value : this.tags,
      images: data.images.present ? data.images.value : this.images,
      position: data.position.present ? data.position.value : this.position,
      place: data.place.present ? data.place.value : this.place,
      weather: data.weather.present ? data.weather.value : this.weather,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetupDb(')
          ..write('id: $id, ')
          ..write('bikeId: $bikeId, ')
          ..write('personId: $personId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('datetime: $datetime, ')
          ..write('datetimeLocal: $datetimeLocal, ')
          ..write('notes: $notes, ')
          ..write('tags: $tags, ')
          ..write('images: $images, ')
          ..write('position: $position, ')
          ..write('place: $place, ')
          ..write('weather: $weather')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bikeId,
    personId,
    isDeleted,
    lastModified,
    name,
    datetime,
    datetimeLocal,
    notes,
    tags,
    images,
    position,
    place,
    weather,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetupDb &&
          other.id == this.id &&
          other.bikeId == this.bikeId &&
          other.personId == this.personId &&
          other.isDeleted == this.isDeleted &&
          other.lastModified == this.lastModified &&
          other.name == this.name &&
          other.datetime == this.datetime &&
          other.datetimeLocal == this.datetimeLocal &&
          other.notes == this.notes &&
          other.tags == this.tags &&
          other.images == this.images &&
          other.position == this.position &&
          other.place == this.place &&
          other.weather == this.weather);
}

class SetupsCompanion extends UpdateCompanion<SetupDb> {
  final Value<String> id;
  final Value<String> bikeId;
  final Value<String?> personId;
  final Value<bool> isDeleted;
  final Value<DateTime> lastModified;
  final Value<String?> name;
  final Value<DateTime> datetime;
  final Value<DateTime> datetimeLocal;
  final Value<String?> notes;
  final Value<Set<String>> tags;
  final Value<List<String>> images;
  final Value<ContextPosition?> position;
  final Value<geo.Placemark?> place;
  final Value<ContextWeather?> weather;
  final Value<int> rowid;
  const SetupsCompanion({
    this.id = const Value.absent(),
    this.bikeId = const Value.absent(),
    this.personId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.name = const Value.absent(),
    this.datetime = const Value.absent(),
    this.datetimeLocal = const Value.absent(),
    this.notes = const Value.absent(),
    this.tags = const Value.absent(),
    this.images = const Value.absent(),
    this.position = const Value.absent(),
    this.place = const Value.absent(),
    this.weather = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetupsCompanion.insert({
    required String id,
    required String bikeId,
    this.personId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime lastModified,
    this.name = const Value.absent(),
    required DateTime datetime,
    required DateTime datetimeLocal,
    this.notes = const Value.absent(),
    required Set<String> tags,
    this.images = const Value.absent(),
    this.position = const Value.absent(),
    this.place = const Value.absent(),
    this.weather = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bikeId = Value(bikeId),
       lastModified = Value(lastModified),
       datetime = Value(datetime),
       datetimeLocal = Value(datetimeLocal),
       tags = Value(tags);
  static Insertable<SetupDb> custom({
    Expression<String>? id,
    Expression<String>? bikeId,
    Expression<String>? personId,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastModified,
    Expression<String>? name,
    Expression<DateTime>? datetime,
    Expression<DateTime>? datetimeLocal,
    Expression<String>? notes,
    Expression<String>? tags,
    Expression<String>? images,
    Expression<String>? position,
    Expression<String>? place,
    Expression<String>? weather,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bikeId != null) 'bike_id': bikeId,
      if (personId != null) 'person_id': personId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastModified != null) 'last_modified': lastModified,
      if (name != null) 'name': name,
      if (datetime != null) 'datetime': datetime,
      if (datetimeLocal != null) 'datetime_local': datetimeLocal,
      if (notes != null) 'notes': notes,
      if (tags != null) 'tags': tags,
      if (images != null) 'images': images,
      if (position != null) 'position': position,
      if (place != null) 'place': place,
      if (weather != null) 'weather': weather,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetupsCompanion copyWith({
    Value<String>? id,
    Value<String>? bikeId,
    Value<String?>? personId,
    Value<bool>? isDeleted,
    Value<DateTime>? lastModified,
    Value<String?>? name,
    Value<DateTime>? datetime,
    Value<DateTime>? datetimeLocal,
    Value<String?>? notes,
    Value<Set<String>>? tags,
    Value<List<String>>? images,
    Value<ContextPosition?>? position,
    Value<geo.Placemark?>? place,
    Value<ContextWeather?>? weather,
    Value<int>? rowid,
  }) {
    return SetupsCompanion(
      id: id ?? this.id,
      bikeId: bikeId ?? this.bikeId,
      personId: personId ?? this.personId,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
      name: name ?? this.name,
      datetime: datetime ?? this.datetime,
      datetimeLocal: datetimeLocal ?? this.datetimeLocal,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      position: position ?? this.position,
      place: place ?? this.place,
      weather: weather ?? this.weather,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bikeId.present) {
      map['bike_id'] = Variable<String>(bikeId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(
        $SetupsTable.$converterlastModified.toSql(lastModified.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (datetime.present) {
      map['datetime'] = Variable<DateTime>(
        $SetupsTable.$converterdatetime.toSql(datetime.value),
      );
    }
    if (datetimeLocal.present) {
      map['datetime_local'] = Variable<DateTime>(
        $SetupsTable.$converterdatetimeLocal.toSql(datetimeLocal.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $SetupsTable.$convertertags.toSql(tags.value),
      );
    }
    if (images.present) {
      map['images'] = Variable<String>(
        $SetupsTable.$converterimages.toSql(images.value),
      );
    }
    if (position.present) {
      map['position'] = Variable<String>(
        $SetupsTable.$converterpositionn.toSql(position.value),
      );
    }
    if (place.present) {
      map['place'] = Variable<String>(
        $SetupsTable.$converterplacen.toSql(place.value),
      );
    }
    if (weather.present) {
      map['weather'] = Variable<String>(
        $SetupsTable.$converterweathern.toSql(weather.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetupsCompanion(')
          ..write('id: $id, ')
          ..write('bikeId: $bikeId, ')
          ..write('personId: $personId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('datetime: $datetime, ')
          ..write('datetimeLocal: $datetimeLocal, ')
          ..write('notes: $notes, ')
          ..write('tags: $tags, ')
          ..write('images: $images, ')
          ..write('position: $position, ')
          ..write('place: $place, ')
          ..write('weather: $weather, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetupAdjustmentValuesTable extends SetupAdjustmentValues
    with TableInfo<$SetupAdjustmentValuesTable, SetupAdjustmentValueDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetupAdjustmentValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _setupIdMeta = const VerificationMeta(
    'setupId',
  );
  @override
  late final GeneratedColumn<String> setupId = GeneratedColumn<String>(
    'setup_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES setups (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _adjustmentIdMeta = const VerificationMeta(
    'adjustmentId',
  );
  @override
  late final GeneratedColumn<String> adjustmentId = GeneratedColumn<String>(
    'adjustment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES adjustments (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [setupId, adjustmentId, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setup_adjustment_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetupAdjustmentValueDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setup_id')) {
      context.handle(
        _setupIdMeta,
        setupId.isAcceptableOrUnknown(data['setup_id']!, _setupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setupIdMeta);
    }
    if (data.containsKey('adjustment_id')) {
      context.handle(
        _adjustmentIdMeta,
        adjustmentId.isAcceptableOrUnknown(
          data['adjustment_id']!,
          _adjustmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_adjustmentIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {setupId, adjustmentId};
  @override
  SetupAdjustmentValueDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetupAdjustmentValueDb(
      setupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setup_id'],
      )!,
      adjustmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adjustment_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SetupAdjustmentValuesTable createAlias(String alias) {
    return $SetupAdjustmentValuesTable(attachedDatabase, alias);
  }
}

class SetupAdjustmentValueDb extends DataClass
    implements Insertable<SetupAdjustmentValueDb> {
  final String setupId;
  final String adjustmentId;
  final String value;
  const SetupAdjustmentValueDb({
    required this.setupId,
    required this.adjustmentId,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setup_id'] = Variable<String>(setupId);
    map['adjustment_id'] = Variable<String>(adjustmentId);
    map['value'] = Variable<String>(value);
    return map;
  }

  SetupAdjustmentValuesCompanion toCompanion(bool nullToAbsent) {
    return SetupAdjustmentValuesCompanion(
      setupId: Value(setupId),
      adjustmentId: Value(adjustmentId),
      value: Value(value),
    );
  }

  factory SetupAdjustmentValueDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetupAdjustmentValueDb(
      setupId: serializer.fromJson<String>(json['setupId']),
      adjustmentId: serializer.fromJson<String>(json['adjustmentId']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setupId': serializer.toJson<String>(setupId),
      'adjustmentId': serializer.toJson<String>(adjustmentId),
      'value': serializer.toJson<String>(value),
    };
  }

  SetupAdjustmentValueDb copyWith({
    String? setupId,
    String? adjustmentId,
    String? value,
  }) => SetupAdjustmentValueDb(
    setupId: setupId ?? this.setupId,
    adjustmentId: adjustmentId ?? this.adjustmentId,
    value: value ?? this.value,
  );
  SetupAdjustmentValueDb copyWithCompanion(
    SetupAdjustmentValuesCompanion data,
  ) {
    return SetupAdjustmentValueDb(
      setupId: data.setupId.present ? data.setupId.value : this.setupId,
      adjustmentId: data.adjustmentId.present
          ? data.adjustmentId.value
          : this.adjustmentId,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetupAdjustmentValueDb(')
          ..write('setupId: $setupId, ')
          ..write('adjustmentId: $adjustmentId, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(setupId, adjustmentId, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetupAdjustmentValueDb &&
          other.setupId == this.setupId &&
          other.adjustmentId == this.adjustmentId &&
          other.value == this.value);
}

class SetupAdjustmentValuesCompanion
    extends UpdateCompanion<SetupAdjustmentValueDb> {
  final Value<String> setupId;
  final Value<String> adjustmentId;
  final Value<String> value;
  final Value<int> rowid;
  const SetupAdjustmentValuesCompanion({
    this.setupId = const Value.absent(),
    this.adjustmentId = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetupAdjustmentValuesCompanion.insert({
    required String setupId,
    required String adjustmentId,
    required String value,
    this.rowid = const Value.absent(),
  }) : setupId = Value(setupId),
       adjustmentId = Value(adjustmentId),
       value = Value(value);
  static Insertable<SetupAdjustmentValueDb> custom({
    Expression<String>? setupId,
    Expression<String>? adjustmentId,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (setupId != null) 'setup_id': setupId,
      if (adjustmentId != null) 'adjustment_id': adjustmentId,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetupAdjustmentValuesCompanion copyWith({
    Value<String>? setupId,
    Value<String>? adjustmentId,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SetupAdjustmentValuesCompanion(
      setupId: setupId ?? this.setupId,
      adjustmentId: adjustmentId ?? this.adjustmentId,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (setupId.present) {
      map['setup_id'] = Variable<String>(setupId.value);
    }
    if (adjustmentId.present) {
      map['adjustment_id'] = Variable<String>(adjustmentId.value);
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
    return (StringBuffer('SetupAdjustmentValuesCompanion(')
          ..write('setupId: $setupId, ')
          ..write('adjustmentId: $adjustmentId, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RatingsTable extends Ratings with TableInfo<$RatingsTable, RatingDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RatingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> lastModified =
      GeneratedColumn<DateTime>(
        'last_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RatingsTable.$converterlastModified);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filterMeta = const VerificationMeta('filter');
  @override
  late final GeneratedColumn<String> filter = GeneratedColumn<String>(
    'filter',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FilterType, String> filterType =
      GeneratedColumn<String>(
        'filter_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FilterType>($RatingsTable.$converterfilterType);
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isDeleted,
    lastModified,
    name,
    notes,
    filter,
    filterType,
    orderIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ratings';
  @override
  VerificationContext validateIntegrity(
    Insertable<RatingDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('filter')) {
      context.handle(
        _filterMeta,
        filter.isAcceptableOrUnknown(data['filter']!, _filterMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RatingDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RatingDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastModified: $RatingsTable.$converterlastModified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_modified'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      filter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter'],
      ),
      filterType: $RatingsTable.$converterfilterType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}filter_type'],
        )!,
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $RatingsTable createAlias(String alias) {
    return $RatingsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterlastModified =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<FilterType, String, String> $converterfilterType =
      const EnumNameConverter<FilterType>(FilterType.values);
}

class RatingDb extends DataClass implements Insertable<RatingDb> {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final String? filter;
  final FilterType filterType;
  final int orderIndex;
  const RatingDb({
    required this.id,
    required this.isDeleted,
    required this.lastModified,
    required this.name,
    this.notes,
    this.filter,
    required this.filterType,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_deleted'] = Variable<bool>(isDeleted);
    {
      map['last_modified'] = Variable<DateTime>(
        $RatingsTable.$converterlastModified.toSql(lastModified),
      );
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || filter != null) {
      map['filter'] = Variable<String>(filter);
    }
    {
      map['filter_type'] = Variable<String>(
        $RatingsTable.$converterfilterType.toSql(filterType),
      );
    }
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  RatingsCompanion toCompanion(bool nullToAbsent) {
    return RatingsCompanion(
      id: Value(id),
      isDeleted: Value(isDeleted),
      lastModified: Value(lastModified),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      filter: filter == null && nullToAbsent
          ? const Value.absent()
          : Value(filter),
      filterType: Value(filterType),
      orderIndex: Value(orderIndex),
    );
  }

  factory RatingDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RatingDb(
      id: serializer.fromJson<String>(json['id']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      filter: serializer.fromJson<String?>(json['filter']),
      filterType: $RatingsTable.$converterfilterType.fromJson(
        serializer.fromJson<String>(json['filterType']),
      ),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'filter': serializer.toJson<String?>(filter),
      'filterType': serializer.toJson<String>(
        $RatingsTable.$converterfilterType.toJson(filterType),
      ),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  RatingDb copyWith({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    String? name,
    Value<String?> notes = const Value.absent(),
    Value<String?> filter = const Value.absent(),
    FilterType? filterType,
    int? orderIndex,
  }) => RatingDb(
    id: id ?? this.id,
    isDeleted: isDeleted ?? this.isDeleted,
    lastModified: lastModified ?? this.lastModified,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    filter: filter.present ? filter.value : this.filter,
    filterType: filterType ?? this.filterType,
    orderIndex: orderIndex ?? this.orderIndex,
  );
  RatingDb copyWithCompanion(RatingsCompanion data) {
    return RatingDb(
      id: data.id.present ? data.id.value : this.id,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      filter: data.filter.present ? data.filter.value : this.filter,
      filterType: data.filterType.present
          ? data.filterType.value
          : this.filterType,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RatingDb(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('filter: $filter, ')
          ..write('filterType: $filterType, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isDeleted,
    lastModified,
    name,
    notes,
    filter,
    filterType,
    orderIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RatingDb &&
          other.id == this.id &&
          other.isDeleted == this.isDeleted &&
          other.lastModified == this.lastModified &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.filter == this.filter &&
          other.filterType == this.filterType &&
          other.orderIndex == this.orderIndex);
}

class RatingsCompanion extends UpdateCompanion<RatingDb> {
  final Value<String> id;
  final Value<bool> isDeleted;
  final Value<DateTime> lastModified;
  final Value<String> name;
  final Value<String?> notes;
  final Value<String?> filter;
  final Value<FilterType> filterType;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const RatingsCompanion({
    this.id = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.filter = const Value.absent(),
    this.filterType = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RatingsCompanion.insert({
    required String id,
    this.isDeleted = const Value.absent(),
    required DateTime lastModified,
    required String name,
    this.notes = const Value.absent(),
    this.filter = const Value.absent(),
    required FilterType filterType,
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lastModified = Value(lastModified),
       name = Value(name),
       filterType = Value(filterType);
  static Insertable<RatingDb> custom({
    Expression<String>? id,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastModified,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<String>? filter,
    Expression<String>? filterType,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastModified != null) 'last_modified': lastModified,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (filter != null) 'filter': filter,
      if (filterType != null) 'filter_type': filterType,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RatingsCompanion copyWith({
    Value<String>? id,
    Value<bool>? isDeleted,
    Value<DateTime>? lastModified,
    Value<String>? name,
    Value<String?>? notes,
    Value<String?>? filter,
    Value<FilterType>? filterType,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return RatingsCompanion(
      id: id ?? this.id,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      filter: filter ?? this.filter,
      filterType: filterType ?? this.filterType,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(
        $RatingsTable.$converterlastModified.toSql(lastModified.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (filter.present) {
      map['filter'] = Variable<String>(filter.value);
    }
    if (filterType.present) {
      map['filter_type'] = Variable<String>(
        $RatingsTable.$converterfilterType.toSql(filterType.value),
      );
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RatingsCompanion(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('filter: $filter, ')
          ..write('filterType: $filterType, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RatingMetricsTable extends RatingMetrics
    with TableInfo<$RatingMetricsTable, RatingMetricDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RatingMetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingIdMeta = const VerificationMeta(
    'ratingId',
  );
  @override
  late final GeneratedColumn<String> ratingId = GeneratedColumn<String>(
    'rating_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ratings (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AdjustmentType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AdjustmentType>($RatingMetricsTable.$convertertype);
  static const VerificationMeta _jsonPayloadMeta = const VerificationMeta(
    'jsonPayload',
  );
  @override
  late final GeneratedColumn<String> jsonPayload = GeneratedColumn<String>(
    'json_payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ratingId,
    orderIndex,
    weight,
    name,
    notes,
    unit,
    type,
    jsonPayload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rating_metrics';
  @override
  VerificationContext validateIntegrity(
    Insertable<RatingMetricDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rating_id')) {
      context.handle(
        _ratingIdMeta,
        ratingId.isAcceptableOrUnknown(data['rating_id']!, _ratingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('json_payload')) {
      context.handle(
        _jsonPayloadMeta,
        jsonPayload.isAcceptableOrUnknown(
          data['json_payload']!,
          _jsonPayloadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RatingMetricDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RatingMetricDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ratingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      type: $RatingMetricsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      jsonPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_payload'],
      ),
    );
  }

  @override
  $RatingMetricsTable createAlias(String alias) {
    return $RatingMetricsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AdjustmentType, String, String> $convertertype =
      const EnumNameConverter<AdjustmentType>(AdjustmentType.values);
}

class RatingMetricDb extends DataClass implements Insertable<RatingMetricDb> {
  final String id;
  final String ratingId;
  final int orderIndex;
  final double weight;
  final String name;
  final String? notes;
  final String? unit;
  final AdjustmentType type;
  final String? jsonPayload;
  const RatingMetricDb({
    required this.id,
    required this.ratingId,
    required this.orderIndex,
    required this.weight,
    required this.name,
    this.notes,
    this.unit,
    required this.type,
    this.jsonPayload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rating_id'] = Variable<String>(ratingId);
    map['order_index'] = Variable<int>(orderIndex);
    map['weight'] = Variable<double>(weight);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    {
      map['type'] = Variable<String>(
        $RatingMetricsTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || jsonPayload != null) {
      map['json_payload'] = Variable<String>(jsonPayload);
    }
    return map;
  }

  RatingMetricsCompanion toCompanion(bool nullToAbsent) {
    return RatingMetricsCompanion(
      id: Value(id),
      ratingId: Value(ratingId),
      orderIndex: Value(orderIndex),
      weight: Value(weight),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      type: Value(type),
      jsonPayload: jsonPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(jsonPayload),
    );
  }

  factory RatingMetricDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RatingMetricDb(
      id: serializer.fromJson<String>(json['id']),
      ratingId: serializer.fromJson<String>(json['ratingId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      weight: serializer.fromJson<double>(json['weight']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      unit: serializer.fromJson<String?>(json['unit']),
      type: $RatingMetricsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      jsonPayload: serializer.fromJson<String?>(json['jsonPayload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ratingId': serializer.toJson<String>(ratingId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'weight': serializer.toJson<double>(weight),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'unit': serializer.toJson<String?>(unit),
      'type': serializer.toJson<String>(
        $RatingMetricsTable.$convertertype.toJson(type),
      ),
      'jsonPayload': serializer.toJson<String?>(jsonPayload),
    };
  }

  RatingMetricDb copyWith({
    String? id,
    String? ratingId,
    int? orderIndex,
    double? weight,
    String? name,
    Value<String?> notes = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    AdjustmentType? type,
    Value<String?> jsonPayload = const Value.absent(),
  }) => RatingMetricDb(
    id: id ?? this.id,
    ratingId: ratingId ?? this.ratingId,
    orderIndex: orderIndex ?? this.orderIndex,
    weight: weight ?? this.weight,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    unit: unit.present ? unit.value : this.unit,
    type: type ?? this.type,
    jsonPayload: jsonPayload.present ? jsonPayload.value : this.jsonPayload,
  );
  RatingMetricDb copyWithCompanion(RatingMetricsCompanion data) {
    return RatingMetricDb(
      id: data.id.present ? data.id.value : this.id,
      ratingId: data.ratingId.present ? data.ratingId.value : this.ratingId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      weight: data.weight.present ? data.weight.value : this.weight,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      unit: data.unit.present ? data.unit.value : this.unit,
      type: data.type.present ? data.type.value : this.type,
      jsonPayload: data.jsonPayload.present
          ? data.jsonPayload.value
          : this.jsonPayload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RatingMetricDb(')
          ..write('id: $id, ')
          ..write('ratingId: $ratingId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('weight: $weight, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('unit: $unit, ')
          ..write('type: $type, ')
          ..write('jsonPayload: $jsonPayload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ratingId,
    orderIndex,
    weight,
    name,
    notes,
    unit,
    type,
    jsonPayload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RatingMetricDb &&
          other.id == this.id &&
          other.ratingId == this.ratingId &&
          other.orderIndex == this.orderIndex &&
          other.weight == this.weight &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.unit == this.unit &&
          other.type == this.type &&
          other.jsonPayload == this.jsonPayload);
}

class RatingMetricsCompanion extends UpdateCompanion<RatingMetricDb> {
  final Value<String> id;
  final Value<String> ratingId;
  final Value<int> orderIndex;
  final Value<double> weight;
  final Value<String> name;
  final Value<String?> notes;
  final Value<String?> unit;
  final Value<AdjustmentType> type;
  final Value<String?> jsonPayload;
  final Value<int> rowid;
  const RatingMetricsCompanion({
    this.id = const Value.absent(),
    this.ratingId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.weight = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.unit = const Value.absent(),
    this.type = const Value.absent(),
    this.jsonPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RatingMetricsCompanion.insert({
    required String id,
    required String ratingId,
    required int orderIndex,
    this.weight = const Value.absent(),
    required String name,
    this.notes = const Value.absent(),
    this.unit = const Value.absent(),
    required AdjustmentType type,
    this.jsonPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ratingId = Value(ratingId),
       orderIndex = Value(orderIndex),
       name = Value(name),
       type = Value(type);
  static Insertable<RatingMetricDb> custom({
    Expression<String>? id,
    Expression<String>? ratingId,
    Expression<int>? orderIndex,
    Expression<double>? weight,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<String>? unit,
    Expression<String>? type,
    Expression<String>? jsonPayload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ratingId != null) 'rating_id': ratingId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (weight != null) 'weight': weight,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (unit != null) 'unit': unit,
      if (type != null) 'type': type,
      if (jsonPayload != null) 'json_payload': jsonPayload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RatingMetricsCompanion copyWith({
    Value<String>? id,
    Value<String>? ratingId,
    Value<int>? orderIndex,
    Value<double>? weight,
    Value<String>? name,
    Value<String?>? notes,
    Value<String?>? unit,
    Value<AdjustmentType>? type,
    Value<String?>? jsonPayload,
    Value<int>? rowid,
  }) {
    return RatingMetricsCompanion(
      id: id ?? this.id,
      ratingId: ratingId ?? this.ratingId,
      orderIndex: orderIndex ?? this.orderIndex,
      weight: weight ?? this.weight,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      jsonPayload: jsonPayload ?? this.jsonPayload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ratingId.present) {
      map['rating_id'] = Variable<String>(ratingId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $RatingMetricsTable.$convertertype.toSql(type.value),
      );
    }
    if (jsonPayload.present) {
      map['json_payload'] = Variable<String>(jsonPayload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RatingMetricsCompanion(')
          ..write('id: $id, ')
          ..write('ratingId: $ratingId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('weight: $weight, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('unit: $unit, ')
          ..write('type: $type, ')
          ..write('jsonPayload: $jsonPayload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RatingEntriesTable extends RatingEntries
    with TableInfo<$RatingEntriesTable, RatingEntryDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RatingEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bikeIdMeta = const VerificationMeta('bikeId');
  @override
  late final GeneratedColumn<String> bikeId = GeneratedColumn<String>(
    'bike_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bikes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _setupIdMeta = const VerificationMeta(
    'setupId',
  );
  @override
  late final GeneratedColumn<String> setupId = GeneratedColumn<String>(
    'setup_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES setups (id)',
    ),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> lastModified =
      GeneratedColumn<DateTime>(
        'last_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RatingEntriesTable.$converterlastModified);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> dateTimeUTC =
      GeneratedColumn<DateTime>(
        'date_time_u_t_c',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RatingEntriesTable.$converterdateTimeUTC);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime>
  dateTimeLocal = GeneratedColumn<DateTime>(
    'date_time_local',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($RatingEntriesTable.$converterdateTimeLocal);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ContextPosition?, String>
  position = GeneratedColumn<String>(
    'position',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ContextPosition?>($RatingEntriesTable.$converterpositionn);
  @override
  late final GeneratedColumnWithTypeConverter<geo.Placemark?, String> place =
      GeneratedColumn<String>(
        'place',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<geo.Placemark?>($RatingEntriesTable.$converterplacen);
  @override
  late final GeneratedColumnWithTypeConverter<ContextWeather?, String> weather =
      GeneratedColumn<String>(
        'weather',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ContextWeather?>($RatingEntriesTable.$converterweathern);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bikeId,
    setupId,
    isDeleted,
    lastModified,
    name,
    dateTimeUTC,
    dateTimeLocal,
    notes,
    position,
    place,
    weather,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rating_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<RatingEntryDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bike_id')) {
      context.handle(
        _bikeIdMeta,
        bikeId.isAcceptableOrUnknown(data['bike_id']!, _bikeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bikeIdMeta);
    }
    if (data.containsKey('setup_id')) {
      context.handle(
        _setupIdMeta,
        setupId.isAcceptableOrUnknown(data['setup_id']!, _setupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setupIdMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RatingEntryDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RatingEntryDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bikeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bike_id'],
      )!,
      setupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setup_id'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastModified: $RatingEntriesTable.$converterlastModified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_modified'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      dateTimeUTC: $RatingEntriesTable.$converterdateTimeUTC.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}date_time_u_t_c'],
        )!,
      ),
      dateTimeLocal: $RatingEntriesTable.$converterdateTimeLocal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}date_time_local'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      position: $RatingEntriesTable.$converterpositionn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}position'],
        ),
      ),
      place: $RatingEntriesTable.$converterplacen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}place'],
        ),
      ),
      weather: $RatingEntriesTable.$converterweathern.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}weather'],
        ),
      ),
    );
  }

  @override
  $RatingEntriesTable createAlias(String alias) {
    return $RatingEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterlastModified =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterdateTimeUTC =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterdateTimeLocal =
      const LocalFloatingDateTimeConverter();
  static TypeConverter<ContextPosition, String> $converterposition =
      const ContextPositionConverter();
  static TypeConverter<ContextPosition?, String?> $converterpositionn =
      NullAwareTypeConverter.wrap($converterposition);
  static TypeConverter<geo.Placemark, String> $converterplace =
      const PlacemarkConverter();
  static TypeConverter<geo.Placemark?, String?> $converterplacen =
      NullAwareTypeConverter.wrap($converterplace);
  static TypeConverter<ContextWeather, String> $converterweather =
      const WeatherConverter();
  static TypeConverter<ContextWeather?, String?> $converterweathern =
      NullAwareTypeConverter.wrap($converterweather);
}

class RatingEntryDb extends DataClass implements Insertable<RatingEntryDb> {
  final String id;
  final String bikeId;
  final String setupId;
  final bool isDeleted;
  final DateTime lastModified;
  final String? name;
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;
  final String? notes;
  final ContextPosition? position;
  final geo.Placemark? place;
  final ContextWeather? weather;
  const RatingEntryDb({
    required this.id,
    required this.bikeId,
    required this.setupId,
    required this.isDeleted,
    required this.lastModified,
    this.name,
    required this.dateTimeUTC,
    required this.dateTimeLocal,
    this.notes,
    this.position,
    this.place,
    this.weather,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bike_id'] = Variable<String>(bikeId);
    map['setup_id'] = Variable<String>(setupId);
    map['is_deleted'] = Variable<bool>(isDeleted);
    {
      map['last_modified'] = Variable<DateTime>(
        $RatingEntriesTable.$converterlastModified.toSql(lastModified),
      );
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    {
      map['date_time_u_t_c'] = Variable<DateTime>(
        $RatingEntriesTable.$converterdateTimeUTC.toSql(dateTimeUTC),
      );
    }
    {
      map['date_time_local'] = Variable<DateTime>(
        $RatingEntriesTable.$converterdateTimeLocal.toSql(dateTimeLocal),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<String>(
        $RatingEntriesTable.$converterpositionn.toSql(position),
      );
    }
    if (!nullToAbsent || place != null) {
      map['place'] = Variable<String>(
        $RatingEntriesTable.$converterplacen.toSql(place),
      );
    }
    if (!nullToAbsent || weather != null) {
      map['weather'] = Variable<String>(
        $RatingEntriesTable.$converterweathern.toSql(weather),
      );
    }
    return map;
  }

  RatingEntriesCompanion toCompanion(bool nullToAbsent) {
    return RatingEntriesCompanion(
      id: Value(id),
      bikeId: Value(bikeId),
      setupId: Value(setupId),
      isDeleted: Value(isDeleted),
      lastModified: Value(lastModified),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      dateTimeUTC: Value(dateTimeUTC),
      dateTimeLocal: Value(dateTimeLocal),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
      place: place == null && nullToAbsent
          ? const Value.absent()
          : Value(place),
      weather: weather == null && nullToAbsent
          ? const Value.absent()
          : Value(weather),
    );
  }

  factory RatingEntryDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RatingEntryDb(
      id: serializer.fromJson<String>(json['id']),
      bikeId: serializer.fromJson<String>(json['bikeId']),
      setupId: serializer.fromJson<String>(json['setupId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      name: serializer.fromJson<String?>(json['name']),
      dateTimeUTC: serializer.fromJson<DateTime>(json['dateTimeUTC']),
      dateTimeLocal: serializer.fromJson<DateTime>(json['dateTimeLocal']),
      notes: serializer.fromJson<String?>(json['notes']),
      position: serializer.fromJson<ContextPosition?>(json['position']),
      place: serializer.fromJson<geo.Placemark?>(json['place']),
      weather: serializer.fromJson<ContextWeather?>(json['weather']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bikeId': serializer.toJson<String>(bikeId),
      'setupId': serializer.toJson<String>(setupId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'name': serializer.toJson<String?>(name),
      'dateTimeUTC': serializer.toJson<DateTime>(dateTimeUTC),
      'dateTimeLocal': serializer.toJson<DateTime>(dateTimeLocal),
      'notes': serializer.toJson<String?>(notes),
      'position': serializer.toJson<ContextPosition?>(position),
      'place': serializer.toJson<geo.Placemark?>(place),
      'weather': serializer.toJson<ContextWeather?>(weather),
    };
  }

  RatingEntryDb copyWith({
    String? id,
    String? bikeId,
    String? setupId,
    bool? isDeleted,
    DateTime? lastModified,
    Value<String?> name = const Value.absent(),
    DateTime? dateTimeUTC,
    DateTime? dateTimeLocal,
    Value<String?> notes = const Value.absent(),
    Value<ContextPosition?> position = const Value.absent(),
    Value<geo.Placemark?> place = const Value.absent(),
    Value<ContextWeather?> weather = const Value.absent(),
  }) => RatingEntryDb(
    id: id ?? this.id,
    bikeId: bikeId ?? this.bikeId,
    setupId: setupId ?? this.setupId,
    isDeleted: isDeleted ?? this.isDeleted,
    lastModified: lastModified ?? this.lastModified,
    name: name.present ? name.value : this.name,
    dateTimeUTC: dateTimeUTC ?? this.dateTimeUTC,
    dateTimeLocal: dateTimeLocal ?? this.dateTimeLocal,
    notes: notes.present ? notes.value : this.notes,
    position: position.present ? position.value : this.position,
    place: place.present ? place.value : this.place,
    weather: weather.present ? weather.value : this.weather,
  );
  RatingEntryDb copyWithCompanion(RatingEntriesCompanion data) {
    return RatingEntryDb(
      id: data.id.present ? data.id.value : this.id,
      bikeId: data.bikeId.present ? data.bikeId.value : this.bikeId,
      setupId: data.setupId.present ? data.setupId.value : this.setupId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      name: data.name.present ? data.name.value : this.name,
      dateTimeUTC: data.dateTimeUTC.present
          ? data.dateTimeUTC.value
          : this.dateTimeUTC,
      dateTimeLocal: data.dateTimeLocal.present
          ? data.dateTimeLocal.value
          : this.dateTimeLocal,
      notes: data.notes.present ? data.notes.value : this.notes,
      position: data.position.present ? data.position.value : this.position,
      place: data.place.present ? data.place.value : this.place,
      weather: data.weather.present ? data.weather.value : this.weather,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RatingEntryDb(')
          ..write('id: $id, ')
          ..write('bikeId: $bikeId, ')
          ..write('setupId: $setupId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('dateTimeUTC: $dateTimeUTC, ')
          ..write('dateTimeLocal: $dateTimeLocal, ')
          ..write('notes: $notes, ')
          ..write('position: $position, ')
          ..write('place: $place, ')
          ..write('weather: $weather')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bikeId,
    setupId,
    isDeleted,
    lastModified,
    name,
    dateTimeUTC,
    dateTimeLocal,
    notes,
    position,
    place,
    weather,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RatingEntryDb &&
          other.id == this.id &&
          other.bikeId == this.bikeId &&
          other.setupId == this.setupId &&
          other.isDeleted == this.isDeleted &&
          other.lastModified == this.lastModified &&
          other.name == this.name &&
          other.dateTimeUTC == this.dateTimeUTC &&
          other.dateTimeLocal == this.dateTimeLocal &&
          other.notes == this.notes &&
          other.position == this.position &&
          other.place == this.place &&
          other.weather == this.weather);
}

class RatingEntriesCompanion extends UpdateCompanion<RatingEntryDb> {
  final Value<String> id;
  final Value<String> bikeId;
  final Value<String> setupId;
  final Value<bool> isDeleted;
  final Value<DateTime> lastModified;
  final Value<String?> name;
  final Value<DateTime> dateTimeUTC;
  final Value<DateTime> dateTimeLocal;
  final Value<String?> notes;
  final Value<ContextPosition?> position;
  final Value<geo.Placemark?> place;
  final Value<ContextWeather?> weather;
  final Value<int> rowid;
  const RatingEntriesCompanion({
    this.id = const Value.absent(),
    this.bikeId = const Value.absent(),
    this.setupId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.name = const Value.absent(),
    this.dateTimeUTC = const Value.absent(),
    this.dateTimeLocal = const Value.absent(),
    this.notes = const Value.absent(),
    this.position = const Value.absent(),
    this.place = const Value.absent(),
    this.weather = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RatingEntriesCompanion.insert({
    required String id,
    required String bikeId,
    required String setupId,
    this.isDeleted = const Value.absent(),
    required DateTime lastModified,
    this.name = const Value.absent(),
    required DateTime dateTimeUTC,
    required DateTime dateTimeLocal,
    this.notes = const Value.absent(),
    this.position = const Value.absent(),
    this.place = const Value.absent(),
    this.weather = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bikeId = Value(bikeId),
       setupId = Value(setupId),
       lastModified = Value(lastModified),
       dateTimeUTC = Value(dateTimeUTC),
       dateTimeLocal = Value(dateTimeLocal);
  static Insertable<RatingEntryDb> custom({
    Expression<String>? id,
    Expression<String>? bikeId,
    Expression<String>? setupId,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastModified,
    Expression<String>? name,
    Expression<DateTime>? dateTimeUTC,
    Expression<DateTime>? dateTimeLocal,
    Expression<String>? notes,
    Expression<String>? position,
    Expression<String>? place,
    Expression<String>? weather,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bikeId != null) 'bike_id': bikeId,
      if (setupId != null) 'setup_id': setupId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastModified != null) 'last_modified': lastModified,
      if (name != null) 'name': name,
      if (dateTimeUTC != null) 'date_time_u_t_c': dateTimeUTC,
      if (dateTimeLocal != null) 'date_time_local': dateTimeLocal,
      if (notes != null) 'notes': notes,
      if (position != null) 'position': position,
      if (place != null) 'place': place,
      if (weather != null) 'weather': weather,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RatingEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? bikeId,
    Value<String>? setupId,
    Value<bool>? isDeleted,
    Value<DateTime>? lastModified,
    Value<String?>? name,
    Value<DateTime>? dateTimeUTC,
    Value<DateTime>? dateTimeLocal,
    Value<String?>? notes,
    Value<ContextPosition?>? position,
    Value<geo.Placemark?>? place,
    Value<ContextWeather?>? weather,
    Value<int>? rowid,
  }) {
    return RatingEntriesCompanion(
      id: id ?? this.id,
      bikeId: bikeId ?? this.bikeId,
      setupId: setupId ?? this.setupId,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
      name: name ?? this.name,
      dateTimeUTC: dateTimeUTC ?? this.dateTimeUTC,
      dateTimeLocal: dateTimeLocal ?? this.dateTimeLocal,
      notes: notes ?? this.notes,
      position: position ?? this.position,
      place: place ?? this.place,
      weather: weather ?? this.weather,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bikeId.present) {
      map['bike_id'] = Variable<String>(bikeId.value);
    }
    if (setupId.present) {
      map['setup_id'] = Variable<String>(setupId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(
        $RatingEntriesTable.$converterlastModified.toSql(lastModified.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dateTimeUTC.present) {
      map['date_time_u_t_c'] = Variable<DateTime>(
        $RatingEntriesTable.$converterdateTimeUTC.toSql(dateTimeUTC.value),
      );
    }
    if (dateTimeLocal.present) {
      map['date_time_local'] = Variable<DateTime>(
        $RatingEntriesTable.$converterdateTimeLocal.toSql(dateTimeLocal.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(
        $RatingEntriesTable.$converterpositionn.toSql(position.value),
      );
    }
    if (place.present) {
      map['place'] = Variable<String>(
        $RatingEntriesTable.$converterplacen.toSql(place.value),
      );
    }
    if (weather.present) {
      map['weather'] = Variable<String>(
        $RatingEntriesTable.$converterweathern.toSql(weather.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RatingEntriesCompanion(')
          ..write('id: $id, ')
          ..write('bikeId: $bikeId, ')
          ..write('setupId: $setupId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('dateTimeUTC: $dateTimeUTC, ')
          ..write('dateTimeLocal: $dateTimeLocal, ')
          ..write('notes: $notes, ')
          ..write('position: $position, ')
          ..write('place: $place, ')
          ..write('weather: $weather, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RatingEntryValuesTable extends RatingEntryValues
    with TableInfo<$RatingEntryValuesTable, RatingEntryValueDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RatingEntryValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ratingEntryIdMeta = const VerificationMeta(
    'ratingEntryId',
  );
  @override
  late final GeneratedColumn<String> ratingEntryId = GeneratedColumn<String>(
    'rating_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rating_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ratingMetricIdMeta = const VerificationMeta(
    'ratingMetricId',
  );
  @override
  late final GeneratedColumn<String> ratingMetricId = GeneratedColumn<String>(
    'rating_metric_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rating_metrics (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [ratingEntryId, ratingMetricId, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rating_entry_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<RatingEntryValueDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rating_entry_id')) {
      context.handle(
        _ratingEntryIdMeta,
        ratingEntryId.isAcceptableOrUnknown(
          data['rating_entry_id']!,
          _ratingEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ratingEntryIdMeta);
    }
    if (data.containsKey('rating_metric_id')) {
      context.handle(
        _ratingMetricIdMeta,
        ratingMetricId.isAcceptableOrUnknown(
          data['rating_metric_id']!,
          _ratingMetricIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ratingMetricIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {ratingEntryId, ratingMetricId};
  @override
  RatingEntryValueDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RatingEntryValueDb(
      ratingEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating_entry_id'],
      )!,
      ratingMetricId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating_metric_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $RatingEntryValuesTable createAlias(String alias) {
    return $RatingEntryValuesTable(attachedDatabase, alias);
  }
}

class RatingEntryValueDb extends DataClass
    implements Insertable<RatingEntryValueDb> {
  final String ratingEntryId;
  final String ratingMetricId;
  final String value;
  const RatingEntryValueDb({
    required this.ratingEntryId,
    required this.ratingMetricId,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['rating_entry_id'] = Variable<String>(ratingEntryId);
    map['rating_metric_id'] = Variable<String>(ratingMetricId);
    map['value'] = Variable<String>(value);
    return map;
  }

  RatingEntryValuesCompanion toCompanion(bool nullToAbsent) {
    return RatingEntryValuesCompanion(
      ratingEntryId: Value(ratingEntryId),
      ratingMetricId: Value(ratingMetricId),
      value: Value(value),
    );
  }

  factory RatingEntryValueDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RatingEntryValueDb(
      ratingEntryId: serializer.fromJson<String>(json['ratingEntryId']),
      ratingMetricId: serializer.fromJson<String>(json['ratingMetricId']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ratingEntryId': serializer.toJson<String>(ratingEntryId),
      'ratingMetricId': serializer.toJson<String>(ratingMetricId),
      'value': serializer.toJson<String>(value),
    };
  }

  RatingEntryValueDb copyWith({
    String? ratingEntryId,
    String? ratingMetricId,
    String? value,
  }) => RatingEntryValueDb(
    ratingEntryId: ratingEntryId ?? this.ratingEntryId,
    ratingMetricId: ratingMetricId ?? this.ratingMetricId,
    value: value ?? this.value,
  );
  RatingEntryValueDb copyWithCompanion(RatingEntryValuesCompanion data) {
    return RatingEntryValueDb(
      ratingEntryId: data.ratingEntryId.present
          ? data.ratingEntryId.value
          : this.ratingEntryId,
      ratingMetricId: data.ratingMetricId.present
          ? data.ratingMetricId.value
          : this.ratingMetricId,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RatingEntryValueDb(')
          ..write('ratingEntryId: $ratingEntryId, ')
          ..write('ratingMetricId: $ratingMetricId, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ratingEntryId, ratingMetricId, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RatingEntryValueDb &&
          other.ratingEntryId == this.ratingEntryId &&
          other.ratingMetricId == this.ratingMetricId &&
          other.value == this.value);
}

class RatingEntryValuesCompanion extends UpdateCompanion<RatingEntryValueDb> {
  final Value<String> ratingEntryId;
  final Value<String> ratingMetricId;
  final Value<String> value;
  final Value<int> rowid;
  const RatingEntryValuesCompanion({
    this.ratingEntryId = const Value.absent(),
    this.ratingMetricId = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RatingEntryValuesCompanion.insert({
    required String ratingEntryId,
    required String ratingMetricId,
    required String value,
    this.rowid = const Value.absent(),
  }) : ratingEntryId = Value(ratingEntryId),
       ratingMetricId = Value(ratingMetricId),
       value = Value(value);
  static Insertable<RatingEntryValueDb> custom({
    Expression<String>? ratingEntryId,
    Expression<String>? ratingMetricId,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ratingEntryId != null) 'rating_entry_id': ratingEntryId,
      if (ratingMetricId != null) 'rating_metric_id': ratingMetricId,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RatingEntryValuesCompanion copyWith({
    Value<String>? ratingEntryId,
    Value<String>? ratingMetricId,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return RatingEntryValuesCompanion(
      ratingEntryId: ratingEntryId ?? this.ratingEntryId,
      ratingMetricId: ratingMetricId ?? this.ratingMetricId,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ratingEntryId.present) {
      map['rating_entry_id'] = Variable<String>(ratingEntryId.value);
    }
    if (ratingMetricId.present) {
      map['rating_metric_id'] = Variable<String>(ratingMetricId.value);
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
    return (StringBuffer('RatingEntryValuesCompanion(')
          ..write('ratingEntryId: $ratingEntryId, ')
          ..write('ratingMetricId: $ratingMetricId, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StravaActivitiesTable extends StravaActivities
    with TableInfo<$StravaActivitiesTable, StravaActivityDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StravaActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> lastModified =
      GeneratedColumn<DateTime>(
        'last_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($StravaActivitiesTable.$converterlastModified);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _athleteMeta = const VerificationMeta(
    'athlete',
  );
  @override
  late final GeneratedColumn<int> athlete = GeneratedColumn<int>(
    'athlete',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SportType, String> sportType =
      GeneratedColumn<String>(
        'sport_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SportType>($StravaActivitiesTable.$convertersportType);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> startDate =
      GeneratedColumn<DateTime>(
        'start_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($StravaActivitiesTable.$converterstartDate);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime>
  startDateLocal = GeneratedColumn<DateTime>(
    'start_date_local',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($StravaActivitiesTable.$converterstartDateLocal);
  static const VerificationMeta _gearIdMeta = const VerificationMeta('gearId');
  @override
  late final GeneratedColumn<String> gearId = GeneratedColumn<String>(
    'gear_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startLatMeta = const VerificationMeta(
    'startLat',
  );
  @override
  late final GeneratedColumn<double> startLat = GeneratedColumn<double>(
    'start_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startLonMeta = const VerificationMeta(
    'startLon',
  );
  @override
  late final GeneratedColumn<double> startLon = GeneratedColumn<double>(
    'start_lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalElevationGainMeta =
      const VerificationMeta('totalElevationGain');
  @override
  late final GeneratedColumn<double> totalElevationGain =
      GeneratedColumn<double>(
        'total_elevation_gain',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _movingTimeMeta = const VerificationMeta(
    'movingTime',
  );
  @override
  late final GeneratedColumn<int> movingTime = GeneratedColumn<int>(
    'moving_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedTimeMeta = const VerificationMeta(
    'elapsedTime',
  );
  @override
  late final GeneratedColumn<int> elapsedTime = GeneratedColumn<int>(
    'elapsed_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutTypeMeta = const VerificationMeta(
    'workoutType',
  );
  @override
  late final GeneratedColumn<int> workoutType = GeneratedColumn<int>(
    'workout_type',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lastModified,
    name,
    athlete,
    sportType,
    startDate,
    startDateLocal,
    gearId,
    startLat,
    startLon,
    distance,
    totalElevationGain,
    movingTime,
    elapsedTime,
    workoutType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strava_activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<StravaActivityDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('athlete')) {
      context.handle(
        _athleteMeta,
        athlete.isAcceptableOrUnknown(data['athlete']!, _athleteMeta),
      );
    } else if (isInserting) {
      context.missing(_athleteMeta);
    }
    if (data.containsKey('gear_id')) {
      context.handle(
        _gearIdMeta,
        gearId.isAcceptableOrUnknown(data['gear_id']!, _gearIdMeta),
      );
    }
    if (data.containsKey('start_lat')) {
      context.handle(
        _startLatMeta,
        startLat.isAcceptableOrUnknown(data['start_lat']!, _startLatMeta),
      );
    }
    if (data.containsKey('start_lon')) {
      context.handle(
        _startLonMeta,
        startLon.isAcceptableOrUnknown(data['start_lon']!, _startLonMeta),
      );
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    }
    if (data.containsKey('total_elevation_gain')) {
      context.handle(
        _totalElevationGainMeta,
        totalElevationGain.isAcceptableOrUnknown(
          data['total_elevation_gain']!,
          _totalElevationGainMeta,
        ),
      );
    }
    if (data.containsKey('moving_time')) {
      context.handle(
        _movingTimeMeta,
        movingTime.isAcceptableOrUnknown(data['moving_time']!, _movingTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_movingTimeMeta);
    }
    if (data.containsKey('elapsed_time')) {
      context.handle(
        _elapsedTimeMeta,
        elapsedTime.isAcceptableOrUnknown(
          data['elapsed_time']!,
          _elapsedTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elapsedTimeMeta);
    }
    if (data.containsKey('workout_type')) {
      context.handle(
        _workoutTypeMeta,
        workoutType.isAcceptableOrUnknown(
          data['workout_type']!,
          _workoutTypeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StravaActivityDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StravaActivityDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lastModified: $StravaActivitiesTable.$converterlastModified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_modified'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      athlete: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}athlete'],
      )!,
      sportType: $StravaActivitiesTable.$convertersportType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sport_type'],
        )!,
      ),
      startDate: $StravaActivitiesTable.$converterstartDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}start_date'],
        )!,
      ),
      startDateLocal: $StravaActivitiesTable.$converterstartDateLocal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}start_date_local'],
        )!,
      ),
      gearId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gear_id'],
      ),
      startLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_lat'],
      ),
      startLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_lon'],
      ),
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      ),
      totalElevationGain: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_elevation_gain'],
      ),
      movingTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_time'],
      )!,
      elapsedTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_time'],
      )!,
      workoutType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_type'],
      ),
    );
  }

  @override
  $StravaActivitiesTable createAlias(String alias) {
    return $StravaActivitiesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterlastModified =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<SportType, String, String> $convertersportType =
      const EnumNameConverter<SportType>(SportType.values);
  static TypeConverter<DateTime, DateTime> $converterstartDate =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterstartDateLocal =
      const LocalFloatingDateTimeConverter();
}

class StravaActivityDb extends DataClass
    implements Insertable<StravaActivityDb> {
  final int id;
  final DateTime lastModified;
  final String name;
  final int athlete;
  final SportType sportType;
  final DateTime startDate;
  final DateTime startDateLocal;
  final String? gearId;
  final double? startLat;
  final double? startLon;
  final double? distance;
  final double? totalElevationGain;
  final int movingTime;
  final int elapsedTime;
  final int? workoutType;
  const StravaActivityDb({
    required this.id,
    required this.lastModified,
    required this.name,
    required this.athlete,
    required this.sportType,
    required this.startDate,
    required this.startDateLocal,
    this.gearId,
    this.startLat,
    this.startLon,
    this.distance,
    this.totalElevationGain,
    required this.movingTime,
    required this.elapsedTime,
    this.workoutType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['last_modified'] = Variable<DateTime>(
        $StravaActivitiesTable.$converterlastModified.toSql(lastModified),
      );
    }
    map['name'] = Variable<String>(name);
    map['athlete'] = Variable<int>(athlete);
    {
      map['sport_type'] = Variable<String>(
        $StravaActivitiesTable.$convertersportType.toSql(sportType),
      );
    }
    {
      map['start_date'] = Variable<DateTime>(
        $StravaActivitiesTable.$converterstartDate.toSql(startDate),
      );
    }
    {
      map['start_date_local'] = Variable<DateTime>(
        $StravaActivitiesTable.$converterstartDateLocal.toSql(startDateLocal),
      );
    }
    if (!nullToAbsent || gearId != null) {
      map['gear_id'] = Variable<String>(gearId);
    }
    if (!nullToAbsent || startLat != null) {
      map['start_lat'] = Variable<double>(startLat);
    }
    if (!nullToAbsent || startLon != null) {
      map['start_lon'] = Variable<double>(startLon);
    }
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    if (!nullToAbsent || totalElevationGain != null) {
      map['total_elevation_gain'] = Variable<double>(totalElevationGain);
    }
    map['moving_time'] = Variable<int>(movingTime);
    map['elapsed_time'] = Variable<int>(elapsedTime);
    if (!nullToAbsent || workoutType != null) {
      map['workout_type'] = Variable<int>(workoutType);
    }
    return map;
  }

  StravaActivitiesCompanion toCompanion(bool nullToAbsent) {
    return StravaActivitiesCompanion(
      id: Value(id),
      lastModified: Value(lastModified),
      name: Value(name),
      athlete: Value(athlete),
      sportType: Value(sportType),
      startDate: Value(startDate),
      startDateLocal: Value(startDateLocal),
      gearId: gearId == null && nullToAbsent
          ? const Value.absent()
          : Value(gearId),
      startLat: startLat == null && nullToAbsent
          ? const Value.absent()
          : Value(startLat),
      startLon: startLon == null && nullToAbsent
          ? const Value.absent()
          : Value(startLon),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
      totalElevationGain: totalElevationGain == null && nullToAbsent
          ? const Value.absent()
          : Value(totalElevationGain),
      movingTime: Value(movingTime),
      elapsedTime: Value(elapsedTime),
      workoutType: workoutType == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutType),
    );
  }

  factory StravaActivityDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StravaActivityDb(
      id: serializer.fromJson<int>(json['id']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      name: serializer.fromJson<String>(json['name']),
      athlete: serializer.fromJson<int>(json['athlete']),
      sportType: $StravaActivitiesTable.$convertersportType.fromJson(
        serializer.fromJson<String>(json['sportType']),
      ),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      startDateLocal: serializer.fromJson<DateTime>(json['startDateLocal']),
      gearId: serializer.fromJson<String?>(json['gearId']),
      startLat: serializer.fromJson<double?>(json['startLat']),
      startLon: serializer.fromJson<double?>(json['startLon']),
      distance: serializer.fromJson<double?>(json['distance']),
      totalElevationGain: serializer.fromJson<double?>(
        json['totalElevationGain'],
      ),
      movingTime: serializer.fromJson<int>(json['movingTime']),
      elapsedTime: serializer.fromJson<int>(json['elapsedTime']),
      workoutType: serializer.fromJson<int?>(json['workoutType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'name': serializer.toJson<String>(name),
      'athlete': serializer.toJson<int>(athlete),
      'sportType': serializer.toJson<String>(
        $StravaActivitiesTable.$convertersportType.toJson(sportType),
      ),
      'startDate': serializer.toJson<DateTime>(startDate),
      'startDateLocal': serializer.toJson<DateTime>(startDateLocal),
      'gearId': serializer.toJson<String?>(gearId),
      'startLat': serializer.toJson<double?>(startLat),
      'startLon': serializer.toJson<double?>(startLon),
      'distance': serializer.toJson<double?>(distance),
      'totalElevationGain': serializer.toJson<double?>(totalElevationGain),
      'movingTime': serializer.toJson<int>(movingTime),
      'elapsedTime': serializer.toJson<int>(elapsedTime),
      'workoutType': serializer.toJson<int?>(workoutType),
    };
  }

  StravaActivityDb copyWith({
    int? id,
    DateTime? lastModified,
    String? name,
    int? athlete,
    SportType? sportType,
    DateTime? startDate,
    DateTime? startDateLocal,
    Value<String?> gearId = const Value.absent(),
    Value<double?> startLat = const Value.absent(),
    Value<double?> startLon = const Value.absent(),
    Value<double?> distance = const Value.absent(),
    Value<double?> totalElevationGain = const Value.absent(),
    int? movingTime,
    int? elapsedTime,
    Value<int?> workoutType = const Value.absent(),
  }) => StravaActivityDb(
    id: id ?? this.id,
    lastModified: lastModified ?? this.lastModified,
    name: name ?? this.name,
    athlete: athlete ?? this.athlete,
    sportType: sportType ?? this.sportType,
    startDate: startDate ?? this.startDate,
    startDateLocal: startDateLocal ?? this.startDateLocal,
    gearId: gearId.present ? gearId.value : this.gearId,
    startLat: startLat.present ? startLat.value : this.startLat,
    startLon: startLon.present ? startLon.value : this.startLon,
    distance: distance.present ? distance.value : this.distance,
    totalElevationGain: totalElevationGain.present
        ? totalElevationGain.value
        : this.totalElevationGain,
    movingTime: movingTime ?? this.movingTime,
    elapsedTime: elapsedTime ?? this.elapsedTime,
    workoutType: workoutType.present ? workoutType.value : this.workoutType,
  );
  StravaActivityDb copyWithCompanion(StravaActivitiesCompanion data) {
    return StravaActivityDb(
      id: data.id.present ? data.id.value : this.id,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      name: data.name.present ? data.name.value : this.name,
      athlete: data.athlete.present ? data.athlete.value : this.athlete,
      sportType: data.sportType.present ? data.sportType.value : this.sportType,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      startDateLocal: data.startDateLocal.present
          ? data.startDateLocal.value
          : this.startDateLocal,
      gearId: data.gearId.present ? data.gearId.value : this.gearId,
      startLat: data.startLat.present ? data.startLat.value : this.startLat,
      startLon: data.startLon.present ? data.startLon.value : this.startLon,
      distance: data.distance.present ? data.distance.value : this.distance,
      totalElevationGain: data.totalElevationGain.present
          ? data.totalElevationGain.value
          : this.totalElevationGain,
      movingTime: data.movingTime.present
          ? data.movingTime.value
          : this.movingTime,
      elapsedTime: data.elapsedTime.present
          ? data.elapsedTime.value
          : this.elapsedTime,
      workoutType: data.workoutType.present
          ? data.workoutType.value
          : this.workoutType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StravaActivityDb(')
          ..write('id: $id, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('athlete: $athlete, ')
          ..write('sportType: $sportType, ')
          ..write('startDate: $startDate, ')
          ..write('startDateLocal: $startDateLocal, ')
          ..write('gearId: $gearId, ')
          ..write('startLat: $startLat, ')
          ..write('startLon: $startLon, ')
          ..write('distance: $distance, ')
          ..write('totalElevationGain: $totalElevationGain, ')
          ..write('movingTime: $movingTime, ')
          ..write('elapsedTime: $elapsedTime, ')
          ..write('workoutType: $workoutType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lastModified,
    name,
    athlete,
    sportType,
    startDate,
    startDateLocal,
    gearId,
    startLat,
    startLon,
    distance,
    totalElevationGain,
    movingTime,
    elapsedTime,
    workoutType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StravaActivityDb &&
          other.id == this.id &&
          other.lastModified == this.lastModified &&
          other.name == this.name &&
          other.athlete == this.athlete &&
          other.sportType == this.sportType &&
          other.startDate == this.startDate &&
          other.startDateLocal == this.startDateLocal &&
          other.gearId == this.gearId &&
          other.startLat == this.startLat &&
          other.startLon == this.startLon &&
          other.distance == this.distance &&
          other.totalElevationGain == this.totalElevationGain &&
          other.movingTime == this.movingTime &&
          other.elapsedTime == this.elapsedTime &&
          other.workoutType == this.workoutType);
}

class StravaActivitiesCompanion extends UpdateCompanion<StravaActivityDb> {
  final Value<int> id;
  final Value<DateTime> lastModified;
  final Value<String> name;
  final Value<int> athlete;
  final Value<SportType> sportType;
  final Value<DateTime> startDate;
  final Value<DateTime> startDateLocal;
  final Value<String?> gearId;
  final Value<double?> startLat;
  final Value<double?> startLon;
  final Value<double?> distance;
  final Value<double?> totalElevationGain;
  final Value<int> movingTime;
  final Value<int> elapsedTime;
  final Value<int?> workoutType;
  const StravaActivitiesCompanion({
    this.id = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.name = const Value.absent(),
    this.athlete = const Value.absent(),
    this.sportType = const Value.absent(),
    this.startDate = const Value.absent(),
    this.startDateLocal = const Value.absent(),
    this.gearId = const Value.absent(),
    this.startLat = const Value.absent(),
    this.startLon = const Value.absent(),
    this.distance = const Value.absent(),
    this.totalElevationGain = const Value.absent(),
    this.movingTime = const Value.absent(),
    this.elapsedTime = const Value.absent(),
    this.workoutType = const Value.absent(),
  });
  StravaActivitiesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime lastModified,
    required String name,
    required int athlete,
    required SportType sportType,
    required DateTime startDate,
    required DateTime startDateLocal,
    this.gearId = const Value.absent(),
    this.startLat = const Value.absent(),
    this.startLon = const Value.absent(),
    this.distance = const Value.absent(),
    this.totalElevationGain = const Value.absent(),
    required int movingTime,
    required int elapsedTime,
    this.workoutType = const Value.absent(),
  }) : lastModified = Value(lastModified),
       name = Value(name),
       athlete = Value(athlete),
       sportType = Value(sportType),
       startDate = Value(startDate),
       startDateLocal = Value(startDateLocal),
       movingTime = Value(movingTime),
       elapsedTime = Value(elapsedTime);
  static Insertable<StravaActivityDb> custom({
    Expression<int>? id,
    Expression<DateTime>? lastModified,
    Expression<String>? name,
    Expression<int>? athlete,
    Expression<String>? sportType,
    Expression<DateTime>? startDate,
    Expression<DateTime>? startDateLocal,
    Expression<String>? gearId,
    Expression<double>? startLat,
    Expression<double>? startLon,
    Expression<double>? distance,
    Expression<double>? totalElevationGain,
    Expression<int>? movingTime,
    Expression<int>? elapsedTime,
    Expression<int>? workoutType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastModified != null) 'last_modified': lastModified,
      if (name != null) 'name': name,
      if (athlete != null) 'athlete': athlete,
      if (sportType != null) 'sport_type': sportType,
      if (startDate != null) 'start_date': startDate,
      if (startDateLocal != null) 'start_date_local': startDateLocal,
      if (gearId != null) 'gear_id': gearId,
      if (startLat != null) 'start_lat': startLat,
      if (startLon != null) 'start_lon': startLon,
      if (distance != null) 'distance': distance,
      if (totalElevationGain != null)
        'total_elevation_gain': totalElevationGain,
      if (movingTime != null) 'moving_time': movingTime,
      if (elapsedTime != null) 'elapsed_time': elapsedTime,
      if (workoutType != null) 'workout_type': workoutType,
    });
  }

  StravaActivitiesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? lastModified,
    Value<String>? name,
    Value<int>? athlete,
    Value<SportType>? sportType,
    Value<DateTime>? startDate,
    Value<DateTime>? startDateLocal,
    Value<String?>? gearId,
    Value<double?>? startLat,
    Value<double?>? startLon,
    Value<double?>? distance,
    Value<double?>? totalElevationGain,
    Value<int>? movingTime,
    Value<int>? elapsedTime,
    Value<int?>? workoutType,
  }) {
    return StravaActivitiesCompanion(
      id: id ?? this.id,
      lastModified: lastModified ?? this.lastModified,
      name: name ?? this.name,
      athlete: athlete ?? this.athlete,
      sportType: sportType ?? this.sportType,
      startDate: startDate ?? this.startDate,
      startDateLocal: startDateLocal ?? this.startDateLocal,
      gearId: gearId ?? this.gearId,
      startLat: startLat ?? this.startLat,
      startLon: startLon ?? this.startLon,
      distance: distance ?? this.distance,
      totalElevationGain: totalElevationGain ?? this.totalElevationGain,
      movingTime: movingTime ?? this.movingTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      workoutType: workoutType ?? this.workoutType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(
        $StravaActivitiesTable.$converterlastModified.toSql(lastModified.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (athlete.present) {
      map['athlete'] = Variable<int>(athlete.value);
    }
    if (sportType.present) {
      map['sport_type'] = Variable<String>(
        $StravaActivitiesTable.$convertersportType.toSql(sportType.value),
      );
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(
        $StravaActivitiesTable.$converterstartDate.toSql(startDate.value),
      );
    }
    if (startDateLocal.present) {
      map['start_date_local'] = Variable<DateTime>(
        $StravaActivitiesTable.$converterstartDateLocal.toSql(
          startDateLocal.value,
        ),
      );
    }
    if (gearId.present) {
      map['gear_id'] = Variable<String>(gearId.value);
    }
    if (startLat.present) {
      map['start_lat'] = Variable<double>(startLat.value);
    }
    if (startLon.present) {
      map['start_lon'] = Variable<double>(startLon.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (totalElevationGain.present) {
      map['total_elevation_gain'] = Variable<double>(totalElevationGain.value);
    }
    if (movingTime.present) {
      map['moving_time'] = Variable<int>(movingTime.value);
    }
    if (elapsedTime.present) {
      map['elapsed_time'] = Variable<int>(elapsedTime.value);
    }
    if (workoutType.present) {
      map['workout_type'] = Variable<int>(workoutType.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StravaActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('athlete: $athlete, ')
          ..write('sportType: $sportType, ')
          ..write('startDate: $startDate, ')
          ..write('startDateLocal: $startDateLocal, ')
          ..write('gearId: $gearId, ')
          ..write('startLat: $startLat, ')
          ..write('startLon: $startLon, ')
          ..write('distance: $distance, ')
          ..write('totalElevationGain: $totalElevationGain, ')
          ..write('movingTime: $movingTime, ')
          ..write('elapsedTime: $elapsedTime, ')
          ..write('workoutType: $workoutType')
          ..write(')'))
        .toString();
  }
}

class $StravaAthletesTable extends StravaAthletes
    with TableInfo<$StravaAthletesTable, StravaAthleteDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StravaAthletesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> lastModified =
      GeneratedColumn<DateTime>(
        'last_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($StravaAthletesTable.$converterlastModified);
  static const VerificationMeta _firstnameMeta = const VerificationMeta(
    'firstname',
  );
  @override
  late final GeneratedColumn<String> firstname = GeneratedColumn<String>(
    'firstname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastnameMeta = const VerificationMeta(
    'lastname',
  );
  @override
  late final GeneratedColumn<String> lastname = GeneratedColumn<String>(
    'lastname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileMeta = const VerificationMeta(
    'profile',
  );
  @override
  late final GeneratedColumn<String> profile = GeneratedColumn<String>(
    'profile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Set<String>, String> gears =
      GeneratedColumn<String>(
        'gears',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Set<String>>($StravaAthletesTable.$convertergears);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lastModified,
    firstname,
    lastname,
    profile,
    gears,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strava_athletes';
  @override
  VerificationContext validateIntegrity(
    Insertable<StravaAthleteDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('firstname')) {
      context.handle(
        _firstnameMeta,
        firstname.isAcceptableOrUnknown(data['firstname']!, _firstnameMeta),
      );
    }
    if (data.containsKey('lastname')) {
      context.handle(
        _lastnameMeta,
        lastname.isAcceptableOrUnknown(data['lastname']!, _lastnameMeta),
      );
    }
    if (data.containsKey('profile')) {
      context.handle(
        _profileMeta,
        profile.isAcceptableOrUnknown(data['profile']!, _profileMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StravaAthleteDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StravaAthleteDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lastModified: $StravaAthletesTable.$converterlastModified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_modified'],
        )!,
      ),
      firstname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firstname'],
      ),
      lastname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lastname'],
      ),
      profile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile'],
      ),
      gears: $StravaAthletesTable.$convertergears.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}gears'],
        )!,
      ),
    );
  }

  @override
  $StravaAthletesTable createAlias(String alias) {
    return $StravaAthletesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterlastModified =
      const UtcDateTimeConverter();
  static TypeConverter<Set<String>, String> $convertergears =
      const StringListConverter();
}

class StravaAthleteDb extends DataClass implements Insertable<StravaAthleteDb> {
  final int id;
  final DateTime lastModified;
  final String? firstname;
  final String? lastname;
  final String? profile;
  final Set<String> gears;
  const StravaAthleteDb({
    required this.id,
    required this.lastModified,
    this.firstname,
    this.lastname,
    this.profile,
    required this.gears,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['last_modified'] = Variable<DateTime>(
        $StravaAthletesTable.$converterlastModified.toSql(lastModified),
      );
    }
    if (!nullToAbsent || firstname != null) {
      map['firstname'] = Variable<String>(firstname);
    }
    if (!nullToAbsent || lastname != null) {
      map['lastname'] = Variable<String>(lastname);
    }
    if (!nullToAbsent || profile != null) {
      map['profile'] = Variable<String>(profile);
    }
    {
      map['gears'] = Variable<String>(
        $StravaAthletesTable.$convertergears.toSql(gears),
      );
    }
    return map;
  }

  StravaAthletesCompanion toCompanion(bool nullToAbsent) {
    return StravaAthletesCompanion(
      id: Value(id),
      lastModified: Value(lastModified),
      firstname: firstname == null && nullToAbsent
          ? const Value.absent()
          : Value(firstname),
      lastname: lastname == null && nullToAbsent
          ? const Value.absent()
          : Value(lastname),
      profile: profile == null && nullToAbsent
          ? const Value.absent()
          : Value(profile),
      gears: Value(gears),
    );
  }

  factory StravaAthleteDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StravaAthleteDb(
      id: serializer.fromJson<int>(json['id']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      firstname: serializer.fromJson<String?>(json['firstname']),
      lastname: serializer.fromJson<String?>(json['lastname']),
      profile: serializer.fromJson<String?>(json['profile']),
      gears: serializer.fromJson<Set<String>>(json['gears']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'firstname': serializer.toJson<String?>(firstname),
      'lastname': serializer.toJson<String?>(lastname),
      'profile': serializer.toJson<String?>(profile),
      'gears': serializer.toJson<Set<String>>(gears),
    };
  }

  StravaAthleteDb copyWith({
    int? id,
    DateTime? lastModified,
    Value<String?> firstname = const Value.absent(),
    Value<String?> lastname = const Value.absent(),
    Value<String?> profile = const Value.absent(),
    Set<String>? gears,
  }) => StravaAthleteDb(
    id: id ?? this.id,
    lastModified: lastModified ?? this.lastModified,
    firstname: firstname.present ? firstname.value : this.firstname,
    lastname: lastname.present ? lastname.value : this.lastname,
    profile: profile.present ? profile.value : this.profile,
    gears: gears ?? this.gears,
  );
  StravaAthleteDb copyWithCompanion(StravaAthletesCompanion data) {
    return StravaAthleteDb(
      id: data.id.present ? data.id.value : this.id,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      firstname: data.firstname.present ? data.firstname.value : this.firstname,
      lastname: data.lastname.present ? data.lastname.value : this.lastname,
      profile: data.profile.present ? data.profile.value : this.profile,
      gears: data.gears.present ? data.gears.value : this.gears,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StravaAthleteDb(')
          ..write('id: $id, ')
          ..write('lastModified: $lastModified, ')
          ..write('firstname: $firstname, ')
          ..write('lastname: $lastname, ')
          ..write('profile: $profile, ')
          ..write('gears: $gears')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, lastModified, firstname, lastname, profile, gears);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StravaAthleteDb &&
          other.id == this.id &&
          other.lastModified == this.lastModified &&
          other.firstname == this.firstname &&
          other.lastname == this.lastname &&
          other.profile == this.profile &&
          other.gears == this.gears);
}

class StravaAthletesCompanion extends UpdateCompanion<StravaAthleteDb> {
  final Value<int> id;
  final Value<DateTime> lastModified;
  final Value<String?> firstname;
  final Value<String?> lastname;
  final Value<String?> profile;
  final Value<Set<String>> gears;
  const StravaAthletesCompanion({
    this.id = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.firstname = const Value.absent(),
    this.lastname = const Value.absent(),
    this.profile = const Value.absent(),
    this.gears = const Value.absent(),
  });
  StravaAthletesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime lastModified,
    this.firstname = const Value.absent(),
    this.lastname = const Value.absent(),
    this.profile = const Value.absent(),
    required Set<String> gears,
  }) : lastModified = Value(lastModified),
       gears = Value(gears);
  static Insertable<StravaAthleteDb> custom({
    Expression<int>? id,
    Expression<DateTime>? lastModified,
    Expression<String>? firstname,
    Expression<String>? lastname,
    Expression<String>? profile,
    Expression<String>? gears,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastModified != null) 'last_modified': lastModified,
      if (firstname != null) 'firstname': firstname,
      if (lastname != null) 'lastname': lastname,
      if (profile != null) 'profile': profile,
      if (gears != null) 'gears': gears,
    });
  }

  StravaAthletesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? lastModified,
    Value<String?>? firstname,
    Value<String?>? lastname,
    Value<String?>? profile,
    Value<Set<String>>? gears,
  }) {
    return StravaAthletesCompanion(
      id: id ?? this.id,
      lastModified: lastModified ?? this.lastModified,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      profile: profile ?? this.profile,
      gears: gears ?? this.gears,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(
        $StravaAthletesTable.$converterlastModified.toSql(lastModified.value),
      );
    }
    if (firstname.present) {
      map['firstname'] = Variable<String>(firstname.value);
    }
    if (lastname.present) {
      map['lastname'] = Variable<String>(lastname.value);
    }
    if (profile.present) {
      map['profile'] = Variable<String>(profile.value);
    }
    if (gears.present) {
      map['gears'] = Variable<String>(
        $StravaAthletesTable.$convertergears.toSql(gears.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StravaAthletesCompanion(')
          ..write('id: $id, ')
          ..write('lastModified: $lastModified, ')
          ..write('firstname: $firstname, ')
          ..write('lastname: $lastname, ')
          ..write('profile: $profile, ')
          ..write('gears: $gears')
          ..write(')'))
        .toString();
  }
}

class $StravaGearsTable extends StravaGears
    with TableInfo<$StravaGearsTable, StravaGearDb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StravaGearsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> lastModified =
      GeneratedColumn<DateTime>(
        'last_modified',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($StravaGearsTable.$converterlastModified);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, lastModified, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strava_gears';
  @override
  VerificationContext validateIntegrity(
    Insertable<StravaGearDb> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StravaGearDb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StravaGearDb(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lastModified: $StravaGearsTable.$converterlastModified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_modified'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $StravaGearsTable createAlias(String alias) {
    return $StravaGearsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterlastModified =
      const UtcDateTimeConverter();
}

class StravaGearDb extends DataClass implements Insertable<StravaGearDb> {
  final String id;
  final DateTime lastModified;
  final String name;
  const StravaGearDb({
    required this.id,
    required this.lastModified,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['last_modified'] = Variable<DateTime>(
        $StravaGearsTable.$converterlastModified.toSql(lastModified),
      );
    }
    map['name'] = Variable<String>(name);
    return map;
  }

  StravaGearsCompanion toCompanion(bool nullToAbsent) {
    return StravaGearsCompanion(
      id: Value(id),
      lastModified: Value(lastModified),
      name: Value(name),
    );
  }

  factory StravaGearDb.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StravaGearDb(
      id: serializer.fromJson<String>(json['id']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'name': serializer.toJson<String>(name),
    };
  }

  StravaGearDb copyWith({String? id, DateTime? lastModified, String? name}) =>
      StravaGearDb(
        id: id ?? this.id,
        lastModified: lastModified ?? this.lastModified,
        name: name ?? this.name,
      );
  StravaGearDb copyWithCompanion(StravaGearsCompanion data) {
    return StravaGearDb(
      id: data.id.present ? data.id.value : this.id,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StravaGearDb(')
          ..write('id: $id, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastModified, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StravaGearDb &&
          other.id == this.id &&
          other.lastModified == this.lastModified &&
          other.name == this.name);
}

class StravaGearsCompanion extends UpdateCompanion<StravaGearDb> {
  final Value<String> id;
  final Value<DateTime> lastModified;
  final Value<String> name;
  final Value<int> rowid;
  const StravaGearsCompanion({
    this.id = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StravaGearsCompanion.insert({
    required String id,
    required DateTime lastModified,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lastModified = Value(lastModified),
       name = Value(name);
  static Insertable<StravaGearDb> custom({
    Expression<String>? id,
    Expression<DateTime>? lastModified,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastModified != null) 'last_modified': lastModified,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StravaGearsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? lastModified,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return StravaGearsCompanion(
      id: id ?? this.id,
      lastModified: lastModified ?? this.lastModified,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(
        $StravaGearsTable.$converterlastModified.toSql(lastModified.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StravaGearsCompanion(')
          ..write('id: $id, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ComponentsTable components = $ComponentsTable(this);
  late final $BikesTable bikes = $BikesTable(this);
  late final $TaskRulesTable taskRules = $TaskRulesTable(this);
  late final $TaskEntriesTable taskEntries = $TaskEntriesTable(this);
  late final $PersonsTable persons = $PersonsTable(this);
  late final $AdjustmentsTable adjustments = $AdjustmentsTable(this);
  late final $InstallationsTable installations = $InstallationsTable(this);
  late final $SetupsTable setups = $SetupsTable(this);
  late final $SetupAdjustmentValuesTable setupAdjustmentValues =
      $SetupAdjustmentValuesTable(this);
  late final $RatingsTable ratings = $RatingsTable(this);
  late final $RatingMetricsTable ratingMetrics = $RatingMetricsTable(this);
  late final $RatingEntriesTable ratingEntries = $RatingEntriesTable(this);
  late final $RatingEntryValuesTable ratingEntryValues =
      $RatingEntryValuesTable(this);
  late final $StravaActivitiesTable stravaActivities = $StravaActivitiesTable(
    this,
  );
  late final $StravaAthletesTable stravaAthletes = $StravaAthletesTable(this);
  late final $StravaGearsTable stravaGears = $StravaGearsTable(this);
  late final BikesDao bikesDao = BikesDao(this as AppDatabase);
  late final ComponentsDao componentsDao = ComponentsDao(this as AppDatabase);
  late final SetupsDao setupsDao = SetupsDao(this as AppDatabase);
  late final PersonsDao personsDao = PersonsDao(this as AppDatabase);
  late final RatingsDao ratingsDao = RatingsDao(this as AppDatabase);
  late final RatingEntriesDao ratingEntriesDao = RatingEntriesDao(
    this as AppDatabase,
  );
  late final TaskDao taskDao = TaskDao(this as AppDatabase);
  late final StravaDao stravaDao = StravaDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    components,
    bikes,
    taskRules,
    taskEntries,
    persons,
    adjustments,
    installations,
    setups,
    setupAdjustmentValues,
    ratings,
    ratingMetrics,
    ratingEntries,
    ratingEntryValues,
    stravaActivities,
    stravaAthletes,
    stravaGears,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'task_rules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'components',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('adjustments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'persons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('adjustments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'components',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('installations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bikes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('setups', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'persons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('setups', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'setups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('setup_adjustment_values', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'adjustments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('setup_adjustment_values', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ratings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rating_metrics', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bikes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rating_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'rating_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rating_entry_values', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'rating_metrics',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rating_entry_values', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ComponentsTableCreateCompanionBuilder =
    ComponentsCompanion Function({
      required String id,
      Value<bool> isDeleted,
      required DateTime lastModified,
      required String name,
      required ComponentType componentType,
      Value<String?> notes,
      Value<int> orderIndex,
      Value<double> initialDistance,
      Value<double> initialElevationGain,
      Value<Duration> initialMovingTime,
      Value<Duration> initialElapsedTime,
      Value<int> initialActivityCount,
      Value<int> rowid,
    });
typedef $$ComponentsTableUpdateCompanionBuilder =
    ComponentsCompanion Function({
      Value<String> id,
      Value<bool> isDeleted,
      Value<DateTime> lastModified,
      Value<String> name,
      Value<ComponentType> componentType,
      Value<String?> notes,
      Value<int> orderIndex,
      Value<double> initialDistance,
      Value<double> initialElevationGain,
      Value<Duration> initialMovingTime,
      Value<Duration> initialElapsedTime,
      Value<int> initialActivityCount,
      Value<int> rowid,
    });

final class $$ComponentsTableReferences
    extends BaseReferences<_$AppDatabase, $ComponentsTable, ComponentDb> {
  $$ComponentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TaskRulesTable, List<TaskRuleDb>>
  _taskRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskRules,
    aliasName: 'components__id__task_rules__component_id',
  );

  $$TaskRulesTableProcessedTableManager get taskRulesRefs {
    final manager = $$TaskRulesTableTableManager(
      $_db,
      $_db.taskRules,
    ).filter((f) => f.componentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskEntriesTable, List<TaskEntryDb>>
  _taskEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskEntries,
    aliasName: 'components__id__task_entries__component_id',
  );

  $$TaskEntriesTableProcessedTableManager get taskEntriesRefs {
    final manager = $$TaskEntriesTableTableManager(
      $_db,
      $_db.taskEntries,
    ).filter((f) => f.componentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AdjustmentsTable, List<AdjustmentDb>>
  _adjustmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.adjustments,
    aliasName: 'components__id__adjustments__component_id',
  );

  $$AdjustmentsTableProcessedTableManager get adjustmentsRefs {
    final manager = $$AdjustmentsTableTableManager(
      $_db,
      $_db.adjustments,
    ).filter((f) => f.componentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_adjustmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InstallationsTable, List<InstallationDb>>
  _installationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.installations,
    aliasName: 'components__id__installations__component_id',
  );

  $$InstallationsTableProcessedTableManager get installationsRefs {
    final manager = $$InstallationsTableTableManager(
      $_db,
      $_db.installations,
    ).filter((f) => f.componentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_installationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ComponentsTableFilterComposer
    extends Composer<_$AppDatabase, $ComponentsTable> {
  $$ComponentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ComponentType, ComponentType, String>
  get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialDistance => $composableBuilder(
    column: $table.initialDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialElevationGain => $composableBuilder(
    column: $table.initialElevationGain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration, Duration, int>
  get initialMovingTime => $composableBuilder(
    column: $table.initialMovingTime,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration, Duration, int>
  get initialElapsedTime => $composableBuilder(
    column: $table.initialElapsedTime,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get initialActivityCount => $composableBuilder(
    column: $table.initialActivityCount,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> taskRulesRefs(
    Expression<bool> Function($$TaskRulesTableFilterComposer f) f,
  ) {
    final $$TaskRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskRules,
      getReferencedColumn: (t) => t.componentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRulesTableFilterComposer(
            $db: $db,
            $table: $db.taskRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskEntriesRefs(
    Expression<bool> Function($$TaskEntriesTableFilterComposer f) f,
  ) {
    final $$TaskEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskEntries,
      getReferencedColumn: (t) => t.componentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskEntriesTableFilterComposer(
            $db: $db,
            $table: $db.taskEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> adjustmentsRefs(
    Expression<bool> Function($$AdjustmentsTableFilterComposer f) f,
  ) {
    final $$AdjustmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adjustments,
      getReferencedColumn: (t) => t.componentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdjustmentsTableFilterComposer(
            $db: $db,
            $table: $db.adjustments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> installationsRefs(
    Expression<bool> Function($$InstallationsTableFilterComposer f) f,
  ) {
    final $$InstallationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.installations,
      getReferencedColumn: (t) => t.componentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallationsTableFilterComposer(
            $db: $db,
            $table: $db.installations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ComponentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ComponentsTable> {
  $$ComponentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialDistance => $composableBuilder(
    column: $table.initialDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialElevationGain => $composableBuilder(
    column: $table.initialElevationGain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialMovingTime => $composableBuilder(
    column: $table.initialMovingTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialElapsedTime => $composableBuilder(
    column: $table.initialElapsedTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialActivityCount => $composableBuilder(
    column: $table.initialActivityCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ComponentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ComponentsTable> {
  $$ComponentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get lastModified =>
      $composableBuilder(
        column: $table.lastModified,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ComponentType, String> get componentType =>
      $composableBuilder(
        column: $table.componentType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<double> get initialDistance => $composableBuilder(
    column: $table.initialDistance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get initialElevationGain => $composableBuilder(
    column: $table.initialElevationGain,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Duration, int> get initialMovingTime =>
      $composableBuilder(
        column: $table.initialMovingTime,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Duration, int> get initialElapsedTime =>
      $composableBuilder(
        column: $table.initialElapsedTime,
        builder: (column) => column,
      );

  GeneratedColumn<int> get initialActivityCount => $composableBuilder(
    column: $table.initialActivityCount,
    builder: (column) => column,
  );

  Expression<T> taskRulesRefs<T extends Object>(
    Expression<T> Function($$TaskRulesTableAnnotationComposer a) f,
  ) {
    final $$TaskRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskRules,
      getReferencedColumn: (t) => t.componentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskEntriesRefs<T extends Object>(
    Expression<T> Function($$TaskEntriesTableAnnotationComposer a) f,
  ) {
    final $$TaskEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskEntries,
      getReferencedColumn: (t) => t.componentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> adjustmentsRefs<T extends Object>(
    Expression<T> Function($$AdjustmentsTableAnnotationComposer a) f,
  ) {
    final $$AdjustmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adjustments,
      getReferencedColumn: (t) => t.componentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdjustmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.adjustments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> installationsRefs<T extends Object>(
    Expression<T> Function($$InstallationsTableAnnotationComposer a) f,
  ) {
    final $$InstallationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.installations,
      getReferencedColumn: (t) => t.componentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallationsTableAnnotationComposer(
            $db: $db,
            $table: $db.installations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ComponentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ComponentsTable,
          ComponentDb,
          $$ComponentsTableFilterComposer,
          $$ComponentsTableOrderingComposer,
          $$ComponentsTableAnnotationComposer,
          $$ComponentsTableCreateCompanionBuilder,
          $$ComponentsTableUpdateCompanionBuilder,
          (ComponentDb, $$ComponentsTableReferences),
          ComponentDb,
          PrefetchHooks Function({
            bool taskRulesRefs,
            bool taskEntriesRefs,
            bool adjustmentsRefs,
            bool installationsRefs,
          })
        > {
  $$ComponentsTableTableManager(_$AppDatabase db, $ComponentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComponentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComponentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComponentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<ComponentType> componentType = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<double> initialDistance = const Value.absent(),
                Value<double> initialElevationGain = const Value.absent(),
                Value<Duration> initialMovingTime = const Value.absent(),
                Value<Duration> initialElapsedTime = const Value.absent(),
                Value<int> initialActivityCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComponentsCompanion(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                componentType: componentType,
                notes: notes,
                orderIndex: orderIndex,
                initialDistance: initialDistance,
                initialElevationGain: initialElevationGain,
                initialMovingTime: initialMovingTime,
                initialElapsedTime: initialElapsedTime,
                initialActivityCount: initialActivityCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> isDeleted = const Value.absent(),
                required DateTime lastModified,
                required String name,
                required ComponentType componentType,
                Value<String?> notes = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<double> initialDistance = const Value.absent(),
                Value<double> initialElevationGain = const Value.absent(),
                Value<Duration> initialMovingTime = const Value.absent(),
                Value<Duration> initialElapsedTime = const Value.absent(),
                Value<int> initialActivityCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComponentsCompanion.insert(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                componentType: componentType,
                notes: notes,
                orderIndex: orderIndex,
                initialDistance: initialDistance,
                initialElevationGain: initialElevationGain,
                initialMovingTime: initialMovingTime,
                initialElapsedTime: initialElapsedTime,
                initialActivityCount: initialActivityCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ComponentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                taskRulesRefs = false,
                taskEntriesRefs = false,
                adjustmentsRefs = false,
                installationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskRulesRefs) db.taskRules,
                    if (taskEntriesRefs) db.taskEntries,
                    if (adjustmentsRefs) db.adjustments,
                    if (installationsRefs) db.installations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskRulesRefs)
                        await $_getPrefetchedData<
                          ComponentDb,
                          $ComponentsTable,
                          TaskRuleDb
                        >(
                          currentTable: table,
                          referencedTable: $$ComponentsTableReferences
                              ._taskRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ComponentsTableReferences(
                                db,
                                table,
                                p0,
                              ).taskRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.componentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskEntriesRefs)
                        await $_getPrefetchedData<
                          ComponentDb,
                          $ComponentsTable,
                          TaskEntryDb
                        >(
                          currentTable: table,
                          referencedTable: $$ComponentsTableReferences
                              ._taskEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ComponentsTableReferences(
                                db,
                                table,
                                p0,
                              ).taskEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.componentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (adjustmentsRefs)
                        await $_getPrefetchedData<
                          ComponentDb,
                          $ComponentsTable,
                          AdjustmentDb
                        >(
                          currentTable: table,
                          referencedTable: $$ComponentsTableReferences
                              ._adjustmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ComponentsTableReferences(
                                db,
                                table,
                                p0,
                              ).adjustmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.componentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (installationsRefs)
                        await $_getPrefetchedData<
                          ComponentDb,
                          $ComponentsTable,
                          InstallationDb
                        >(
                          currentTable: table,
                          referencedTable: $$ComponentsTableReferences
                              ._installationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ComponentsTableReferences(
                                db,
                                table,
                                p0,
                              ).installationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.componentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ComponentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ComponentsTable,
      ComponentDb,
      $$ComponentsTableFilterComposer,
      $$ComponentsTableOrderingComposer,
      $$ComponentsTableAnnotationComposer,
      $$ComponentsTableCreateCompanionBuilder,
      $$ComponentsTableUpdateCompanionBuilder,
      (ComponentDb, $$ComponentsTableReferences),
      ComponentDb,
      PrefetchHooks Function({
        bool taskRulesRefs,
        bool taskEntriesRefs,
        bool adjustmentsRefs,
        bool installationsRefs,
      })
    >;
typedef $$BikesTableCreateCompanionBuilder =
    BikesCompanion Function({
      required String id,
      Value<bool> isDeleted,
      required DateTime lastModified,
      required String name,
      Value<String?> notes,
      Value<String?> person,
      Value<String?> stravaGear,
      Value<int> orderIndex,
      Value<int> rowid,
    });
typedef $$BikesTableUpdateCompanionBuilder =
    BikesCompanion Function({
      Value<String> id,
      Value<bool> isDeleted,
      Value<DateTime> lastModified,
      Value<String> name,
      Value<String?> notes,
      Value<String?> person,
      Value<String?> stravaGear,
      Value<int> orderIndex,
      Value<int> rowid,
    });

final class $$BikesTableReferences
    extends BaseReferences<_$AppDatabase, $BikesTable, BikeDb> {
  $$BikesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TaskRulesTable, List<TaskRuleDb>>
  _taskRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskRules,
    aliasName: 'bikes__id__task_rules__bike_id',
  );

  $$TaskRulesTableProcessedTableManager get taskRulesRefs {
    final manager = $$TaskRulesTableTableManager(
      $_db,
      $_db.taskRules,
    ).filter((f) => f.bikeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskEntriesTable, List<TaskEntryDb>>
  _taskEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskEntries,
    aliasName: 'bikes__id__task_entries__bike_id',
  );

  $$TaskEntriesTableProcessedTableManager get taskEntriesRefs {
    final manager = $$TaskEntriesTableTableManager(
      $_db,
      $_db.taskEntries,
    ).filter((f) => f.bikeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SetupsTable, List<SetupDb>> _setupsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.setups,
    aliasName: 'bikes__id__setups__bike_id',
  );

  $$SetupsTableProcessedTableManager get setupsRefs {
    final manager = $$SetupsTableTableManager(
      $_db,
      $_db.setups,
    ).filter((f) => f.bikeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_setupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RatingEntriesTable, List<RatingEntryDb>>
  _ratingEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ratingEntries,
    aliasName: 'bikes__id__rating_entries__bike_id',
  );

  $$RatingEntriesTableProcessedTableManager get ratingEntriesRefs {
    final manager = $$RatingEntriesTableTableManager(
      $_db,
      $_db.ratingEntries,
    ).filter((f) => f.bikeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ratingEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BikesTableFilterComposer extends Composer<_$AppDatabase, $BikesTable> {
  $$BikesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stravaGear => $composableBuilder(
    column: $table.stravaGear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> taskRulesRefs(
    Expression<bool> Function($$TaskRulesTableFilterComposer f) f,
  ) {
    final $$TaskRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskRules,
      getReferencedColumn: (t) => t.bikeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRulesTableFilterComposer(
            $db: $db,
            $table: $db.taskRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskEntriesRefs(
    Expression<bool> Function($$TaskEntriesTableFilterComposer f) f,
  ) {
    final $$TaskEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskEntries,
      getReferencedColumn: (t) => t.bikeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskEntriesTableFilterComposer(
            $db: $db,
            $table: $db.taskEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> setupsRefs(
    Expression<bool> Function($$SetupsTableFilterComposer f) f,
  ) {
    final $$SetupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setups,
      getReferencedColumn: (t) => t.bikeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetupsTableFilterComposer(
            $db: $db,
            $table: $db.setups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ratingEntriesRefs(
    Expression<bool> Function($$RatingEntriesTableFilterComposer f) f,
  ) {
    final $$RatingEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ratingEntries,
      getReferencedColumn: (t) => t.bikeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ratingEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BikesTableOrderingComposer
    extends Composer<_$AppDatabase, $BikesTable> {
  $$BikesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stravaGear => $composableBuilder(
    column: $table.stravaGear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BikesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BikesTable> {
  $$BikesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get lastModified =>
      $composableBuilder(
        column: $table.lastModified,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get person =>
      $composableBuilder(column: $table.person, builder: (column) => column);

  GeneratedColumn<String> get stravaGear => $composableBuilder(
    column: $table.stravaGear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  Expression<T> taskRulesRefs<T extends Object>(
    Expression<T> Function($$TaskRulesTableAnnotationComposer a) f,
  ) {
    final $$TaskRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskRules,
      getReferencedColumn: (t) => t.bikeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskEntriesRefs<T extends Object>(
    Expression<T> Function($$TaskEntriesTableAnnotationComposer a) f,
  ) {
    final $$TaskEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskEntries,
      getReferencedColumn: (t) => t.bikeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> setupsRefs<T extends Object>(
    Expression<T> Function($$SetupsTableAnnotationComposer a) f,
  ) {
    final $$SetupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setups,
      getReferencedColumn: (t) => t.bikeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetupsTableAnnotationComposer(
            $db: $db,
            $table: $db.setups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ratingEntriesRefs<T extends Object>(
    Expression<T> Function($$RatingEntriesTableAnnotationComposer a) f,
  ) {
    final $$RatingEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ratingEntries,
      getReferencedColumn: (t) => t.bikeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ratingEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BikesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BikesTable,
          BikeDb,
          $$BikesTableFilterComposer,
          $$BikesTableOrderingComposer,
          $$BikesTableAnnotationComposer,
          $$BikesTableCreateCompanionBuilder,
          $$BikesTableUpdateCompanionBuilder,
          (BikeDb, $$BikesTableReferences),
          BikeDb,
          PrefetchHooks Function({
            bool taskRulesRefs,
            bool taskEntriesRefs,
            bool setupsRefs,
            bool ratingEntriesRefs,
          })
        > {
  $$BikesTableTableManager(_$AppDatabase db, $BikesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BikesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BikesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BikesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> person = const Value.absent(),
                Value<String?> stravaGear = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BikesCompanion(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                notes: notes,
                person: person,
                stravaGear: stravaGear,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> isDeleted = const Value.absent(),
                required DateTime lastModified,
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<String?> person = const Value.absent(),
                Value<String?> stravaGear = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BikesCompanion.insert(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                notes: notes,
                person: person,
                stravaGear: stravaGear,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BikesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                taskRulesRefs = false,
                taskEntriesRefs = false,
                setupsRefs = false,
                ratingEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskRulesRefs) db.taskRules,
                    if (taskEntriesRefs) db.taskEntries,
                    if (setupsRefs) db.setups,
                    if (ratingEntriesRefs) db.ratingEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskRulesRefs)
                        await $_getPrefetchedData<
                          BikeDb,
                          $BikesTable,
                          TaskRuleDb
                        >(
                          currentTable: table,
                          referencedTable: $$BikesTableReferences
                              ._taskRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BikesTableReferences(
                                db,
                                table,
                                p0,
                              ).taskRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bikeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskEntriesRefs)
                        await $_getPrefetchedData<
                          BikeDb,
                          $BikesTable,
                          TaskEntryDb
                        >(
                          currentTable: table,
                          referencedTable: $$BikesTableReferences
                              ._taskEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BikesTableReferences(
                                db,
                                table,
                                p0,
                              ).taskEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bikeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (setupsRefs)
                        await $_getPrefetchedData<BikeDb, $BikesTable, SetupDb>(
                          currentTable: table,
                          referencedTable: $$BikesTableReferences
                              ._setupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BikesTableReferences(db, table, p0).setupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bikeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ratingEntriesRefs)
                        await $_getPrefetchedData<
                          BikeDb,
                          $BikesTable,
                          RatingEntryDb
                        >(
                          currentTable: table,
                          referencedTable: $$BikesTableReferences
                              ._ratingEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BikesTableReferences(
                                db,
                                table,
                                p0,
                              ).ratingEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bikeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BikesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BikesTable,
      BikeDb,
      $$BikesTableFilterComposer,
      $$BikesTableOrderingComposer,
      $$BikesTableAnnotationComposer,
      $$BikesTableCreateCompanionBuilder,
      $$BikesTableUpdateCompanionBuilder,
      (BikeDb, $$BikesTableReferences),
      BikeDb,
      PrefetchHooks Function({
        bool taskRulesRefs,
        bool taskEntriesRefs,
        bool setupsRefs,
        bool ratingEntriesRefs,
      })
    >;
typedef $$TaskRulesTableCreateCompanionBuilder =
    TaskRulesCompanion Function({
      required String id,
      Value<bool> isDeleted,
      required DateTime lastModified,
      Value<String?> componentId,
      Value<String?> bikeId,
      required String name,
      Value<String?> notes,
      Value<TaskPriority> priority,
      Value<Set<String>> tags,
      Value<String?> interval,
      Value<String?> delay,
      Value<bool> repeat,
      Value<int> rowid,
    });
typedef $$TaskRulesTableUpdateCompanionBuilder =
    TaskRulesCompanion Function({
      Value<String> id,
      Value<bool> isDeleted,
      Value<DateTime> lastModified,
      Value<String?> componentId,
      Value<String?> bikeId,
      Value<String> name,
      Value<String?> notes,
      Value<TaskPriority> priority,
      Value<Set<String>> tags,
      Value<String?> interval,
      Value<String?> delay,
      Value<bool> repeat,
      Value<int> rowid,
    });

final class $$TaskRulesTableReferences
    extends BaseReferences<_$AppDatabase, $TaskRulesTable, TaskRuleDb> {
  $$TaskRulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ComponentsTable _componentIdTable(_$AppDatabase db) =>
      db.components.createAlias('task_rules__component_id__components__id');

  $$ComponentsTableProcessedTableManager? get componentId {
    final $_column = $_itemColumn<String>('component_id');
    if ($_column == null) return null;
    final manager = $$ComponentsTableTableManager(
      $_db,
      $_db.components,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_componentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BikesTable _bikeIdTable(_$AppDatabase db) =>
      db.bikes.createAlias('task_rules__bike_id__bikes__id');

  $$BikesTableProcessedTableManager? get bikeId {
    final $_column = $_itemColumn<String>('bike_id');
    if ($_column == null) return null;
    final manager = $$BikesTableTableManager(
      $_db,
      $_db.bikes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bikeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TaskEntriesTable, List<TaskEntryDb>>
  _taskEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskEntries,
    aliasName: 'task_rules__id__task_entries__task_rule',
  );

  $$TaskEntriesTableProcessedTableManager get taskEntriesRefs {
    final manager = $$TaskEntriesTableTableManager(
      $_db,
      $_db.taskEntries,
    ).filter((f) => f.taskRule.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TaskRulesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskRulesTable> {
  $$TaskRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskPriority, TaskPriority, String>
  get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Set<String>, Set<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get delay => $composableBuilder(
    column: $table.delay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get repeat => $composableBuilder(
    column: $table.repeat,
    builder: (column) => ColumnFilters(column),
  );

  $$ComponentsTableFilterComposer get componentId {
    final $$ComponentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableFilterComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BikesTableFilterComposer get bikeId {
    final $$BikesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bikeId,
      referencedTable: $db.bikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BikesTableFilterComposer(
            $db: $db,
            $table: $db.bikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> taskEntriesRefs(
    Expression<bool> Function($$TaskEntriesTableFilterComposer f) f,
  ) {
    final $$TaskEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskEntries,
      getReferencedColumn: (t) => t.taskRule,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskEntriesTableFilterComposer(
            $db: $db,
            $table: $db.taskEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TaskRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskRulesTable> {
  $$TaskRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get delay => $composableBuilder(
    column: $table.delay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get repeat => $composableBuilder(
    column: $table.repeat,
    builder: (column) => ColumnOrderings(column),
  );

  $$ComponentsTableOrderingComposer get componentId {
    final $$ComponentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableOrderingComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BikesTableOrderingComposer get bikeId {
    final $$BikesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bikeId,
      referencedTable: $db.bikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BikesTableOrderingComposer(
            $db: $db,
            $table: $db.bikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskRulesTable> {
  $$TaskRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get lastModified =>
      $composableBuilder(
        column: $table.lastModified,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskPriority, String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Set<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<String> get delay =>
      $composableBuilder(column: $table.delay, builder: (column) => column);

  GeneratedColumn<bool> get repeat =>
      $composableBuilder(column: $table.repeat, builder: (column) => column);

  $$ComponentsTableAnnotationComposer get componentId {
    final $$ComponentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableAnnotationComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BikesTableAnnotationComposer get bikeId {
    final $$BikesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bikeId,
      referencedTable: $db.bikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BikesTableAnnotationComposer(
            $db: $db,
            $table: $db.bikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> taskEntriesRefs<T extends Object>(
    Expression<T> Function($$TaskEntriesTableAnnotationComposer a) f,
  ) {
    final $$TaskEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskEntries,
      getReferencedColumn: (t) => t.taskRule,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TaskRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRulesTable,
          TaskRuleDb,
          $$TaskRulesTableFilterComposer,
          $$TaskRulesTableOrderingComposer,
          $$TaskRulesTableAnnotationComposer,
          $$TaskRulesTableCreateCompanionBuilder,
          $$TaskRulesTableUpdateCompanionBuilder,
          (TaskRuleDb, $$TaskRulesTableReferences),
          TaskRuleDb,
          PrefetchHooks Function({
            bool componentId,
            bool bikeId,
            bool taskEntriesRefs,
          })
        > {
  $$TaskRulesTableTableManager(_$AppDatabase db, $TaskRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String?> componentId = const Value.absent(),
                Value<String?> bikeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<TaskPriority> priority = const Value.absent(),
                Value<Set<String>> tags = const Value.absent(),
                Value<String?> interval = const Value.absent(),
                Value<String?> delay = const Value.absent(),
                Value<bool> repeat = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRulesCompanion(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                componentId: componentId,
                bikeId: bikeId,
                name: name,
                notes: notes,
                priority: priority,
                tags: tags,
                interval: interval,
                delay: delay,
                repeat: repeat,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> isDeleted = const Value.absent(),
                required DateTime lastModified,
                Value<String?> componentId = const Value.absent(),
                Value<String?> bikeId = const Value.absent(),
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<TaskPriority> priority = const Value.absent(),
                Value<Set<String>> tags = const Value.absent(),
                Value<String?> interval = const Value.absent(),
                Value<String?> delay = const Value.absent(),
                Value<bool> repeat = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRulesCompanion.insert(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                componentId: componentId,
                bikeId: bikeId,
                name: name,
                notes: notes,
                priority: priority,
                tags: tags,
                interval: interval,
                delay: delay,
                repeat: repeat,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({componentId = false, bikeId = false, taskEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskEntriesRefs) db.taskEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (componentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.componentId,
                                    referencedTable: $$TaskRulesTableReferences
                                        ._componentIdTable(db),
                                    referencedColumn: $$TaskRulesTableReferences
                                        ._componentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (bikeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bikeId,
                                    referencedTable: $$TaskRulesTableReferences
                                        ._bikeIdTable(db),
                                    referencedColumn: $$TaskRulesTableReferences
                                        ._bikeIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskEntriesRefs)
                        await $_getPrefetchedData<
                          TaskRuleDb,
                          $TaskRulesTable,
                          TaskEntryDb
                        >(
                          currentTable: table,
                          referencedTable: $$TaskRulesTableReferences
                              ._taskEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskRulesTableReferences(
                                db,
                                table,
                                p0,
                              ).taskEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskRule == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TaskRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRulesTable,
      TaskRuleDb,
      $$TaskRulesTableFilterComposer,
      $$TaskRulesTableOrderingComposer,
      $$TaskRulesTableAnnotationComposer,
      $$TaskRulesTableCreateCompanionBuilder,
      $$TaskRulesTableUpdateCompanionBuilder,
      (TaskRuleDb, $$TaskRulesTableReferences),
      TaskRuleDb,
      PrefetchHooks Function({
        bool componentId,
        bool bikeId,
        bool taskEntriesRefs,
      })
    >;
typedef $$TaskEntriesTableCreateCompanionBuilder =
    TaskEntriesCompanion Function({
      required String id,
      Value<bool> isDeleted,
      required DateTime lastModified,
      required String name,
      Value<String?> notes,
      required DateTime dateTimeUTC,
      required DateTime dateTimeLocal,
      required String taskRule,
      Value<String?> componentId,
      Value<String?> bikeId,
      Value<String?> snapshot,
      Value<int> rowid,
    });
typedef $$TaskEntriesTableUpdateCompanionBuilder =
    TaskEntriesCompanion Function({
      Value<String> id,
      Value<bool> isDeleted,
      Value<DateTime> lastModified,
      Value<String> name,
      Value<String?> notes,
      Value<DateTime> dateTimeUTC,
      Value<DateTime> dateTimeLocal,
      Value<String> taskRule,
      Value<String?> componentId,
      Value<String?> bikeId,
      Value<String?> snapshot,
      Value<int> rowid,
    });

final class $$TaskEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $TaskEntriesTable, TaskEntryDb> {
  $$TaskEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TaskRulesTable _taskRuleTable(_$AppDatabase db) =>
      db.taskRules.createAlias('task_entries__task_rule__task_rules__id');

  $$TaskRulesTableProcessedTableManager get taskRule {
    final $_column = $_itemColumn<String>('task_rule')!;

    final manager = $$TaskRulesTableTableManager(
      $_db,
      $_db.taskRules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskRuleTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ComponentsTable _componentIdTable(_$AppDatabase db) =>
      db.components.createAlias('task_entries__component_id__components__id');

  $$ComponentsTableProcessedTableManager? get componentId {
    final $_column = $_itemColumn<String>('component_id');
    if ($_column == null) return null;
    final manager = $$ComponentsTableTableManager(
      $_db,
      $_db.components,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_componentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BikesTable _bikeIdTable(_$AppDatabase db) =>
      db.bikes.createAlias('task_entries__bike_id__bikes__id');

  $$BikesTableProcessedTableManager? get bikeId {
    final $_column = $_itemColumn<String>('bike_id');
    if ($_column == null) return null;
    final manager = $$BikesTableTableManager(
      $_db,
      $_db.bikes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bikeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskEntriesTable> {
  $$TaskEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get dateTimeUTC => $composableBuilder(
    column: $table.dateTimeUTC,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get dateTimeLocal => $composableBuilder(
    column: $table.dateTimeLocal,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskRulesTableFilterComposer get taskRule {
    final $$TaskRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskRule,
      referencedTable: $db.taskRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRulesTableFilterComposer(
            $db: $db,
            $table: $db.taskRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComponentsTableFilterComposer get componentId {
    final $$ComponentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableFilterComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BikesTableFilterComposer get bikeId {
    final $$BikesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bikeId,
      referencedTable: $db.bikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BikesTableFilterComposer(
            $db: $db,
            $table: $db.bikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskEntriesTable> {
  $$TaskEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTimeUTC => $composableBuilder(
    column: $table.dateTimeUTC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTimeLocal => $composableBuilder(
    column: $table.dateTimeLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskRulesTableOrderingComposer get taskRule {
    final $$TaskRulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskRule,
      referencedTable: $db.taskRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRulesTableOrderingComposer(
            $db: $db,
            $table: $db.taskRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComponentsTableOrderingComposer get componentId {
    final $$ComponentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableOrderingComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BikesTableOrderingComposer get bikeId {
    final $$BikesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bikeId,
      referencedTable: $db.bikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BikesTableOrderingComposer(
            $db: $db,
            $table: $db.bikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskEntriesTable> {
  $$TaskEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get lastModified =>
      $composableBuilder(
        column: $table.lastModified,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get dateTimeUTC =>
      $composableBuilder(
        column: $table.dateTimeUTC,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get dateTimeLocal =>
      $composableBuilder(
        column: $table.dateTimeLocal,
        builder: (column) => column,
      );

  GeneratedColumn<String> get snapshot =>
      $composableBuilder(column: $table.snapshot, builder: (column) => column);

  $$TaskRulesTableAnnotationComposer get taskRule {
    final $$TaskRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskRule,
      referencedTable: $db.taskRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ComponentsTableAnnotationComposer get componentId {
    final $$ComponentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableAnnotationComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BikesTableAnnotationComposer get bikeId {
    final $$BikesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bikeId,
      referencedTable: $db.bikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BikesTableAnnotationComposer(
            $db: $db,
            $table: $db.bikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskEntriesTable,
          TaskEntryDb,
          $$TaskEntriesTableFilterComposer,
          $$TaskEntriesTableOrderingComposer,
          $$TaskEntriesTableAnnotationComposer,
          $$TaskEntriesTableCreateCompanionBuilder,
          $$TaskEntriesTableUpdateCompanionBuilder,
          (TaskEntryDb, $$TaskEntriesTableReferences),
          TaskEntryDb,
          PrefetchHooks Function({bool taskRule, bool componentId, bool bikeId})
        > {
  $$TaskEntriesTableTableManager(_$AppDatabase db, $TaskEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> dateTimeUTC = const Value.absent(),
                Value<DateTime> dateTimeLocal = const Value.absent(),
                Value<String> taskRule = const Value.absent(),
                Value<String?> componentId = const Value.absent(),
                Value<String?> bikeId = const Value.absent(),
                Value<String?> snapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskEntriesCompanion(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                notes: notes,
                dateTimeUTC: dateTimeUTC,
                dateTimeLocal: dateTimeLocal,
                taskRule: taskRule,
                componentId: componentId,
                bikeId: bikeId,
                snapshot: snapshot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> isDeleted = const Value.absent(),
                required DateTime lastModified,
                required String name,
                Value<String?> notes = const Value.absent(),
                required DateTime dateTimeUTC,
                required DateTime dateTimeLocal,
                required String taskRule,
                Value<String?> componentId = const Value.absent(),
                Value<String?> bikeId = const Value.absent(),
                Value<String?> snapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskEntriesCompanion.insert(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                notes: notes,
                dateTimeUTC: dateTimeUTC,
                dateTimeLocal: dateTimeLocal,
                taskRule: taskRule,
                componentId: componentId,
                bikeId: bikeId,
                snapshot: snapshot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({taskRule = false, componentId = false, bikeId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (taskRule) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.taskRule,
                                    referencedTable:
                                        $$TaskEntriesTableReferences
                                            ._taskRuleTable(db),
                                    referencedColumn:
                                        $$TaskEntriesTableReferences
                                            ._taskRuleTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (componentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.componentId,
                                    referencedTable:
                                        $$TaskEntriesTableReferences
                                            ._componentIdTable(db),
                                    referencedColumn:
                                        $$TaskEntriesTableReferences
                                            ._componentIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (bikeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bikeId,
                                    referencedTable:
                                        $$TaskEntriesTableReferences
                                            ._bikeIdTable(db),
                                    referencedColumn:
                                        $$TaskEntriesTableReferences
                                            ._bikeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TaskEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskEntriesTable,
      TaskEntryDb,
      $$TaskEntriesTableFilterComposer,
      $$TaskEntriesTableOrderingComposer,
      $$TaskEntriesTableAnnotationComposer,
      $$TaskEntriesTableCreateCompanionBuilder,
      $$TaskEntriesTableUpdateCompanionBuilder,
      (TaskEntryDb, $$TaskEntriesTableReferences),
      TaskEntryDb,
      PrefetchHooks Function({bool taskRule, bool componentId, bool bikeId})
    >;
typedef $$PersonsTableCreateCompanionBuilder =
    PersonsCompanion Function({
      required String id,
      Value<bool> isDeleted,
      required DateTime lastModified,
      required String name,
      Value<String?> notes,
      Value<int?> stravaAthlete,
      Value<int> orderIndex,
      Value<int> rowid,
    });
typedef $$PersonsTableUpdateCompanionBuilder =
    PersonsCompanion Function({
      Value<String> id,
      Value<bool> isDeleted,
      Value<DateTime> lastModified,
      Value<String> name,
      Value<String?> notes,
      Value<int?> stravaAthlete,
      Value<int> orderIndex,
      Value<int> rowid,
    });

final class $$PersonsTableReferences
    extends BaseReferences<_$AppDatabase, $PersonsTable, PersonDb> {
  $$PersonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AdjustmentsTable, List<AdjustmentDb>>
  _adjustmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.adjustments,
    aliasName: 'persons__id__adjustments__person_id',
  );

  $$AdjustmentsTableProcessedTableManager get adjustmentsRefs {
    final manager = $$AdjustmentsTableTableManager(
      $_db,
      $_db.adjustments,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_adjustmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SetupsTable, List<SetupDb>> _setupsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.setups,
    aliasName: 'persons__id__setups__person_id',
  );

  $$SetupsTableProcessedTableManager get setupsRefs {
    final manager = $$SetupsTableTableManager(
      $_db,
      $_db.setups,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_setupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PersonsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stravaAthlete => $composableBuilder(
    column: $table.stravaAthlete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> adjustmentsRefs(
    Expression<bool> Function($$AdjustmentsTableFilterComposer f) f,
  ) {
    final $$AdjustmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adjustments,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdjustmentsTableFilterComposer(
            $db: $db,
            $table: $db.adjustments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> setupsRefs(
    Expression<bool> Function($$SetupsTableFilterComposer f) f,
  ) {
    final $$SetupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setups,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetupsTableFilterComposer(
            $db: $db,
            $table: $db.setups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stravaAthlete => $composableBuilder(
    column: $table.stravaAthlete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get lastModified =>
      $composableBuilder(
        column: $table.lastModified,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get stravaAthlete => $composableBuilder(
    column: $table.stravaAthlete,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  Expression<T> adjustmentsRefs<T extends Object>(
    Expression<T> Function($$AdjustmentsTableAnnotationComposer a) f,
  ) {
    final $$AdjustmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adjustments,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdjustmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.adjustments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> setupsRefs<T extends Object>(
    Expression<T> Function($$SetupsTableAnnotationComposer a) f,
  ) {
    final $$SetupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setups,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetupsTableAnnotationComposer(
            $db: $db,
            $table: $db.setups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PersonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonsTable,
          PersonDb,
          $$PersonsTableFilterComposer,
          $$PersonsTableOrderingComposer,
          $$PersonsTableAnnotationComposer,
          $$PersonsTableCreateCompanionBuilder,
          $$PersonsTableUpdateCompanionBuilder,
          (PersonDb, $$PersonsTableReferences),
          PersonDb,
          PrefetchHooks Function({bool adjustmentsRefs, bool setupsRefs})
        > {
  $$PersonsTableTableManager(_$AppDatabase db, $PersonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> stravaAthlete = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonsCompanion(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                notes: notes,
                stravaAthlete: stravaAthlete,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> isDeleted = const Value.absent(),
                required DateTime lastModified,
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<int?> stravaAthlete = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonsCompanion.insert(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                notes: notes,
                stravaAthlete: stravaAthlete,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({adjustmentsRefs = false, setupsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (adjustmentsRefs) db.adjustments,
                    if (setupsRefs) db.setups,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (adjustmentsRefs)
                        await $_getPrefetchedData<
                          PersonDb,
                          $PersonsTable,
                          AdjustmentDb
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._adjustmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).adjustmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (setupsRefs)
                        await $_getPrefetchedData<
                          PersonDb,
                          $PersonsTable,
                          SetupDb
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._setupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).setupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PersonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonsTable,
      PersonDb,
      $$PersonsTableFilterComposer,
      $$PersonsTableOrderingComposer,
      $$PersonsTableAnnotationComposer,
      $$PersonsTableCreateCompanionBuilder,
      $$PersonsTableUpdateCompanionBuilder,
      (PersonDb, $$PersonsTableReferences),
      PersonDb,
      PrefetchHooks Function({bool adjustmentsRefs, bool setupsRefs})
    >;
typedef $$AdjustmentsTableCreateCompanionBuilder =
    AdjustmentsCompanion Function({
      required String id,
      Value<String?> componentId,
      Value<String?> personId,
      required int orderIndex,
      required String name,
      Value<String?> notes,
      Value<String?> unit,
      required AdjustmentType type,
      Value<String?> jsonPayload,
      Value<int> rowid,
    });
typedef $$AdjustmentsTableUpdateCompanionBuilder =
    AdjustmentsCompanion Function({
      Value<String> id,
      Value<String?> componentId,
      Value<String?> personId,
      Value<int> orderIndex,
      Value<String> name,
      Value<String?> notes,
      Value<String?> unit,
      Value<AdjustmentType> type,
      Value<String?> jsonPayload,
      Value<int> rowid,
    });

final class $$AdjustmentsTableReferences
    extends BaseReferences<_$AppDatabase, $AdjustmentsTable, AdjustmentDb> {
  $$AdjustmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ComponentsTable _componentIdTable(_$AppDatabase db) =>
      db.components.createAlias('adjustments__component_id__components__id');

  $$ComponentsTableProcessedTableManager? get componentId {
    final $_column = $_itemColumn<String>('component_id');
    if ($_column == null) return null;
    final manager = $$ComponentsTableTableManager(
      $_db,
      $_db.components,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_componentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias('adjustments__person_id__persons__id');

  $$PersonsTableProcessedTableManager? get personId {
    final $_column = $_itemColumn<String>('person_id');
    if ($_column == null) return null;
    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $SetupAdjustmentValuesTable,
    List<SetupAdjustmentValueDb>
  >
  _setupAdjustmentValuesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.setupAdjustmentValues,
        aliasName: 'adjustments__id__setup_adjustment_values__adjustment_id',
      );

  $$SetupAdjustmentValuesTableProcessedTableManager
  get setupAdjustmentValuesRefs {
    final manager = $$SetupAdjustmentValuesTableTableManager(
      $_db,
      $_db.setupAdjustmentValues,
    ).filter((f) => f.adjustmentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _setupAdjustmentValuesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AdjustmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AdjustmentsTable> {
  $$AdjustmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AdjustmentType, AdjustmentType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => ColumnFilters(column),
  );

  $$ComponentsTableFilterComposer get componentId {
    final $$ComponentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableFilterComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> setupAdjustmentValuesRefs(
    Expression<bool> Function($$SetupAdjustmentValuesTableFilterComposer f) f,
  ) {
    final $$SetupAdjustmentValuesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.setupAdjustmentValues,
          getReferencedColumn: (t) => t.adjustmentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SetupAdjustmentValuesTableFilterComposer(
                $db: $db,
                $table: $db.setupAdjustmentValues,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AdjustmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AdjustmentsTable> {
  $$AdjustmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => ColumnOrderings(column),
  );

  $$ComponentsTableOrderingComposer get componentId {
    final $$ComponentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableOrderingComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdjustmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdjustmentsTable> {
  $$AdjustmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AdjustmentType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => column,
  );

  $$ComponentsTableAnnotationComposer get componentId {
    final $$ComponentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableAnnotationComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> setupAdjustmentValuesRefs<T extends Object>(
    Expression<T> Function($$SetupAdjustmentValuesTableAnnotationComposer a) f,
  ) {
    final $$SetupAdjustmentValuesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.setupAdjustmentValues,
          getReferencedColumn: (t) => t.adjustmentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SetupAdjustmentValuesTableAnnotationComposer(
                $db: $db,
                $table: $db.setupAdjustmentValues,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AdjustmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdjustmentsTable,
          AdjustmentDb,
          $$AdjustmentsTableFilterComposer,
          $$AdjustmentsTableOrderingComposer,
          $$AdjustmentsTableAnnotationComposer,
          $$AdjustmentsTableCreateCompanionBuilder,
          $$AdjustmentsTableUpdateCompanionBuilder,
          (AdjustmentDb, $$AdjustmentsTableReferences),
          AdjustmentDb,
          PrefetchHooks Function({
            bool componentId,
            bool personId,
            bool setupAdjustmentValuesRefs,
          })
        > {
  $$AdjustmentsTableTableManager(_$AppDatabase db, $AdjustmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdjustmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdjustmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdjustmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> componentId = const Value.absent(),
                Value<String?> personId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<AdjustmentType> type = const Value.absent(),
                Value<String?> jsonPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdjustmentsCompanion(
                id: id,
                componentId: componentId,
                personId: personId,
                orderIndex: orderIndex,
                name: name,
                notes: notes,
                unit: unit,
                type: type,
                jsonPayload: jsonPayload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> componentId = const Value.absent(),
                Value<String?> personId = const Value.absent(),
                required int orderIndex,
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                required AdjustmentType type,
                Value<String?> jsonPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdjustmentsCompanion.insert(
                id: id,
                componentId: componentId,
                personId: personId,
                orderIndex: orderIndex,
                name: name,
                notes: notes,
                unit: unit,
                type: type,
                jsonPayload: jsonPayload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AdjustmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                componentId = false,
                personId = false,
                setupAdjustmentValuesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (setupAdjustmentValuesRefs) db.setupAdjustmentValues,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (componentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.componentId,
                                    referencedTable:
                                        $$AdjustmentsTableReferences
                                            ._componentIdTable(db),
                                    referencedColumn:
                                        $$AdjustmentsTableReferences
                                            ._componentIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (personId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.personId,
                                    referencedTable:
                                        $$AdjustmentsTableReferences
                                            ._personIdTable(db),
                                    referencedColumn:
                                        $$AdjustmentsTableReferences
                                            ._personIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (setupAdjustmentValuesRefs)
                        await $_getPrefetchedData<
                          AdjustmentDb,
                          $AdjustmentsTable,
                          SetupAdjustmentValueDb
                        >(
                          currentTable: table,
                          referencedTable: $$AdjustmentsTableReferences
                              ._setupAdjustmentValuesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AdjustmentsTableReferences(
                                db,
                                table,
                                p0,
                              ).setupAdjustmentValuesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.adjustmentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AdjustmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdjustmentsTable,
      AdjustmentDb,
      $$AdjustmentsTableFilterComposer,
      $$AdjustmentsTableOrderingComposer,
      $$AdjustmentsTableAnnotationComposer,
      $$AdjustmentsTableCreateCompanionBuilder,
      $$AdjustmentsTableUpdateCompanionBuilder,
      (AdjustmentDb, $$AdjustmentsTableReferences),
      AdjustmentDb,
      PrefetchHooks Function({
        bool componentId,
        bool personId,
        bool setupAdjustmentValuesRefs,
      })
    >;
typedef $$InstallationsTableCreateCompanionBuilder =
    InstallationsCompanion Function({
      required String id,
      required String componentId,
      Value<String?> parent,
      Value<InstallationParentType> parentType,
      required DateTime dateTimeUTC,
      required DateTime dateTimeLocal,
      Value<int> rowid,
    });
typedef $$InstallationsTableUpdateCompanionBuilder =
    InstallationsCompanion Function({
      Value<String> id,
      Value<String> componentId,
      Value<String?> parent,
      Value<InstallationParentType> parentType,
      Value<DateTime> dateTimeUTC,
      Value<DateTime> dateTimeLocal,
      Value<int> rowid,
    });

final class $$InstallationsTableReferences
    extends BaseReferences<_$AppDatabase, $InstallationsTable, InstallationDb> {
  $$InstallationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ComponentsTable _componentIdTable(_$AppDatabase db) =>
      db.components.createAlias('installations__component_id__components__id');

  $$ComponentsTableProcessedTableManager get componentId {
    final $_column = $_itemColumn<String>('component_id')!;

    final manager = $$ComponentsTableTableManager(
      $_db,
      $_db.components,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_componentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InstallationsTableFilterComposer
    extends Composer<_$AppDatabase, $InstallationsTable> {
  $$InstallationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parent => $composableBuilder(
    column: $table.parent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    InstallationParentType,
    InstallationParentType,
    String
  >
  get parentType => $composableBuilder(
    column: $table.parentType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get dateTimeUTC => $composableBuilder(
    column: $table.dateTimeUTC,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get dateTimeLocal => $composableBuilder(
    column: $table.dateTimeLocal,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$ComponentsTableFilterComposer get componentId {
    final $$ComponentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableFilterComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallationsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstallationsTable> {
  $$InstallationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parent => $composableBuilder(
    column: $table.parent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentType => $composableBuilder(
    column: $table.parentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTimeUTC => $composableBuilder(
    column: $table.dateTimeUTC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTimeLocal => $composableBuilder(
    column: $table.dateTimeLocal,
    builder: (column) => ColumnOrderings(column),
  );

  $$ComponentsTableOrderingComposer get componentId {
    final $$ComponentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableOrderingComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstallationsTable> {
  $$InstallationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parent =>
      $composableBuilder(column: $table.parent, builder: (column) => column);

  GeneratedColumnWithTypeConverter<InstallationParentType, String>
  get parentType => $composableBuilder(
    column: $table.parentType,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get dateTimeUTC =>
      $composableBuilder(
        column: $table.dateTimeUTC,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get dateTimeLocal =>
      $composableBuilder(
        column: $table.dateTimeLocal,
        builder: (column) => column,
      );

  $$ComponentsTableAnnotationComposer get componentId {
    final $$ComponentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.components,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComponentsTableAnnotationComposer(
            $db: $db,
            $table: $db.components,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstallationsTable,
          InstallationDb,
          $$InstallationsTableFilterComposer,
          $$InstallationsTableOrderingComposer,
          $$InstallationsTableAnnotationComposer,
          $$InstallationsTableCreateCompanionBuilder,
          $$InstallationsTableUpdateCompanionBuilder,
          (InstallationDb, $$InstallationsTableReferences),
          InstallationDb,
          PrefetchHooks Function({bool componentId})
        > {
  $$InstallationsTableTableManager(_$AppDatabase db, $InstallationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstallationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstallationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> componentId = const Value.absent(),
                Value<String?> parent = const Value.absent(),
                Value<InstallationParentType> parentType = const Value.absent(),
                Value<DateTime> dateTimeUTC = const Value.absent(),
                Value<DateTime> dateTimeLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstallationsCompanion(
                id: id,
                componentId: componentId,
                parent: parent,
                parentType: parentType,
                dateTimeUTC: dateTimeUTC,
                dateTimeLocal: dateTimeLocal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String componentId,
                Value<String?> parent = const Value.absent(),
                Value<InstallationParentType> parentType = const Value.absent(),
                required DateTime dateTimeUTC,
                required DateTime dateTimeLocal,
                Value<int> rowid = const Value.absent(),
              }) => InstallationsCompanion.insert(
                id: id,
                componentId: componentId,
                parent: parent,
                parentType: parentType,
                dateTimeUTC: dateTimeUTC,
                dateTimeLocal: dateTimeLocal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InstallationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({componentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (componentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.componentId,
                                referencedTable: $$InstallationsTableReferences
                                    ._componentIdTable(db),
                                referencedColumn: $$InstallationsTableReferences
                                    ._componentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InstallationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstallationsTable,
      InstallationDb,
      $$InstallationsTableFilterComposer,
      $$InstallationsTableOrderingComposer,
      $$InstallationsTableAnnotationComposer,
      $$InstallationsTableCreateCompanionBuilder,
      $$InstallationsTableUpdateCompanionBuilder,
      (InstallationDb, $$InstallationsTableReferences),
      InstallationDb,
      PrefetchHooks Function({bool componentId})
    >;
typedef $$SetupsTableCreateCompanionBuilder =
    SetupsCompanion Function({
      required String id,
      required String bikeId,
      Value<String?> personId,
      Value<bool> isDeleted,
      required DateTime lastModified,
      Value<String?> name,
      required DateTime datetime,
      required DateTime datetimeLocal,
      Value<String?> notes,
      required Set<String> tags,
      Value<List<String>> images,
      Value<ContextPosition?> position,
      Value<geo.Placemark?> place,
      Value<ContextWeather?> weather,
      Value<int> rowid,
    });
typedef $$SetupsTableUpdateCompanionBuilder =
    SetupsCompanion Function({
      Value<String> id,
      Value<String> bikeId,
      Value<String?> personId,
      Value<bool> isDeleted,
      Value<DateTime> lastModified,
      Value<String?> name,
      Value<DateTime> datetime,
      Value<DateTime> datetimeLocal,
      Value<String?> notes,
      Value<Set<String>> tags,
      Value<List<String>> images,
      Value<ContextPosition?> position,
      Value<geo.Placemark?> place,
      Value<ContextWeather?> weather,
      Value<int> rowid,
    });

final class $$SetupsTableReferences
    extends BaseReferences<_$AppDatabase, $SetupsTable, SetupDb> {
  $$SetupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BikesTable _bikeIdTable(_$AppDatabase db) =>
      db.bikes.createAlias('setups__bike_id__bikes__id');

  $$BikesTableProcessedTableManager get bikeId {
    final $_column = $_itemColumn<String>('bike_id')!;

    final manager = $$BikesTableTableManager(
      $_db,
      $_db.bikes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bikeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias('setups__person_id__persons__id');

  $$PersonsTableProcessedTableManager? get personId {
    final $_column = $_itemColumn<String>('person_id');
    if ($_column == null) return null;
    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $SetupAdjustmentValuesTable,
    List<SetupAdjustmentValueDb>
  >
  _setupAdjustmentValuesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.setupAdjustmentValues,
        aliasName: 'setups__id__setup_adjustment_values__setup_id',
      );

  $$SetupAdjustmentValuesTableProcessedTableManager
  get setupAdjustmentValuesRefs {
    final manager = $$SetupAdjustmentValuesTableTableManager(
      $_db,
      $_db.setupAdjustmentValues,
    ).filter((f) => f.setupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _setupAdjustmentValuesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RatingEntriesTable, List<RatingEntryDb>>
  _ratingEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ratingEntries,
    aliasName: 'setups__id__rating_entries__setup_id',
  );

  $$RatingEntriesTableProcessedTableManager get ratingEntriesRefs {
    final manager = $$RatingEntriesTableTableManager(
      $_db,
      $_db.ratingEntries,
    ).filter((f) => f.setupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ratingEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SetupsTableFilterComposer
    extends Composer<_$AppDatabase, $SetupsTable> {
  $$SetupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get datetime =>
      $composableBuilder(
        column: $table.datetime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get datetimeLocal => $composableBuilder(
    column: $table.datetimeLocal,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Set<String>, Set<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ContextPosition?, ContextPosition, String>
  get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<geo.Placemark?, geo.Placemark, String>
  get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ContextWeather?, ContextWeather, String>
  get weather => $composableBuilder(
    column: $table.weather,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$BikesTableFilterComposer get bikeId {
    final $$BikesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bikeId,
      referencedTable: $db.bikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BikesTableFilterComposer(
            $db: $db,
            $table: $db.bikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> setupAdjustmentValuesRefs(
    Expression<bool> Function($$SetupAdjustmentValuesTableFilterComposer f) f,
  ) {
    final $$SetupAdjustmentValuesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.setupAdjustmentValues,
          getReferencedColumn: (t) => t.setupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SetupAdjustmentValuesTableFilterComposer(
                $db: $db,
                $table: $db.setupAdjustmentValues,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> ratingEntriesRefs(
    Expression<bool> Function($$RatingEntriesTableFilterComposer f) f,
  ) {
    final $$RatingEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ratingEntries,
      getReferencedColumn: (t) => t.setupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ratingEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SetupsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetupsTable> {
  $$SetupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get datetime => $composableBuilder(
    column: $table.datetime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get datetimeLocal => $composableBuilder(
    column: $table.datetimeLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weather => $composableBuilder(
    column: $table.weather,
    builder: (column) => ColumnOrderings(column),
  );

  $$BikesTableOrderingComposer get bikeId {
    final $$BikesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bikeId,
      referencedTable: $db.bikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BikesTableOrderingComposer(
            $db: $db,
            $table: $db.bikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetupsTable> {
  $$SetupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get lastModified =>
      $composableBuilder(
        column: $table.lastModified,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get datetime =>
      $composableBuilder(column: $table.datetime, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get datetimeLocal =>
      $composableBuilder(
        column: $table.datetimeLocal,
        builder: (column) => column,
      );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Set<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get images =>
      $composableBuilder(column: $table.images, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ContextPosition?, String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumnWithTypeConverter<geo.Placemark?, String> get place =>
      $composableBuilder(column: $table.place, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ContextWeather?, String> get weather =>
      $composableBuilder(column: $table.weather, builder: (column) => column);

  $$BikesTableAnnotationComposer get bikeId {
    final $$BikesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bikeId,
      referencedTable: $db.bikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BikesTableAnnotationComposer(
            $db: $db,
            $table: $db.bikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> setupAdjustmentValuesRefs<T extends Object>(
    Expression<T> Function($$SetupAdjustmentValuesTableAnnotationComposer a) f,
  ) {
    final $$SetupAdjustmentValuesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.setupAdjustmentValues,
          getReferencedColumn: (t) => t.setupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SetupAdjustmentValuesTableAnnotationComposer(
                $db: $db,
                $table: $db.setupAdjustmentValues,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> ratingEntriesRefs<T extends Object>(
    Expression<T> Function($$RatingEntriesTableAnnotationComposer a) f,
  ) {
    final $$RatingEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ratingEntries,
      getReferencedColumn: (t) => t.setupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ratingEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SetupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetupsTable,
          SetupDb,
          $$SetupsTableFilterComposer,
          $$SetupsTableOrderingComposer,
          $$SetupsTableAnnotationComposer,
          $$SetupsTableCreateCompanionBuilder,
          $$SetupsTableUpdateCompanionBuilder,
          (SetupDb, $$SetupsTableReferences),
          SetupDb,
          PrefetchHooks Function({
            bool bikeId,
            bool personId,
            bool setupAdjustmentValuesRefs,
            bool ratingEntriesRefs,
          })
        > {
  $$SetupsTableTableManager(_$AppDatabase db, $SetupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bikeId = const Value.absent(),
                Value<String?> personId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<DateTime> datetime = const Value.absent(),
                Value<DateTime> datetimeLocal = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<Set<String>> tags = const Value.absent(),
                Value<List<String>> images = const Value.absent(),
                Value<ContextPosition?> position = const Value.absent(),
                Value<geo.Placemark?> place = const Value.absent(),
                Value<ContextWeather?> weather = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetupsCompanion(
                id: id,
                bikeId: bikeId,
                personId: personId,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                datetime: datetime,
                datetimeLocal: datetimeLocal,
                notes: notes,
                tags: tags,
                images: images,
                position: position,
                place: place,
                weather: weather,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bikeId,
                Value<String?> personId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required DateTime lastModified,
                Value<String?> name = const Value.absent(),
                required DateTime datetime,
                required DateTime datetimeLocal,
                Value<String?> notes = const Value.absent(),
                required Set<String> tags,
                Value<List<String>> images = const Value.absent(),
                Value<ContextPosition?> position = const Value.absent(),
                Value<geo.Placemark?> place = const Value.absent(),
                Value<ContextWeather?> weather = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetupsCompanion.insert(
                id: id,
                bikeId: bikeId,
                personId: personId,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                datetime: datetime,
                datetimeLocal: datetimeLocal,
                notes: notes,
                tags: tags,
                images: images,
                position: position,
                place: place,
                weather: weather,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SetupsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bikeId = false,
                personId = false,
                setupAdjustmentValuesRefs = false,
                ratingEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (setupAdjustmentValuesRefs) db.setupAdjustmentValues,
                    if (ratingEntriesRefs) db.ratingEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (bikeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bikeId,
                                    referencedTable: $$SetupsTableReferences
                                        ._bikeIdTable(db),
                                    referencedColumn: $$SetupsTableReferences
                                        ._bikeIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (personId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.personId,
                                    referencedTable: $$SetupsTableReferences
                                        ._personIdTable(db),
                                    referencedColumn: $$SetupsTableReferences
                                        ._personIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (setupAdjustmentValuesRefs)
                        await $_getPrefetchedData<
                          SetupDb,
                          $SetupsTable,
                          SetupAdjustmentValueDb
                        >(
                          currentTable: table,
                          referencedTable: $$SetupsTableReferences
                              ._setupAdjustmentValuesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SetupsTableReferences(
                                db,
                                table,
                                p0,
                              ).setupAdjustmentValuesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.setupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ratingEntriesRefs)
                        await $_getPrefetchedData<
                          SetupDb,
                          $SetupsTable,
                          RatingEntryDb
                        >(
                          currentTable: table,
                          referencedTable: $$SetupsTableReferences
                              ._ratingEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SetupsTableReferences(
                                db,
                                table,
                                p0,
                              ).ratingEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.setupId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SetupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetupsTable,
      SetupDb,
      $$SetupsTableFilterComposer,
      $$SetupsTableOrderingComposer,
      $$SetupsTableAnnotationComposer,
      $$SetupsTableCreateCompanionBuilder,
      $$SetupsTableUpdateCompanionBuilder,
      (SetupDb, $$SetupsTableReferences),
      SetupDb,
      PrefetchHooks Function({
        bool bikeId,
        bool personId,
        bool setupAdjustmentValuesRefs,
        bool ratingEntriesRefs,
      })
    >;
typedef $$SetupAdjustmentValuesTableCreateCompanionBuilder =
    SetupAdjustmentValuesCompanion Function({
      required String setupId,
      required String adjustmentId,
      required String value,
      Value<int> rowid,
    });
typedef $$SetupAdjustmentValuesTableUpdateCompanionBuilder =
    SetupAdjustmentValuesCompanion Function({
      Value<String> setupId,
      Value<String> adjustmentId,
      Value<String> value,
      Value<int> rowid,
    });

final class $$SetupAdjustmentValuesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SetupAdjustmentValuesTable,
          SetupAdjustmentValueDb
        > {
  $$SetupAdjustmentValuesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SetupsTable _setupIdTable(_$AppDatabase db) =>
      db.setups.createAlias('setup_adjustment_values__setup_id__setups__id');

  $$SetupsTableProcessedTableManager get setupId {
    final $_column = $_itemColumn<String>('setup_id')!;

    final manager = $$SetupsTableTableManager(
      $_db,
      $_db.setups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_setupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AdjustmentsTable _adjustmentIdTable(_$AppDatabase db) => db
      .adjustments
      .createAlias('setup_adjustment_values__adjustment_id__adjustments__id');

  $$AdjustmentsTableProcessedTableManager get adjustmentId {
    final $_column = $_itemColumn<String>('adjustment_id')!;

    final manager = $$AdjustmentsTableTableManager(
      $_db,
      $_db.adjustments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_adjustmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SetupAdjustmentValuesTableFilterComposer
    extends Composer<_$AppDatabase, $SetupAdjustmentValuesTable> {
  $$SetupAdjustmentValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$SetupsTableFilterComposer get setupId {
    final $$SetupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setupId,
      referencedTable: $db.setups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetupsTableFilterComposer(
            $db: $db,
            $table: $db.setups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AdjustmentsTableFilterComposer get adjustmentId {
    final $$AdjustmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adjustmentId,
      referencedTable: $db.adjustments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdjustmentsTableFilterComposer(
            $db: $db,
            $table: $db.adjustments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetupAdjustmentValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $SetupAdjustmentValuesTable> {
  $$SetupAdjustmentValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$SetupsTableOrderingComposer get setupId {
    final $$SetupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setupId,
      referencedTable: $db.setups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetupsTableOrderingComposer(
            $db: $db,
            $table: $db.setups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AdjustmentsTableOrderingComposer get adjustmentId {
    final $$AdjustmentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adjustmentId,
      referencedTable: $db.adjustments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdjustmentsTableOrderingComposer(
            $db: $db,
            $table: $db.adjustments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetupAdjustmentValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetupAdjustmentValuesTable> {
  $$SetupAdjustmentValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$SetupsTableAnnotationComposer get setupId {
    final $$SetupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setupId,
      referencedTable: $db.setups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetupsTableAnnotationComposer(
            $db: $db,
            $table: $db.setups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AdjustmentsTableAnnotationComposer get adjustmentId {
    final $$AdjustmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adjustmentId,
      referencedTable: $db.adjustments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdjustmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.adjustments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetupAdjustmentValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetupAdjustmentValuesTable,
          SetupAdjustmentValueDb,
          $$SetupAdjustmentValuesTableFilterComposer,
          $$SetupAdjustmentValuesTableOrderingComposer,
          $$SetupAdjustmentValuesTableAnnotationComposer,
          $$SetupAdjustmentValuesTableCreateCompanionBuilder,
          $$SetupAdjustmentValuesTableUpdateCompanionBuilder,
          (SetupAdjustmentValueDb, $$SetupAdjustmentValuesTableReferences),
          SetupAdjustmentValueDb,
          PrefetchHooks Function({bool setupId, bool adjustmentId})
        > {
  $$SetupAdjustmentValuesTableTableManager(
    _$AppDatabase db,
    $SetupAdjustmentValuesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetupAdjustmentValuesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SetupAdjustmentValuesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SetupAdjustmentValuesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> setupId = const Value.absent(),
                Value<String> adjustmentId = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetupAdjustmentValuesCompanion(
                setupId: setupId,
                adjustmentId: adjustmentId,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String setupId,
                required String adjustmentId,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SetupAdjustmentValuesCompanion.insert(
                setupId: setupId,
                adjustmentId: adjustmentId,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SetupAdjustmentValuesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({setupId = false, adjustmentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (setupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.setupId,
                                referencedTable:
                                    $$SetupAdjustmentValuesTableReferences
                                        ._setupIdTable(db),
                                referencedColumn:
                                    $$SetupAdjustmentValuesTableReferences
                                        ._setupIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (adjustmentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.adjustmentId,
                                referencedTable:
                                    $$SetupAdjustmentValuesTableReferences
                                        ._adjustmentIdTable(db),
                                referencedColumn:
                                    $$SetupAdjustmentValuesTableReferences
                                        ._adjustmentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SetupAdjustmentValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetupAdjustmentValuesTable,
      SetupAdjustmentValueDb,
      $$SetupAdjustmentValuesTableFilterComposer,
      $$SetupAdjustmentValuesTableOrderingComposer,
      $$SetupAdjustmentValuesTableAnnotationComposer,
      $$SetupAdjustmentValuesTableCreateCompanionBuilder,
      $$SetupAdjustmentValuesTableUpdateCompanionBuilder,
      (SetupAdjustmentValueDb, $$SetupAdjustmentValuesTableReferences),
      SetupAdjustmentValueDb,
      PrefetchHooks Function({bool setupId, bool adjustmentId})
    >;
typedef $$RatingsTableCreateCompanionBuilder =
    RatingsCompanion Function({
      required String id,
      Value<bool> isDeleted,
      required DateTime lastModified,
      required String name,
      Value<String?> notes,
      Value<String?> filter,
      required FilterType filterType,
      Value<int> orderIndex,
      Value<int> rowid,
    });
typedef $$RatingsTableUpdateCompanionBuilder =
    RatingsCompanion Function({
      Value<String> id,
      Value<bool> isDeleted,
      Value<DateTime> lastModified,
      Value<String> name,
      Value<String?> notes,
      Value<String?> filter,
      Value<FilterType> filterType,
      Value<int> orderIndex,
      Value<int> rowid,
    });

final class $$RatingsTableReferences
    extends BaseReferences<_$AppDatabase, $RatingsTable, RatingDb> {
  $$RatingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RatingMetricsTable, List<RatingMetricDb>>
  _ratingMetricsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ratingMetrics,
    aliasName: 'ratings__id__rating_metrics__rating_id',
  );

  $$RatingMetricsTableProcessedTableManager get ratingMetricsRefs {
    final manager = $$RatingMetricsTableTableManager(
      $_db,
      $_db.ratingMetrics,
    ).filter((f) => f.ratingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ratingMetricsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RatingsTableFilterComposer
    extends Composer<_$AppDatabase, $RatingsTable> {
  $$RatingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filter => $composableBuilder(
    column: $table.filter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FilterType, FilterType, String>
  get filterType => $composableBuilder(
    column: $table.filterType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ratingMetricsRefs(
    Expression<bool> Function($$RatingMetricsTableFilterComposer f) f,
  ) {
    final $$RatingMetricsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ratingMetrics,
      getReferencedColumn: (t) => t.ratingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingMetricsTableFilterComposer(
            $db: $db,
            $table: $db.ratingMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RatingsTableOrderingComposer
    extends Composer<_$AppDatabase, $RatingsTable> {
  $$RatingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filter => $composableBuilder(
    column: $table.filter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterType => $composableBuilder(
    column: $table.filterType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RatingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RatingsTable> {
  $$RatingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get lastModified =>
      $composableBuilder(
        column: $table.lastModified,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get filter =>
      $composableBuilder(column: $table.filter, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FilterType, String> get filterType =>
      $composableBuilder(
        column: $table.filterType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  Expression<T> ratingMetricsRefs<T extends Object>(
    Expression<T> Function($$RatingMetricsTableAnnotationComposer a) f,
  ) {
    final $$RatingMetricsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ratingMetrics,
      getReferencedColumn: (t) => t.ratingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingMetricsTableAnnotationComposer(
            $db: $db,
            $table: $db.ratingMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RatingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RatingsTable,
          RatingDb,
          $$RatingsTableFilterComposer,
          $$RatingsTableOrderingComposer,
          $$RatingsTableAnnotationComposer,
          $$RatingsTableCreateCompanionBuilder,
          $$RatingsTableUpdateCompanionBuilder,
          (RatingDb, $$RatingsTableReferences),
          RatingDb,
          PrefetchHooks Function({bool ratingMetricsRefs})
        > {
  $$RatingsTableTableManager(_$AppDatabase db, $RatingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RatingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RatingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RatingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> filter = const Value.absent(),
                Value<FilterType> filterType = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatingsCompanion(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                notes: notes,
                filter: filter,
                filterType: filterType,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> isDeleted = const Value.absent(),
                required DateTime lastModified,
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<String?> filter = const Value.absent(),
                required FilterType filterType,
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatingsCompanion.insert(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                notes: notes,
                filter: filter,
                filterType: filterType,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RatingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ratingMetricsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ratingMetricsRefs) db.ratingMetrics,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ratingMetricsRefs)
                    await $_getPrefetchedData<
                      RatingDb,
                      $RatingsTable,
                      RatingMetricDb
                    >(
                      currentTable: table,
                      referencedTable: $$RatingsTableReferences
                          ._ratingMetricsRefsTable(db),
                      managerFromTypedResult: (p0) => $$RatingsTableReferences(
                        db,
                        table,
                        p0,
                      ).ratingMetricsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.ratingId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RatingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RatingsTable,
      RatingDb,
      $$RatingsTableFilterComposer,
      $$RatingsTableOrderingComposer,
      $$RatingsTableAnnotationComposer,
      $$RatingsTableCreateCompanionBuilder,
      $$RatingsTableUpdateCompanionBuilder,
      (RatingDb, $$RatingsTableReferences),
      RatingDb,
      PrefetchHooks Function({bool ratingMetricsRefs})
    >;
typedef $$RatingMetricsTableCreateCompanionBuilder =
    RatingMetricsCompanion Function({
      required String id,
      required String ratingId,
      required int orderIndex,
      Value<double> weight,
      required String name,
      Value<String?> notes,
      Value<String?> unit,
      required AdjustmentType type,
      Value<String?> jsonPayload,
      Value<int> rowid,
    });
typedef $$RatingMetricsTableUpdateCompanionBuilder =
    RatingMetricsCompanion Function({
      Value<String> id,
      Value<String> ratingId,
      Value<int> orderIndex,
      Value<double> weight,
      Value<String> name,
      Value<String?> notes,
      Value<String?> unit,
      Value<AdjustmentType> type,
      Value<String?> jsonPayload,
      Value<int> rowid,
    });

final class $$RatingMetricsTableReferences
    extends BaseReferences<_$AppDatabase, $RatingMetricsTable, RatingMetricDb> {
  $$RatingMetricsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RatingsTable _ratingIdTable(_$AppDatabase db) =>
      db.ratings.createAlias('rating_metrics__rating_id__ratings__id');

  $$RatingsTableProcessedTableManager get ratingId {
    final $_column = $_itemColumn<String>('rating_id')!;

    final manager = $$RatingsTableTableManager(
      $_db,
      $_db.ratings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ratingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RatingEntryValuesTable, List<RatingEntryValueDb>>
  _ratingEntryValuesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ratingEntryValues,
        aliasName: 'rating_metrics__id__rating_entry_values__rating_metric_id',
      );

  $$RatingEntryValuesTableProcessedTableManager get ratingEntryValuesRefs {
    final manager = $$RatingEntryValuesTableTableManager(
      $_db,
      $_db.ratingEntryValues,
    ).filter((f) => f.ratingMetricId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ratingEntryValuesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RatingMetricsTableFilterComposer
    extends Composer<_$AppDatabase, $RatingMetricsTable> {
  $$RatingMetricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AdjustmentType, AdjustmentType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => ColumnFilters(column),
  );

  $$RatingsTableFilterComposer get ratingId {
    final $$RatingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ratingId,
      referencedTable: $db.ratings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingsTableFilterComposer(
            $db: $db,
            $table: $db.ratings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ratingEntryValuesRefs(
    Expression<bool> Function($$RatingEntryValuesTableFilterComposer f) f,
  ) {
    final $$RatingEntryValuesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ratingEntryValues,
      getReferencedColumn: (t) => t.ratingMetricId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingEntryValuesTableFilterComposer(
            $db: $db,
            $table: $db.ratingEntryValues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RatingMetricsTableOrderingComposer
    extends Composer<_$AppDatabase, $RatingMetricsTable> {
  $$RatingMetricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => ColumnOrderings(column),
  );

  $$RatingsTableOrderingComposer get ratingId {
    final $$RatingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ratingId,
      referencedTable: $db.ratings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingsTableOrderingComposer(
            $db: $db,
            $table: $db.ratings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RatingMetricsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RatingMetricsTable> {
  $$RatingMetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AdjustmentType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get jsonPayload => $composableBuilder(
    column: $table.jsonPayload,
    builder: (column) => column,
  );

  $$RatingsTableAnnotationComposer get ratingId {
    final $$RatingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ratingId,
      referencedTable: $db.ratings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingsTableAnnotationComposer(
            $db: $db,
            $table: $db.ratings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ratingEntryValuesRefs<T extends Object>(
    Expression<T> Function($$RatingEntryValuesTableAnnotationComposer a) f,
  ) {
    final $$RatingEntryValuesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ratingEntryValues,
          getReferencedColumn: (t) => t.ratingMetricId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RatingEntryValuesTableAnnotationComposer(
                $db: $db,
                $table: $db.ratingEntryValues,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RatingMetricsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RatingMetricsTable,
          RatingMetricDb,
          $$RatingMetricsTableFilterComposer,
          $$RatingMetricsTableOrderingComposer,
          $$RatingMetricsTableAnnotationComposer,
          $$RatingMetricsTableCreateCompanionBuilder,
          $$RatingMetricsTableUpdateCompanionBuilder,
          (RatingMetricDb, $$RatingMetricsTableReferences),
          RatingMetricDb,
          PrefetchHooks Function({bool ratingId, bool ratingEntryValuesRefs})
        > {
  $$RatingMetricsTableTableManager(_$AppDatabase db, $RatingMetricsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RatingMetricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RatingMetricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RatingMetricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ratingId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<AdjustmentType> type = const Value.absent(),
                Value<String?> jsonPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatingMetricsCompanion(
                id: id,
                ratingId: ratingId,
                orderIndex: orderIndex,
                weight: weight,
                name: name,
                notes: notes,
                unit: unit,
                type: type,
                jsonPayload: jsonPayload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ratingId,
                required int orderIndex,
                Value<double> weight = const Value.absent(),
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                required AdjustmentType type,
                Value<String?> jsonPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatingMetricsCompanion.insert(
                id: id,
                ratingId: ratingId,
                orderIndex: orderIndex,
                weight: weight,
                name: name,
                notes: notes,
                unit: unit,
                type: type,
                jsonPayload: jsonPayload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RatingMetricsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({ratingId = false, ratingEntryValuesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ratingEntryValuesRefs) db.ratingEntryValues,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ratingId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ratingId,
                                    referencedTable:
                                        $$RatingMetricsTableReferences
                                            ._ratingIdTable(db),
                                    referencedColumn:
                                        $$RatingMetricsTableReferences
                                            ._ratingIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ratingEntryValuesRefs)
                        await $_getPrefetchedData<
                          RatingMetricDb,
                          $RatingMetricsTable,
                          RatingEntryValueDb
                        >(
                          currentTable: table,
                          referencedTable: $$RatingMetricsTableReferences
                              ._ratingEntryValuesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RatingMetricsTableReferences(
                                db,
                                table,
                                p0,
                              ).ratingEntryValuesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ratingMetricId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RatingMetricsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RatingMetricsTable,
      RatingMetricDb,
      $$RatingMetricsTableFilterComposer,
      $$RatingMetricsTableOrderingComposer,
      $$RatingMetricsTableAnnotationComposer,
      $$RatingMetricsTableCreateCompanionBuilder,
      $$RatingMetricsTableUpdateCompanionBuilder,
      (RatingMetricDb, $$RatingMetricsTableReferences),
      RatingMetricDb,
      PrefetchHooks Function({bool ratingId, bool ratingEntryValuesRefs})
    >;
typedef $$RatingEntriesTableCreateCompanionBuilder =
    RatingEntriesCompanion Function({
      required String id,
      required String bikeId,
      required String setupId,
      Value<bool> isDeleted,
      required DateTime lastModified,
      Value<String?> name,
      required DateTime dateTimeUTC,
      required DateTime dateTimeLocal,
      Value<String?> notes,
      Value<ContextPosition?> position,
      Value<geo.Placemark?> place,
      Value<ContextWeather?> weather,
      Value<int> rowid,
    });
typedef $$RatingEntriesTableUpdateCompanionBuilder =
    RatingEntriesCompanion Function({
      Value<String> id,
      Value<String> bikeId,
      Value<String> setupId,
      Value<bool> isDeleted,
      Value<DateTime> lastModified,
      Value<String?> name,
      Value<DateTime> dateTimeUTC,
      Value<DateTime> dateTimeLocal,
      Value<String?> notes,
      Value<ContextPosition?> position,
      Value<geo.Placemark?> place,
      Value<ContextWeather?> weather,
      Value<int> rowid,
    });

final class $$RatingEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $RatingEntriesTable, RatingEntryDb> {
  $$RatingEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BikesTable _bikeIdTable(_$AppDatabase db) =>
      db.bikes.createAlias('rating_entries__bike_id__bikes__id');

  $$BikesTableProcessedTableManager get bikeId {
    final $_column = $_itemColumn<String>('bike_id')!;

    final manager = $$BikesTableTableManager(
      $_db,
      $_db.bikes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bikeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SetupsTable _setupIdTable(_$AppDatabase db) =>
      db.setups.createAlias('rating_entries__setup_id__setups__id');

  $$SetupsTableProcessedTableManager get setupId {
    final $_column = $_itemColumn<String>('setup_id')!;

    final manager = $$SetupsTableTableManager(
      $_db,
      $_db.setups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_setupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RatingEntryValuesTable, List<RatingEntryValueDb>>
  _ratingEntryValuesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ratingEntryValues,
        aliasName: 'rating_entries__id__rating_entry_values__rating_entry_id',
      );

  $$RatingEntryValuesTableProcessedTableManager get ratingEntryValuesRefs {
    final manager = $$RatingEntryValuesTableTableManager(
      $_db,
      $_db.ratingEntryValues,
    ).filter((f) => f.ratingEntryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ratingEntryValuesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RatingEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $RatingEntriesTable> {
  $$RatingEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get dateTimeUTC => $composableBuilder(
    column: $table.dateTimeUTC,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get dateTimeLocal => $composableBuilder(
    column: $table.dateTimeLocal,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ContextPosition?, ContextPosition, String>
  get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<geo.Placemark?, geo.Placemark, String>
  get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ContextWeather?, ContextWeather, String>
  get weather => $composableBuilder(
    column: $table.weather,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$BikesTableFilterComposer get bikeId {
    final $$BikesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bikeId,
      referencedTable: $db.bikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BikesTableFilterComposer(
            $db: $db,
            $table: $db.bikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SetupsTableFilterComposer get setupId {
    final $$SetupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setupId,
      referencedTable: $db.setups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetupsTableFilterComposer(
            $db: $db,
            $table: $db.setups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ratingEntryValuesRefs(
    Expression<bool> Function($$RatingEntryValuesTableFilterComposer f) f,
  ) {
    final $$RatingEntryValuesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ratingEntryValues,
      getReferencedColumn: (t) => t.ratingEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingEntryValuesTableFilterComposer(
            $db: $db,
            $table: $db.ratingEntryValues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RatingEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $RatingEntriesTable> {
  $$RatingEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTimeUTC => $composableBuilder(
    column: $table.dateTimeUTC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTimeLocal => $composableBuilder(
    column: $table.dateTimeLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weather => $composableBuilder(
    column: $table.weather,
    builder: (column) => ColumnOrderings(column),
  );

  $$BikesTableOrderingComposer get bikeId {
    final $$BikesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bikeId,
      referencedTable: $db.bikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BikesTableOrderingComposer(
            $db: $db,
            $table: $db.bikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SetupsTableOrderingComposer get setupId {
    final $$SetupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setupId,
      referencedTable: $db.setups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetupsTableOrderingComposer(
            $db: $db,
            $table: $db.setups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RatingEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RatingEntriesTable> {
  $$RatingEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get lastModified =>
      $composableBuilder(
        column: $table.lastModified,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get dateTimeUTC =>
      $composableBuilder(
        column: $table.dateTimeUTC,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get dateTimeLocal =>
      $composableBuilder(
        column: $table.dateTimeLocal,
        builder: (column) => column,
      );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ContextPosition?, String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumnWithTypeConverter<geo.Placemark?, String> get place =>
      $composableBuilder(column: $table.place, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ContextWeather?, String> get weather =>
      $composableBuilder(column: $table.weather, builder: (column) => column);

  $$BikesTableAnnotationComposer get bikeId {
    final $$BikesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bikeId,
      referencedTable: $db.bikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BikesTableAnnotationComposer(
            $db: $db,
            $table: $db.bikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SetupsTableAnnotationComposer get setupId {
    final $$SetupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setupId,
      referencedTable: $db.setups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetupsTableAnnotationComposer(
            $db: $db,
            $table: $db.setups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ratingEntryValuesRefs<T extends Object>(
    Expression<T> Function($$RatingEntryValuesTableAnnotationComposer a) f,
  ) {
    final $$RatingEntryValuesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ratingEntryValues,
          getReferencedColumn: (t) => t.ratingEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RatingEntryValuesTableAnnotationComposer(
                $db: $db,
                $table: $db.ratingEntryValues,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RatingEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RatingEntriesTable,
          RatingEntryDb,
          $$RatingEntriesTableFilterComposer,
          $$RatingEntriesTableOrderingComposer,
          $$RatingEntriesTableAnnotationComposer,
          $$RatingEntriesTableCreateCompanionBuilder,
          $$RatingEntriesTableUpdateCompanionBuilder,
          (RatingEntryDb, $$RatingEntriesTableReferences),
          RatingEntryDb,
          PrefetchHooks Function({
            bool bikeId,
            bool setupId,
            bool ratingEntryValuesRefs,
          })
        > {
  $$RatingEntriesTableTableManager(_$AppDatabase db, $RatingEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RatingEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RatingEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RatingEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bikeId = const Value.absent(),
                Value<String> setupId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<DateTime> dateTimeUTC = const Value.absent(),
                Value<DateTime> dateTimeLocal = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<ContextPosition?> position = const Value.absent(),
                Value<geo.Placemark?> place = const Value.absent(),
                Value<ContextWeather?> weather = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatingEntriesCompanion(
                id: id,
                bikeId: bikeId,
                setupId: setupId,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                dateTimeUTC: dateTimeUTC,
                dateTimeLocal: dateTimeLocal,
                notes: notes,
                position: position,
                place: place,
                weather: weather,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bikeId,
                required String setupId,
                Value<bool> isDeleted = const Value.absent(),
                required DateTime lastModified,
                Value<String?> name = const Value.absent(),
                required DateTime dateTimeUTC,
                required DateTime dateTimeLocal,
                Value<String?> notes = const Value.absent(),
                Value<ContextPosition?> position = const Value.absent(),
                Value<geo.Placemark?> place = const Value.absent(),
                Value<ContextWeather?> weather = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatingEntriesCompanion.insert(
                id: id,
                bikeId: bikeId,
                setupId: setupId,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                dateTimeUTC: dateTimeUTC,
                dateTimeLocal: dateTimeLocal,
                notes: notes,
                position: position,
                place: place,
                weather: weather,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RatingEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bikeId = false,
                setupId = false,
                ratingEntryValuesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ratingEntryValuesRefs) db.ratingEntryValues,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (bikeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bikeId,
                                    referencedTable:
                                        $$RatingEntriesTableReferences
                                            ._bikeIdTable(db),
                                    referencedColumn:
                                        $$RatingEntriesTableReferences
                                            ._bikeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (setupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.setupId,
                                    referencedTable:
                                        $$RatingEntriesTableReferences
                                            ._setupIdTable(db),
                                    referencedColumn:
                                        $$RatingEntriesTableReferences
                                            ._setupIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ratingEntryValuesRefs)
                        await $_getPrefetchedData<
                          RatingEntryDb,
                          $RatingEntriesTable,
                          RatingEntryValueDb
                        >(
                          currentTable: table,
                          referencedTable: $$RatingEntriesTableReferences
                              ._ratingEntryValuesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RatingEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).ratingEntryValuesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ratingEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RatingEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RatingEntriesTable,
      RatingEntryDb,
      $$RatingEntriesTableFilterComposer,
      $$RatingEntriesTableOrderingComposer,
      $$RatingEntriesTableAnnotationComposer,
      $$RatingEntriesTableCreateCompanionBuilder,
      $$RatingEntriesTableUpdateCompanionBuilder,
      (RatingEntryDb, $$RatingEntriesTableReferences),
      RatingEntryDb,
      PrefetchHooks Function({
        bool bikeId,
        bool setupId,
        bool ratingEntryValuesRefs,
      })
    >;
typedef $$RatingEntryValuesTableCreateCompanionBuilder =
    RatingEntryValuesCompanion Function({
      required String ratingEntryId,
      required String ratingMetricId,
      required String value,
      Value<int> rowid,
    });
typedef $$RatingEntryValuesTableUpdateCompanionBuilder =
    RatingEntryValuesCompanion Function({
      Value<String> ratingEntryId,
      Value<String> ratingMetricId,
      Value<String> value,
      Value<int> rowid,
    });

final class $$RatingEntryValuesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RatingEntryValuesTable,
          RatingEntryValueDb
        > {
  $$RatingEntryValuesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RatingEntriesTable _ratingEntryIdTable(_$AppDatabase db) => db
      .ratingEntries
      .createAlias('rating_entry_values__rating_entry_id__rating_entries__id');

  $$RatingEntriesTableProcessedTableManager get ratingEntryId {
    final $_column = $_itemColumn<String>('rating_entry_id')!;

    final manager = $$RatingEntriesTableTableManager(
      $_db,
      $_db.ratingEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ratingEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RatingMetricsTable _ratingMetricIdTable(_$AppDatabase db) => db
      .ratingMetrics
      .createAlias('rating_entry_values__rating_metric_id__rating_metrics__id');

  $$RatingMetricsTableProcessedTableManager get ratingMetricId {
    final $_column = $_itemColumn<String>('rating_metric_id')!;

    final manager = $$RatingMetricsTableTableManager(
      $_db,
      $_db.ratingMetrics,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ratingMetricIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RatingEntryValuesTableFilterComposer
    extends Composer<_$AppDatabase, $RatingEntryValuesTable> {
  $$RatingEntryValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$RatingEntriesTableFilterComposer get ratingEntryId {
    final $$RatingEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ratingEntryId,
      referencedTable: $db.ratingEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ratingEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RatingMetricsTableFilterComposer get ratingMetricId {
    final $$RatingMetricsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ratingMetricId,
      referencedTable: $db.ratingMetrics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingMetricsTableFilterComposer(
            $db: $db,
            $table: $db.ratingMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RatingEntryValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $RatingEntryValuesTable> {
  $$RatingEntryValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$RatingEntriesTableOrderingComposer get ratingEntryId {
    final $$RatingEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ratingEntryId,
      referencedTable: $db.ratingEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.ratingEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RatingMetricsTableOrderingComposer get ratingMetricId {
    final $$RatingMetricsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ratingMetricId,
      referencedTable: $db.ratingMetrics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingMetricsTableOrderingComposer(
            $db: $db,
            $table: $db.ratingMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RatingEntryValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RatingEntryValuesTable> {
  $$RatingEntryValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$RatingEntriesTableAnnotationComposer get ratingEntryId {
    final $$RatingEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ratingEntryId,
      referencedTable: $db.ratingEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ratingEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RatingMetricsTableAnnotationComposer get ratingMetricId {
    final $$RatingMetricsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ratingMetricId,
      referencedTable: $db.ratingMetrics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingMetricsTableAnnotationComposer(
            $db: $db,
            $table: $db.ratingMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RatingEntryValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RatingEntryValuesTable,
          RatingEntryValueDb,
          $$RatingEntryValuesTableFilterComposer,
          $$RatingEntryValuesTableOrderingComposer,
          $$RatingEntryValuesTableAnnotationComposer,
          $$RatingEntryValuesTableCreateCompanionBuilder,
          $$RatingEntryValuesTableUpdateCompanionBuilder,
          (RatingEntryValueDb, $$RatingEntryValuesTableReferences),
          RatingEntryValueDb,
          PrefetchHooks Function({bool ratingEntryId, bool ratingMetricId})
        > {
  $$RatingEntryValuesTableTableManager(
    _$AppDatabase db,
    $RatingEntryValuesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RatingEntryValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RatingEntryValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RatingEntryValuesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ratingEntryId = const Value.absent(),
                Value<String> ratingMetricId = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatingEntryValuesCompanion(
                ratingEntryId: ratingEntryId,
                ratingMetricId: ratingMetricId,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ratingEntryId,
                required String ratingMetricId,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => RatingEntryValuesCompanion.insert(
                ratingEntryId: ratingEntryId,
                ratingMetricId: ratingMetricId,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RatingEntryValuesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({ratingEntryId = false, ratingMetricId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ratingEntryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ratingEntryId,
                                    referencedTable:
                                        $$RatingEntryValuesTableReferences
                                            ._ratingEntryIdTable(db),
                                    referencedColumn:
                                        $$RatingEntryValuesTableReferences
                                            ._ratingEntryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (ratingMetricId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ratingMetricId,
                                    referencedTable:
                                        $$RatingEntryValuesTableReferences
                                            ._ratingMetricIdTable(db),
                                    referencedColumn:
                                        $$RatingEntryValuesTableReferences
                                            ._ratingMetricIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$RatingEntryValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RatingEntryValuesTable,
      RatingEntryValueDb,
      $$RatingEntryValuesTableFilterComposer,
      $$RatingEntryValuesTableOrderingComposer,
      $$RatingEntryValuesTableAnnotationComposer,
      $$RatingEntryValuesTableCreateCompanionBuilder,
      $$RatingEntryValuesTableUpdateCompanionBuilder,
      (RatingEntryValueDb, $$RatingEntryValuesTableReferences),
      RatingEntryValueDb,
      PrefetchHooks Function({bool ratingEntryId, bool ratingMetricId})
    >;
typedef $$StravaActivitiesTableCreateCompanionBuilder =
    StravaActivitiesCompanion Function({
      Value<int> id,
      required DateTime lastModified,
      required String name,
      required int athlete,
      required SportType sportType,
      required DateTime startDate,
      required DateTime startDateLocal,
      Value<String?> gearId,
      Value<double?> startLat,
      Value<double?> startLon,
      Value<double?> distance,
      Value<double?> totalElevationGain,
      required int movingTime,
      required int elapsedTime,
      Value<int?> workoutType,
    });
typedef $$StravaActivitiesTableUpdateCompanionBuilder =
    StravaActivitiesCompanion Function({
      Value<int> id,
      Value<DateTime> lastModified,
      Value<String> name,
      Value<int> athlete,
      Value<SportType> sportType,
      Value<DateTime> startDate,
      Value<DateTime> startDateLocal,
      Value<String?> gearId,
      Value<double?> startLat,
      Value<double?> startLon,
      Value<double?> distance,
      Value<double?> totalElevationGain,
      Value<int> movingTime,
      Value<int> elapsedTime,
      Value<int?> workoutType,
    });

class $$StravaActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $StravaActivitiesTable> {
  $$StravaActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get athlete => $composableBuilder(
    column: $table.athlete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SportType, SportType, String> get sportType =>
      $composableBuilder(
        column: $table.sportType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get startDate =>
      $composableBuilder(
        column: $table.startDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get startDateLocal => $composableBuilder(
    column: $table.startDateLocal,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get gearId => $composableBuilder(
    column: $table.gearId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLat => $composableBuilder(
    column: $table.startLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLon => $composableBuilder(
    column: $table.startLon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalElevationGain => $composableBuilder(
    column: $table.totalElevationGain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movingTime => $composableBuilder(
    column: $table.movingTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedTime => $composableBuilder(
    column: $table.elapsedTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workoutType => $composableBuilder(
    column: $table.workoutType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StravaActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $StravaActivitiesTable> {
  $$StravaActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get athlete => $composableBuilder(
    column: $table.athlete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sportType => $composableBuilder(
    column: $table.sportType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDateLocal => $composableBuilder(
    column: $table.startDateLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gearId => $composableBuilder(
    column: $table.gearId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLat => $composableBuilder(
    column: $table.startLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLon => $composableBuilder(
    column: $table.startLon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalElevationGain => $composableBuilder(
    column: $table.totalElevationGain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingTime => $composableBuilder(
    column: $table.movingTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedTime => $composableBuilder(
    column: $table.elapsedTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workoutType => $composableBuilder(
    column: $table.workoutType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StravaActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StravaActivitiesTable> {
  $$StravaActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get lastModified =>
      $composableBuilder(
        column: $table.lastModified,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get athlete =>
      $composableBuilder(column: $table.athlete, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SportType, String> get sportType =>
      $composableBuilder(column: $table.sportType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get startDateLocal =>
      $composableBuilder(
        column: $table.startDateLocal,
        builder: (column) => column,
      );

  GeneratedColumn<String> get gearId =>
      $composableBuilder(column: $table.gearId, builder: (column) => column);

  GeneratedColumn<double> get startLat =>
      $composableBuilder(column: $table.startLat, builder: (column) => column);

  GeneratedColumn<double> get startLon =>
      $composableBuilder(column: $table.startLon, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<double> get totalElevationGain => $composableBuilder(
    column: $table.totalElevationGain,
    builder: (column) => column,
  );

  GeneratedColumn<int> get movingTime => $composableBuilder(
    column: $table.movingTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedTime => $composableBuilder(
    column: $table.elapsedTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get workoutType => $composableBuilder(
    column: $table.workoutType,
    builder: (column) => column,
  );
}

class $$StravaActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StravaActivitiesTable,
          StravaActivityDb,
          $$StravaActivitiesTableFilterComposer,
          $$StravaActivitiesTableOrderingComposer,
          $$StravaActivitiesTableAnnotationComposer,
          $$StravaActivitiesTableCreateCompanionBuilder,
          $$StravaActivitiesTableUpdateCompanionBuilder,
          (
            StravaActivityDb,
            BaseReferences<
              _$AppDatabase,
              $StravaActivitiesTable,
              StravaActivityDb
            >,
          ),
          StravaActivityDb,
          PrefetchHooks Function()
        > {
  $$StravaActivitiesTableTableManager(
    _$AppDatabase db,
    $StravaActivitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StravaActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StravaActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StravaActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> athlete = const Value.absent(),
                Value<SportType> sportType = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> startDateLocal = const Value.absent(),
                Value<String?> gearId = const Value.absent(),
                Value<double?> startLat = const Value.absent(),
                Value<double?> startLon = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<double?> totalElevationGain = const Value.absent(),
                Value<int> movingTime = const Value.absent(),
                Value<int> elapsedTime = const Value.absent(),
                Value<int?> workoutType = const Value.absent(),
              }) => StravaActivitiesCompanion(
                id: id,
                lastModified: lastModified,
                name: name,
                athlete: athlete,
                sportType: sportType,
                startDate: startDate,
                startDateLocal: startDateLocal,
                gearId: gearId,
                startLat: startLat,
                startLon: startLon,
                distance: distance,
                totalElevationGain: totalElevationGain,
                movingTime: movingTime,
                elapsedTime: elapsedTime,
                workoutType: workoutType,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime lastModified,
                required String name,
                required int athlete,
                required SportType sportType,
                required DateTime startDate,
                required DateTime startDateLocal,
                Value<String?> gearId = const Value.absent(),
                Value<double?> startLat = const Value.absent(),
                Value<double?> startLon = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<double?> totalElevationGain = const Value.absent(),
                required int movingTime,
                required int elapsedTime,
                Value<int?> workoutType = const Value.absent(),
              }) => StravaActivitiesCompanion.insert(
                id: id,
                lastModified: lastModified,
                name: name,
                athlete: athlete,
                sportType: sportType,
                startDate: startDate,
                startDateLocal: startDateLocal,
                gearId: gearId,
                startLat: startLat,
                startLon: startLon,
                distance: distance,
                totalElevationGain: totalElevationGain,
                movingTime: movingTime,
                elapsedTime: elapsedTime,
                workoutType: workoutType,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StravaActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StravaActivitiesTable,
      StravaActivityDb,
      $$StravaActivitiesTableFilterComposer,
      $$StravaActivitiesTableOrderingComposer,
      $$StravaActivitiesTableAnnotationComposer,
      $$StravaActivitiesTableCreateCompanionBuilder,
      $$StravaActivitiesTableUpdateCompanionBuilder,
      (
        StravaActivityDb,
        BaseReferences<_$AppDatabase, $StravaActivitiesTable, StravaActivityDb>,
      ),
      StravaActivityDb,
      PrefetchHooks Function()
    >;
typedef $$StravaAthletesTableCreateCompanionBuilder =
    StravaAthletesCompanion Function({
      Value<int> id,
      required DateTime lastModified,
      Value<String?> firstname,
      Value<String?> lastname,
      Value<String?> profile,
      required Set<String> gears,
    });
typedef $$StravaAthletesTableUpdateCompanionBuilder =
    StravaAthletesCompanion Function({
      Value<int> id,
      Value<DateTime> lastModified,
      Value<String?> firstname,
      Value<String?> lastname,
      Value<String?> profile,
      Value<Set<String>> gears,
    });

class $$StravaAthletesTableFilterComposer
    extends Composer<_$AppDatabase, $StravaAthletesTable> {
  $$StravaAthletesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get firstname => $composableBuilder(
    column: $table.firstname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastname => $composableBuilder(
    column: $table.lastname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profile => $composableBuilder(
    column: $table.profile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Set<String>, Set<String>, String> get gears =>
      $composableBuilder(
        column: $table.gears,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$StravaAthletesTableOrderingComposer
    extends Composer<_$AppDatabase, $StravaAthletesTable> {
  $$StravaAthletesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstname => $composableBuilder(
    column: $table.firstname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastname => $composableBuilder(
    column: $table.lastname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profile => $composableBuilder(
    column: $table.profile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gears => $composableBuilder(
    column: $table.gears,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StravaAthletesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StravaAthletesTable> {
  $$StravaAthletesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get lastModified =>
      $composableBuilder(
        column: $table.lastModified,
        builder: (column) => column,
      );

  GeneratedColumn<String> get firstname =>
      $composableBuilder(column: $table.firstname, builder: (column) => column);

  GeneratedColumn<String> get lastname =>
      $composableBuilder(column: $table.lastname, builder: (column) => column);

  GeneratedColumn<String> get profile =>
      $composableBuilder(column: $table.profile, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Set<String>, String> get gears =>
      $composableBuilder(column: $table.gears, builder: (column) => column);
}

class $$StravaAthletesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StravaAthletesTable,
          StravaAthleteDb,
          $$StravaAthletesTableFilterComposer,
          $$StravaAthletesTableOrderingComposer,
          $$StravaAthletesTableAnnotationComposer,
          $$StravaAthletesTableCreateCompanionBuilder,
          $$StravaAthletesTableUpdateCompanionBuilder,
          (
            StravaAthleteDb,
            BaseReferences<
              _$AppDatabase,
              $StravaAthletesTable,
              StravaAthleteDb
            >,
          ),
          StravaAthleteDb,
          PrefetchHooks Function()
        > {
  $$StravaAthletesTableTableManager(
    _$AppDatabase db,
    $StravaAthletesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StravaAthletesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StravaAthletesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StravaAthletesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String?> firstname = const Value.absent(),
                Value<String?> lastname = const Value.absent(),
                Value<String?> profile = const Value.absent(),
                Value<Set<String>> gears = const Value.absent(),
              }) => StravaAthletesCompanion(
                id: id,
                lastModified: lastModified,
                firstname: firstname,
                lastname: lastname,
                profile: profile,
                gears: gears,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime lastModified,
                Value<String?> firstname = const Value.absent(),
                Value<String?> lastname = const Value.absent(),
                Value<String?> profile = const Value.absent(),
                required Set<String> gears,
              }) => StravaAthletesCompanion.insert(
                id: id,
                lastModified: lastModified,
                firstname: firstname,
                lastname: lastname,
                profile: profile,
                gears: gears,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StravaAthletesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StravaAthletesTable,
      StravaAthleteDb,
      $$StravaAthletesTableFilterComposer,
      $$StravaAthletesTableOrderingComposer,
      $$StravaAthletesTableAnnotationComposer,
      $$StravaAthletesTableCreateCompanionBuilder,
      $$StravaAthletesTableUpdateCompanionBuilder,
      (
        StravaAthleteDb,
        BaseReferences<_$AppDatabase, $StravaAthletesTable, StravaAthleteDb>,
      ),
      StravaAthleteDb,
      PrefetchHooks Function()
    >;
typedef $$StravaGearsTableCreateCompanionBuilder =
    StravaGearsCompanion Function({
      required String id,
      required DateTime lastModified,
      required String name,
      Value<int> rowid,
    });
typedef $$StravaGearsTableUpdateCompanionBuilder =
    StravaGearsCompanion Function({
      Value<String> id,
      Value<DateTime> lastModified,
      Value<String> name,
      Value<int> rowid,
    });

class $$StravaGearsTableFilterComposer
    extends Composer<_$AppDatabase, $StravaGearsTable> {
  $$StravaGearsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StravaGearsTableOrderingComposer
    extends Composer<_$AppDatabase, $StravaGearsTable> {
  $$StravaGearsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StravaGearsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StravaGearsTable> {
  $$StravaGearsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get lastModified =>
      $composableBuilder(
        column: $table.lastModified,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$StravaGearsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StravaGearsTable,
          StravaGearDb,
          $$StravaGearsTableFilterComposer,
          $$StravaGearsTableOrderingComposer,
          $$StravaGearsTableAnnotationComposer,
          $$StravaGearsTableCreateCompanionBuilder,
          $$StravaGearsTableUpdateCompanionBuilder,
          (
            StravaGearDb,
            BaseReferences<_$AppDatabase, $StravaGearsTable, StravaGearDb>,
          ),
          StravaGearDb,
          PrefetchHooks Function()
        > {
  $$StravaGearsTableTableManager(_$AppDatabase db, $StravaGearsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StravaGearsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StravaGearsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StravaGearsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StravaGearsCompanion(
                id: id,
                lastModified: lastModified,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime lastModified,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => StravaGearsCompanion.insert(
                id: id,
                lastModified: lastModified,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StravaGearsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StravaGearsTable,
      StravaGearDb,
      $$StravaGearsTableFilterComposer,
      $$StravaGearsTableOrderingComposer,
      $$StravaGearsTableAnnotationComposer,
      $$StravaGearsTableCreateCompanionBuilder,
      $$StravaGearsTableUpdateCompanionBuilder,
      (
        StravaGearDb,
        BaseReferences<_$AppDatabase, $StravaGearsTable, StravaGearDb>,
      ),
      StravaGearDb,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ComponentsTableTableManager get components =>
      $$ComponentsTableTableManager(_db, _db.components);
  $$BikesTableTableManager get bikes =>
      $$BikesTableTableManager(_db, _db.bikes);
  $$TaskRulesTableTableManager get taskRules =>
      $$TaskRulesTableTableManager(_db, _db.taskRules);
  $$TaskEntriesTableTableManager get taskEntries =>
      $$TaskEntriesTableTableManager(_db, _db.taskEntries);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db, _db.persons);
  $$AdjustmentsTableTableManager get adjustments =>
      $$AdjustmentsTableTableManager(_db, _db.adjustments);
  $$InstallationsTableTableManager get installations =>
      $$InstallationsTableTableManager(_db, _db.installations);
  $$SetupsTableTableManager get setups =>
      $$SetupsTableTableManager(_db, _db.setups);
  $$SetupAdjustmentValuesTableTableManager get setupAdjustmentValues =>
      $$SetupAdjustmentValuesTableTableManager(_db, _db.setupAdjustmentValues);
  $$RatingsTableTableManager get ratings =>
      $$RatingsTableTableManager(_db, _db.ratings);
  $$RatingMetricsTableTableManager get ratingMetrics =>
      $$RatingMetricsTableTableManager(_db, _db.ratingMetrics);
  $$RatingEntriesTableTableManager get ratingEntries =>
      $$RatingEntriesTableTableManager(_db, _db.ratingEntries);
  $$RatingEntryValuesTableTableManager get ratingEntryValues =>
      $$RatingEntryValuesTableTableManager(_db, _db.ratingEntryValues);
  $$StravaActivitiesTableTableManager get stravaActivities =>
      $$StravaActivitiesTableTableManager(_db, _db.stravaActivities);
  $$StravaAthletesTableTableManager get stravaAthletes =>
      $$StravaAthletesTableTableManager(_db, _db.stravaAthletes);
  $$StravaGearsTableTableManager get stravaGears =>
      $$StravaGearsTableTableManager(_db, _db.stravaGears);
}
