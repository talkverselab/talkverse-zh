import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─── Tables ─────────────────────────────────────────────────────────────────

@DataClassName('TurnRow')
class Turns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get level => text()(); // 'L1' | 'L2' | 'L3'
  TextColumn get dialect => text().withDefault(const Constant('north'))(); // 'north' | 'south'
  TextColumn get episodeId => text().nullable()(); // 'ep1' .. 'ep5'
  IntColumn get num => integer()();
  TextColumn get speaker => text()(); // 'A' | 'B'
  TextColumn get zh => text()();
  TextColumn get pinyin => text().nullable()();
  TextColumn get ko => text().nullable()();
  TextColumn get tones => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get tagsJson => text().nullable()();
}

@DataClassName('HanziRow')
class Hanzi extends Table {
  TextColumn get char => text()();
  IntColumn get rank => integer().nullable()();
  IntColumn get freq => integer().nullable()();
  TextColumn get hskLevel => text().nullable()();
  IntColumn get phase => integer().nullable()(); // 1, 2, 3, 4
  TextColumn get pinyin => text().nullable()();
  IntColumn get tone => integer().nullable()();
  TextColumn get meaningKo => text().nullable()();
  TextColumn get koHanja => text().nullable()();

  @override
  Set<Column> get primaryKey => {char};
}

@DataClassName('PhoneticRootRow')
class PhoneticRoots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get root => text()();
  TextColumn get pinyin => text().nullable()();
  TextColumn get koHanja => text().nullable()();
  IntColumn get clusterCount => integer().withDefault(const Constant(0))();
  TextColumn get mnemonic => text().nullable()();
}

@DataClassName('WordRow')
class Words extends Table {
  IntColumn get rank => integer()();
  TextColumn get word => text()();
  RealColumn get freq => real().nullable()();
  RealColumn get cumPct => real().nullable()();
  TextColumn get region => text().nullable()(); // R1, R2, R3, R4
  TextColumn get hskLevel => text().nullable()();

  @override
  Set<Column> get primaryKey => {rank};
}

@DataClassName('AnnotationRow')
class Annotations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get turnId => integer().references(Turns, #id)();
  TextColumn get target => text()();
  TextColumn get kind => text()(); // particle, measure, combo, chunk, honorific
  TextColumn get shape => text().withDefault(const Constant('highlight'))();
  TextColumn get color => text().withDefault(const Constant('yellow'))();
  TextColumn get comment => text().nullable()();
  IntColumn get start => integer().nullable()();
  IntColumn get end => integer().nullable()();
}

@DataClassName('UserProgressRow')
class UserProgress extends Table {
  IntColumn get turnId => integer().references(Turns, #id)();
  BoolColumn get learned => boolean().withDefault(const Constant(false))();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastReviewed => dateTime().nullable()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {turnId};
}

@DataClassName('HanziProgressRow')
class HanziProgress extends Table {
  TextColumn get char => text().references(Hanzi, #char)();
  BoolColumn get known => boolean().withDefault(const Constant(false))();
  IntColumn get exposureCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReviewed => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {char};
}

@DataClassName('UserMemoRow')
class UserMemos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get context => text()(); // screen+turn or 'global'
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── Database ───────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Turns,
  Hanzi,
  PhoneticRoots,
  Words,
  Annotations,
  UserProgress,
  HanziProgress,
  UserMemos,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'chinese_universe');
  }
}
