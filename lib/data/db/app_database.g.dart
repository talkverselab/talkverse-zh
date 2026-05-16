// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TurnsTable extends Turns with TableInfo<$TurnsTable, TurnRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TurnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dialectMeta = const VerificationMeta(
    'dialect',
  );
  @override
  late final GeneratedColumn<String> dialect = GeneratedColumn<String>(
    'dialect',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('north'),
  );
  static const VerificationMeta _episodeIdMeta = const VerificationMeta(
    'episodeId',
  );
  @override
  late final GeneratedColumn<String> episodeId = GeneratedColumn<String>(
    'episode_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numMeta = const VerificationMeta('num');
  @override
  late final GeneratedColumn<int> num = GeneratedColumn<int>(
    'num',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speakerMeta = const VerificationMeta(
    'speaker',
  );
  @override
  late final GeneratedColumn<String> speaker = GeneratedColumn<String>(
    'speaker',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zhMeta = const VerificationMeta('zh');
  @override
  late final GeneratedColumn<String> zh = GeneratedColumn<String>(
    'zh',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinyinMeta = const VerificationMeta('pinyin');
  @override
  late final GeneratedColumn<String> pinyin = GeneratedColumn<String>(
    'pinyin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _koMeta = const VerificationMeta('ko');
  @override
  late final GeneratedColumn<String> ko = GeneratedColumn<String>(
    'ko',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tonesMeta = const VerificationMeta('tones');
  @override
  late final GeneratedColumn<String> tones = GeneratedColumn<String>(
    'tones',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    level,
    dialect,
    episodeId,
    num,
    speaker,
    zh,
    pinyin,
    ko,
    tones,
    note,
    tagsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'turns';
  @override
  VerificationContext validateIntegrity(
    Insertable<TurnRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('dialect')) {
      context.handle(
        _dialectMeta,
        dialect.isAcceptableOrUnknown(data['dialect']!, _dialectMeta),
      );
    }
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    }
    if (data.containsKey('num')) {
      context.handle(
        _numMeta,
        num.isAcceptableOrUnknown(data['num']!, _numMeta),
      );
    } else if (isInserting) {
      context.missing(_numMeta);
    }
    if (data.containsKey('speaker')) {
      context.handle(
        _speakerMeta,
        speaker.isAcceptableOrUnknown(data['speaker']!, _speakerMeta),
      );
    } else if (isInserting) {
      context.missing(_speakerMeta);
    }
    if (data.containsKey('zh')) {
      context.handle(_zhMeta, zh.isAcceptableOrUnknown(data['zh']!, _zhMeta));
    } else if (isInserting) {
      context.missing(_zhMeta);
    }
    if (data.containsKey('pinyin')) {
      context.handle(
        _pinyinMeta,
        pinyin.isAcceptableOrUnknown(data['pinyin']!, _pinyinMeta),
      );
    }
    if (data.containsKey('ko')) {
      context.handle(_koMeta, ko.isAcceptableOrUnknown(data['ko']!, _koMeta));
    }
    if (data.containsKey('tones')) {
      context.handle(
        _tonesMeta,
        tones.isAcceptableOrUnknown(data['tones']!, _tonesMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TurnRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TurnRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      dialect: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dialect'],
      )!,
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_id'],
      ),
      num: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}num'],
      )!,
      speaker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}speaker'],
      )!,
      zh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zh'],
      )!,
      pinyin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pinyin'],
      ),
      ko: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ko'],
      ),
      tones: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tones'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      ),
    );
  }

  @override
  $TurnsTable createAlias(String alias) {
    return $TurnsTable(attachedDatabase, alias);
  }
}

class TurnRow extends DataClass implements Insertable<TurnRow> {
  final int id;
  final String level;
  final String dialect;
  final String? episodeId;
  final int num;
  final String speaker;
  final String zh;
  final String? pinyin;
  final String? ko;
  final String? tones;
  final String? note;
  final String? tagsJson;
  const TurnRow({
    required this.id,
    required this.level,
    required this.dialect,
    this.episodeId,
    required this.num,
    required this.speaker,
    required this.zh,
    this.pinyin,
    this.ko,
    this.tones,
    this.note,
    this.tagsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['level'] = Variable<String>(level);
    map['dialect'] = Variable<String>(dialect);
    if (!nullToAbsent || episodeId != null) {
      map['episode_id'] = Variable<String>(episodeId);
    }
    map['num'] = Variable<int>(num);
    map['speaker'] = Variable<String>(speaker);
    map['zh'] = Variable<String>(zh);
    if (!nullToAbsent || pinyin != null) {
      map['pinyin'] = Variable<String>(pinyin);
    }
    if (!nullToAbsent || ko != null) {
      map['ko'] = Variable<String>(ko);
    }
    if (!nullToAbsent || tones != null) {
      map['tones'] = Variable<String>(tones);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || tagsJson != null) {
      map['tags_json'] = Variable<String>(tagsJson);
    }
    return map;
  }

  TurnsCompanion toCompanion(bool nullToAbsent) {
    return TurnsCompanion(
      id: Value(id),
      level: Value(level),
      dialect: Value(dialect),
      episodeId: episodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeId),
      num: Value(num),
      speaker: Value(speaker),
      zh: Value(zh),
      pinyin: pinyin == null && nullToAbsent
          ? const Value.absent()
          : Value(pinyin),
      ko: ko == null && nullToAbsent ? const Value.absent() : Value(ko),
      tones: tones == null && nullToAbsent
          ? const Value.absent()
          : Value(tones),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      tagsJson: tagsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(tagsJson),
    );
  }

  factory TurnRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TurnRow(
      id: serializer.fromJson<int>(json['id']),
      level: serializer.fromJson<String>(json['level']),
      dialect: serializer.fromJson<String>(json['dialect']),
      episodeId: serializer.fromJson<String?>(json['episodeId']),
      num: serializer.fromJson<int>(json['num']),
      speaker: serializer.fromJson<String>(json['speaker']),
      zh: serializer.fromJson<String>(json['zh']),
      pinyin: serializer.fromJson<String?>(json['pinyin']),
      ko: serializer.fromJson<String?>(json['ko']),
      tones: serializer.fromJson<String?>(json['tones']),
      note: serializer.fromJson<String?>(json['note']),
      tagsJson: serializer.fromJson<String?>(json['tagsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'level': serializer.toJson<String>(level),
      'dialect': serializer.toJson<String>(dialect),
      'episodeId': serializer.toJson<String?>(episodeId),
      'num': serializer.toJson<int>(num),
      'speaker': serializer.toJson<String>(speaker),
      'zh': serializer.toJson<String>(zh),
      'pinyin': serializer.toJson<String?>(pinyin),
      'ko': serializer.toJson<String?>(ko),
      'tones': serializer.toJson<String?>(tones),
      'note': serializer.toJson<String?>(note),
      'tagsJson': serializer.toJson<String?>(tagsJson),
    };
  }

  TurnRow copyWith({
    int? id,
    String? level,
    String? dialect,
    Value<String?> episodeId = const Value.absent(),
    int? num,
    String? speaker,
    String? zh,
    Value<String?> pinyin = const Value.absent(),
    Value<String?> ko = const Value.absent(),
    Value<String?> tones = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> tagsJson = const Value.absent(),
  }) => TurnRow(
    id: id ?? this.id,
    level: level ?? this.level,
    dialect: dialect ?? this.dialect,
    episodeId: episodeId.present ? episodeId.value : this.episodeId,
    num: num ?? this.num,
    speaker: speaker ?? this.speaker,
    zh: zh ?? this.zh,
    pinyin: pinyin.present ? pinyin.value : this.pinyin,
    ko: ko.present ? ko.value : this.ko,
    tones: tones.present ? tones.value : this.tones,
    note: note.present ? note.value : this.note,
    tagsJson: tagsJson.present ? tagsJson.value : this.tagsJson,
  );
  TurnRow copyWithCompanion(TurnsCompanion data) {
    return TurnRow(
      id: data.id.present ? data.id.value : this.id,
      level: data.level.present ? data.level.value : this.level,
      dialect: data.dialect.present ? data.dialect.value : this.dialect,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      num: data.num.present ? data.num.value : this.num,
      speaker: data.speaker.present ? data.speaker.value : this.speaker,
      zh: data.zh.present ? data.zh.value : this.zh,
      pinyin: data.pinyin.present ? data.pinyin.value : this.pinyin,
      ko: data.ko.present ? data.ko.value : this.ko,
      tones: data.tones.present ? data.tones.value : this.tones,
      note: data.note.present ? data.note.value : this.note,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TurnRow(')
          ..write('id: $id, ')
          ..write('level: $level, ')
          ..write('dialect: $dialect, ')
          ..write('episodeId: $episodeId, ')
          ..write('num: $num, ')
          ..write('speaker: $speaker, ')
          ..write('zh: $zh, ')
          ..write('pinyin: $pinyin, ')
          ..write('ko: $ko, ')
          ..write('tones: $tones, ')
          ..write('note: $note, ')
          ..write('tagsJson: $tagsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    level,
    dialect,
    episodeId,
    num,
    speaker,
    zh,
    pinyin,
    ko,
    tones,
    note,
    tagsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TurnRow &&
          other.id == this.id &&
          other.level == this.level &&
          other.dialect == this.dialect &&
          other.episodeId == this.episodeId &&
          other.num == this.num &&
          other.speaker == this.speaker &&
          other.zh == this.zh &&
          other.pinyin == this.pinyin &&
          other.ko == this.ko &&
          other.tones == this.tones &&
          other.note == this.note &&
          other.tagsJson == this.tagsJson);
}

class TurnsCompanion extends UpdateCompanion<TurnRow> {
  final Value<int> id;
  final Value<String> level;
  final Value<String> dialect;
  final Value<String?> episodeId;
  final Value<int> num;
  final Value<String> speaker;
  final Value<String> zh;
  final Value<String?> pinyin;
  final Value<String?> ko;
  final Value<String?> tones;
  final Value<String?> note;
  final Value<String?> tagsJson;
  const TurnsCompanion({
    this.id = const Value.absent(),
    this.level = const Value.absent(),
    this.dialect = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.num = const Value.absent(),
    this.speaker = const Value.absent(),
    this.zh = const Value.absent(),
    this.pinyin = const Value.absent(),
    this.ko = const Value.absent(),
    this.tones = const Value.absent(),
    this.note = const Value.absent(),
    this.tagsJson = const Value.absent(),
  });
  TurnsCompanion.insert({
    this.id = const Value.absent(),
    required String level,
    this.dialect = const Value.absent(),
    this.episodeId = const Value.absent(),
    required int num,
    required String speaker,
    required String zh,
    this.pinyin = const Value.absent(),
    this.ko = const Value.absent(),
    this.tones = const Value.absent(),
    this.note = const Value.absent(),
    this.tagsJson = const Value.absent(),
  }) : level = Value(level),
       num = Value(num),
       speaker = Value(speaker),
       zh = Value(zh);
  static Insertable<TurnRow> custom({
    Expression<int>? id,
    Expression<String>? level,
    Expression<String>? dialect,
    Expression<String>? episodeId,
    Expression<int>? num,
    Expression<String>? speaker,
    Expression<String>? zh,
    Expression<String>? pinyin,
    Expression<String>? ko,
    Expression<String>? tones,
    Expression<String>? note,
    Expression<String>? tagsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (level != null) 'level': level,
      if (dialect != null) 'dialect': dialect,
      if (episodeId != null) 'episode_id': episodeId,
      if (num != null) 'num': num,
      if (speaker != null) 'speaker': speaker,
      if (zh != null) 'zh': zh,
      if (pinyin != null) 'pinyin': pinyin,
      if (ko != null) 'ko': ko,
      if (tones != null) 'tones': tones,
      if (note != null) 'note': note,
      if (tagsJson != null) 'tags_json': tagsJson,
    });
  }

  TurnsCompanion copyWith({
    Value<int>? id,
    Value<String>? level,
    Value<String>? dialect,
    Value<String?>? episodeId,
    Value<int>? num,
    Value<String>? speaker,
    Value<String>? zh,
    Value<String?>? pinyin,
    Value<String?>? ko,
    Value<String?>? tones,
    Value<String?>? note,
    Value<String?>? tagsJson,
  }) {
    return TurnsCompanion(
      id: id ?? this.id,
      level: level ?? this.level,
      dialect: dialect ?? this.dialect,
      episodeId: episodeId ?? this.episodeId,
      num: num ?? this.num,
      speaker: speaker ?? this.speaker,
      zh: zh ?? this.zh,
      pinyin: pinyin ?? this.pinyin,
      ko: ko ?? this.ko,
      tones: tones ?? this.tones,
      note: note ?? this.note,
      tagsJson: tagsJson ?? this.tagsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (dialect.present) {
      map['dialect'] = Variable<String>(dialect.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (num.present) {
      map['num'] = Variable<int>(num.value);
    }
    if (speaker.present) {
      map['speaker'] = Variable<String>(speaker.value);
    }
    if (zh.present) {
      map['zh'] = Variable<String>(zh.value);
    }
    if (pinyin.present) {
      map['pinyin'] = Variable<String>(pinyin.value);
    }
    if (ko.present) {
      map['ko'] = Variable<String>(ko.value);
    }
    if (tones.present) {
      map['tones'] = Variable<String>(tones.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TurnsCompanion(')
          ..write('id: $id, ')
          ..write('level: $level, ')
          ..write('dialect: $dialect, ')
          ..write('episodeId: $episodeId, ')
          ..write('num: $num, ')
          ..write('speaker: $speaker, ')
          ..write('zh: $zh, ')
          ..write('pinyin: $pinyin, ')
          ..write('ko: $ko, ')
          ..write('tones: $tones, ')
          ..write('note: $note, ')
          ..write('tagsJson: $tagsJson')
          ..write(')'))
        .toString();
  }
}

class $HanziTable extends Hanzi with TableInfo<$HanziTable, HanziRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HanziTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _charMeta = const VerificationMeta('char');
  @override
  late final GeneratedColumn<String> char = GeneratedColumn<String>(
    'char',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _freqMeta = const VerificationMeta('freq');
  @override
  late final GeneratedColumn<int> freq = GeneratedColumn<int>(
    'freq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hskLevelMeta = const VerificationMeta(
    'hskLevel',
  );
  @override
  late final GeneratedColumn<String> hskLevel = GeneratedColumn<String>(
    'hsk_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<int> phase = GeneratedColumn<int>(
    'phase',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinyinMeta = const VerificationMeta('pinyin');
  @override
  late final GeneratedColumn<String> pinyin = GeneratedColumn<String>(
    'pinyin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toneMeta = const VerificationMeta('tone');
  @override
  late final GeneratedColumn<int> tone = GeneratedColumn<int>(
    'tone',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meaningKoMeta = const VerificationMeta(
    'meaningKo',
  );
  @override
  late final GeneratedColumn<String> meaningKo = GeneratedColumn<String>(
    'meaning_ko',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _koHanjaMeta = const VerificationMeta(
    'koHanja',
  );
  @override
  late final GeneratedColumn<String> koHanja = GeneratedColumn<String>(
    'ko_hanja',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    char,
    rank,
    freq,
    hskLevel,
    phase,
    pinyin,
    tone,
    meaningKo,
    koHanja,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hanzi';
  @override
  VerificationContext validateIntegrity(
    Insertable<HanziRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('char')) {
      context.handle(
        _charMeta,
        char.isAcceptableOrUnknown(data['char']!, _charMeta),
      );
    } else if (isInserting) {
      context.missing(_charMeta);
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    }
    if (data.containsKey('freq')) {
      context.handle(
        _freqMeta,
        freq.isAcceptableOrUnknown(data['freq']!, _freqMeta),
      );
    }
    if (data.containsKey('hsk_level')) {
      context.handle(
        _hskLevelMeta,
        hskLevel.isAcceptableOrUnknown(data['hsk_level']!, _hskLevelMeta),
      );
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    }
    if (data.containsKey('pinyin')) {
      context.handle(
        _pinyinMeta,
        pinyin.isAcceptableOrUnknown(data['pinyin']!, _pinyinMeta),
      );
    }
    if (data.containsKey('tone')) {
      context.handle(
        _toneMeta,
        tone.isAcceptableOrUnknown(data['tone']!, _toneMeta),
      );
    }
    if (data.containsKey('meaning_ko')) {
      context.handle(
        _meaningKoMeta,
        meaningKo.isAcceptableOrUnknown(data['meaning_ko']!, _meaningKoMeta),
      );
    }
    if (data.containsKey('ko_hanja')) {
      context.handle(
        _koHanjaMeta,
        koHanja.isAcceptableOrUnknown(data['ko_hanja']!, _koHanjaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {char};
  @override
  HanziRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HanziRow(
      char: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}char'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      ),
      freq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}freq'],
      ),
      hskLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hsk_level'],
      ),
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phase'],
      ),
      pinyin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pinyin'],
      ),
      tone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tone'],
      ),
      meaningKo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning_ko'],
      ),
      koHanja: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ko_hanja'],
      ),
    );
  }

  @override
  $HanziTable createAlias(String alias) {
    return $HanziTable(attachedDatabase, alias);
  }
}

class HanziRow extends DataClass implements Insertable<HanziRow> {
  final String char;
  final int? rank;
  final int? freq;
  final String? hskLevel;
  final int? phase;
  final String? pinyin;
  final int? tone;
  final String? meaningKo;
  final String? koHanja;
  const HanziRow({
    required this.char,
    this.rank,
    this.freq,
    this.hskLevel,
    this.phase,
    this.pinyin,
    this.tone,
    this.meaningKo,
    this.koHanja,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['char'] = Variable<String>(char);
    if (!nullToAbsent || rank != null) {
      map['rank'] = Variable<int>(rank);
    }
    if (!nullToAbsent || freq != null) {
      map['freq'] = Variable<int>(freq);
    }
    if (!nullToAbsent || hskLevel != null) {
      map['hsk_level'] = Variable<String>(hskLevel);
    }
    if (!nullToAbsent || phase != null) {
      map['phase'] = Variable<int>(phase);
    }
    if (!nullToAbsent || pinyin != null) {
      map['pinyin'] = Variable<String>(pinyin);
    }
    if (!nullToAbsent || tone != null) {
      map['tone'] = Variable<int>(tone);
    }
    if (!nullToAbsent || meaningKo != null) {
      map['meaning_ko'] = Variable<String>(meaningKo);
    }
    if (!nullToAbsent || koHanja != null) {
      map['ko_hanja'] = Variable<String>(koHanja);
    }
    return map;
  }

  HanziCompanion toCompanion(bool nullToAbsent) {
    return HanziCompanion(
      char: Value(char),
      rank: rank == null && nullToAbsent ? const Value.absent() : Value(rank),
      freq: freq == null && nullToAbsent ? const Value.absent() : Value(freq),
      hskLevel: hskLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(hskLevel),
      phase: phase == null && nullToAbsent
          ? const Value.absent()
          : Value(phase),
      pinyin: pinyin == null && nullToAbsent
          ? const Value.absent()
          : Value(pinyin),
      tone: tone == null && nullToAbsent ? const Value.absent() : Value(tone),
      meaningKo: meaningKo == null && nullToAbsent
          ? const Value.absent()
          : Value(meaningKo),
      koHanja: koHanja == null && nullToAbsent
          ? const Value.absent()
          : Value(koHanja),
    );
  }

  factory HanziRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HanziRow(
      char: serializer.fromJson<String>(json['char']),
      rank: serializer.fromJson<int?>(json['rank']),
      freq: serializer.fromJson<int?>(json['freq']),
      hskLevel: serializer.fromJson<String?>(json['hskLevel']),
      phase: serializer.fromJson<int?>(json['phase']),
      pinyin: serializer.fromJson<String?>(json['pinyin']),
      tone: serializer.fromJson<int?>(json['tone']),
      meaningKo: serializer.fromJson<String?>(json['meaningKo']),
      koHanja: serializer.fromJson<String?>(json['koHanja']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'char': serializer.toJson<String>(char),
      'rank': serializer.toJson<int?>(rank),
      'freq': serializer.toJson<int?>(freq),
      'hskLevel': serializer.toJson<String?>(hskLevel),
      'phase': serializer.toJson<int?>(phase),
      'pinyin': serializer.toJson<String?>(pinyin),
      'tone': serializer.toJson<int?>(tone),
      'meaningKo': serializer.toJson<String?>(meaningKo),
      'koHanja': serializer.toJson<String?>(koHanja),
    };
  }

  HanziRow copyWith({
    String? char,
    Value<int?> rank = const Value.absent(),
    Value<int?> freq = const Value.absent(),
    Value<String?> hskLevel = const Value.absent(),
    Value<int?> phase = const Value.absent(),
    Value<String?> pinyin = const Value.absent(),
    Value<int?> tone = const Value.absent(),
    Value<String?> meaningKo = const Value.absent(),
    Value<String?> koHanja = const Value.absent(),
  }) => HanziRow(
    char: char ?? this.char,
    rank: rank.present ? rank.value : this.rank,
    freq: freq.present ? freq.value : this.freq,
    hskLevel: hskLevel.present ? hskLevel.value : this.hskLevel,
    phase: phase.present ? phase.value : this.phase,
    pinyin: pinyin.present ? pinyin.value : this.pinyin,
    tone: tone.present ? tone.value : this.tone,
    meaningKo: meaningKo.present ? meaningKo.value : this.meaningKo,
    koHanja: koHanja.present ? koHanja.value : this.koHanja,
  );
  HanziRow copyWithCompanion(HanziCompanion data) {
    return HanziRow(
      char: data.char.present ? data.char.value : this.char,
      rank: data.rank.present ? data.rank.value : this.rank,
      freq: data.freq.present ? data.freq.value : this.freq,
      hskLevel: data.hskLevel.present ? data.hskLevel.value : this.hskLevel,
      phase: data.phase.present ? data.phase.value : this.phase,
      pinyin: data.pinyin.present ? data.pinyin.value : this.pinyin,
      tone: data.tone.present ? data.tone.value : this.tone,
      meaningKo: data.meaningKo.present ? data.meaningKo.value : this.meaningKo,
      koHanja: data.koHanja.present ? data.koHanja.value : this.koHanja,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HanziRow(')
          ..write('char: $char, ')
          ..write('rank: $rank, ')
          ..write('freq: $freq, ')
          ..write('hskLevel: $hskLevel, ')
          ..write('phase: $phase, ')
          ..write('pinyin: $pinyin, ')
          ..write('tone: $tone, ')
          ..write('meaningKo: $meaningKo, ')
          ..write('koHanja: $koHanja')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    char,
    rank,
    freq,
    hskLevel,
    phase,
    pinyin,
    tone,
    meaningKo,
    koHanja,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HanziRow &&
          other.char == this.char &&
          other.rank == this.rank &&
          other.freq == this.freq &&
          other.hskLevel == this.hskLevel &&
          other.phase == this.phase &&
          other.pinyin == this.pinyin &&
          other.tone == this.tone &&
          other.meaningKo == this.meaningKo &&
          other.koHanja == this.koHanja);
}

class HanziCompanion extends UpdateCompanion<HanziRow> {
  final Value<String> char;
  final Value<int?> rank;
  final Value<int?> freq;
  final Value<String?> hskLevel;
  final Value<int?> phase;
  final Value<String?> pinyin;
  final Value<int?> tone;
  final Value<String?> meaningKo;
  final Value<String?> koHanja;
  final Value<int> rowid;
  const HanziCompanion({
    this.char = const Value.absent(),
    this.rank = const Value.absent(),
    this.freq = const Value.absent(),
    this.hskLevel = const Value.absent(),
    this.phase = const Value.absent(),
    this.pinyin = const Value.absent(),
    this.tone = const Value.absent(),
    this.meaningKo = const Value.absent(),
    this.koHanja = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HanziCompanion.insert({
    required String char,
    this.rank = const Value.absent(),
    this.freq = const Value.absent(),
    this.hskLevel = const Value.absent(),
    this.phase = const Value.absent(),
    this.pinyin = const Value.absent(),
    this.tone = const Value.absent(),
    this.meaningKo = const Value.absent(),
    this.koHanja = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : char = Value(char);
  static Insertable<HanziRow> custom({
    Expression<String>? char,
    Expression<int>? rank,
    Expression<int>? freq,
    Expression<String>? hskLevel,
    Expression<int>? phase,
    Expression<String>? pinyin,
    Expression<int>? tone,
    Expression<String>? meaningKo,
    Expression<String>? koHanja,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (char != null) 'char': char,
      if (rank != null) 'rank': rank,
      if (freq != null) 'freq': freq,
      if (hskLevel != null) 'hsk_level': hskLevel,
      if (phase != null) 'phase': phase,
      if (pinyin != null) 'pinyin': pinyin,
      if (tone != null) 'tone': tone,
      if (meaningKo != null) 'meaning_ko': meaningKo,
      if (koHanja != null) 'ko_hanja': koHanja,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HanziCompanion copyWith({
    Value<String>? char,
    Value<int?>? rank,
    Value<int?>? freq,
    Value<String?>? hskLevel,
    Value<int?>? phase,
    Value<String?>? pinyin,
    Value<int?>? tone,
    Value<String?>? meaningKo,
    Value<String?>? koHanja,
    Value<int>? rowid,
  }) {
    return HanziCompanion(
      char: char ?? this.char,
      rank: rank ?? this.rank,
      freq: freq ?? this.freq,
      hskLevel: hskLevel ?? this.hskLevel,
      phase: phase ?? this.phase,
      pinyin: pinyin ?? this.pinyin,
      tone: tone ?? this.tone,
      meaningKo: meaningKo ?? this.meaningKo,
      koHanja: koHanja ?? this.koHanja,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (char.present) {
      map['char'] = Variable<String>(char.value);
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    if (freq.present) {
      map['freq'] = Variable<int>(freq.value);
    }
    if (hskLevel.present) {
      map['hsk_level'] = Variable<String>(hskLevel.value);
    }
    if (phase.present) {
      map['phase'] = Variable<int>(phase.value);
    }
    if (pinyin.present) {
      map['pinyin'] = Variable<String>(pinyin.value);
    }
    if (tone.present) {
      map['tone'] = Variable<int>(tone.value);
    }
    if (meaningKo.present) {
      map['meaning_ko'] = Variable<String>(meaningKo.value);
    }
    if (koHanja.present) {
      map['ko_hanja'] = Variable<String>(koHanja.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HanziCompanion(')
          ..write('char: $char, ')
          ..write('rank: $rank, ')
          ..write('freq: $freq, ')
          ..write('hskLevel: $hskLevel, ')
          ..write('phase: $phase, ')
          ..write('pinyin: $pinyin, ')
          ..write('tone: $tone, ')
          ..write('meaningKo: $meaningKo, ')
          ..write('koHanja: $koHanja, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhoneticRootsTable extends PhoneticRoots
    with TableInfo<$PhoneticRootsTable, PhoneticRootRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhoneticRootsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _rootMeta = const VerificationMeta('root');
  @override
  late final GeneratedColumn<String> root = GeneratedColumn<String>(
    'root',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinyinMeta = const VerificationMeta('pinyin');
  @override
  late final GeneratedColumn<String> pinyin = GeneratedColumn<String>(
    'pinyin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _koHanjaMeta = const VerificationMeta(
    'koHanja',
  );
  @override
  late final GeneratedColumn<String> koHanja = GeneratedColumn<String>(
    'ko_hanja',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clusterCountMeta = const VerificationMeta(
    'clusterCount',
  );
  @override
  late final GeneratedColumn<int> clusterCount = GeneratedColumn<int>(
    'cluster_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mnemonicMeta = const VerificationMeta(
    'mnemonic',
  );
  @override
  late final GeneratedColumn<String> mnemonic = GeneratedColumn<String>(
    'mnemonic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    root,
    pinyin,
    koHanja,
    clusterCount,
    mnemonic,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'phonetic_roots';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhoneticRootRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('root')) {
      context.handle(
        _rootMeta,
        root.isAcceptableOrUnknown(data['root']!, _rootMeta),
      );
    } else if (isInserting) {
      context.missing(_rootMeta);
    }
    if (data.containsKey('pinyin')) {
      context.handle(
        _pinyinMeta,
        pinyin.isAcceptableOrUnknown(data['pinyin']!, _pinyinMeta),
      );
    }
    if (data.containsKey('ko_hanja')) {
      context.handle(
        _koHanjaMeta,
        koHanja.isAcceptableOrUnknown(data['ko_hanja']!, _koHanjaMeta),
      );
    }
    if (data.containsKey('cluster_count')) {
      context.handle(
        _clusterCountMeta,
        clusterCount.isAcceptableOrUnknown(
          data['cluster_count']!,
          _clusterCountMeta,
        ),
      );
    }
    if (data.containsKey('mnemonic')) {
      context.handle(
        _mnemonicMeta,
        mnemonic.isAcceptableOrUnknown(data['mnemonic']!, _mnemonicMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhoneticRootRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhoneticRootRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      root: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root'],
      )!,
      pinyin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pinyin'],
      ),
      koHanja: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ko_hanja'],
      ),
      clusterCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cluster_count'],
      )!,
      mnemonic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mnemonic'],
      ),
    );
  }

  @override
  $PhoneticRootsTable createAlias(String alias) {
    return $PhoneticRootsTable(attachedDatabase, alias);
  }
}

class PhoneticRootRow extends DataClass implements Insertable<PhoneticRootRow> {
  final int id;
  final String root;
  final String? pinyin;
  final String? koHanja;
  final int clusterCount;
  final String? mnemonic;
  const PhoneticRootRow({
    required this.id,
    required this.root,
    this.pinyin,
    this.koHanja,
    required this.clusterCount,
    this.mnemonic,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['root'] = Variable<String>(root);
    if (!nullToAbsent || pinyin != null) {
      map['pinyin'] = Variable<String>(pinyin);
    }
    if (!nullToAbsent || koHanja != null) {
      map['ko_hanja'] = Variable<String>(koHanja);
    }
    map['cluster_count'] = Variable<int>(clusterCount);
    if (!nullToAbsent || mnemonic != null) {
      map['mnemonic'] = Variable<String>(mnemonic);
    }
    return map;
  }

  PhoneticRootsCompanion toCompanion(bool nullToAbsent) {
    return PhoneticRootsCompanion(
      id: Value(id),
      root: Value(root),
      pinyin: pinyin == null && nullToAbsent
          ? const Value.absent()
          : Value(pinyin),
      koHanja: koHanja == null && nullToAbsent
          ? const Value.absent()
          : Value(koHanja),
      clusterCount: Value(clusterCount),
      mnemonic: mnemonic == null && nullToAbsent
          ? const Value.absent()
          : Value(mnemonic),
    );
  }

  factory PhoneticRootRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhoneticRootRow(
      id: serializer.fromJson<int>(json['id']),
      root: serializer.fromJson<String>(json['root']),
      pinyin: serializer.fromJson<String?>(json['pinyin']),
      koHanja: serializer.fromJson<String?>(json['koHanja']),
      clusterCount: serializer.fromJson<int>(json['clusterCount']),
      mnemonic: serializer.fromJson<String?>(json['mnemonic']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'root': serializer.toJson<String>(root),
      'pinyin': serializer.toJson<String?>(pinyin),
      'koHanja': serializer.toJson<String?>(koHanja),
      'clusterCount': serializer.toJson<int>(clusterCount),
      'mnemonic': serializer.toJson<String?>(mnemonic),
    };
  }

  PhoneticRootRow copyWith({
    int? id,
    String? root,
    Value<String?> pinyin = const Value.absent(),
    Value<String?> koHanja = const Value.absent(),
    int? clusterCount,
    Value<String?> mnemonic = const Value.absent(),
  }) => PhoneticRootRow(
    id: id ?? this.id,
    root: root ?? this.root,
    pinyin: pinyin.present ? pinyin.value : this.pinyin,
    koHanja: koHanja.present ? koHanja.value : this.koHanja,
    clusterCount: clusterCount ?? this.clusterCount,
    mnemonic: mnemonic.present ? mnemonic.value : this.mnemonic,
  );
  PhoneticRootRow copyWithCompanion(PhoneticRootsCompanion data) {
    return PhoneticRootRow(
      id: data.id.present ? data.id.value : this.id,
      root: data.root.present ? data.root.value : this.root,
      pinyin: data.pinyin.present ? data.pinyin.value : this.pinyin,
      koHanja: data.koHanja.present ? data.koHanja.value : this.koHanja,
      clusterCount: data.clusterCount.present
          ? data.clusterCount.value
          : this.clusterCount,
      mnemonic: data.mnemonic.present ? data.mnemonic.value : this.mnemonic,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhoneticRootRow(')
          ..write('id: $id, ')
          ..write('root: $root, ')
          ..write('pinyin: $pinyin, ')
          ..write('koHanja: $koHanja, ')
          ..write('clusterCount: $clusterCount, ')
          ..write('mnemonic: $mnemonic')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, root, pinyin, koHanja, clusterCount, mnemonic);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhoneticRootRow &&
          other.id == this.id &&
          other.root == this.root &&
          other.pinyin == this.pinyin &&
          other.koHanja == this.koHanja &&
          other.clusterCount == this.clusterCount &&
          other.mnemonic == this.mnemonic);
}

class PhoneticRootsCompanion extends UpdateCompanion<PhoneticRootRow> {
  final Value<int> id;
  final Value<String> root;
  final Value<String?> pinyin;
  final Value<String?> koHanja;
  final Value<int> clusterCount;
  final Value<String?> mnemonic;
  const PhoneticRootsCompanion({
    this.id = const Value.absent(),
    this.root = const Value.absent(),
    this.pinyin = const Value.absent(),
    this.koHanja = const Value.absent(),
    this.clusterCount = const Value.absent(),
    this.mnemonic = const Value.absent(),
  });
  PhoneticRootsCompanion.insert({
    this.id = const Value.absent(),
    required String root,
    this.pinyin = const Value.absent(),
    this.koHanja = const Value.absent(),
    this.clusterCount = const Value.absent(),
    this.mnemonic = const Value.absent(),
  }) : root = Value(root);
  static Insertable<PhoneticRootRow> custom({
    Expression<int>? id,
    Expression<String>? root,
    Expression<String>? pinyin,
    Expression<String>? koHanja,
    Expression<int>? clusterCount,
    Expression<String>? mnemonic,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (root != null) 'root': root,
      if (pinyin != null) 'pinyin': pinyin,
      if (koHanja != null) 'ko_hanja': koHanja,
      if (clusterCount != null) 'cluster_count': clusterCount,
      if (mnemonic != null) 'mnemonic': mnemonic,
    });
  }

  PhoneticRootsCompanion copyWith({
    Value<int>? id,
    Value<String>? root,
    Value<String?>? pinyin,
    Value<String?>? koHanja,
    Value<int>? clusterCount,
    Value<String?>? mnemonic,
  }) {
    return PhoneticRootsCompanion(
      id: id ?? this.id,
      root: root ?? this.root,
      pinyin: pinyin ?? this.pinyin,
      koHanja: koHanja ?? this.koHanja,
      clusterCount: clusterCount ?? this.clusterCount,
      mnemonic: mnemonic ?? this.mnemonic,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (root.present) {
      map['root'] = Variable<String>(root.value);
    }
    if (pinyin.present) {
      map['pinyin'] = Variable<String>(pinyin.value);
    }
    if (koHanja.present) {
      map['ko_hanja'] = Variable<String>(koHanja.value);
    }
    if (clusterCount.present) {
      map['cluster_count'] = Variable<int>(clusterCount.value);
    }
    if (mnemonic.present) {
      map['mnemonic'] = Variable<String>(mnemonic.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhoneticRootsCompanion(')
          ..write('id: $id, ')
          ..write('root: $root, ')
          ..write('pinyin: $pinyin, ')
          ..write('koHanja: $koHanja, ')
          ..write('clusterCount: $clusterCount, ')
          ..write('mnemonic: $mnemonic')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, WordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _freqMeta = const VerificationMeta('freq');
  @override
  late final GeneratedColumn<double> freq = GeneratedColumn<double>(
    'freq',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cumPctMeta = const VerificationMeta('cumPct');
  @override
  late final GeneratedColumn<double> cumPct = GeneratedColumn<double>(
    'cum_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hskLevelMeta = const VerificationMeta(
    'hskLevel',
  );
  @override
  late final GeneratedColumn<String> hskLevel = GeneratedColumn<String>(
    'hsk_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rank,
    word,
    freq,
    cumPct,
    region,
    hskLevel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('freq')) {
      context.handle(
        _freqMeta,
        freq.isAcceptableOrUnknown(data['freq']!, _freqMeta),
      );
    }
    if (data.containsKey('cum_pct')) {
      context.handle(
        _cumPctMeta,
        cumPct.isAcceptableOrUnknown(data['cum_pct']!, _cumPctMeta),
      );
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('hsk_level')) {
      context.handle(
        _hskLevelMeta,
        hskLevel.isAcceptableOrUnknown(data['hsk_level']!, _hskLevelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rank};
  @override
  WordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordRow(
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      freq: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}freq'],
      ),
      cumPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cum_pct'],
      ),
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      ),
      hskLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hsk_level'],
      ),
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class WordRow extends DataClass implements Insertable<WordRow> {
  final int rank;
  final String word;
  final double? freq;
  final double? cumPct;
  final String? region;
  final String? hskLevel;
  const WordRow({
    required this.rank,
    required this.word,
    this.freq,
    this.cumPct,
    this.region,
    this.hskLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['rank'] = Variable<int>(rank);
    map['word'] = Variable<String>(word);
    if (!nullToAbsent || freq != null) {
      map['freq'] = Variable<double>(freq);
    }
    if (!nullToAbsent || cumPct != null) {
      map['cum_pct'] = Variable<double>(cumPct);
    }
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    if (!nullToAbsent || hskLevel != null) {
      map['hsk_level'] = Variable<String>(hskLevel);
    }
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      rank: Value(rank),
      word: Value(word),
      freq: freq == null && nullToAbsent ? const Value.absent() : Value(freq),
      cumPct: cumPct == null && nullToAbsent
          ? const Value.absent()
          : Value(cumPct),
      region: region == null && nullToAbsent
          ? const Value.absent()
          : Value(region),
      hskLevel: hskLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(hskLevel),
    );
  }

  factory WordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordRow(
      rank: serializer.fromJson<int>(json['rank']),
      word: serializer.fromJson<String>(json['word']),
      freq: serializer.fromJson<double?>(json['freq']),
      cumPct: serializer.fromJson<double?>(json['cumPct']),
      region: serializer.fromJson<String?>(json['region']),
      hskLevel: serializer.fromJson<String?>(json['hskLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rank': serializer.toJson<int>(rank),
      'word': serializer.toJson<String>(word),
      'freq': serializer.toJson<double?>(freq),
      'cumPct': serializer.toJson<double?>(cumPct),
      'region': serializer.toJson<String?>(region),
      'hskLevel': serializer.toJson<String?>(hskLevel),
    };
  }

  WordRow copyWith({
    int? rank,
    String? word,
    Value<double?> freq = const Value.absent(),
    Value<double?> cumPct = const Value.absent(),
    Value<String?> region = const Value.absent(),
    Value<String?> hskLevel = const Value.absent(),
  }) => WordRow(
    rank: rank ?? this.rank,
    word: word ?? this.word,
    freq: freq.present ? freq.value : this.freq,
    cumPct: cumPct.present ? cumPct.value : this.cumPct,
    region: region.present ? region.value : this.region,
    hskLevel: hskLevel.present ? hskLevel.value : this.hskLevel,
  );
  WordRow copyWithCompanion(WordsCompanion data) {
    return WordRow(
      rank: data.rank.present ? data.rank.value : this.rank,
      word: data.word.present ? data.word.value : this.word,
      freq: data.freq.present ? data.freq.value : this.freq,
      cumPct: data.cumPct.present ? data.cumPct.value : this.cumPct,
      region: data.region.present ? data.region.value : this.region,
      hskLevel: data.hskLevel.present ? data.hskLevel.value : this.hskLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordRow(')
          ..write('rank: $rank, ')
          ..write('word: $word, ')
          ..write('freq: $freq, ')
          ..write('cumPct: $cumPct, ')
          ..write('region: $region, ')
          ..write('hskLevel: $hskLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rank, word, freq, cumPct, region, hskLevel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordRow &&
          other.rank == this.rank &&
          other.word == this.word &&
          other.freq == this.freq &&
          other.cumPct == this.cumPct &&
          other.region == this.region &&
          other.hskLevel == this.hskLevel);
}

class WordsCompanion extends UpdateCompanion<WordRow> {
  final Value<int> rank;
  final Value<String> word;
  final Value<double?> freq;
  final Value<double?> cumPct;
  final Value<String?> region;
  final Value<String?> hskLevel;
  const WordsCompanion({
    this.rank = const Value.absent(),
    this.word = const Value.absent(),
    this.freq = const Value.absent(),
    this.cumPct = const Value.absent(),
    this.region = const Value.absent(),
    this.hskLevel = const Value.absent(),
  });
  WordsCompanion.insert({
    this.rank = const Value.absent(),
    required String word,
    this.freq = const Value.absent(),
    this.cumPct = const Value.absent(),
    this.region = const Value.absent(),
    this.hskLevel = const Value.absent(),
  }) : word = Value(word);
  static Insertable<WordRow> custom({
    Expression<int>? rank,
    Expression<String>? word,
    Expression<double>? freq,
    Expression<double>? cumPct,
    Expression<String>? region,
    Expression<String>? hskLevel,
  }) {
    return RawValuesInsertable({
      if (rank != null) 'rank': rank,
      if (word != null) 'word': word,
      if (freq != null) 'freq': freq,
      if (cumPct != null) 'cum_pct': cumPct,
      if (region != null) 'region': region,
      if (hskLevel != null) 'hsk_level': hskLevel,
    });
  }

  WordsCompanion copyWith({
    Value<int>? rank,
    Value<String>? word,
    Value<double?>? freq,
    Value<double?>? cumPct,
    Value<String?>? region,
    Value<String?>? hskLevel,
  }) {
    return WordsCompanion(
      rank: rank ?? this.rank,
      word: word ?? this.word,
      freq: freq ?? this.freq,
      cumPct: cumPct ?? this.cumPct,
      region: region ?? this.region,
      hskLevel: hskLevel ?? this.hskLevel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (freq.present) {
      map['freq'] = Variable<double>(freq.value);
    }
    if (cumPct.present) {
      map['cum_pct'] = Variable<double>(cumPct.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (hskLevel.present) {
      map['hsk_level'] = Variable<String>(hskLevel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('rank: $rank, ')
          ..write('word: $word, ')
          ..write('freq: $freq, ')
          ..write('cumPct: $cumPct, ')
          ..write('region: $region, ')
          ..write('hskLevel: $hskLevel')
          ..write(')'))
        .toString();
  }
}

class $AnnotationsTable extends Annotations
    with TableInfo<$AnnotationsTable, AnnotationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _turnIdMeta = const VerificationMeta('turnId');
  @override
  late final GeneratedColumn<int> turnId = GeneratedColumn<int>(
    'turn_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES turns (id)',
    ),
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shapeMeta = const VerificationMeta('shape');
  @override
  late final GeneratedColumn<String> shape = GeneratedColumn<String>(
    'shape',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('highlight'),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('yellow'),
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<int> start = GeneratedColumn<int>(
    'start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<int> end = GeneratedColumn<int>(
    'end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    turnId,
    target,
    kind,
    shape,
    color,
    comment,
    start,
    end,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnnotationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_turnIdMeta);
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('shape')) {
      context.handle(
        _shapeMeta,
        shape.isAcceptableOrUnknown(data['shape']!, _shapeMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnnotationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnotationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}turn_id'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      shape: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shape'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start'],
      ),
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end'],
      ),
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }
}

class AnnotationRow extends DataClass implements Insertable<AnnotationRow> {
  final int id;
  final int turnId;
  final String target;
  final String kind;
  final String shape;
  final String color;
  final String? comment;
  final int? start;
  final int? end;
  const AnnotationRow({
    required this.id,
    required this.turnId,
    required this.target,
    required this.kind,
    required this.shape,
    required this.color,
    this.comment,
    this.start,
    this.end,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['turn_id'] = Variable<int>(turnId);
    map['target'] = Variable<String>(target);
    map['kind'] = Variable<String>(kind);
    map['shape'] = Variable<String>(shape);
    map['color'] = Variable<String>(color);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    if (!nullToAbsent || start != null) {
      map['start'] = Variable<int>(start);
    }
    if (!nullToAbsent || end != null) {
      map['end'] = Variable<int>(end);
    }
    return map;
  }

  AnnotationsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationsCompanion(
      id: Value(id),
      turnId: Value(turnId),
      target: Value(target),
      kind: Value(kind),
      shape: Value(shape),
      color: Value(color),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      start: start == null && nullToAbsent
          ? const Value.absent()
          : Value(start),
      end: end == null && nullToAbsent ? const Value.absent() : Value(end),
    );
  }

  factory AnnotationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnotationRow(
      id: serializer.fromJson<int>(json['id']),
      turnId: serializer.fromJson<int>(json['turnId']),
      target: serializer.fromJson<String>(json['target']),
      kind: serializer.fromJson<String>(json['kind']),
      shape: serializer.fromJson<String>(json['shape']),
      color: serializer.fromJson<String>(json['color']),
      comment: serializer.fromJson<String?>(json['comment']),
      start: serializer.fromJson<int?>(json['start']),
      end: serializer.fromJson<int?>(json['end']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'turnId': serializer.toJson<int>(turnId),
      'target': serializer.toJson<String>(target),
      'kind': serializer.toJson<String>(kind),
      'shape': serializer.toJson<String>(shape),
      'color': serializer.toJson<String>(color),
      'comment': serializer.toJson<String?>(comment),
      'start': serializer.toJson<int?>(start),
      'end': serializer.toJson<int?>(end),
    };
  }

  AnnotationRow copyWith({
    int? id,
    int? turnId,
    String? target,
    String? kind,
    String? shape,
    String? color,
    Value<String?> comment = const Value.absent(),
    Value<int?> start = const Value.absent(),
    Value<int?> end = const Value.absent(),
  }) => AnnotationRow(
    id: id ?? this.id,
    turnId: turnId ?? this.turnId,
    target: target ?? this.target,
    kind: kind ?? this.kind,
    shape: shape ?? this.shape,
    color: color ?? this.color,
    comment: comment.present ? comment.value : this.comment,
    start: start.present ? start.value : this.start,
    end: end.present ? end.value : this.end,
  );
  AnnotationRow copyWithCompanion(AnnotationsCompanion data) {
    return AnnotationRow(
      id: data.id.present ? data.id.value : this.id,
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      target: data.target.present ? data.target.value : this.target,
      kind: data.kind.present ? data.kind.value : this.kind,
      shape: data.shape.present ? data.shape.value : this.shape,
      color: data.color.present ? data.color.value : this.color,
      comment: data.comment.present ? data.comment.value : this.comment,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationRow(')
          ..write('id: $id, ')
          ..write('turnId: $turnId, ')
          ..write('target: $target, ')
          ..write('kind: $kind, ')
          ..write('shape: $shape, ')
          ..write('color: $color, ')
          ..write('comment: $comment, ')
          ..write('start: $start, ')
          ..write('end: $end')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, turnId, target, kind, shape, color, comment, start, end);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnotationRow &&
          other.id == this.id &&
          other.turnId == this.turnId &&
          other.target == this.target &&
          other.kind == this.kind &&
          other.shape == this.shape &&
          other.color == this.color &&
          other.comment == this.comment &&
          other.start == this.start &&
          other.end == this.end);
}

class AnnotationsCompanion extends UpdateCompanion<AnnotationRow> {
  final Value<int> id;
  final Value<int> turnId;
  final Value<String> target;
  final Value<String> kind;
  final Value<String> shape;
  final Value<String> color;
  final Value<String?> comment;
  final Value<int?> start;
  final Value<int?> end;
  const AnnotationsCompanion({
    this.id = const Value.absent(),
    this.turnId = const Value.absent(),
    this.target = const Value.absent(),
    this.kind = const Value.absent(),
    this.shape = const Value.absent(),
    this.color = const Value.absent(),
    this.comment = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
  });
  AnnotationsCompanion.insert({
    this.id = const Value.absent(),
    required int turnId,
    required String target,
    required String kind,
    this.shape = const Value.absent(),
    this.color = const Value.absent(),
    this.comment = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
  }) : turnId = Value(turnId),
       target = Value(target),
       kind = Value(kind);
  static Insertable<AnnotationRow> custom({
    Expression<int>? id,
    Expression<int>? turnId,
    Expression<String>? target,
    Expression<String>? kind,
    Expression<String>? shape,
    Expression<String>? color,
    Expression<String>? comment,
    Expression<int>? start,
    Expression<int>? end,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (turnId != null) 'turn_id': turnId,
      if (target != null) 'target': target,
      if (kind != null) 'kind': kind,
      if (shape != null) 'shape': shape,
      if (color != null) 'color': color,
      if (comment != null) 'comment': comment,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
    });
  }

  AnnotationsCompanion copyWith({
    Value<int>? id,
    Value<int>? turnId,
    Value<String>? target,
    Value<String>? kind,
    Value<String>? shape,
    Value<String>? color,
    Value<String?>? comment,
    Value<int?>? start,
    Value<int?>? end,
  }) {
    return AnnotationsCompanion(
      id: id ?? this.id,
      turnId: turnId ?? this.turnId,
      target: target ?? this.target,
      kind: kind ?? this.kind,
      shape: shape ?? this.shape,
      color: color ?? this.color,
      comment: comment ?? this.comment,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (turnId.present) {
      map['turn_id'] = Variable<int>(turnId.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(target.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (shape.present) {
      map['shape'] = Variable<String>(shape.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (start.present) {
      map['start'] = Variable<int>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<int>(end.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('turnId: $turnId, ')
          ..write('target: $target, ')
          ..write('kind: $kind, ')
          ..write('shape: $shape, ')
          ..write('color: $color, ')
          ..write('comment: $comment, ')
          ..write('start: $start, ')
          ..write('end: $end')
          ..write(')'))
        .toString();
  }
}

class $UserProgressTable extends UserProgress
    with TableInfo<$UserProgressTable, UserProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _turnIdMeta = const VerificationMeta('turnId');
  @override
  late final GeneratedColumn<int> turnId = GeneratedColumn<int>(
    'turn_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES turns (id)',
    ),
  );
  static const VerificationMeta _learnedMeta = const VerificationMeta(
    'learned',
  );
  @override
  late final GeneratedColumn<bool> learned = GeneratedColumn<bool>(
    'learned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("learned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastReviewedMeta = const VerificationMeta(
    'lastReviewed',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewed = GeneratedColumn<DateTime>(
    'last_reviewed',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    turnId,
    learned,
    favorite,
    lastReviewed,
    reviewCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    }
    if (data.containsKey('learned')) {
      context.handle(
        _learnedMeta,
        learned.isAcceptableOrUnknown(data['learned']!, _learnedMeta),
      );
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('last_reviewed')) {
      context.handle(
        _lastReviewedMeta,
        lastReviewed.isAcceptableOrUnknown(
          data['last_reviewed']!,
          _lastReviewedMeta,
        ),
      );
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {turnId};
  @override
  UserProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProgressRow(
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}turn_id'],
      )!,
      learned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}learned'],
      )!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      lastReviewed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed'],
      ),
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
    );
  }

  @override
  $UserProgressTable createAlias(String alias) {
    return $UserProgressTable(attachedDatabase, alias);
  }
}

class UserProgressRow extends DataClass implements Insertable<UserProgressRow> {
  final int turnId;
  final bool learned;
  final bool favorite;
  final DateTime? lastReviewed;
  final int reviewCount;
  const UserProgressRow({
    required this.turnId,
    required this.learned,
    required this.favorite,
    this.lastReviewed,
    required this.reviewCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['turn_id'] = Variable<int>(turnId);
    map['learned'] = Variable<bool>(learned);
    map['favorite'] = Variable<bool>(favorite);
    if (!nullToAbsent || lastReviewed != null) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed);
    }
    map['review_count'] = Variable<int>(reviewCount);
    return map;
  }

  UserProgressCompanion toCompanion(bool nullToAbsent) {
    return UserProgressCompanion(
      turnId: Value(turnId),
      learned: Value(learned),
      favorite: Value(favorite),
      lastReviewed: lastReviewed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewed),
      reviewCount: Value(reviewCount),
    );
  }

  factory UserProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProgressRow(
      turnId: serializer.fromJson<int>(json['turnId']),
      learned: serializer.fromJson<bool>(json['learned']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      lastReviewed: serializer.fromJson<DateTime?>(json['lastReviewed']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'turnId': serializer.toJson<int>(turnId),
      'learned': serializer.toJson<bool>(learned),
      'favorite': serializer.toJson<bool>(favorite),
      'lastReviewed': serializer.toJson<DateTime?>(lastReviewed),
      'reviewCount': serializer.toJson<int>(reviewCount),
    };
  }

  UserProgressRow copyWith({
    int? turnId,
    bool? learned,
    bool? favorite,
    Value<DateTime?> lastReviewed = const Value.absent(),
    int? reviewCount,
  }) => UserProgressRow(
    turnId: turnId ?? this.turnId,
    learned: learned ?? this.learned,
    favorite: favorite ?? this.favorite,
    lastReviewed: lastReviewed.present ? lastReviewed.value : this.lastReviewed,
    reviewCount: reviewCount ?? this.reviewCount,
  );
  UserProgressRow copyWithCompanion(UserProgressCompanion data) {
    return UserProgressRow(
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      learned: data.learned.present ? data.learned.value : this.learned,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      lastReviewed: data.lastReviewed.present
          ? data.lastReviewed.value
          : this.lastReviewed,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProgressRow(')
          ..write('turnId: $turnId, ')
          ..write('learned: $learned, ')
          ..write('favorite: $favorite, ')
          ..write('lastReviewed: $lastReviewed, ')
          ..write('reviewCount: $reviewCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(turnId, learned, favorite, lastReviewed, reviewCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProgressRow &&
          other.turnId == this.turnId &&
          other.learned == this.learned &&
          other.favorite == this.favorite &&
          other.lastReviewed == this.lastReviewed &&
          other.reviewCount == this.reviewCount);
}

class UserProgressCompanion extends UpdateCompanion<UserProgressRow> {
  final Value<int> turnId;
  final Value<bool> learned;
  final Value<bool> favorite;
  final Value<DateTime?> lastReviewed;
  final Value<int> reviewCount;
  const UserProgressCompanion({
    this.turnId = const Value.absent(),
    this.learned = const Value.absent(),
    this.favorite = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.reviewCount = const Value.absent(),
  });
  UserProgressCompanion.insert({
    this.turnId = const Value.absent(),
    this.learned = const Value.absent(),
    this.favorite = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.reviewCount = const Value.absent(),
  });
  static Insertable<UserProgressRow> custom({
    Expression<int>? turnId,
    Expression<bool>? learned,
    Expression<bool>? favorite,
    Expression<DateTime>? lastReviewed,
    Expression<int>? reviewCount,
  }) {
    return RawValuesInsertable({
      if (turnId != null) 'turn_id': turnId,
      if (learned != null) 'learned': learned,
      if (favorite != null) 'favorite': favorite,
      if (lastReviewed != null) 'last_reviewed': lastReviewed,
      if (reviewCount != null) 'review_count': reviewCount,
    });
  }

  UserProgressCompanion copyWith({
    Value<int>? turnId,
    Value<bool>? learned,
    Value<bool>? favorite,
    Value<DateTime?>? lastReviewed,
    Value<int>? reviewCount,
  }) {
    return UserProgressCompanion(
      turnId: turnId ?? this.turnId,
      learned: learned ?? this.learned,
      favorite: favorite ?? this.favorite,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (turnId.present) {
      map['turn_id'] = Variable<int>(turnId.value);
    }
    if (learned.present) {
      map['learned'] = Variable<bool>(learned.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (lastReviewed.present) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProgressCompanion(')
          ..write('turnId: $turnId, ')
          ..write('learned: $learned, ')
          ..write('favorite: $favorite, ')
          ..write('lastReviewed: $lastReviewed, ')
          ..write('reviewCount: $reviewCount')
          ..write(')'))
        .toString();
  }
}

class $HanziProgressTable extends HanziProgress
    with TableInfo<$HanziProgressTable, HanziProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HanziProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _charMeta = const VerificationMeta('char');
  @override
  late final GeneratedColumn<String> char = GeneratedColumn<String>(
    'char',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES hanzi (char)',
    ),
  );
  static const VerificationMeta _knownMeta = const VerificationMeta('known');
  @override
  late final GeneratedColumn<bool> known = GeneratedColumn<bool>(
    'known',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("known" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _exposureCountMeta = const VerificationMeta(
    'exposureCount',
  );
  @override
  late final GeneratedColumn<int> exposureCount = GeneratedColumn<int>(
    'exposure_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReviewedMeta = const VerificationMeta(
    'lastReviewed',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewed = GeneratedColumn<DateTime>(
    'last_reviewed',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    char,
    known,
    exposureCount,
    lastReviewed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hanzi_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<HanziProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('char')) {
      context.handle(
        _charMeta,
        char.isAcceptableOrUnknown(data['char']!, _charMeta),
      );
    } else if (isInserting) {
      context.missing(_charMeta);
    }
    if (data.containsKey('known')) {
      context.handle(
        _knownMeta,
        known.isAcceptableOrUnknown(data['known']!, _knownMeta),
      );
    }
    if (data.containsKey('exposure_count')) {
      context.handle(
        _exposureCountMeta,
        exposureCount.isAcceptableOrUnknown(
          data['exposure_count']!,
          _exposureCountMeta,
        ),
      );
    }
    if (data.containsKey('last_reviewed')) {
      context.handle(
        _lastReviewedMeta,
        lastReviewed.isAcceptableOrUnknown(
          data['last_reviewed']!,
          _lastReviewedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {char};
  @override
  HanziProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HanziProgressRow(
      char: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}char'],
      )!,
      known: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}known'],
      )!,
      exposureCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exposure_count'],
      )!,
      lastReviewed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed'],
      ),
    );
  }

  @override
  $HanziProgressTable createAlias(String alias) {
    return $HanziProgressTable(attachedDatabase, alias);
  }
}

class HanziProgressRow extends DataClass
    implements Insertable<HanziProgressRow> {
  final String char;
  final bool known;
  final int exposureCount;
  final DateTime? lastReviewed;
  const HanziProgressRow({
    required this.char,
    required this.known,
    required this.exposureCount,
    this.lastReviewed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['char'] = Variable<String>(char);
    map['known'] = Variable<bool>(known);
    map['exposure_count'] = Variable<int>(exposureCount);
    if (!nullToAbsent || lastReviewed != null) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed);
    }
    return map;
  }

  HanziProgressCompanion toCompanion(bool nullToAbsent) {
    return HanziProgressCompanion(
      char: Value(char),
      known: Value(known),
      exposureCount: Value(exposureCount),
      lastReviewed: lastReviewed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewed),
    );
  }

  factory HanziProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HanziProgressRow(
      char: serializer.fromJson<String>(json['char']),
      known: serializer.fromJson<bool>(json['known']),
      exposureCount: serializer.fromJson<int>(json['exposureCount']),
      lastReviewed: serializer.fromJson<DateTime?>(json['lastReviewed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'char': serializer.toJson<String>(char),
      'known': serializer.toJson<bool>(known),
      'exposureCount': serializer.toJson<int>(exposureCount),
      'lastReviewed': serializer.toJson<DateTime?>(lastReviewed),
    };
  }

  HanziProgressRow copyWith({
    String? char,
    bool? known,
    int? exposureCount,
    Value<DateTime?> lastReviewed = const Value.absent(),
  }) => HanziProgressRow(
    char: char ?? this.char,
    known: known ?? this.known,
    exposureCount: exposureCount ?? this.exposureCount,
    lastReviewed: lastReviewed.present ? lastReviewed.value : this.lastReviewed,
  );
  HanziProgressRow copyWithCompanion(HanziProgressCompanion data) {
    return HanziProgressRow(
      char: data.char.present ? data.char.value : this.char,
      known: data.known.present ? data.known.value : this.known,
      exposureCount: data.exposureCount.present
          ? data.exposureCount.value
          : this.exposureCount,
      lastReviewed: data.lastReviewed.present
          ? data.lastReviewed.value
          : this.lastReviewed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HanziProgressRow(')
          ..write('char: $char, ')
          ..write('known: $known, ')
          ..write('exposureCount: $exposureCount, ')
          ..write('lastReviewed: $lastReviewed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(char, known, exposureCount, lastReviewed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HanziProgressRow &&
          other.char == this.char &&
          other.known == this.known &&
          other.exposureCount == this.exposureCount &&
          other.lastReviewed == this.lastReviewed);
}

class HanziProgressCompanion extends UpdateCompanion<HanziProgressRow> {
  final Value<String> char;
  final Value<bool> known;
  final Value<int> exposureCount;
  final Value<DateTime?> lastReviewed;
  final Value<int> rowid;
  const HanziProgressCompanion({
    this.char = const Value.absent(),
    this.known = const Value.absent(),
    this.exposureCount = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HanziProgressCompanion.insert({
    required String char,
    this.known = const Value.absent(),
    this.exposureCount = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : char = Value(char);
  static Insertable<HanziProgressRow> custom({
    Expression<String>? char,
    Expression<bool>? known,
    Expression<int>? exposureCount,
    Expression<DateTime>? lastReviewed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (char != null) 'char': char,
      if (known != null) 'known': known,
      if (exposureCount != null) 'exposure_count': exposureCount,
      if (lastReviewed != null) 'last_reviewed': lastReviewed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HanziProgressCompanion copyWith({
    Value<String>? char,
    Value<bool>? known,
    Value<int>? exposureCount,
    Value<DateTime?>? lastReviewed,
    Value<int>? rowid,
  }) {
    return HanziProgressCompanion(
      char: char ?? this.char,
      known: known ?? this.known,
      exposureCount: exposureCount ?? this.exposureCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (char.present) {
      map['char'] = Variable<String>(char.value);
    }
    if (known.present) {
      map['known'] = Variable<bool>(known.value);
    }
    if (exposureCount.present) {
      map['exposure_count'] = Variable<int>(exposureCount.value);
    }
    if (lastReviewed.present) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HanziProgressCompanion(')
          ..write('char: $char, ')
          ..write('known: $known, ')
          ..write('exposureCount: $exposureCount, ')
          ..write('lastReviewed: $lastReviewed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserMemosTable extends UserMemos
    with TableInfo<$UserMemosTable, UserMemoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserMemosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, context, body, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_memos';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserMemoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    } else if (isInserting) {
      context.missing(_contextMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserMemoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserMemoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserMemosTable createAlias(String alias) {
    return $UserMemosTable(attachedDatabase, alias);
  }
}

class UserMemoRow extends DataClass implements Insertable<UserMemoRow> {
  final int id;
  final String context;
  final String body;
  final DateTime createdAt;
  const UserMemoRow({
    required this.id,
    required this.context,
    required this.body,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['context'] = Variable<String>(context);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserMemosCompanion toCompanion(bool nullToAbsent) {
    return UserMemosCompanion(
      id: Value(id),
      context: Value(context),
      body: Value(body),
      createdAt: Value(createdAt),
    );
  }

  factory UserMemoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserMemoRow(
      id: serializer.fromJson<int>(json['id']),
      context: serializer.fromJson<String>(json['context']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'context': serializer.toJson<String>(context),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserMemoRow copyWith({
    int? id,
    String? context,
    String? body,
    DateTime? createdAt,
  }) => UserMemoRow(
    id: id ?? this.id,
    context: context ?? this.context,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
  );
  UserMemoRow copyWithCompanion(UserMemosCompanion data) {
    return UserMemoRow(
      id: data.id.present ? data.id.value : this.id,
      context: data.context.present ? data.context.value : this.context,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserMemoRow(')
          ..write('id: $id, ')
          ..write('context: $context, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, context, body, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserMemoRow &&
          other.id == this.id &&
          other.context == this.context &&
          other.body == this.body &&
          other.createdAt == this.createdAt);
}

class UserMemosCompanion extends UpdateCompanion<UserMemoRow> {
  final Value<int> id;
  final Value<String> context;
  final Value<String> body;
  final Value<DateTime> createdAt;
  const UserMemosCompanion({
    this.id = const Value.absent(),
    this.context = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserMemosCompanion.insert({
    this.id = const Value.absent(),
    required String context,
    required String body,
    this.createdAt = const Value.absent(),
  }) : context = Value(context),
       body = Value(body);
  static Insertable<UserMemoRow> custom({
    Expression<int>? id,
    Expression<String>? context,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (context != null) 'context': context,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserMemosCompanion copyWith({
    Value<int>? id,
    Value<String>? context,
    Value<String>? body,
    Value<DateTime>? createdAt,
  }) {
    return UserMemosCompanion(
      id: id ?? this.id,
      context: context ?? this.context,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserMemosCompanion(')
          ..write('id: $id, ')
          ..write('context: $context, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TurnsTable turns = $TurnsTable(this);
  late final $HanziTable hanzi = $HanziTable(this);
  late final $PhoneticRootsTable phoneticRoots = $PhoneticRootsTable(this);
  late final $WordsTable words = $WordsTable(this);
  late final $AnnotationsTable annotations = $AnnotationsTable(this);
  late final $UserProgressTable userProgress = $UserProgressTable(this);
  late final $HanziProgressTable hanziProgress = $HanziProgressTable(this);
  late final $UserMemosTable userMemos = $UserMemosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    turns,
    hanzi,
    phoneticRoots,
    words,
    annotations,
    userProgress,
    hanziProgress,
    userMemos,
  ];
}

typedef $$TurnsTableCreateCompanionBuilder =
    TurnsCompanion Function({
      Value<int> id,
      required String level,
      Value<String> dialect,
      Value<String?> episodeId,
      required int num,
      required String speaker,
      required String zh,
      Value<String?> pinyin,
      Value<String?> ko,
      Value<String?> tones,
      Value<String?> note,
      Value<String?> tagsJson,
    });
typedef $$TurnsTableUpdateCompanionBuilder =
    TurnsCompanion Function({
      Value<int> id,
      Value<String> level,
      Value<String> dialect,
      Value<String?> episodeId,
      Value<int> num,
      Value<String> speaker,
      Value<String> zh,
      Value<String?> pinyin,
      Value<String?> ko,
      Value<String?> tones,
      Value<String?> note,
      Value<String?> tagsJson,
    });

final class $$TurnsTableReferences
    extends BaseReferences<_$AppDatabase, $TurnsTable, TurnRow> {
  $$TurnsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AnnotationsTable, List<AnnotationRow>>
  _annotationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.annotations,
    aliasName: $_aliasNameGenerator(db.turns.id, db.annotations.turnId),
  );

  $$AnnotationsTableProcessedTableManager get annotationsRefs {
    final manager = $$AnnotationsTableTableManager(
      $_db,
      $_db.annotations,
    ).filter((f) => f.turnId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_annotationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserProgressTable, List<UserProgressRow>>
  _userProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userProgress,
    aliasName: $_aliasNameGenerator(db.turns.id, db.userProgress.turnId),
  );

  $$UserProgressTableProcessedTableManager get userProgressRefs {
    final manager = $$UserProgressTableTableManager(
      $_db,
      $_db.userProgress,
    ).filter((f) => f.turnId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userProgressRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TurnsTableFilterComposer extends Composer<_$AppDatabase, $TurnsTable> {
  $$TurnsTableFilterComposer({
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

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dialect => $composableBuilder(
    column: $table.dialect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get num => $composableBuilder(
    column: $table.num,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get speaker => $composableBuilder(
    column: $table.speaker,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zh => $composableBuilder(
    column: $table.zh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinyin => $composableBuilder(
    column: $table.pinyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ko => $composableBuilder(
    column: $table.ko,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tones => $composableBuilder(
    column: $table.tones,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> annotationsRefs(
    Expression<bool> Function($$AnnotationsTableFilterComposer f) f,
  ) {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userProgressRefs(
    Expression<bool> Function($$UserProgressTableFilterComposer f) f,
  ) {
    final $$UserProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userProgress,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserProgressTableFilterComposer(
            $db: $db,
            $table: $db.userProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TurnsTableOrderingComposer
    extends Composer<_$AppDatabase, $TurnsTable> {
  $$TurnsTableOrderingComposer({
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

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dialect => $composableBuilder(
    column: $table.dialect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get num => $composableBuilder(
    column: $table.num,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get speaker => $composableBuilder(
    column: $table.speaker,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zh => $composableBuilder(
    column: $table.zh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinyin => $composableBuilder(
    column: $table.pinyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ko => $composableBuilder(
    column: $table.ko,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tones => $composableBuilder(
    column: $table.tones,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TurnsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TurnsTable> {
  $$TurnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get dialect =>
      $composableBuilder(column: $table.dialect, builder: (column) => column);

  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<int> get num =>
      $composableBuilder(column: $table.num, builder: (column) => column);

  GeneratedColumn<String> get speaker =>
      $composableBuilder(column: $table.speaker, builder: (column) => column);

  GeneratedColumn<String> get zh =>
      $composableBuilder(column: $table.zh, builder: (column) => column);

  GeneratedColumn<String> get pinyin =>
      $composableBuilder(column: $table.pinyin, builder: (column) => column);

  GeneratedColumn<String> get ko =>
      $composableBuilder(column: $table.ko, builder: (column) => column);

  GeneratedColumn<String> get tones =>
      $composableBuilder(column: $table.tones, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  Expression<T> annotationsRefs<T extends Object>(
    Expression<T> Function($$AnnotationsTableAnnotationComposer a) f,
  ) {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userProgressRefs<T extends Object>(
    Expression<T> Function($$UserProgressTableAnnotationComposer a) f,
  ) {
    final $$UserProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userProgress,
      getReferencedColumn: (t) => t.turnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.userProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TurnsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TurnsTable,
          TurnRow,
          $$TurnsTableFilterComposer,
          $$TurnsTableOrderingComposer,
          $$TurnsTableAnnotationComposer,
          $$TurnsTableCreateCompanionBuilder,
          $$TurnsTableUpdateCompanionBuilder,
          (TurnRow, $$TurnsTableReferences),
          TurnRow,
          PrefetchHooks Function({bool annotationsRefs, bool userProgressRefs})
        > {
  $$TurnsTableTableManager(_$AppDatabase db, $TurnsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TurnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TurnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TurnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String> dialect = const Value.absent(),
                Value<String?> episodeId = const Value.absent(),
                Value<int> num = const Value.absent(),
                Value<String> speaker = const Value.absent(),
                Value<String> zh = const Value.absent(),
                Value<String?> pinyin = const Value.absent(),
                Value<String?> ko = const Value.absent(),
                Value<String?> tones = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
              }) => TurnsCompanion(
                id: id,
                level: level,
                dialect: dialect,
                episodeId: episodeId,
                num: num,
                speaker: speaker,
                zh: zh,
                pinyin: pinyin,
                ko: ko,
                tones: tones,
                note: note,
                tagsJson: tagsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String level,
                Value<String> dialect = const Value.absent(),
                Value<String?> episodeId = const Value.absent(),
                required int num,
                required String speaker,
                required String zh,
                Value<String?> pinyin = const Value.absent(),
                Value<String?> ko = const Value.absent(),
                Value<String?> tones = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
              }) => TurnsCompanion.insert(
                id: id,
                level: level,
                dialect: dialect,
                episodeId: episodeId,
                num: num,
                speaker: speaker,
                zh: zh,
                pinyin: pinyin,
                ko: ko,
                tones: tones,
                note: note,
                tagsJson: tagsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TurnsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({annotationsRefs = false, userProgressRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (annotationsRefs) db.annotations,
                    if (userProgressRefs) db.userProgress,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (annotationsRefs)
                        await $_getPrefetchedData<
                          TurnRow,
                          $TurnsTable,
                          AnnotationRow
                        >(
                          currentTable: table,
                          referencedTable: $$TurnsTableReferences
                              ._annotationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TurnsTableReferences(
                                db,
                                table,
                                p0,
                              ).annotationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.turnId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userProgressRefs)
                        await $_getPrefetchedData<
                          TurnRow,
                          $TurnsTable,
                          UserProgressRow
                        >(
                          currentTable: table,
                          referencedTable: $$TurnsTableReferences
                              ._userProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TurnsTableReferences(
                                db,
                                table,
                                p0,
                              ).userProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.turnId == item.id,
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

typedef $$TurnsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TurnsTable,
      TurnRow,
      $$TurnsTableFilterComposer,
      $$TurnsTableOrderingComposer,
      $$TurnsTableAnnotationComposer,
      $$TurnsTableCreateCompanionBuilder,
      $$TurnsTableUpdateCompanionBuilder,
      (TurnRow, $$TurnsTableReferences),
      TurnRow,
      PrefetchHooks Function({bool annotationsRefs, bool userProgressRefs})
    >;
typedef $$HanziTableCreateCompanionBuilder =
    HanziCompanion Function({
      required String char,
      Value<int?> rank,
      Value<int?> freq,
      Value<String?> hskLevel,
      Value<int?> phase,
      Value<String?> pinyin,
      Value<int?> tone,
      Value<String?> meaningKo,
      Value<String?> koHanja,
      Value<int> rowid,
    });
typedef $$HanziTableUpdateCompanionBuilder =
    HanziCompanion Function({
      Value<String> char,
      Value<int?> rank,
      Value<int?> freq,
      Value<String?> hskLevel,
      Value<int?> phase,
      Value<String?> pinyin,
      Value<int?> tone,
      Value<String?> meaningKo,
      Value<String?> koHanja,
      Value<int> rowid,
    });

final class $$HanziTableReferences
    extends BaseReferences<_$AppDatabase, $HanziTable, HanziRow> {
  $$HanziTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HanziProgressTable, List<HanziProgressRow>>
  _hanziProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.hanziProgress,
    aliasName: $_aliasNameGenerator(db.hanzi.char, db.hanziProgress.char),
  );

  $$HanziProgressTableProcessedTableManager get hanziProgressRefs {
    final manager = $$HanziProgressTableTableManager(
      $_db,
      $_db.hanziProgress,
    ).filter((f) => f.char.char.sqlEquals($_itemColumn<String>('char')!));

    final cache = $_typedResult.readTableOrNull(_hanziProgressRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HanziTableFilterComposer extends Composer<_$AppDatabase, $HanziTable> {
  $$HanziTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get char => $composableBuilder(
    column: $table.char,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get freq => $composableBuilder(
    column: $table.freq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hskLevel => $composableBuilder(
    column: $table.hskLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinyin => $composableBuilder(
    column: $table.pinyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tone => $composableBuilder(
    column: $table.tone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaningKo => $composableBuilder(
    column: $table.meaningKo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get koHanja => $composableBuilder(
    column: $table.koHanja,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> hanziProgressRefs(
    Expression<bool> Function($$HanziProgressTableFilterComposer f) f,
  ) {
    final $$HanziProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.char,
      referencedTable: $db.hanziProgress,
      getReferencedColumn: (t) => t.char,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HanziProgressTableFilterComposer(
            $db: $db,
            $table: $db.hanziProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HanziTableOrderingComposer
    extends Composer<_$AppDatabase, $HanziTable> {
  $$HanziTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get char => $composableBuilder(
    column: $table.char,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get freq => $composableBuilder(
    column: $table.freq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hskLevel => $composableBuilder(
    column: $table.hskLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinyin => $composableBuilder(
    column: $table.pinyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tone => $composableBuilder(
    column: $table.tone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaningKo => $composableBuilder(
    column: $table.meaningKo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get koHanja => $composableBuilder(
    column: $table.koHanja,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HanziTableAnnotationComposer
    extends Composer<_$AppDatabase, $HanziTable> {
  $$HanziTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get char =>
      $composableBuilder(column: $table.char, builder: (column) => column);

  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<int> get freq =>
      $composableBuilder(column: $table.freq, builder: (column) => column);

  GeneratedColumn<String> get hskLevel =>
      $composableBuilder(column: $table.hskLevel, builder: (column) => column);

  GeneratedColumn<int> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<String> get pinyin =>
      $composableBuilder(column: $table.pinyin, builder: (column) => column);

  GeneratedColumn<int> get tone =>
      $composableBuilder(column: $table.tone, builder: (column) => column);

  GeneratedColumn<String> get meaningKo =>
      $composableBuilder(column: $table.meaningKo, builder: (column) => column);

  GeneratedColumn<String> get koHanja =>
      $composableBuilder(column: $table.koHanja, builder: (column) => column);

  Expression<T> hanziProgressRefs<T extends Object>(
    Expression<T> Function($$HanziProgressTableAnnotationComposer a) f,
  ) {
    final $$HanziProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.char,
      referencedTable: $db.hanziProgress,
      getReferencedColumn: (t) => t.char,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HanziProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.hanziProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HanziTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HanziTable,
          HanziRow,
          $$HanziTableFilterComposer,
          $$HanziTableOrderingComposer,
          $$HanziTableAnnotationComposer,
          $$HanziTableCreateCompanionBuilder,
          $$HanziTableUpdateCompanionBuilder,
          (HanziRow, $$HanziTableReferences),
          HanziRow,
          PrefetchHooks Function({bool hanziProgressRefs})
        > {
  $$HanziTableTableManager(_$AppDatabase db, $HanziTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HanziTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HanziTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HanziTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> char = const Value.absent(),
                Value<int?> rank = const Value.absent(),
                Value<int?> freq = const Value.absent(),
                Value<String?> hskLevel = const Value.absent(),
                Value<int?> phase = const Value.absent(),
                Value<String?> pinyin = const Value.absent(),
                Value<int?> tone = const Value.absent(),
                Value<String?> meaningKo = const Value.absent(),
                Value<String?> koHanja = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HanziCompanion(
                char: char,
                rank: rank,
                freq: freq,
                hskLevel: hskLevel,
                phase: phase,
                pinyin: pinyin,
                tone: tone,
                meaningKo: meaningKo,
                koHanja: koHanja,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String char,
                Value<int?> rank = const Value.absent(),
                Value<int?> freq = const Value.absent(),
                Value<String?> hskLevel = const Value.absent(),
                Value<int?> phase = const Value.absent(),
                Value<String?> pinyin = const Value.absent(),
                Value<int?> tone = const Value.absent(),
                Value<String?> meaningKo = const Value.absent(),
                Value<String?> koHanja = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HanziCompanion.insert(
                char: char,
                rank: rank,
                freq: freq,
                hskLevel: hskLevel,
                phase: phase,
                pinyin: pinyin,
                tone: tone,
                meaningKo: meaningKo,
                koHanja: koHanja,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$HanziTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({hanziProgressRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (hanziProgressRefs) db.hanziProgress,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (hanziProgressRefs)
                    await $_getPrefetchedData<
                      HanziRow,
                      $HanziTable,
                      HanziProgressRow
                    >(
                      currentTable: table,
                      referencedTable: $$HanziTableReferences
                          ._hanziProgressRefsTable(db),
                      managerFromTypedResult: (p0) => $$HanziTableReferences(
                        db,
                        table,
                        p0,
                      ).hanziProgressRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.char == item.char),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HanziTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HanziTable,
      HanziRow,
      $$HanziTableFilterComposer,
      $$HanziTableOrderingComposer,
      $$HanziTableAnnotationComposer,
      $$HanziTableCreateCompanionBuilder,
      $$HanziTableUpdateCompanionBuilder,
      (HanziRow, $$HanziTableReferences),
      HanziRow,
      PrefetchHooks Function({bool hanziProgressRefs})
    >;
typedef $$PhoneticRootsTableCreateCompanionBuilder =
    PhoneticRootsCompanion Function({
      Value<int> id,
      required String root,
      Value<String?> pinyin,
      Value<String?> koHanja,
      Value<int> clusterCount,
      Value<String?> mnemonic,
    });
typedef $$PhoneticRootsTableUpdateCompanionBuilder =
    PhoneticRootsCompanion Function({
      Value<int> id,
      Value<String> root,
      Value<String?> pinyin,
      Value<String?> koHanja,
      Value<int> clusterCount,
      Value<String?> mnemonic,
    });

class $$PhoneticRootsTableFilterComposer
    extends Composer<_$AppDatabase, $PhoneticRootsTable> {
  $$PhoneticRootsTableFilterComposer({
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

  ColumnFilters<String> get root => $composableBuilder(
    column: $table.root,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinyin => $composableBuilder(
    column: $table.pinyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get koHanja => $composableBuilder(
    column: $table.koHanja,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clusterCount => $composableBuilder(
    column: $table.clusterCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mnemonic => $composableBuilder(
    column: $table.mnemonic,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhoneticRootsTableOrderingComposer
    extends Composer<_$AppDatabase, $PhoneticRootsTable> {
  $$PhoneticRootsTableOrderingComposer({
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

  ColumnOrderings<String> get root => $composableBuilder(
    column: $table.root,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinyin => $composableBuilder(
    column: $table.pinyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get koHanja => $composableBuilder(
    column: $table.koHanja,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clusterCount => $composableBuilder(
    column: $table.clusterCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mnemonic => $composableBuilder(
    column: $table.mnemonic,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhoneticRootsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhoneticRootsTable> {
  $$PhoneticRootsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get root =>
      $composableBuilder(column: $table.root, builder: (column) => column);

  GeneratedColumn<String> get pinyin =>
      $composableBuilder(column: $table.pinyin, builder: (column) => column);

  GeneratedColumn<String> get koHanja =>
      $composableBuilder(column: $table.koHanja, builder: (column) => column);

  GeneratedColumn<int> get clusterCount => $composableBuilder(
    column: $table.clusterCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mnemonic =>
      $composableBuilder(column: $table.mnemonic, builder: (column) => column);
}

class $$PhoneticRootsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhoneticRootsTable,
          PhoneticRootRow,
          $$PhoneticRootsTableFilterComposer,
          $$PhoneticRootsTableOrderingComposer,
          $$PhoneticRootsTableAnnotationComposer,
          $$PhoneticRootsTableCreateCompanionBuilder,
          $$PhoneticRootsTableUpdateCompanionBuilder,
          (
            PhoneticRootRow,
            BaseReferences<_$AppDatabase, $PhoneticRootsTable, PhoneticRootRow>,
          ),
          PhoneticRootRow,
          PrefetchHooks Function()
        > {
  $$PhoneticRootsTableTableManager(_$AppDatabase db, $PhoneticRootsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhoneticRootsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhoneticRootsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhoneticRootsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> root = const Value.absent(),
                Value<String?> pinyin = const Value.absent(),
                Value<String?> koHanja = const Value.absent(),
                Value<int> clusterCount = const Value.absent(),
                Value<String?> mnemonic = const Value.absent(),
              }) => PhoneticRootsCompanion(
                id: id,
                root: root,
                pinyin: pinyin,
                koHanja: koHanja,
                clusterCount: clusterCount,
                mnemonic: mnemonic,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String root,
                Value<String?> pinyin = const Value.absent(),
                Value<String?> koHanja = const Value.absent(),
                Value<int> clusterCount = const Value.absent(),
                Value<String?> mnemonic = const Value.absent(),
              }) => PhoneticRootsCompanion.insert(
                id: id,
                root: root,
                pinyin: pinyin,
                koHanja: koHanja,
                clusterCount: clusterCount,
                mnemonic: mnemonic,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhoneticRootsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhoneticRootsTable,
      PhoneticRootRow,
      $$PhoneticRootsTableFilterComposer,
      $$PhoneticRootsTableOrderingComposer,
      $$PhoneticRootsTableAnnotationComposer,
      $$PhoneticRootsTableCreateCompanionBuilder,
      $$PhoneticRootsTableUpdateCompanionBuilder,
      (
        PhoneticRootRow,
        BaseReferences<_$AppDatabase, $PhoneticRootsTable, PhoneticRootRow>,
      ),
      PhoneticRootRow,
      PrefetchHooks Function()
    >;
typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      Value<int> rank,
      required String word,
      Value<double?> freq,
      Value<double?> cumPct,
      Value<String?> region,
      Value<String?> hskLevel,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<int> rank,
      Value<String> word,
      Value<double?> freq,
      Value<double?> cumPct,
      Value<String?> region,
      Value<String?> hskLevel,
    });

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get freq => $composableBuilder(
    column: $table.freq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cumPct => $composableBuilder(
    column: $table.cumPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hskLevel => $composableBuilder(
    column: $table.hskLevel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get freq => $composableBuilder(
    column: $table.freq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cumPct => $composableBuilder(
    column: $table.cumPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hskLevel => $composableBuilder(
    column: $table.hskLevel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<double> get freq =>
      $composableBuilder(column: $table.freq, builder: (column) => column);

  GeneratedColumn<double> get cumPct =>
      $composableBuilder(column: $table.cumPct, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get hskLevel =>
      $composableBuilder(column: $table.hskLevel, builder: (column) => column);
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          WordRow,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (WordRow, BaseReferences<_$AppDatabase, $WordsTable, WordRow>),
          WordRow,
          PrefetchHooks Function()
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rank = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<double?> freq = const Value.absent(),
                Value<double?> cumPct = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<String?> hskLevel = const Value.absent(),
              }) => WordsCompanion(
                rank: rank,
                word: word,
                freq: freq,
                cumPct: cumPct,
                region: region,
                hskLevel: hskLevel,
              ),
          createCompanionCallback:
              ({
                Value<int> rank = const Value.absent(),
                required String word,
                Value<double?> freq = const Value.absent(),
                Value<double?> cumPct = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<String?> hskLevel = const Value.absent(),
              }) => WordsCompanion.insert(
                rank: rank,
                word: word,
                freq: freq,
                cumPct: cumPct,
                region: region,
                hskLevel: hskLevel,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      WordRow,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (WordRow, BaseReferences<_$AppDatabase, $WordsTable, WordRow>),
      WordRow,
      PrefetchHooks Function()
    >;
typedef $$AnnotationsTableCreateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<int> id,
      required int turnId,
      required String target,
      required String kind,
      Value<String> shape,
      Value<String> color,
      Value<String?> comment,
      Value<int?> start,
      Value<int?> end,
    });
typedef $$AnnotationsTableUpdateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<int> id,
      Value<int> turnId,
      Value<String> target,
      Value<String> kind,
      Value<String> shape,
      Value<String> color,
      Value<String?> comment,
      Value<int?> start,
      Value<int?> end,
    });

final class $$AnnotationsTableReferences
    extends BaseReferences<_$AppDatabase, $AnnotationsTable, AnnotationRow> {
  $$AnnotationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TurnsTable _turnIdTable(_$AppDatabase db) => db.turns.createAlias(
    $_aliasNameGenerator(db.annotations.turnId, db.turns.id),
  );

  $$TurnsTableProcessedTableManager get turnId {
    final $_column = $_itemColumn<int>('turn_id')!;

    final manager = $$TurnsTableTableManager(
      $_db,
      $_db.turns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_turnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnnotationsTableFilterComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer({
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

  ColumnFilters<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shape => $composableBuilder(
    column: $table.shape,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );

  $$TurnsTableFilterComposer get turnId {
    final $$TurnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableFilterComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer({
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

  ColumnOrderings<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shape => $composableBuilder(
    column: $table.shape,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );

  $$TurnsTableOrderingComposer get turnId {
    final $$TurnsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableOrderingComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get shape =>
      $composableBuilder(column: $table.shape, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<int> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<int> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  $$TurnsTableAnnotationComposer get turnId {
    final $$TurnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableAnnotationComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationsTable,
          AnnotationRow,
          $$AnnotationsTableFilterComposer,
          $$AnnotationsTableOrderingComposer,
          $$AnnotationsTableAnnotationComposer,
          $$AnnotationsTableCreateCompanionBuilder,
          $$AnnotationsTableUpdateCompanionBuilder,
          (AnnotationRow, $$AnnotationsTableReferences),
          AnnotationRow,
          PrefetchHooks Function({bool turnId})
        > {
  $$AnnotationsTableTableManager(_$AppDatabase db, $AnnotationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> turnId = const Value.absent(),
                Value<String> target = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> shape = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<int?> start = const Value.absent(),
                Value<int?> end = const Value.absent(),
              }) => AnnotationsCompanion(
                id: id,
                turnId: turnId,
                target: target,
                kind: kind,
                shape: shape,
                color: color,
                comment: comment,
                start: start,
                end: end,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int turnId,
                required String target,
                required String kind,
                Value<String> shape = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<int?> start = const Value.absent(),
                Value<int?> end = const Value.absent(),
              }) => AnnotationsCompanion.insert(
                id: id,
                turnId: turnId,
                target: target,
                kind: kind,
                shape: shape,
                color: color,
                comment: comment,
                start: start,
                end: end,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnnotationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({turnId = false}) {
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
                    if (turnId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.turnId,
                                referencedTable: $$AnnotationsTableReferences
                                    ._turnIdTable(db),
                                referencedColumn: $$AnnotationsTableReferences
                                    ._turnIdTable(db)
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

typedef $$AnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationsTable,
      AnnotationRow,
      $$AnnotationsTableFilterComposer,
      $$AnnotationsTableOrderingComposer,
      $$AnnotationsTableAnnotationComposer,
      $$AnnotationsTableCreateCompanionBuilder,
      $$AnnotationsTableUpdateCompanionBuilder,
      (AnnotationRow, $$AnnotationsTableReferences),
      AnnotationRow,
      PrefetchHooks Function({bool turnId})
    >;
typedef $$UserProgressTableCreateCompanionBuilder =
    UserProgressCompanion Function({
      Value<int> turnId,
      Value<bool> learned,
      Value<bool> favorite,
      Value<DateTime?> lastReviewed,
      Value<int> reviewCount,
    });
typedef $$UserProgressTableUpdateCompanionBuilder =
    UserProgressCompanion Function({
      Value<int> turnId,
      Value<bool> learned,
      Value<bool> favorite,
      Value<DateTime?> lastReviewed,
      Value<int> reviewCount,
    });

final class $$UserProgressTableReferences
    extends BaseReferences<_$AppDatabase, $UserProgressTable, UserProgressRow> {
  $$UserProgressTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TurnsTable _turnIdTable(_$AppDatabase db) => db.turns.createAlias(
    $_aliasNameGenerator(db.userProgress.turnId, db.turns.id),
  );

  $$TurnsTableProcessedTableManager get turnId {
    final $_column = $_itemColumn<int>('turn_id')!;

    final manager = $$TurnsTableTableManager(
      $_db,
      $_db.turns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_turnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserProgressTableFilterComposer
    extends Composer<_$AppDatabase, $UserProgressTable> {
  $$UserProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get learned => $composableBuilder(
    column: $table.learned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  $$TurnsTableFilterComposer get turnId {
    final $$TurnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableFilterComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProgressTable> {
  $$UserProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get learned => $composableBuilder(
    column: $table.learned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$TurnsTableOrderingComposer get turnId {
    final $$TurnsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableOrderingComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProgressTable> {
  $$UserProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get learned =>
      $composableBuilder(column: $table.learned, builder: (column) => column);

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  $$TurnsTableAnnotationComposer get turnId {
    final $$TurnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.turnId,
      referencedTable: $db.turns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TurnsTableAnnotationComposer(
            $db: $db,
            $table: $db.turns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProgressTable,
          UserProgressRow,
          $$UserProgressTableFilterComposer,
          $$UserProgressTableOrderingComposer,
          $$UserProgressTableAnnotationComposer,
          $$UserProgressTableCreateCompanionBuilder,
          $$UserProgressTableUpdateCompanionBuilder,
          (UserProgressRow, $$UserProgressTableReferences),
          UserProgressRow,
          PrefetchHooks Function({bool turnId})
        > {
  $$UserProgressTableTableManager(_$AppDatabase db, $UserProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> turnId = const Value.absent(),
                Value<bool> learned = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<DateTime?> lastReviewed = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
              }) => UserProgressCompanion(
                turnId: turnId,
                learned: learned,
                favorite: favorite,
                lastReviewed: lastReviewed,
                reviewCount: reviewCount,
              ),
          createCompanionCallback:
              ({
                Value<int> turnId = const Value.absent(),
                Value<bool> learned = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<DateTime?> lastReviewed = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
              }) => UserProgressCompanion.insert(
                turnId: turnId,
                learned: learned,
                favorite: favorite,
                lastReviewed: lastReviewed,
                reviewCount: reviewCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({turnId = false}) {
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
                    if (turnId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.turnId,
                                referencedTable: $$UserProgressTableReferences
                                    ._turnIdTable(db),
                                referencedColumn: $$UserProgressTableReferences
                                    ._turnIdTable(db)
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

typedef $$UserProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProgressTable,
      UserProgressRow,
      $$UserProgressTableFilterComposer,
      $$UserProgressTableOrderingComposer,
      $$UserProgressTableAnnotationComposer,
      $$UserProgressTableCreateCompanionBuilder,
      $$UserProgressTableUpdateCompanionBuilder,
      (UserProgressRow, $$UserProgressTableReferences),
      UserProgressRow,
      PrefetchHooks Function({bool turnId})
    >;
typedef $$HanziProgressTableCreateCompanionBuilder =
    HanziProgressCompanion Function({
      required String char,
      Value<bool> known,
      Value<int> exposureCount,
      Value<DateTime?> lastReviewed,
      Value<int> rowid,
    });
typedef $$HanziProgressTableUpdateCompanionBuilder =
    HanziProgressCompanion Function({
      Value<String> char,
      Value<bool> known,
      Value<int> exposureCount,
      Value<DateTime?> lastReviewed,
      Value<int> rowid,
    });

final class $$HanziProgressTableReferences
    extends
        BaseReferences<_$AppDatabase, $HanziProgressTable, HanziProgressRow> {
  $$HanziProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HanziTable _charTable(_$AppDatabase db) => db.hanzi.createAlias(
    $_aliasNameGenerator(db.hanziProgress.char, db.hanzi.char),
  );

  $$HanziTableProcessedTableManager get char {
    final $_column = $_itemColumn<String>('char')!;

    final manager = $$HanziTableTableManager(
      $_db,
      $_db.hanzi,
    ).filter((f) => f.char.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_charTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HanziProgressTableFilterComposer
    extends Composer<_$AppDatabase, $HanziProgressTable> {
  $$HanziProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get known => $composableBuilder(
    column: $table.known,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exposureCount => $composableBuilder(
    column: $table.exposureCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => ColumnFilters(column),
  );

  $$HanziTableFilterComposer get char {
    final $$HanziTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.char,
      referencedTable: $db.hanzi,
      getReferencedColumn: (t) => t.char,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HanziTableFilterComposer(
            $db: $db,
            $table: $db.hanzi,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HanziProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $HanziProgressTable> {
  $$HanziProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get known => $composableBuilder(
    column: $table.known,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exposureCount => $composableBuilder(
    column: $table.exposureCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => ColumnOrderings(column),
  );

  $$HanziTableOrderingComposer get char {
    final $$HanziTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.char,
      referencedTable: $db.hanzi,
      getReferencedColumn: (t) => t.char,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HanziTableOrderingComposer(
            $db: $db,
            $table: $db.hanzi,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HanziProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $HanziProgressTable> {
  $$HanziProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get known =>
      $composableBuilder(column: $table.known, builder: (column) => column);

  GeneratedColumn<int> get exposureCount => $composableBuilder(
    column: $table.exposureCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => column,
  );

  $$HanziTableAnnotationComposer get char {
    final $$HanziTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.char,
      referencedTable: $db.hanzi,
      getReferencedColumn: (t) => t.char,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HanziTableAnnotationComposer(
            $db: $db,
            $table: $db.hanzi,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HanziProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HanziProgressTable,
          HanziProgressRow,
          $$HanziProgressTableFilterComposer,
          $$HanziProgressTableOrderingComposer,
          $$HanziProgressTableAnnotationComposer,
          $$HanziProgressTableCreateCompanionBuilder,
          $$HanziProgressTableUpdateCompanionBuilder,
          (HanziProgressRow, $$HanziProgressTableReferences),
          HanziProgressRow,
          PrefetchHooks Function({bool char})
        > {
  $$HanziProgressTableTableManager(_$AppDatabase db, $HanziProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HanziProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HanziProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HanziProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> char = const Value.absent(),
                Value<bool> known = const Value.absent(),
                Value<int> exposureCount = const Value.absent(),
                Value<DateTime?> lastReviewed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HanziProgressCompanion(
                char: char,
                known: known,
                exposureCount: exposureCount,
                lastReviewed: lastReviewed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String char,
                Value<bool> known = const Value.absent(),
                Value<int> exposureCount = const Value.absent(),
                Value<DateTime?> lastReviewed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HanziProgressCompanion.insert(
                char: char,
                known: known,
                exposureCount: exposureCount,
                lastReviewed: lastReviewed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HanziProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({char = false}) {
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
                    if (char) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.char,
                                referencedTable: $$HanziProgressTableReferences
                                    ._charTable(db),
                                referencedColumn: $$HanziProgressTableReferences
                                    ._charTable(db)
                                    .char,
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

typedef $$HanziProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HanziProgressTable,
      HanziProgressRow,
      $$HanziProgressTableFilterComposer,
      $$HanziProgressTableOrderingComposer,
      $$HanziProgressTableAnnotationComposer,
      $$HanziProgressTableCreateCompanionBuilder,
      $$HanziProgressTableUpdateCompanionBuilder,
      (HanziProgressRow, $$HanziProgressTableReferences),
      HanziProgressRow,
      PrefetchHooks Function({bool char})
    >;
typedef $$UserMemosTableCreateCompanionBuilder =
    UserMemosCompanion Function({
      Value<int> id,
      required String context,
      required String body,
      Value<DateTime> createdAt,
    });
typedef $$UserMemosTableUpdateCompanionBuilder =
    UserMemosCompanion Function({
      Value<int> id,
      Value<String> context,
      Value<String> body,
      Value<DateTime> createdAt,
    });

class $$UserMemosTableFilterComposer
    extends Composer<_$AppDatabase, $UserMemosTable> {
  $$UserMemosTableFilterComposer({
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

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserMemosTableOrderingComposer
    extends Composer<_$AppDatabase, $UserMemosTable> {
  $$UserMemosTableOrderingComposer({
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

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserMemosTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserMemosTable> {
  $$UserMemosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserMemosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserMemosTable,
          UserMemoRow,
          $$UserMemosTableFilterComposer,
          $$UserMemosTableOrderingComposer,
          $$UserMemosTableAnnotationComposer,
          $$UserMemosTableCreateCompanionBuilder,
          $$UserMemosTableUpdateCompanionBuilder,
          (
            UserMemoRow,
            BaseReferences<_$AppDatabase, $UserMemosTable, UserMemoRow>,
          ),
          UserMemoRow,
          PrefetchHooks Function()
        > {
  $$UserMemosTableTableManager(_$AppDatabase db, $UserMemosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserMemosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserMemosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserMemosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> context = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserMemosCompanion(
                id: id,
                context: context,
                body: body,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String context,
                required String body,
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserMemosCompanion.insert(
                id: id,
                context: context,
                body: body,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserMemosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserMemosTable,
      UserMemoRow,
      $$UserMemosTableFilterComposer,
      $$UserMemosTableOrderingComposer,
      $$UserMemosTableAnnotationComposer,
      $$UserMemosTableCreateCompanionBuilder,
      $$UserMemosTableUpdateCompanionBuilder,
      (
        UserMemoRow,
        BaseReferences<_$AppDatabase, $UserMemosTable, UserMemoRow>,
      ),
      UserMemoRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TurnsTableTableManager get turns =>
      $$TurnsTableTableManager(_db, _db.turns);
  $$HanziTableTableManager get hanzi =>
      $$HanziTableTableManager(_db, _db.hanzi);
  $$PhoneticRootsTableTableManager get phoneticRoots =>
      $$PhoneticRootsTableTableManager(_db, _db.phoneticRoots);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db, _db.annotations);
  $$UserProgressTableTableManager get userProgress =>
      $$UserProgressTableTableManager(_db, _db.userProgress);
  $$HanziProgressTableTableManager get hanziProgress =>
      $$HanziProgressTableTableManager(_db, _db.hanziProgress);
  $$UserMemosTableTableManager get userMemos =>
      $$UserMemosTableTableManager(_db, _db.userMemos);
}
