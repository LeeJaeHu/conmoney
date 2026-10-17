import 'package:conmoney/core/budget_engine.dart';
import 'package:conmoney/core/models.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/data/ledger_repository.dart';
import 'package:conmoney/data/notification_ingest.dart';
import 'package:conmoney/data/spending_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// 실제 롯데카드 알림톡 형식에 금액·가맹점·이름만 바꾼 샘플
String lotteBody(String merchant, String amount, {String verb = '승인', String when = '일시불, 10/17 12:34'}) =>
    '$merchant\n$amount원 $verb\n홍*동 LOCA LIKIT Eat(1*2*)\n$when\n누적금액 123,456원';

RawPaymentNotification raw(int id, String body, {DateTime? at, String package = 'com.kakao.talk', String? title = '롯데카드'}) =>
    RawPaymentNotification(
      id: id,
      packageName: package,
      title: title,
      body: body,
      postedAt: at ?? DateTime(2026, 10, 17, 12, 35),
    );

void main() {
  late AppDatabase db;
  late NotificationIngestor ingestor;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ingestor = NotificationIngestor(db);
  });
  tearDown(() => db.close());

  Future<List<TransactionRow>> txns() => db.select(db.transactions).get();

  test('롯데 승인 알림 → 거래 저장, 오늘 지출에 반영, 같은 원문은 한 번만', () async {
    final r = await ingestor.ingest([raw(1, lotteBody('버거킹 강남역점', '9,300'))]);
    expect(r.saved, 1);
    expect(r.newApprovals, hasLength(1));

    final t = (await txns()).single;
    expect(t.amount, 9300);
    expect(t.localDate, '2026-10-17');
    expect(t.confirmed, isFalse); // 확인 안 한 결제로 홈에 뜬다
    expect(t.suggestSource, 'BUILTIN_RULE');
    final cats = {for (final c in await db.select(db.categories).get()) c.id: c.name};
    expect(cats[t.suggestedCategoryId], '식비');

    final engine = BudgetEngine(await LedgerRepository(db).loadLedger());
    expect(engine.spent(YearMonth(2026, 10)), 9300);
    final items = await SpendingRepository(db).items();
    expect(items.single.date, DateTime(2026, 10, 17)); // 달력의 그날 내역

    final again = await ingestor.ingest([raw(1, lotteBody('버거킹 강남역점', '9,300'))]);
    expect(again.saved, 0);
    expect(await txns(), hasLength(1));
  });

  test('같은 결제 알림이 다시 와도(원문 id가 달라도) 한 번만', () async {
    await ingestor.ingest([raw(1, lotteBody('버거킹 강남역점', '9,300'))]);
    final r = await ingestor.ingest([raw(2, lotteBody('버거킹 강남역점', '9,300'))]);
    expect(r.duplicates, 1);
    expect(await txns(), hasLength(1));
  });

  test('카드사 내역 파일로 이미 가져온 결제는 중복으로 본다(롯데는 가맹점 뒤 _법인명)', () async {
    await importTransactions(db, [
      ImportRow(
        date: DateTime(2026, 10, 17),
        time: '',
        card: '롯데 LOCA LIKIT Eat',
        merchant: '버거킹(비케이알)',
        merchantRaw: '버거킹 강남역점_비케이알',
        amount: 9300,
        installmentMonths: 1,
        isForeign: false,
        currency: 'KRW',
        originalAmount: '',
        cancelled: false,
        category: '식비',
        isUnusual: false,
        source: 'test',
      ),
    ]);
    // 가져오기로 만든 카드에 알림 출처가 붙어 있으므로 같은 카드로 찾는다
    final r = await ingestor.ingest([raw(1, lotteBody('버거킹 강남역점', '9,300'))]);
    expect(r.duplicates, 1);
    expect(await txns(), hasLength(1));
  });

  test('같은 달 취소: 원거래를 취소 처리, 이번 달 지출에서 빠짐', () async {
    await ingestor.ingest([raw(1, lotteBody('버거킹 강남역점', '9,300'))]);
    final r = await ingestor.ingest([
      raw(2, lotteBody('버거킹 강남역점', '9,300', verb: '승인취소', when: '일시불, 10/17 13:00')),
    ]);
    expect(r.cancels, 1);
    final all = await txns();
    expect(all.firstWhere((t) => t.kind == 'APPROVAL').status, 'CANCELLED');
    final engine = BudgetEngine(await LedgerRepository(db).loadLedger());
    expect(engine.spent(YearMonth(2026, 10)), 0);
  });

  test('원거래를 못 찾은 취소는 음수로 반영하고 확인 필요', () async {
    await ingestor.ingest([raw(1, lotteBody('맘스터치 역삼점', '7,000', verb: '취소'))]);
    final t = (await txns()).single;
    expect(t.amount, -7000);
    expect(t.needsReview, isTrue);
    expect(t.reviewReason, 'CANCEL_UNMATCHED');
  });

  test('할부 승인은 회차 일정을 만든다', () async {
    await ingestor.ingest([raw(1, lotteBody('하이마트 강남점', '300,000', when: '3개월, 10/17 12:34'))]);
    final rows = await db.select(db.installmentSchedules).get();
    expect([for (final r in rows) r.amount], [100000, 100000, 100000]);
  });

  test('결제가 아닌 알림톡은 무시, 못 읽은 결제 알림은 확인 필요 거래(금액 0)', () async {
    final r = await ingestor.ingest([
      raw(1, '10월 결제예정금액 안내\n결제일 11/14'),
      raw(2, '승인 내역을 확인해 주세요\n합계 9,300 원'),
    ]);
    expect(r.ignored, 1);
    expect(r.failed, 1);
    final t = (await txns()).single;
    expect(t.amount, 0);
    expect(t.needsReview, isTrue);
  });

  test('현대카드 알림 → 거래, 내역 파일의 (주)우아한형제들과는 같은 가맹점으로 본다', () async {
    const body = '홍길동 님, 현대 ZERO 승인 15,400원 일시불, 10/18 4:04 \r\n㈜우아한형제들 \r\n누적123,456원';
    final r = await ingestor.ingest([
      raw(1, body, package: 'com.hyundaicard.appcard', title: '현대카드', at: DateTime(2026, 10, 18, 4, 5)),
    ]);
    expect(r.saved, 1);
    final t = (await txns()).single;
    expect(t.merchantNorm, '배달의민족');
    expect(t.localDate, '2026-10-18');
    final cats = {for (final c in await db.select(db.categories).get()) c.id: c.name};
    expect(cats[t.suggestedCategoryId], '식비');
  });

  test('파서가 없는 출처(토스)는 보류했다가 다음에 다시 본다', () async {
    final r = await ingestor.ingest([raw(1, '9,300원 결제', package: 'viva.republica.toss', title: '토스')]);
    expect(r.unsupported, 1);
    expect(await txns(), isEmpty);
    final rows = await (db.select(db.notificationResults)..where((x) => x.rawId.equals(1))).get();
    expect(rows.single.result, 'UNSUPPORTED');
  });

  test('내가 바꾼 카테고리 규칙이 내장 규칙보다 먼저', () async {
    final cats = {for (final c in await db.select(db.categories).get()) c.name: c.id};
    await db
        .into(db.merchantRules)
        .insert(MerchantRulesCompanion.insert(merchantNorm: '버거킹 강남역점', categoryId: cats['기타']!));
    await ingestor.ingest([raw(1, lotteBody('버거킹 강남역점', '9,300'))]);
    final t = (await txns()).single;
    expect(t.suggestedCategoryId, cats['기타']);
    expect(t.suggestSource, 'USER_RULE');
  });
}
