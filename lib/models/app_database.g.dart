// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TodoRulesTable extends TodoRules
    with TableInfo<$TodoRulesTable, TodoRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoRulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  @override
  late final GeneratedColumnWithTypeConverter<TodoPriority, String> priority =
      GeneratedColumn<String>(
        'priority',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('medium'),
      ).withConverter<TodoPriority>($TodoRulesTable.$converterpriority);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isDeleted,
    lastModified,
    name,
    notes,
    priority,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todo_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<TodoRule> instance, {
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
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      priority: $TodoRulesTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}priority'],
        )!,
      ),
    );
  }

  @override
  $TodoRulesTable createAlias(String alias) {
    return $TodoRulesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TodoPriority, String, String> $converterpriority =
      const EnumNameConverter<TodoPriority>(TodoPriority.values);
}

class TodoRule extends DataClass implements Insertable<TodoRule> {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final TodoPriority priority;
  const TodoRule({
    required this.id,
    required this.isDeleted,
    required this.lastModified,
    required this.name,
    this.notes,
    required this.priority,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['last_modified'] = Variable<DateTime>(lastModified);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['priority'] = Variable<String>(
        $TodoRulesTable.$converterpriority.toSql(priority),
      );
    }
    return map;
  }

  TodoRulesCompanion toCompanion(bool nullToAbsent) {
    return TodoRulesCompanion(
      id: Value(id),
      isDeleted: Value(isDeleted),
      lastModified: Value(lastModified),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      priority: Value(priority),
    );
  }

  factory TodoRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoRule(
      id: serializer.fromJson<String>(json['id']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      priority: $TodoRulesTable.$converterpriority.fromJson(
        serializer.fromJson<String>(json['priority']),
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
      'notes': serializer.toJson<String?>(notes),
      'priority': serializer.toJson<String>(
        $TodoRulesTable.$converterpriority.toJson(priority),
      ),
    };
  }

  TodoRule copyWith({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    String? name,
    Value<String?> notes = const Value.absent(),
    TodoPriority? priority,
  }) => TodoRule(
    id: id ?? this.id,
    isDeleted: isDeleted ?? this.isDeleted,
    lastModified: lastModified ?? this.lastModified,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    priority: priority ?? this.priority,
  );
  TodoRule copyWithCompanion(TodoRulesCompanion data) {
    return TodoRule(
      id: data.id.present ? data.id.value : this.id,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      priority: data.priority.present ? data.priority.value : this.priority,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoRule(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, isDeleted, lastModified, name, notes, priority);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoRule &&
          other.id == this.id &&
          other.isDeleted == this.isDeleted &&
          other.lastModified == this.lastModified &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.priority == this.priority);
}

class TodoRulesCompanion extends UpdateCompanion<TodoRule> {
  final Value<String> id;
  final Value<bool> isDeleted;
  final Value<DateTime> lastModified;
  final Value<String> name;
  final Value<String?> notes;
  final Value<TodoPriority> priority;
  final Value<int> rowid;
  const TodoRulesCompanion({
    this.id = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.priority = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodoRulesCompanion.insert({
    required String id,
    this.isDeleted = const Value.absent(),
    required DateTime lastModified,
    required String name,
    this.notes = const Value.absent(),
    this.priority = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lastModified = Value(lastModified),
       name = Value(name);
  static Insertable<TodoRule> custom({
    Expression<String>? id,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastModified,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<String>? priority,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastModified != null) 'last_modified': lastModified,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (priority != null) 'priority': priority,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodoRulesCompanion copyWith({
    Value<String>? id,
    Value<bool>? isDeleted,
    Value<DateTime>? lastModified,
    Value<String>? name,
    Value<String?>? notes,
    Value<TodoPriority>? priority,
    Value<int>? rowid,
  }) {
    return TodoRulesCompanion(
      id: id ?? this.id,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
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
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(
        $TodoRulesTable.$converterpriority.toSql(priority.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoRulesCompanion(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('priority: $priority, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TodoEntriesTable extends TodoEntries
    with TableInfo<$TodoEntriesTable, TodoEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _dateTimeUTCMeta = const VerificationMeta(
    'dateTimeUTC',
  );
  @override
  late final GeneratedColumn<DateTime> dateTimeUTC = GeneratedColumn<DateTime>(
    'date_time_u_t_c',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateTimeLocalMeta = const VerificationMeta(
    'dateTimeLocal',
  );
  @override
  late final GeneratedColumn<DateTime> dateTimeLocal =
      GeneratedColumn<DateTime>(
        'date_time_local',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _todoRuleMeta = const VerificationMeta(
    'todoRule',
  );
  @override
  late final GeneratedColumn<String> todoRule = GeneratedColumn<String>(
    'todo_rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES todo_rules (id)',
    ),
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
    todoRule,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todo_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TodoEntry> instance, {
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
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
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
    if (data.containsKey('date_time_u_t_c')) {
      context.handle(
        _dateTimeUTCMeta,
        dateTimeUTC.isAcceptableOrUnknown(
          data['date_time_u_t_c']!,
          _dateTimeUTCMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateTimeUTCMeta);
    }
    if (data.containsKey('date_time_local')) {
      context.handle(
        _dateTimeLocalMeta,
        dateTimeLocal.isAcceptableOrUnknown(
          data['date_time_local']!,
          _dateTimeLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateTimeLocalMeta);
    }
    if (data.containsKey('todo_rule')) {
      context.handle(
        _todoRuleMeta,
        todoRule.isAcceptableOrUnknown(data['todo_rule']!, _todoRuleMeta),
      );
    } else if (isInserting) {
      context.missing(_todoRuleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      dateTimeUTC: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_time_u_t_c'],
      )!,
      dateTimeLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_time_local'],
      )!,
      todoRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}todo_rule'],
      )!,
    );
  }

  @override
  $TodoEntriesTable createAlias(String alias) {
    return $TodoEntriesTable(attachedDatabase, alias);
  }
}

class TodoEntry extends DataClass implements Insertable<TodoEntry> {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;
  final String todoRule;
  const TodoEntry({
    required this.id,
    required this.isDeleted,
    required this.lastModified,
    required this.name,
    this.notes,
    required this.dateTimeUTC,
    required this.dateTimeLocal,
    required this.todoRule,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['last_modified'] = Variable<DateTime>(lastModified);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['date_time_u_t_c'] = Variable<DateTime>(dateTimeUTC);
    map['date_time_local'] = Variable<DateTime>(dateTimeLocal);
    map['todo_rule'] = Variable<String>(todoRule);
    return map;
  }

  TodoEntriesCompanion toCompanion(bool nullToAbsent) {
    return TodoEntriesCompanion(
      id: Value(id),
      isDeleted: Value(isDeleted),
      lastModified: Value(lastModified),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      dateTimeUTC: Value(dateTimeUTC),
      dateTimeLocal: Value(dateTimeLocal),
      todoRule: Value(todoRule),
    );
  }

  factory TodoEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoEntry(
      id: serializer.fromJson<String>(json['id']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      dateTimeUTC: serializer.fromJson<DateTime>(json['dateTimeUTC']),
      dateTimeLocal: serializer.fromJson<DateTime>(json['dateTimeLocal']),
      todoRule: serializer.fromJson<String>(json['todoRule']),
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
      'todoRule': serializer.toJson<String>(todoRule),
    };
  }

  TodoEntry copyWith({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    String? name,
    Value<String?> notes = const Value.absent(),
    DateTime? dateTimeUTC,
    DateTime? dateTimeLocal,
    String? todoRule,
  }) => TodoEntry(
    id: id ?? this.id,
    isDeleted: isDeleted ?? this.isDeleted,
    lastModified: lastModified ?? this.lastModified,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    dateTimeUTC: dateTimeUTC ?? this.dateTimeUTC,
    dateTimeLocal: dateTimeLocal ?? this.dateTimeLocal,
    todoRule: todoRule ?? this.todoRule,
  );
  TodoEntry copyWithCompanion(TodoEntriesCompanion data) {
    return TodoEntry(
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
      todoRule: data.todoRule.present ? data.todoRule.value : this.todoRule,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoEntry(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('dateTimeUTC: $dateTimeUTC, ')
          ..write('dateTimeLocal: $dateTimeLocal, ')
          ..write('todoRule: $todoRule')
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
    todoRule,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoEntry &&
          other.id == this.id &&
          other.isDeleted == this.isDeleted &&
          other.lastModified == this.lastModified &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.dateTimeUTC == this.dateTimeUTC &&
          other.dateTimeLocal == this.dateTimeLocal &&
          other.todoRule == this.todoRule);
}

class TodoEntriesCompanion extends UpdateCompanion<TodoEntry> {
  final Value<String> id;
  final Value<bool> isDeleted;
  final Value<DateTime> lastModified;
  final Value<String> name;
  final Value<String?> notes;
  final Value<DateTime> dateTimeUTC;
  final Value<DateTime> dateTimeLocal;
  final Value<String> todoRule;
  final Value<int> rowid;
  const TodoEntriesCompanion({
    this.id = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.dateTimeUTC = const Value.absent(),
    this.dateTimeLocal = const Value.absent(),
    this.todoRule = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodoEntriesCompanion.insert({
    required String id,
    this.isDeleted = const Value.absent(),
    required DateTime lastModified,
    required String name,
    this.notes = const Value.absent(),
    required DateTime dateTimeUTC,
    required DateTime dateTimeLocal,
    required String todoRule,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lastModified = Value(lastModified),
       name = Value(name),
       dateTimeUTC = Value(dateTimeUTC),
       dateTimeLocal = Value(dateTimeLocal),
       todoRule = Value(todoRule);
  static Insertable<TodoEntry> custom({
    Expression<String>? id,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastModified,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<DateTime>? dateTimeUTC,
    Expression<DateTime>? dateTimeLocal,
    Expression<String>? todoRule,
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
      if (todoRule != null) 'todo_rule': todoRule,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodoEntriesCompanion copyWith({
    Value<String>? id,
    Value<bool>? isDeleted,
    Value<DateTime>? lastModified,
    Value<String>? name,
    Value<String?>? notes,
    Value<DateTime>? dateTimeUTC,
    Value<DateTime>? dateTimeLocal,
    Value<String>? todoRule,
    Value<int>? rowid,
  }) {
    return TodoEntriesCompanion(
      id: id ?? this.id,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      dateTimeUTC: dateTimeUTC ?? this.dateTimeUTC,
      dateTimeLocal: dateTimeLocal ?? this.dateTimeLocal,
      todoRule: todoRule ?? this.todoRule,
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
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (dateTimeUTC.present) {
      map['date_time_u_t_c'] = Variable<DateTime>(dateTimeUTC.value);
    }
    if (dateTimeLocal.present) {
      map['date_time_local'] = Variable<DateTime>(dateTimeLocal.value);
    }
    if (todoRule.present) {
      map['todo_rule'] = Variable<String>(todoRule.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoEntriesCompanion(')
          ..write('id: $id, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('dateTimeUTC: $dateTimeUTC, ')
          ..write('dateTimeLocal: $dateTimeLocal, ')
          ..write('todoRule: $todoRule, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TodoRulesTable todoRules = $TodoRulesTable(this);
  late final $TodoEntriesTable todoEntries = $TodoEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [todoRules, todoEntries];
}

typedef $$TodoRulesTableCreateCompanionBuilder =
    TodoRulesCompanion Function({
      required String id,
      Value<bool> isDeleted,
      required DateTime lastModified,
      required String name,
      Value<String?> notes,
      Value<TodoPriority> priority,
      Value<int> rowid,
    });
typedef $$TodoRulesTableUpdateCompanionBuilder =
    TodoRulesCompanion Function({
      Value<String> id,
      Value<bool> isDeleted,
      Value<DateTime> lastModified,
      Value<String> name,
      Value<String?> notes,
      Value<TodoPriority> priority,
      Value<int> rowid,
    });

final class $$TodoRulesTableReferences
    extends BaseReferences<_$AppDatabase, $TodoRulesTable, TodoRule> {
  $$TodoRulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TodoEntriesTable, List<TodoEntry>>
  _todoEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.todoEntries,
    aliasName: $_aliasNameGenerator(db.todoRules.id, db.todoEntries.todoRule),
  );

  $$TodoEntriesTableProcessedTableManager get todoEntriesRefs {
    final manager = $$TodoEntriesTableTableManager(
      $_db,
      $_db.todoEntries,
    ).filter((f) => f.todoRule.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_todoEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TodoRulesTableFilterComposer
    extends Composer<_$AppDatabase, $TodoRulesTable> {
  $$TodoRulesTableFilterComposer({
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

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
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

  ColumnWithTypeConverterFilters<TodoPriority, TodoPriority, String>
  get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  Expression<bool> todoEntriesRefs(
    Expression<bool> Function($$TodoEntriesTableFilterComposer f) f,
  ) {
    final $$TodoEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.todoEntries,
      getReferencedColumn: (t) => t.todoRule,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodoEntriesTableFilterComposer(
            $db: $db,
            $table: $db.todoEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TodoRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $TodoRulesTable> {
  $$TodoRulesTableOrderingComposer({
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
}

class $$TodoRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodoRulesTable> {
  $$TodoRulesTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TodoPriority, String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  Expression<T> todoEntriesRefs<T extends Object>(
    Expression<T> Function($$TodoEntriesTableAnnotationComposer a) f,
  ) {
    final $$TodoEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.todoEntries,
      getReferencedColumn: (t) => t.todoRule,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodoEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.todoEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TodoRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TodoRulesTable,
          TodoRule,
          $$TodoRulesTableFilterComposer,
          $$TodoRulesTableOrderingComposer,
          $$TodoRulesTableAnnotationComposer,
          $$TodoRulesTableCreateCompanionBuilder,
          $$TodoRulesTableUpdateCompanionBuilder,
          (TodoRule, $$TodoRulesTableReferences),
          TodoRule,
          PrefetchHooks Function({bool todoEntriesRefs})
        > {
  $$TodoRulesTableTableManager(_$AppDatabase db, $TodoRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<TodoPriority> priority = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TodoRulesCompanion(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                notes: notes,
                priority: priority,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> isDeleted = const Value.absent(),
                required DateTime lastModified,
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<TodoPriority> priority = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TodoRulesCompanion.insert(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                notes: notes,
                priority: priority,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TodoRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({todoEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (todoEntriesRefs) db.todoEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (todoEntriesRefs)
                    await $_getPrefetchedData<
                      TodoRule,
                      $TodoRulesTable,
                      TodoEntry
                    >(
                      currentTable: table,
                      referencedTable: $$TodoRulesTableReferences
                          ._todoEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TodoRulesTableReferences(
                            db,
                            table,
                            p0,
                          ).todoEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.todoRule == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TodoRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TodoRulesTable,
      TodoRule,
      $$TodoRulesTableFilterComposer,
      $$TodoRulesTableOrderingComposer,
      $$TodoRulesTableAnnotationComposer,
      $$TodoRulesTableCreateCompanionBuilder,
      $$TodoRulesTableUpdateCompanionBuilder,
      (TodoRule, $$TodoRulesTableReferences),
      TodoRule,
      PrefetchHooks Function({bool todoEntriesRefs})
    >;
typedef $$TodoEntriesTableCreateCompanionBuilder =
    TodoEntriesCompanion Function({
      required String id,
      Value<bool> isDeleted,
      required DateTime lastModified,
      required String name,
      Value<String?> notes,
      required DateTime dateTimeUTC,
      required DateTime dateTimeLocal,
      required String todoRule,
      Value<int> rowid,
    });
typedef $$TodoEntriesTableUpdateCompanionBuilder =
    TodoEntriesCompanion Function({
      Value<String> id,
      Value<bool> isDeleted,
      Value<DateTime> lastModified,
      Value<String> name,
      Value<String?> notes,
      Value<DateTime> dateTimeUTC,
      Value<DateTime> dateTimeLocal,
      Value<String> todoRule,
      Value<int> rowid,
    });

final class $$TodoEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $TodoEntriesTable, TodoEntry> {
  $$TodoEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TodoRulesTable _todoRuleTable(_$AppDatabase db) =>
      db.todoRules.createAlias(
        $_aliasNameGenerator(db.todoEntries.todoRule, db.todoRules.id),
      );

  $$TodoRulesTableProcessedTableManager get todoRule {
    final $_column = $_itemColumn<String>('todo_rule')!;

    final manager = $$TodoRulesTableTableManager(
      $_db,
      $_db.todoRules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_todoRuleTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TodoEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TodoEntriesTable> {
  $$TodoEntriesTableFilterComposer({
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

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
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

  ColumnFilters<DateTime> get dateTimeUTC => $composableBuilder(
    column: $table.dateTimeUTC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateTimeLocal => $composableBuilder(
    column: $table.dateTimeLocal,
    builder: (column) => ColumnFilters(column),
  );

  $$TodoRulesTableFilterComposer get todoRule {
    final $$TodoRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.todoRule,
      referencedTable: $db.todoRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodoRulesTableFilterComposer(
            $db: $db,
            $table: $db.todoRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TodoEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TodoEntriesTable> {
  $$TodoEntriesTableOrderingComposer({
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

  $$TodoRulesTableOrderingComposer get todoRule {
    final $$TodoRulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.todoRule,
      referencedTable: $db.todoRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodoRulesTableOrderingComposer(
            $db: $db,
            $table: $db.todoRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TodoEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodoEntriesTable> {
  $$TodoEntriesTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get dateTimeUTC => $composableBuilder(
    column: $table.dateTimeUTC,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateTimeLocal => $composableBuilder(
    column: $table.dateTimeLocal,
    builder: (column) => column,
  );

  $$TodoRulesTableAnnotationComposer get todoRule {
    final $$TodoRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.todoRule,
      referencedTable: $db.todoRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TodoRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.todoRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TodoEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TodoEntriesTable,
          TodoEntry,
          $$TodoEntriesTableFilterComposer,
          $$TodoEntriesTableOrderingComposer,
          $$TodoEntriesTableAnnotationComposer,
          $$TodoEntriesTableCreateCompanionBuilder,
          $$TodoEntriesTableUpdateCompanionBuilder,
          (TodoEntry, $$TodoEntriesTableReferences),
          TodoEntry,
          PrefetchHooks Function({bool todoRule})
        > {
  $$TodoEntriesTableTableManager(_$AppDatabase db, $TodoEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> dateTimeUTC = const Value.absent(),
                Value<DateTime> dateTimeLocal = const Value.absent(),
                Value<String> todoRule = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TodoEntriesCompanion(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                notes: notes,
                dateTimeUTC: dateTimeUTC,
                dateTimeLocal: dateTimeLocal,
                todoRule: todoRule,
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
                required String todoRule,
                Value<int> rowid = const Value.absent(),
              }) => TodoEntriesCompanion.insert(
                id: id,
                isDeleted: isDeleted,
                lastModified: lastModified,
                name: name,
                notes: notes,
                dateTimeUTC: dateTimeUTC,
                dateTimeLocal: dateTimeLocal,
                todoRule: todoRule,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TodoEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({todoRule = false}) {
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
                    if (todoRule) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.todoRule,
                                referencedTable: $$TodoEntriesTableReferences
                                    ._todoRuleTable(db),
                                referencedColumn: $$TodoEntriesTableReferences
                                    ._todoRuleTable(db)
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

typedef $$TodoEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TodoEntriesTable,
      TodoEntry,
      $$TodoEntriesTableFilterComposer,
      $$TodoEntriesTableOrderingComposer,
      $$TodoEntriesTableAnnotationComposer,
      $$TodoEntriesTableCreateCompanionBuilder,
      $$TodoEntriesTableUpdateCompanionBuilder,
      (TodoEntry, $$TodoEntriesTableReferences),
      TodoEntry,
      PrefetchHooks Function({bool todoRule})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TodoRulesTableTableManager get todoRules =>
      $$TodoRulesTableTableManager(_db, _db.todoRules);
  $$TodoEntriesTableTableManager get todoEntries =>
      $$TodoEntriesTableTableManager(_db, _db.todoEntries);
}
