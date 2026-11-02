// Talkverse 공통 복습 엔진 — 라이트너 7단계(2026-11-02, docs/LEITNER_SPEC.md).
// 순수 로직만(저장·화면 없음). 날짜는 기기 현지 날짜(yyyy-mm-dd) 단위, 시계는 주입 가능(시험용).
//   레벨 0 = 새 카드(아직 안 봄), 1~7 = 상자, 8 = 졸업.
//   맞음: 레벨 +1, due = 오늘 + 간격(1·2·4·8·16·32·64일, 졸업 128일)
//   틀림: 레벨 1, 같은 세션 끝에 다시(세션 안 재출제는 레벨을 더 올리지 않고 due = 내일)
import 'dart:math';

/// 복습 항목 하나. id = 'kind:key' (deck:<카드id> / turn:<턴id> / kanji:<글자> …)
class ReviewItem {
  final String id;
  int level;
  String due; // yyyy-mm-dd
  int reps;
  int lapses;
  String? lastAt; // yyyy-mm-dd
  String? hint; // 내 힌트 한 줄
  String? image; // 내 사진 경로(기기)
  ReviewItem(this.id, {this.level = 0, this.due = '', this.reps = 0, this.lapses = 0, this.lastAt, this.hint, this.image});

  bool get isNew => level == 0;
  bool get graduated => level >= ReviewEngine.graduateLevel;

  Map<String, dynamic> toJson() => {
        'l': level, 'd': due, 'r': reps, 'x': lapses,
        if (lastAt != null) 't': lastAt,
        if (hint != null && hint!.isNotEmpty) 'h': hint,
        if (image != null && image!.isNotEmpty) 'i': image,
      };
  factory ReviewItem.fromJson(String id, Map<String, dynamic> j) => ReviewItem(id,
      level: (j['l'] as num?)?.toInt() ?? 0, due: j['d'] as String? ?? '', reps: (j['r'] as num?)?.toInt() ?? 0,
      lapses: (j['x'] as num?)?.toInt() ?? 0, lastAt: j['t'] as String?, hint: j['h'] as String?, image: j['i'] as String?);
}

/// 앱이 엔진에 넘기는 새 카드 후보(순서 = 앱이 원하는 학습 순서, 예: 빈도 순위).
class ReviewCandidate {
  final String id;
  final String? category; // 같은 범주(예: 같은 회화 편·같은 주제)는 하루 1개
  final String? soundKey; // 동음(같은 읽기)은 하루 1개
  const ReviewCandidate(this.id, {this.category, this.soundKey});
}

class TodayPlan {
  final List<String> review; // 오늘 복습(높은 레벨부터)
  final List<String> fresh; // 오늘 새 카드
  const TodayPlan(this.review, this.fresh);
  int get total => review.length + fresh.length;
  List<String> get all => [...review, ...fresh];
}

class ReviewEngine {
  static const intervals = [1, 2, 4, 8, 16, 32, 64]; // 레벨 1~7
  static const graduateLevel = 8;
  static const graduateDays = 128;
  static const knownLevel = 5; // 빠른 분류 '알아요'
  static const migratedKnownLevel = 3; // 옛 '알아요' 이전

  final DateTime Function() now;
  ReviewEngine({DateTime Function()? clock}) : now = clock ?? DateTime.now;

  static String ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String get today => ymd(now());
  String addDays(int n) {
    final t = now();
    return ymd(DateTime(t.year, t.month, t.day + n));
  }

  static int intervalFor(int level) => level >= graduateLevel ? graduateDays : intervals[(level.clamp(1, 7)) - 1];

  /// 맞음. 같은 날 이미 올린 항목(세션 안 재출제)은 레벨을 더 올리지 않는다.
  void correct(ReviewItem it, {bool sameSessionRetry = false}) {
    it.reps++;
    if (sameSessionRetry) {
      it.due = addDays(1);
    } else {
      it.level = min(it.level + 1, graduateLevel);
      it.due = addDays(intervalFor(it.level));
    }
    it.lastAt = today;
  }

  /// 틀림 → 레벨 1. due 는 오늘(세션 끝 재출제), 세션이 끝나면 내일로.
  void wrong(ReviewItem it) {
    it.reps++;
    if (!it.isNew) it.lapses++;
    it.level = 1;
    it.due = today;
    it.lastAt = today;
  }

  /// 세션이 끝났는데 아직 오늘 due 로 남은(마지막에 또 틀린) 항목은 내일로.
  void closeSession(Iterable<ReviewItem> items) {
    for (final it in items) {
      if (!it.isNew && it.due.compareTo(today) <= 0 && it.lastAt == today) it.due = addDays(1);
    }
  }

  /// 빠른 분류: 아는 카드 → 레벨 5(간격 16일). 몰리지 않게 1~16일에 나눠 둔다.
  void markKnown(ReviewItem it, {int? spread}) {
    it.level = knownLevel;
    it.due = addDays(spread ?? intervalFor(knownLevel));
    it.lastAt = today;
  }

  /// 옛 '알아요' 상태 이전 → 레벨 3(간격 4일).
  void migrateKnown(ReviewItem it) {
    if (!it.isNew) return;
    it.level = migratedKnownLevel;
    it.due = addDays(intervalFor(migratedKnownLevel));
  }

  /// 오늘 할 카드. 복습 = due 지난 것 전부(높은 레벨부터, 같은 레벨은 오래 밀린 것부터),
  /// 새 카드 = 후보 중 아직 안 본 것에서 (상한 - 오늘 이미 시작한 수)개, 같은 범주·동음은 하루 1개.
  /// 새 카드는 후보 앞쪽(학습 순서) 일정 범위 안에서 섞는다.
  TodayPlan plan(Map<String, ReviewItem> items, List<ReviewCandidate> candidates,
      {int newPerDay = 20, int startedToday = 0, Random? rng}) {
    final t = today;
    final due = items.values.where((i) => !i.isNew && i.due.compareTo(t) <= 0).toList()
      ..sort((a, b) {
        final c = b.level.compareTo(a.level);
        return c != 0 ? c : a.due.compareTo(b.due);
      });
    final quota = max(0, newPerDay - startedToday);
    final fresh = <String>[];
    if (quota > 0) {
      final pool = candidates.where((c) => items[c.id] == null || items[c.id]!.isNew).take(quota * 3).toList()
        ..shuffle(rng ?? Random());
      final usedCat = <String>{}, usedSound = <String>{};
      // 오늘 이미 본 카드의 범주·읽기도 막는다
      final seenToday = items.values.where((i) => i.lastAt == t).map((i) => i.id).toSet();
      for (final c in candidates.where((c) => seenToday.contains(c.id))) {
        if (c.category != null) usedCat.add(c.category!);
        if (c.soundKey != null) usedSound.add(c.soundKey!);
      }
      for (final c in pool) {
        if (fresh.length >= quota) break;
        if (c.category != null && usedCat.contains(c.category)) continue;
        if (c.soundKey != null && usedSound.contains(c.soundKey)) continue;
        fresh.add(c.id);
        if (c.category != null) usedCat.add(c.category!);
        if (c.soundKey != null) usedSound.add(c.soundKey!);
      }
    }
    return TodayPlan(due.map((i) => i.id).toList(), fresh);
  }
}
