import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// Spec 2.1 테이블. 금액은 원 단위 int, 날짜는 `yyyy-MM-dd`(KST) 문자열 또는 DateTime.

@DataClassName('CardRow')
class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get issuer => text()(); // HYUNDAI / LOTTE / TOSS / SHINHAN
  TextColumn get productName => text()();
  TextColumn get source => text().nullable()(); // 알림 출처 키. 알림을 받지 않는 카드는 null
  TextColumn get last4 => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
}

@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer().nullable().references(Cards, #id)();
  TextColumn get kind => text()(); // APPROVAL / CANCEL / MANUAL
  IntColumn get amount => integer()();
  TextColumn get currency => text().withDefault(const Constant('KRW'))();
  TextColumn get originalAmount => text().nullable()();
  TextColumn get merchantRaw => text()();
  TextColumn get merchantNorm => text()();
  DateTimeColumn get approvedAt => dateTime()();
  TextColumn get localDate => text()();
  IntColumn get installmentMonths => integer().withDefault(const Constant(1))();
  BoolColumn get isForeign => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))(); // ACTIVE / CANCELLED
  BoolColumn get excludedFromSums => boolean().withDefault(const Constant(false))();
  IntColumn get cancelOfId => integer().nullable()();
  @ReferenceName('confirmedTransactions')
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  @ReferenceName('suggestedTransactions')
  IntColumn get suggestedCategoryId => integer().nullable().references(Categories, #id)();
  TextColumn get suggestSource => text().nullable()();
  BoolColumn get isUnusual => boolean().withDefault(const Constant(false))();
  TextColumn get memo => text().nullable()();
  BoolColumn get confirmed => boolean().withDefault(const Constant(false))();
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();
  TextColumn get reviewReason => text().nullable()();
  IntColumn get recurringItemId => integer().nullable()();
  TextColumn get rawText => text().withDefault(const Constant(''))();
  TextColumn get sourcePackage => text().nullable()(); // 알림 패키지명, 가져오기는 IMPORT:파일명
  TextColumn get notifKey => text().nullable()();
  TextColumn get dedupeKey => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('InstallmentScheduleRow')
class InstallmentSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  IntColumn get seq => integer()();
  TextColumn get month => text()(); // yyyy-MM
  IntColumn get amount => integer()();
  BoolColumn get voided => boolean().withDefault(const Constant(false))();
}

@DataClassName('RecurringItemRow')
class RecurringItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get amount => integer()();
  BoolColumn get isEstimate => boolean().withDefault(const Constant(false))();
  IntColumn get dueDay => integer()();
  IntColumn get cardId => integer().nullable()();
  TextColumn get matchPattern => text()();
  IntColumn get amountTolerancePct => integer().nullable().withDefault(const Constant(30))();
  // 월 예약형(교통비 등). 스키마 v3
  BoolColumn get isEnvelope => boolean().withDefault(const Constant(false))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

@DataClassName('RecurringMatchRow')
class RecurringMatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recurringItemId => integer().references(RecurringItems, #id)();
  TextColumn get month => text()();
  IntColumn get transactionId => integer().nullable()();
  TextColumn get status => text()(); // PAID / SKIPPED
  TextColumn get decidedOn => text()(); // yyyy-MM-dd
}

/// 한 번만 나갈 예정인 지출(축의금 등). 스키마 v5
@DataClassName('PlannedExpenseRow')
class PlannedExpenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get amount => integer()();
  TextColumn get date => text()(); // yyyy-MM-dd, 낼 날짜
  TextColumn get doneOn => text().nullable()(); // [냈어요]를 누른 날
  IntColumn get transactionId => integer().nullable()(); // 그때 만든 MANUAL 거래
  TextColumn get source => text().withDefault(const Constant('USER'))(); // USER / AGENT
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('BudgetRow')
class Budgets extends Table {
  TextColumn get month => text()(); // yyyy-MM
  IntColumn get amount => integer()();
  TextColumn get source => text()(); // FIXED / STEP_PLAN / MANUAL

  @override
  Set<Column> get primaryKey => {month};
}

@DataClassName('BudgetPlanRow')
class BudgetPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mode => text()(); // FIXED / STEP
  TextColumn get startMonth => text()();
  IntColumn get startAmount => integer()();
  IntColumn get targetAmount => integer()();
  IntColumn get months => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('MerchantRuleRow')
class MerchantRules extends Table {
  TextColumn get merchantNorm => text()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {merchantNorm};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// 보낸 알림 기록(Spec 2.1). 먼저 알려주기의 하루 1회 제한에 쓴다.
@DataClassName('NotificationLogRow')
class NotificationLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // CONFIRM / TODAY_OVER / BIG_FIXED_SOON / PACE / MORNING_CHECKED
  DateTimeColumn get sentAt => dateTime()();
  TextColumn get localDate => text()();
  TextColumn get summary => text().nullable()();
}

/// 실사용 지표(PRD 8장 실사용 평가). 수치·선택만 남기고 대화 본문은 남기지 않는다. 스키마 v4
@DataClassName('MetricEventRow')
class MetricEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // CONSULT / CATEGORY_REVIEW / ALERT
  DateTimeColumn get at => dateTime()();
  TextColumn get data => text()(); // JSON
}

/// 결제 알림 원문(Kotlin raw_notifications.db) 1건을 처리한 결과(Spec F2 처리 순서 3~4). 스키마 v6
/// 원문은 네이티브 DB에 그대로 두고 여기는 결과만 남긴다. UNSUPPORTED(아직 파서가 없는 출처)는 다음 동기화 때 다시 본다.
@DataClassName('NotificationResultRow')
class NotificationResults extends Table {
  IntColumn get rawId => integer()();
  TextColumn get result => text()(); // SAVED / DUP / CANCEL / IGNORED / PARSE_FAIL / UNSUPPORTED
  IntColumn get transactionId => integer().nullable()();
  DateTimeColumn get processedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {rawId};
}

/// 기본 카테고리(PRD F3, 10/13 검수 반영).
const defaultCategories = [
  '식비',
  '카페·간식',
  '교통',
  '게임',
  '쇼핑',
  '구독',
  'API',
  '통신',
  '공과금',
  '의료',
  '교육',
  '영화',
  '경조사·선물',
  '연회비',
  '기타',
];

@DriftDatabase(
  tables: [
    Cards,
    Categories,
    Transactions,
    InstallmentSchedules,
    RecurringItems,
    RecurringMatches,
    Budgets,
    BudgetPlans,
    MerchantRules,
    Settings,
    NotificationLogs,
    MetricEvents,
    PlannedExpenses,
    NotificationResults,
  ],
)
class AppDatabase extends _$AppDatabase {
  // 백그라운드 작업(먼저 알려주기)도 같은 DB를 열기 때문에 isolate 간 공유를 켠다
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'conmoney', native: const DriftNativeOptions(shareAcrossIsolates: true)));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await batch((b) {
        b.insertAll(categories, [
          for (var i = 0; i < defaultCategories.length; i++)
            CategoriesCompanion.insert(name: defaultCategories[i], sortOrder: Value(i), isDefault: const Value(true)),
        ]);
      });
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(notificationLogs);
      if (from < 3) await m.addColumn(recurringItems, recurringItems.isEnvelope);
      if (from < 4) await m.createTable(metricEvents);
      if (from < 5) await m.createTable(plannedExpenses);
      if (from < 6) await m.createTable(notificationResults);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<String?> setting(String key) async =>
      (await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> putSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
