// Talkverse 공통 복습 서비스 — 엔진 + 저장(기기 JSON 파일) + 설정(SharedPreferences).
// 앱은 시작 때 ReviewService.instance.load() 한 번, 화면은 changes(ValueNotifier) 를 듣는다.
// 저장 파일: <앱 문서 폴더>/review_items.json  {v:1, items:{id:{l,d,r,x,t,h,i}}, started:{yyyy-mm-dd:n}}
import 'dart:async';
import '../core/embed_env.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../core/prefs.dart';

import 'review_engine.dart';

enum ReviewDirection { learnerToTarget, targetToLearner }

class ReviewService {
  ReviewService._();
  static final instance = ReviewService._();

  ReviewEngine engine = ReviewEngine();
  final Map<String, ReviewItem> items = {};
  final Map<String, int> _started = {}; // 날짜별 새 카드 시작 수
  final changes = ValueNotifier<int>(0);

  int newPerDay = 20; // 10 / 20 / 30
  ReviewDirection direction = ReviewDirection.learnerToTarget;
  int? reminderMinutes; // 알림 시각(0시부터 분), null = 끔

  /// 답할 때마다 0.4초 뒤 파일 저장. 위젯 시험에서는 끈다.
  bool autosave = true;

  File? _file;
  Timer? _saveTimer;
  bool _loaded = false;

  Future<void> load({File? file}) async {
    if (_loaded) return;
    // 통합 앱이면 언어별 폴더(다른 언어 복습 기록과 겹치지 않게), 단독 앱은 예전 위치 그대로
    _file = file ?? File(embedded ? '${await dataDir()}/review_items.json' : '${(await getApplicationDocumentsDirectory()).path}/review_items.json');
    try {
      if (await _file!.exists()) {
        final j = jsonDecode(await _file!.readAsString()) as Map<String, dynamic>;
        (j['items'] as Map<String, dynamic>? ?? {}).forEach((k, v) => items[k] = ReviewItem.fromJson(k, v as Map<String, dynamic>));
        (j['started'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _started[k] = (v as num).toInt());
      }
    } catch (_) {}
    try {
      final p = await Prefs.getInstance();
      newPerDay = p.getInt('review_new_per_day') ?? 20;
      direction = ReviewDirection.values[p.getInt('review_direction') ?? 0];
      reminderMinutes = p.getInt('review_reminder');
    } catch (_) {}
    _loaded = true;
    changes.value++;
  }

  ReviewItem item(String id) => items.putIfAbsent(id, () => ReviewItem(id));
  ReviewItem? peek(String id) => items[id];
  int get startedToday => _started[engine.today] ?? 0;

  TodayPlan plan(List<ReviewCandidate> candidates) =>
      engine.plan(items, candidates, newPerDay: newPerDay, startedToday: startedToday);

  /// 답 기록. retry = 같은 세션에서 다시 나온 카드.
  void answer(String id, bool ok, {bool retry = false}) {
    final it = item(id);
    if (it.isNew && !retry) _started[engine.today] = startedToday + 1;
    ok ? engine.correct(it, sameSessionRetry: retry) : engine.wrong(it);
    _changed();
  }

  void closeSession(Iterable<String> ids) {
    engine.closeSession(ids.map(item));
    _changed();
  }

  void markKnown(Iterable<String> ids) {
    var n = 0;
    for (final id in ids) {
      final it = item(id);
      if (it.isNew) engine.markKnown(it, spread: 1 + (n++ % ReviewEngine.intervalFor(ReviewEngine.knownLevel)));
    }
    _changed();
  }

  /// 옛 '알아요' 상태 이전 — 앱 업데이트 때 한 번(이미 한 적 있으면 건너뜀).
  Future<void> migrateKnownOnce(Iterable<String> ids) async {
    final p = await Prefs.getInstance();
    if (p.getBool('review_migrated_v1') ?? false) return;
    for (final id in ids) {
      engine.migrateKnown(item(id));
    }
    await p.setBool('review_migrated_v1', true);
    _changed();
  }

  void setHint(String id, String? hint) {
    item(id).hint = (hint == null || hint.trim().isEmpty) ? null : hint.trim().substring(0, min(hint.trim().length, 120));
    _changed();
  }

  void setImage(String id, String? path) {
    item(id).image = path;
    _changed();
  }

  Future<void> setNewPerDay(int n) async {
    newPerDay = n;
    (await Prefs.getInstance()).setInt('review_new_per_day', n);
    changes.value++;
  }

  Future<void> setDirection(ReviewDirection d) async {
    direction = d;
    (await Prefs.getInstance()).setInt('review_direction', d.index);
    changes.value++;
  }

  Future<void> setReminder(int? minutes) async {
    reminderMinutes = minutes;
    final p = await Prefs.getInstance();
    minutes == null ? p.remove('review_reminder') : p.setInt('review_reminder', minutes);
    changes.value++;
  }

  /// 통계(진도 화면용): 레벨별 개수
  Map<int, int> levelCounts() {
    final m = <int, int>{};
    for (final i in items.values) {
      m[i.level] = (m[i.level] ?? 0) + 1;
    }
    return m;
  }

  void _changed() {
    changes.value++;
    if (!autosave) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), save);
  }

  Future<void> save() async {
    final f = _file;
    if (f == null) return;
    // 지난 날짜 시작 기록은 30일만 남긴다
    final cut = engine.addDays(-30);
    _started.removeWhere((k, _) => k.compareTo(cut) < 0);
    final data = jsonEncode({'v': 1, 'items': items.map((k, v) => MapEntry(k, v.toJson())), 'started': _started});
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(data, flush: true);
    await tmp.rename(f.path);
  }

  /// 시험용 초기화
  @visibleForTesting
  void resetForTest(ReviewEngine e) {
    engine = e;
    items.clear();
    _started.clear();
    _loaded = false;
  }
}

int min(int a, int b) => a < b ? a : b;
