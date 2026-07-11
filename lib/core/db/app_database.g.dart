// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalItemStatesTable extends LocalItemStates
    with TableInfo<$LocalItemStatesTable, LocalItemState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalItemStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<String> learnerId = GeneratedColumn<String>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _incorrectCountMeta = const VerificationMeta(
    'incorrectCount',
  );
  @override
  late final GeneratedColumn<int> incorrectCount = GeneratedColumn<int>(
    'incorrect_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastResponseMsMeta = const VerificationMeta(
    'lastResponseMs',
  );
  @override
  late final GeneratedColumn<int> lastResponseMs = GeneratedColumn<int>(
    'last_response_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pronunciationScoreMeta =
      const VerificationMeta('pronunciationScore');
  @override
  late final GeneratedColumn<double> pronunciationScore =
      GeneratedColumn<double>(
        'pronunciation_score',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _easeMeta = const VerificationMeta('ease');
  @override
  late final GeneratedColumn<double> ease = GeneratedColumn<double>(
    'ease',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<double> intervalDays = GeneratedColumn<double>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    learnerId,
    itemId,
    correctCount,
    incorrectCount,
    attempts,
    lastResponseMs,
    pronunciationScore,
    ease,
    intervalDays,
    repetitions,
    dueAt,
    updatedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_item_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalItemState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('incorrect_count')) {
      context.handle(
        _incorrectCountMeta,
        incorrectCount.isAcceptableOrUnknown(
          data['incorrect_count']!,
          _incorrectCountMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_response_ms')) {
      context.handle(
        _lastResponseMsMeta,
        lastResponseMs.isAcceptableOrUnknown(
          data['last_response_ms']!,
          _lastResponseMsMeta,
        ),
      );
    }
    if (data.containsKey('pronunciation_score')) {
      context.handle(
        _pronunciationScoreMeta,
        pronunciationScore.isAcceptableOrUnknown(
          data['pronunciation_score']!,
          _pronunciationScoreMeta,
        ),
      );
    }
    if (data.containsKey('ease')) {
      context.handle(
        _easeMeta,
        ease.isAcceptableOrUnknown(data['ease']!, _easeMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {learnerId, itemId};
  @override
  LocalItemState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalItemState(
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learner_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      incorrectCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}incorrect_count'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastResponseMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_response_ms'],
      ),
      pronunciationScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pronunciation_score'],
      ),
      ease: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interval_days'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $LocalItemStatesTable createAlias(String alias) {
    return $LocalItemStatesTable(attachedDatabase, alias);
  }
}

class LocalItemState extends DataClass implements Insertable<LocalItemState> {
  final String learnerId;
  final String itemId;
  final int correctCount;
  final int incorrectCount;
  final int attempts;
  final int? lastResponseMs;
  final double? pronunciationScore;
  final double ease;
  final double intervalDays;
  final int repetitions;
  final DateTime dueAt;
  final DateTime updatedAt;

  /// False = pending upload to Supabase (outbox).
  final bool synced;
  const LocalItemState({
    required this.learnerId,
    required this.itemId,
    required this.correctCount,
    required this.incorrectCount,
    required this.attempts,
    this.lastResponseMs,
    this.pronunciationScore,
    required this.ease,
    required this.intervalDays,
    required this.repetitions,
    required this.dueAt,
    required this.updatedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['learner_id'] = Variable<String>(learnerId);
    map['item_id'] = Variable<String>(itemId);
    map['correct_count'] = Variable<int>(correctCount);
    map['incorrect_count'] = Variable<int>(incorrectCount);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastResponseMs != null) {
      map['last_response_ms'] = Variable<int>(lastResponseMs);
    }
    if (!nullToAbsent || pronunciationScore != null) {
      map['pronunciation_score'] = Variable<double>(pronunciationScore);
    }
    map['ease'] = Variable<double>(ease);
    map['interval_days'] = Variable<double>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    map['due_at'] = Variable<DateTime>(dueAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  LocalItemStatesCompanion toCompanion(bool nullToAbsent) {
    return LocalItemStatesCompanion(
      learnerId: Value(learnerId),
      itemId: Value(itemId),
      correctCount: Value(correctCount),
      incorrectCount: Value(incorrectCount),
      attempts: Value(attempts),
      lastResponseMs: lastResponseMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastResponseMs),
      pronunciationScore: pronunciationScore == null && nullToAbsent
          ? const Value.absent()
          : Value(pronunciationScore),
      ease: Value(ease),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      dueAt: Value(dueAt),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
    );
  }

  factory LocalItemState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalItemState(
      learnerId: serializer.fromJson<String>(json['learnerId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      incorrectCount: serializer.fromJson<int>(json['incorrectCount']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastResponseMs: serializer.fromJson<int?>(json['lastResponseMs']),
      pronunciationScore: serializer.fromJson<double?>(
        json['pronunciationScore'],
      ),
      ease: serializer.fromJson<double>(json['ease']),
      intervalDays: serializer.fromJson<double>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'learnerId': serializer.toJson<String>(learnerId),
      'itemId': serializer.toJson<String>(itemId),
      'correctCount': serializer.toJson<int>(correctCount),
      'incorrectCount': serializer.toJson<int>(incorrectCount),
      'attempts': serializer.toJson<int>(attempts),
      'lastResponseMs': serializer.toJson<int?>(lastResponseMs),
      'pronunciationScore': serializer.toJson<double?>(pronunciationScore),
      'ease': serializer.toJson<double>(ease),
      'intervalDays': serializer.toJson<double>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  LocalItemState copyWith({
    String? learnerId,
    String? itemId,
    int? correctCount,
    int? incorrectCount,
    int? attempts,
    Value<int?> lastResponseMs = const Value.absent(),
    Value<double?> pronunciationScore = const Value.absent(),
    double? ease,
    double? intervalDays,
    int? repetitions,
    DateTime? dueAt,
    DateTime? updatedAt,
    bool? synced,
  }) => LocalItemState(
    learnerId: learnerId ?? this.learnerId,
    itemId: itemId ?? this.itemId,
    correctCount: correctCount ?? this.correctCount,
    incorrectCount: incorrectCount ?? this.incorrectCount,
    attempts: attempts ?? this.attempts,
    lastResponseMs: lastResponseMs.present
        ? lastResponseMs.value
        : this.lastResponseMs,
    pronunciationScore: pronunciationScore.present
        ? pronunciationScore.value
        : this.pronunciationScore,
    ease: ease ?? this.ease,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    dueAt: dueAt ?? this.dueAt,
    updatedAt: updatedAt ?? this.updatedAt,
    synced: synced ?? this.synced,
  );
  LocalItemState copyWithCompanion(LocalItemStatesCompanion data) {
    return LocalItemState(
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      incorrectCount: data.incorrectCount.present
          ? data.incorrectCount.value
          : this.incorrectCount,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastResponseMs: data.lastResponseMs.present
          ? data.lastResponseMs.value
          : this.lastResponseMs,
      pronunciationScore: data.pronunciationScore.present
          ? data.pronunciationScore.value
          : this.pronunciationScore,
      ease: data.ease.present ? data.ease.value : this.ease,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalItemState(')
          ..write('learnerId: $learnerId, ')
          ..write('itemId: $itemId, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('attempts: $attempts, ')
          ..write('lastResponseMs: $lastResponseMs, ')
          ..write('pronunciationScore: $pronunciationScore, ')
          ..write('ease: $ease, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('dueAt: $dueAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    learnerId,
    itemId,
    correctCount,
    incorrectCount,
    attempts,
    lastResponseMs,
    pronunciationScore,
    ease,
    intervalDays,
    repetitions,
    dueAt,
    updatedAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalItemState &&
          other.learnerId == this.learnerId &&
          other.itemId == this.itemId &&
          other.correctCount == this.correctCount &&
          other.incorrectCount == this.incorrectCount &&
          other.attempts == this.attempts &&
          other.lastResponseMs == this.lastResponseMs &&
          other.pronunciationScore == this.pronunciationScore &&
          other.ease == this.ease &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.dueAt == this.dueAt &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced);
}

class LocalItemStatesCompanion extends UpdateCompanion<LocalItemState> {
  final Value<String> learnerId;
  final Value<String> itemId;
  final Value<int> correctCount;
  final Value<int> incorrectCount;
  final Value<int> attempts;
  final Value<int?> lastResponseMs;
  final Value<double?> pronunciationScore;
  final Value<double> ease;
  final Value<double> intervalDays;
  final Value<int> repetitions;
  final Value<DateTime> dueAt;
  final Value<DateTime> updatedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const LocalItemStatesCompanion({
    this.learnerId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastResponseMs = const Value.absent(),
    this.pronunciationScore = const Value.absent(),
    this.ease = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalItemStatesCompanion.insert({
    required String learnerId,
    required String itemId,
    this.correctCount = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastResponseMs = const Value.absent(),
    this.pronunciationScore = const Value.absent(),
    this.ease = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    required DateTime dueAt,
    required DateTime updatedAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : learnerId = Value(learnerId),
       itemId = Value(itemId),
       dueAt = Value(dueAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalItemState> custom({
    Expression<String>? learnerId,
    Expression<String>? itemId,
    Expression<int>? correctCount,
    Expression<int>? incorrectCount,
    Expression<int>? attempts,
    Expression<int>? lastResponseMs,
    Expression<double>? pronunciationScore,
    Expression<double>? ease,
    Expression<double>? intervalDays,
    Expression<int>? repetitions,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (learnerId != null) 'learner_id': learnerId,
      if (itemId != null) 'item_id': itemId,
      if (correctCount != null) 'correct_count': correctCount,
      if (incorrectCount != null) 'incorrect_count': incorrectCount,
      if (attempts != null) 'attempts': attempts,
      if (lastResponseMs != null) 'last_response_ms': lastResponseMs,
      if (pronunciationScore != null) 'pronunciation_score': pronunciationScore,
      if (ease != null) 'ease': ease,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (dueAt != null) 'due_at': dueAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalItemStatesCompanion copyWith({
    Value<String>? learnerId,
    Value<String>? itemId,
    Value<int>? correctCount,
    Value<int>? incorrectCount,
    Value<int>? attempts,
    Value<int?>? lastResponseMs,
    Value<double?>? pronunciationScore,
    Value<double>? ease,
    Value<double>? intervalDays,
    Value<int>? repetitions,
    Value<DateTime>? dueAt,
    Value<DateTime>? updatedAt,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return LocalItemStatesCompanion(
      learnerId: learnerId ?? this.learnerId,
      itemId: itemId ?? this.itemId,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      attempts: attempts ?? this.attempts,
      lastResponseMs: lastResponseMs ?? this.lastResponseMs,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
      ease: ease ?? this.ease,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      dueAt: dueAt ?? this.dueAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (learnerId.present) {
      map['learner_id'] = Variable<String>(learnerId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (incorrectCount.present) {
      map['incorrect_count'] = Variable<int>(incorrectCount.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastResponseMs.present) {
      map['last_response_ms'] = Variable<int>(lastResponseMs.value);
    }
    if (pronunciationScore.present) {
      map['pronunciation_score'] = Variable<double>(pronunciationScore.value);
    }
    if (ease.present) {
      map['ease'] = Variable<double>(ease.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<double>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalItemStatesCompanion(')
          ..write('learnerId: $learnerId, ')
          ..write('itemId: $itemId, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('attempts: $attempts, ')
          ..write('lastResponseMs: $lastResponseMs, ')
          ..write('pronunciationScore: $pronunciationScore, ')
          ..write('ease: $ease, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('dueAt: $dueAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearnerSettingsTable extends LearnerSettings
    with TableInfo<$LearnerSettingsTable, LearnerSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearnerSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<String> learnerId = GeneratedColumn<String>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyLimitMinutesMeta = const VerificationMeta(
    'dailyLimitMinutes',
  );
  @override
  late final GeneratedColumn<int> dailyLimitMinutes = GeneratedColumn<int>(
    'daily_limit_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _consentGivenMeta = const VerificationMeta(
    'consentGiven',
  );
  @override
  late final GeneratedColumn<bool> consentGiven = GeneratedColumn<bool>(
    'consent_given',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("consent_given" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    learnerId,
    dailyLimitMinutes,
    consentGiven,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learner_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearnerSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('daily_limit_minutes')) {
      context.handle(
        _dailyLimitMinutesMeta,
        dailyLimitMinutes.isAcceptableOrUnknown(
          data['daily_limit_minutes']!,
          _dailyLimitMinutesMeta,
        ),
      );
    }
    if (data.containsKey('consent_given')) {
      context.handle(
        _consentGivenMeta,
        consentGiven.isAcceptableOrUnknown(
          data['consent_given']!,
          _consentGivenMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {learnerId};
  @override
  LearnerSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearnerSetting(
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learner_id'],
      )!,
      dailyLimitMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_limit_minutes'],
      )!,
      consentGiven: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}consent_given'],
      )!,
    );
  }

  @override
  $LearnerSettingsTable createAlias(String alias) {
    return $LearnerSettingsTable(attachedDatabase, alias);
  }
}

class LearnerSetting extends DataClass implements Insertable<LearnerSetting> {
  final String learnerId;
  final int dailyLimitMinutes;

  /// True once a parent/guardian has confirmed the age-gate. Checked before
  /// the first play session; anonymous auth continues underneath either way.
  final bool consentGiven;
  const LearnerSetting({
    required this.learnerId,
    required this.dailyLimitMinutes,
    required this.consentGiven,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['learner_id'] = Variable<String>(learnerId);
    map['daily_limit_minutes'] = Variable<int>(dailyLimitMinutes);
    map['consent_given'] = Variable<bool>(consentGiven);
    return map;
  }

  LearnerSettingsCompanion toCompanion(bool nullToAbsent) {
    return LearnerSettingsCompanion(
      learnerId: Value(learnerId),
      dailyLimitMinutes: Value(dailyLimitMinutes),
      consentGiven: Value(consentGiven),
    );
  }

  factory LearnerSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearnerSetting(
      learnerId: serializer.fromJson<String>(json['learnerId']),
      dailyLimitMinutes: serializer.fromJson<int>(json['dailyLimitMinutes']),
      consentGiven: serializer.fromJson<bool>(json['consentGiven']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'learnerId': serializer.toJson<String>(learnerId),
      'dailyLimitMinutes': serializer.toJson<int>(dailyLimitMinutes),
      'consentGiven': serializer.toJson<bool>(consentGiven),
    };
  }

  LearnerSetting copyWith({
    String? learnerId,
    int? dailyLimitMinutes,
    bool? consentGiven,
  }) => LearnerSetting(
    learnerId: learnerId ?? this.learnerId,
    dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
    consentGiven: consentGiven ?? this.consentGiven,
  );
  LearnerSetting copyWithCompanion(LearnerSettingsCompanion data) {
    return LearnerSetting(
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      dailyLimitMinutes: data.dailyLimitMinutes.present
          ? data.dailyLimitMinutes.value
          : this.dailyLimitMinutes,
      consentGiven: data.consentGiven.present
          ? data.consentGiven.value
          : this.consentGiven,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearnerSetting(')
          ..write('learnerId: $learnerId, ')
          ..write('dailyLimitMinutes: $dailyLimitMinutes, ')
          ..write('consentGiven: $consentGiven')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(learnerId, dailyLimitMinutes, consentGiven);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearnerSetting &&
          other.learnerId == this.learnerId &&
          other.dailyLimitMinutes == this.dailyLimitMinutes &&
          other.consentGiven == this.consentGiven);
}

class LearnerSettingsCompanion extends UpdateCompanion<LearnerSetting> {
  final Value<String> learnerId;
  final Value<int> dailyLimitMinutes;
  final Value<bool> consentGiven;
  final Value<int> rowid;
  const LearnerSettingsCompanion({
    this.learnerId = const Value.absent(),
    this.dailyLimitMinutes = const Value.absent(),
    this.consentGiven = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearnerSettingsCompanion.insert({
    required String learnerId,
    this.dailyLimitMinutes = const Value.absent(),
    this.consentGiven = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : learnerId = Value(learnerId);
  static Insertable<LearnerSetting> custom({
    Expression<String>? learnerId,
    Expression<int>? dailyLimitMinutes,
    Expression<bool>? consentGiven,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (learnerId != null) 'learner_id': learnerId,
      if (dailyLimitMinutes != null) 'daily_limit_minutes': dailyLimitMinutes,
      if (consentGiven != null) 'consent_given': consentGiven,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearnerSettingsCompanion copyWith({
    Value<String>? learnerId,
    Value<int>? dailyLimitMinutes,
    Value<bool>? consentGiven,
    Value<int>? rowid,
  }) {
    return LearnerSettingsCompanion(
      learnerId: learnerId ?? this.learnerId,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      consentGiven: consentGiven ?? this.consentGiven,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (learnerId.present) {
      map['learner_id'] = Variable<String>(learnerId.value);
    }
    if (dailyLimitMinutes.present) {
      map['daily_limit_minutes'] = Variable<int>(dailyLimitMinutes.value);
    }
    if (consentGiven.present) {
      map['consent_given'] = Variable<bool>(consentGiven.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearnerSettingsCompanion(')
          ..write('learnerId: $learnerId, ')
          ..write('dailyLimitMinutes: $dailyLimitMinutes, ')
          ..write('consentGiven: $consentGiven, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalItemStatesTable localItemStates = $LocalItemStatesTable(
    this,
  );
  late final $LearnerSettingsTable learnerSettings = $LearnerSettingsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localItemStates,
    learnerSettings,
  ];
}

typedef $$LocalItemStatesTableCreateCompanionBuilder =
    LocalItemStatesCompanion Function({
      required String learnerId,
      required String itemId,
      Value<int> correctCount,
      Value<int> incorrectCount,
      Value<int> attempts,
      Value<int?> lastResponseMs,
      Value<double?> pronunciationScore,
      Value<double> ease,
      Value<double> intervalDays,
      Value<int> repetitions,
      required DateTime dueAt,
      required DateTime updatedAt,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$LocalItemStatesTableUpdateCompanionBuilder =
    LocalItemStatesCompanion Function({
      Value<String> learnerId,
      Value<String> itemId,
      Value<int> correctCount,
      Value<int> incorrectCount,
      Value<int> attempts,
      Value<int?> lastResponseMs,
      Value<double?> pronunciationScore,
      Value<double> ease,
      Value<double> intervalDays,
      Value<int> repetitions,
      Value<DateTime> dueAt,
      Value<DateTime> updatedAt,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$LocalItemStatesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalItemStatesTable> {
  $$LocalItemStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get learnerId => $composableBuilder(
    column: $table.learnerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get incorrectCount => $composableBuilder(
    column: $table.incorrectCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastResponseMs => $composableBuilder(
    column: $table.lastResponseMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pronunciationScore => $composableBuilder(
    column: $table.pronunciationScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalItemStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalItemStatesTable> {
  $$LocalItemStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get learnerId => $composableBuilder(
    column: $table.learnerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get incorrectCount => $composableBuilder(
    column: $table.incorrectCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastResponseMs => $composableBuilder(
    column: $table.lastResponseMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pronunciationScore => $composableBuilder(
    column: $table.pronunciationScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalItemStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalItemStatesTable> {
  $$LocalItemStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get learnerId =>
      $composableBuilder(column: $table.learnerId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get incorrectCount => $composableBuilder(
    column: $table.incorrectCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get lastResponseMs => $composableBuilder(
    column: $table.lastResponseMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pronunciationScore => $composableBuilder(
    column: $table.pronunciationScore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ease =>
      $composableBuilder(column: $table.ease, builder: (column) => column);

  GeneratedColumn<double> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$LocalItemStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalItemStatesTable,
          LocalItemState,
          $$LocalItemStatesTableFilterComposer,
          $$LocalItemStatesTableOrderingComposer,
          $$LocalItemStatesTableAnnotationComposer,
          $$LocalItemStatesTableCreateCompanionBuilder,
          $$LocalItemStatesTableUpdateCompanionBuilder,
          (
            LocalItemState,
            BaseReferences<
              _$AppDatabase,
              $LocalItemStatesTable,
              LocalItemState
            >,
          ),
          LocalItemState,
          PrefetchHooks Function()
        > {
  $$LocalItemStatesTableTableManager(
    _$AppDatabase db,
    $LocalItemStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalItemStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalItemStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalItemStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> learnerId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> incorrectCount = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int?> lastResponseMs = const Value.absent(),
                Value<double?> pronunciationScore = const Value.absent(),
                Value<double> ease = const Value.absent(),
                Value<double> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalItemStatesCompanion(
                learnerId: learnerId,
                itemId: itemId,
                correctCount: correctCount,
                incorrectCount: incorrectCount,
                attempts: attempts,
                lastResponseMs: lastResponseMs,
                pronunciationScore: pronunciationScore,
                ease: ease,
                intervalDays: intervalDays,
                repetitions: repetitions,
                dueAt: dueAt,
                updatedAt: updatedAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String learnerId,
                required String itemId,
                Value<int> correctCount = const Value.absent(),
                Value<int> incorrectCount = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int?> lastResponseMs = const Value.absent(),
                Value<double?> pronunciationScore = const Value.absent(),
                Value<double> ease = const Value.absent(),
                Value<double> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                required DateTime dueAt,
                required DateTime updatedAt,
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalItemStatesCompanion.insert(
                learnerId: learnerId,
                itemId: itemId,
                correctCount: correctCount,
                incorrectCount: incorrectCount,
                attempts: attempts,
                lastResponseMs: lastResponseMs,
                pronunciationScore: pronunciationScore,
                ease: ease,
                intervalDays: intervalDays,
                repetitions: repetitions,
                dueAt: dueAt,
                updatedAt: updatedAt,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalItemStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalItemStatesTable,
      LocalItemState,
      $$LocalItemStatesTableFilterComposer,
      $$LocalItemStatesTableOrderingComposer,
      $$LocalItemStatesTableAnnotationComposer,
      $$LocalItemStatesTableCreateCompanionBuilder,
      $$LocalItemStatesTableUpdateCompanionBuilder,
      (
        LocalItemState,
        BaseReferences<_$AppDatabase, $LocalItemStatesTable, LocalItemState>,
      ),
      LocalItemState,
      PrefetchHooks Function()
    >;
typedef $$LearnerSettingsTableCreateCompanionBuilder =
    LearnerSettingsCompanion Function({
      required String learnerId,
      Value<int> dailyLimitMinutes,
      Value<bool> consentGiven,
      Value<int> rowid,
    });
typedef $$LearnerSettingsTableUpdateCompanionBuilder =
    LearnerSettingsCompanion Function({
      Value<String> learnerId,
      Value<int> dailyLimitMinutes,
      Value<bool> consentGiven,
      Value<int> rowid,
    });

class $$LearnerSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LearnerSettingsTable> {
  $$LearnerSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get learnerId => $composableBuilder(
    column: $table.learnerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyLimitMinutes => $composableBuilder(
    column: $table.dailyLimitMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get consentGiven => $composableBuilder(
    column: $table.consentGiven,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearnerSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearnerSettingsTable> {
  $$LearnerSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get learnerId => $composableBuilder(
    column: $table.learnerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyLimitMinutes => $composableBuilder(
    column: $table.dailyLimitMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get consentGiven => $composableBuilder(
    column: $table.consentGiven,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearnerSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearnerSettingsTable> {
  $$LearnerSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get learnerId =>
      $composableBuilder(column: $table.learnerId, builder: (column) => column);

  GeneratedColumn<int> get dailyLimitMinutes => $composableBuilder(
    column: $table.dailyLimitMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get consentGiven => $composableBuilder(
    column: $table.consentGiven,
    builder: (column) => column,
  );
}

class $$LearnerSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearnerSettingsTable,
          LearnerSetting,
          $$LearnerSettingsTableFilterComposer,
          $$LearnerSettingsTableOrderingComposer,
          $$LearnerSettingsTableAnnotationComposer,
          $$LearnerSettingsTableCreateCompanionBuilder,
          $$LearnerSettingsTableUpdateCompanionBuilder,
          (
            LearnerSetting,
            BaseReferences<
              _$AppDatabase,
              $LearnerSettingsTable,
              LearnerSetting
            >,
          ),
          LearnerSetting,
          PrefetchHooks Function()
        > {
  $$LearnerSettingsTableTableManager(
    _$AppDatabase db,
    $LearnerSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearnerSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearnerSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearnerSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> learnerId = const Value.absent(),
                Value<int> dailyLimitMinutes = const Value.absent(),
                Value<bool> consentGiven = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearnerSettingsCompanion(
                learnerId: learnerId,
                dailyLimitMinutes: dailyLimitMinutes,
                consentGiven: consentGiven,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String learnerId,
                Value<int> dailyLimitMinutes = const Value.absent(),
                Value<bool> consentGiven = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearnerSettingsCompanion.insert(
                learnerId: learnerId,
                dailyLimitMinutes: dailyLimitMinutes,
                consentGiven: consentGiven,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearnerSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearnerSettingsTable,
      LearnerSetting,
      $$LearnerSettingsTableFilterComposer,
      $$LearnerSettingsTableOrderingComposer,
      $$LearnerSettingsTableAnnotationComposer,
      $$LearnerSettingsTableCreateCompanionBuilder,
      $$LearnerSettingsTableUpdateCompanionBuilder,
      (
        LearnerSetting,
        BaseReferences<_$AppDatabase, $LearnerSettingsTable, LearnerSetting>,
      ),
      LearnerSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalItemStatesTableTableManager get localItemStates =>
      $$LocalItemStatesTableTableManager(_db, _db.localItemStates);
  $$LearnerSettingsTableTableManager get learnerSettings =>
      $$LearnerSettingsTableTableManager(_db, _db.learnerSettings);
}
