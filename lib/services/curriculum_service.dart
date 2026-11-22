import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/prefs.dart';
import 'dialogue_service.dart';
import 'learner_prefs.dart';

/// 토크버스 커리큘럼 — 전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`(2026-11-22 uk).
/// 회화 레벨에서 편을 골라 코스를 만들고 → 편마다 듣기·따라 말하기·확인 문제 → 틀린 줄과 연습한 줄은 간격 반복(1·3·7일)
/// → 코스 시험 80% 이상이면 통과. 하루 목표(새 편 1·2·3 + 복습). 기기 저장 키 `curriculum_v1`(전 언어 같음).

/// 간격 반복 간격(일). 맞히면 다음 간격, 틀리면 1일로. 7일 간격에서 또 맞히면 졸업(대기열에서 뺌).
const kReviewSteps = [1, 3, 7];

/// 코스 통과 기준(%).
const kPassPercent = 80;

/// 하루 목표 → 새 편 수.
const kDailyGoals = {'light': 1, 'normal': 2, 'focus': 3};

/// 고를 편 수.
const kCourseSizes = [3, 5, 10];

String dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime _parseDay(String s) => DateTime.parse(s);
String addDays(String day, int n) => dayKey(_parseDay(day).add(Duration(days: n, hours: 12)));

/// 점수 = 정답 수 / 문제 수, 소수점 버림.
int scorePercent(int correct, int total) => total <= 0 ? 0 : (correct * 100) ~/ total;
bool isPass(int correct, int total) => total > 0 && scorePercent(correct, total) >= kPassPercent;

/// 줄 아이디 = 편 아이디#턴 번호.
String lineId(String dialogueId, int turn) => '$dialogueId#$turn';
(String, int)? parseLineId(String id) {
  final i = id.lastIndexOf('#');
  if (i <= 0) return null;
  final n = int.tryParse(id.substring(i + 1));
  return n == null ? null : (id.substring(0, i), n);
}

class ReviewItem {
  final String lineId;
  String due; // yyyy-MM-dd
  int step; // kReviewSteps 의 몇 번째 간격
  ReviewItem(this.lineId, this.due, this.step);
  Map<String, dynamic> toJson() => {'lineId': lineId, 'due': due, 'step': step};
  factory ReviewItem.fromJson(Map<String, dynamic> j) => ReviewItem('${j['lineId']}', '${j['due']}', (j['step'] as num?)?.toInt() ?? 0);
}

class Course {
  final String id;
  final List<String> dialogueIds;
  final List<String> practiced;
  final List<int> examScores;
  String? passedAt;
  Course({required this.id, required this.dialogueIds, List<String>? practiced, List<int>? examScores, this.passedAt})
      : practiced = practiced ?? [],
        examScores = examScores ?? [];
  bool get allPracticed => dialogueIds.every(practiced.contains);
  bool get passed => passedAt != null;
  Map<String, dynamic> toJson() => {'id': id, 'dialogueIds': dialogueIds, 'practiced': practiced, 'examScores': examScores, 'passedAt': passedAt};
  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: '${j['id']}',
        dialogueIds: [for (final e in (j['dialogueIds'] as List? ?? const [])) '$e'],
        practiced: [for (final e in (j['practiced'] as List? ?? const [])) '$e'],
        examScores: [for (final e in (j['examScores'] as List? ?? const [])) (e as num).toInt()],
        passedAt: j['passedAt'] as String?,
      );
}

/// 저장 형식(spec §7) + 오늘 진행(`today`, 이 앱이 더한 칸 — 하루 분량 막대용).
class CurriculumState {
  String? level;
  String dailyGoal;
  Course? course;
  final List<String> passedDialogues;
  final List<ReviewItem> review;
  int streakCount;
  String? streakLastDay;
  String? todayDay;
  int todayNew;
  int todayReview;
  CurriculumState({
    this.level,
    this.dailyGoal = 'normal',
    this.course,
    List<String>? passedDialogues,
    List<ReviewItem>? review,
    this.streakCount = 0,
    this.streakLastDay,
    this.todayDay,
    this.todayNew = 0,
    this.todayReview = 0,
  })  : passedDialogues = passedDialogues ?? [],
        review = review ?? [];

  Map<String, dynamic> toJson() => {
        'level': level,
        'dailyGoal': dailyGoal,
        'course': course?.toJson(),
        'passedDialogues': passedDialogues,
        'review': [for (final r in review) r.toJson()],
        'streak': {'count': streakCount, 'lastDay': streakLastDay},
        'today': {'day': todayDay, 'new': todayNew, 'review': todayReview},
      };

  factory CurriculumState.fromJson(Map<String, dynamic> j) {
    final s = (j['streak'] as Map?) ?? const {};
    final t = (j['today'] as Map?) ?? const {};
    return CurriculumState(
      level: j['level'] as String?,
      dailyGoal: kDailyGoals.containsKey(j['dailyGoal']) ? j['dailyGoal'] as String : 'normal',
      course: j['course'] is Map ? Course.fromJson((j['course'] as Map).cast<String, dynamic>()) : null,
      passedDialogues: [for (final e in (j['passedDialogues'] as List? ?? const [])) '$e'],
      review: [for (final e in (j['review'] as List? ?? const [])) if (e is Map) ReviewItem.fromJson(e.cast<String, dynamic>())],
      streakCount: (s['count'] as num?)?.toInt() ?? 0,
      streakLastDay: s['lastDay'] as String?,
      todayDay: t['day'] as String?,
      todayNew: (t['new'] as num?)?.toInt() ?? 0,
      todayReview: (t['review'] as num?)?.toInt() ?? 0,
    );
  }

  int get newGoal => kDailyGoals[dailyGoal] ?? 2;

  void _rollDay(String today) {
    if (todayDay == today) return;
    todayDay = today;
    todayNew = 0;
    todayReview = 0;
  }

  List<ReviewItem> dueOn(String today) => review.where((r) => r.due.compareTo(today) <= 0).toList();

  /// 오늘 남은 새 편 수(목표 - 오늘 한 것).
  int newLeft(String today) => max(0, newGoal - (todayDay == today ? todayNew : 0));

  /// 오늘 분량 끝 = 밀린 복습 0 · 새 편 목표 채움.
  bool doneToday(String today) => dueOn(today).isEmpty && newLeft(today) == 0;

  /// 오늘 진행 막대(0~1): (오늘 한 복습 + 새 편) / (그것 + 남은 복습 + 남은 새 편).
  double progress(String today) {
    final doneN = todayDay == today ? todayNew + todayReview : 0;
    final left = dueOn(today).length + newLeft(today);
    final all = doneN + left;
    return all == 0 ? 1 : doneN / all;
  }

  /// 줄 하나의 복습 결과. 대기열에 없으면 1일 뒤로 넣는다.
  void grade(String id, bool correct, String today) {
    final i = review.indexWhere((r) => r.lineId == id);
    if (i < 0) {
      review.add(ReviewItem(id, addDays(today, kReviewSteps[0]), 0));
      return;
    }
    final r = review[i];
    if (!correct) {
      r
        ..step = 0
        ..due = addDays(today, kReviewSteps[0]);
      return;
    }
    final next = r.step + 1;
    if (next >= kReviewSteps.length) {
      review.removeAt(i); // 7일 간격까지 맞힘 — 졸업
    } else {
      r
        ..step = next
        ..due = addDays(today, kReviewSteps[next]);
    }
  }

  /// 연습한 편의 줄을 대기열에 넣는다(이미 있으면 그대로, 틀린 줄은 1일로).
  void addPracticed(Iterable<String> lineIds, Set<String> wrong, String today) {
    for (final id in lineIds) {
      final i = review.indexWhere((r) => r.lineId == id);
      if (i < 0) {
        review.add(ReviewItem(id, addDays(today, kReviewSteps[0]), 0));
      } else if (wrong.contains(id)) {
        review[i]
          ..step = 0
          ..due = addDays(today, kReviewSteps[0]);
      }
    }
  }

  /// 편 연습을 마침. 코스에서 처음 마친 편이면 오늘 새 편으로 센다.
  void practiceDone(String dialogueId, Iterable<String> lineIds, Set<String> wrong, String today) {
    _rollDay(today);
    final c = course;
    if (c != null && c.dialogueIds.contains(dialogueId) && !c.practiced.contains(dialogueId)) {
      c.practiced.add(dialogueId);
      todayNew++;
    }
    addPracticed(lineIds, wrong, today);
    _touchStreak(today);
  }

  /// 복습 한 문제를 풂.
  void reviewDone(String id, bool correct, String today) {
    _rollDay(today);
    grade(id, correct, today);
    todayReview++;
    _touchStreak(today);
  }

  /// 코스 시험 결과. 통과면 코스 완료·편 통과 기록, 아니면 틀린 편의 연습 표시를 지워 다시 연습하게 한다.
  bool examDone(int correct, int total, Set<String> wrongDialogues, String today) {
    final c = course;
    if (c == null) return false;
    c.examScores.add(scorePercent(correct, total));
    if (isPass(correct, total)) {
      c.passedAt = today;
      for (final id in c.dialogueIds) {
        if (!passedDialogues.contains(id)) passedDialogues.add(id);
      }
      return true;
    }
    c.practiced.removeWhere(wrongDialogues.contains);
    return false;
  }

  void _touchStreak(String today) {
    if (!doneToday(today) || streakLastDay == today) return;
    streakCount = streakLastDay == addDays(today, -1) ? streakCount + 1 : 1;
    streakLastDay = today;
  }

  /// 표시용 연속 일수(어제 끊겼으면 0).
  int streakShown(String today) => (streakLastDay == today || streakLastDay == addDays(today, -1)) ? streakCount : 0;
}

/// 문제 하나. kind = 'meaning'(중국어 줄 → 뜻 4지선다) · 'blank'(빈칸 낱말 4지선다).
class CurriculumQuestion {
  final String kind;
  final String lineId;
  final String dialogueId;
  final String prompt; // 중국어(빈칸이면 ＿＿ 자리)
  final String hint; // 빈칸 문제의 뜻
  final List<String> options;
  final int answer;
  final DialogueTurn turn;
  const CurriculumQuestion({required this.kind, required this.lineId, required this.dialogueId, required this.prompt, this.hint = '', required this.options, required this.answer, required this.turn});
}

final _paren = RegExp(r'[（(][^)）]*[)）]');
final _han = RegExp(r'[一-鿿]');
String _clean(String s) => s.replaceAll(_paren, '').trim();

/// 문제로 쓸 수 있는 줄(한자가 있고 뜻이 있음).
bool usableTurn(DialogueTurn t) => _han.hasMatch(_clean(t.zh)) && t.ko.trim().isNotEmpty;

/// 문제 만들기. [turns] = 문제 낼 줄(편, 턴), [pool] = 오답 보기를 뽑을 편들(같은 레벨).
List<CurriculumQuestion> buildQuestions(List<(Dialogue, DialogueTurn)> turns, List<Dialogue> pool, {required int limit, Random? rnd}) {
  final r = rnd ?? Random();
  final kos = <String>{};
  final words = <String>{};
  for (final d in pool) {
    for (final t in d.turns) {
      if (!usableTurn(t)) continue;
      kos.add(LearnerPrefs.fill(t.ko, ko: true).trim());
      for (final l in t.lemmas) {
        if (_han.hasMatch(l.surface)) words.add(l.surface);
      }
    }
  }
  final picked = [for (final x in turns) if (usableTurn(x.$2)) x]..shuffle(r);
  final out = <CurriculumQuestion>[];
  for (final (d, t) in picked.take(limit)) {
    final zh = _clean(LearnerPrefs.fill(t.zh));
    final ko = LearnerPrefs.fill(t.ko, ko: true).trim();
    final id = lineId(d.id, t.num);
    CurriculumQuestion? q;
    if (out.length.isOdd) {
      // 빈칸: 이 줄에 실제로 나오는 내용어 중 하나
      final cands = [for (final l in t.lemmas) if (_han.hasMatch(l.surface) && zh.contains(l.surface)) l.surface]..shuffle(r);
      if (cands.isNotEmpty) {
        final w = cands.first;
        final wrong = (words.where((x) => x != w && !zh.contains(x)).toList()..shuffle(r)).take(3).toList();
        if (wrong.length == 3) {
          final opts = [w, ...wrong]..shuffle(r);
          q = CurriculumQuestion(kind: 'blank', lineId: id, dialogueId: d.id, prompt: zh.replaceFirst(w, '＿＿'), hint: ko, options: opts, answer: opts.indexOf(w), turn: t);
        }
      }
    }
    if (q == null) {
      final wrong = (kos.where((x) => x != ko).toList()..shuffle(r)).take(3).toList();
      if (wrong.length < 3) continue;
      final opts = [ko, ...wrong]..shuffle(r);
      q = CurriculumQuestion(kind: 'meaning', lineId: id, dialogueId: d.id, prompt: zh, options: opts, answer: opts.indexOf(ko), turn: t);
    }
    out.add(q);
  }
  return out;
}

/// 편 연습 문제: 편의 줄 수만큼, 최대 10문제.
List<CurriculumQuestion> practiceQuestions(Dialogue d, List<Dialogue> pool, {Random? rnd}) =>
    buildQuestions([for (final t in d.turns) (d, t)], pool, limit: 10, rnd: rnd);

/// 코스 시험: 편당 최소 3문제, 모두 최대 30문제.
List<CurriculumQuestion> examQuestions(List<Dialogue> ds, List<Dialogue> pool, {Random? rnd}) {
  if (ds.isEmpty) return const [];
  final r = rnd ?? Random();
  final per = max(3, 30 ~/ ds.length);
  final out = <CurriculumQuestion>[];
  for (final d in ds) {
    out.addAll(buildQuestions([for (final t in d.turns) (d, t)], pool, limit: per, rnd: r));
  }
  out.shuffle(r);
  return out.take(30).toList();
}

/// 「추천으로 채우기」: 아직 통과 안 한 편에서 주제가 겹치지 않게 돌아가며 고른다(이미 고른 것은 둠).
List<String> recommend(List<Dialogue> levelList, Set<String> passed, List<String> chosen, int size) {
  final out = [...chosen];
  final rest = levelList.where((d) => !passed.contains(d.id) && !out.contains(d.id)).toList();
  final byIsland = <String, List<Dialogue>>{};
  for (final d in rest) {
    byIsland.putIfAbsent(d.island, () => []).add(d);
  }
  final used = <String>{for (final d in levelList) if (out.contains(d.id)) d.island};
  while (out.length < size && byIsland.values.any((l) => l.isNotEmpty)) {
    final keys = byIsland.keys.where((k) => byIsland[k]!.isNotEmpty).toList()
      ..sort((a, b) => (used.contains(a) ? 1 : 0).compareTo(used.contains(b) ? 1 : 0));
    final k = keys.first;
    out.add(byIsland[k]!.removeAt(0).id);
    used.add(k);
    if (keys.every(used.contains)) used.clear();
  }
  return out;
}

class CurriculumService extends ChangeNotifier {
  CurriculumService._();
  static final CurriculumService instance = CurriculumService._();
  static const prefKey = 'curriculum_v1';

  CurriculumState state = CurriculumState();
  bool _loaded = false;
  bool get loaded => _loaded;

  /// 시험용 오늘 날짜.
  @visibleForTesting
  DateTime? debugNow;
  String get today => dayKey(debugNow ?? DateTime.now());

  Future<void> load() async {
    if (_loaded) return;
    final raw = (await Prefs.getInstance()).getString(prefKey);
    if (raw != null) {
      try {
        state = CurriculumState.fromJson((json.decode(raw) as Map).cast<String, dynamic>());
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  @visibleForTesting
  void debugReset() {
    state = CurriculumState();
    _loaded = false;
  }

  Future<void> save() async {
    await (await Prefs.getInstance()).setString(prefKey, json.encode(state.toJson()));
    notifyListeners();
  }

  Future<void> setLevel(String lv) async {
    state.level = lv;
    await save();
  }

  Future<void> setDailyGoal(String g) async {
    state.dailyGoal = g;
    await save();
  }

  Future<void> startCourse(List<String> ids) async {
    state.course = Course(id: '${DateTime.now().millisecondsSinceEpoch}', dialogueIds: ids);
    await save();
  }

  Future<void> practiceDone(Dialogue d, Set<String> wrongLines) async {
    state.practiceDone(d.id, [for (final t in d.turns) if (usableTurn(t)) lineId(d.id, t.num)], wrongLines, today);
    await save();
  }

  Future<void> reviewDone(String id, bool correct) async {
    state.reviewDone(id, correct, today);
    await save();
  }

  /// 시험 결과 저장. 통과하고 그 레벨 편을 모두 통과했으면 다음 레벨로 옮긴다. 반환 = 통과 여부.
  Future<bool> examDone(int correct, int total, Set<String> wrongDialogues) async {
    final ok = state.examDone(correct, total, wrongDialogues, today);
    if (ok) {
      final lv = state.level;
      final svc = DialogueService.instance;
      if (lv != null && svc.list(region: lv).every((d) => state.passedDialogues.contains(d.id))) {
        final i = DialogueService.levels.indexOf(lv);
        for (final next in DialogueService.levels.skip(i + 1)) {
          if (svc.count(next) > 0) {
            state.level = next;
            break;
          }
        }
      }
    }
    await save();
    return ok;
  }

  /// 오늘 복습할 줄(편이 사라진 줄은 대기열에서 뺀다).
  List<(Dialogue, DialogueTurn)> dueTurns() {
    final svc = DialogueService.instance;
    final out = <(Dialogue, DialogueTurn)>[];
    final gone = <String>{};
    for (final r in state.dueOn(today)) {
      final p = parseLineId(r.lineId);
      final d = p == null ? null : svc.byId(p.$1);
      final t = d?.turns.where((t) => t.num == p!.$2).firstOrNull;
      if (d == null || t == null || !usableTurn(t)) {
        gone.add(r.lineId);
      } else {
        out.add((d, t));
      }
    }
    if (gone.isNotEmpty && svc.isLoaded) state.review.removeWhere((r) => gone.contains(r.lineId));
    return out;
  }
}
