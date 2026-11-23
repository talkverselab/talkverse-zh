import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chinese_universe/screens/curriculum_screen.dart';
import 'package:chinese_universe/services/curriculum_service.dart';
import 'package:chinese_universe/services/dialogue_service.dart';

Dialogue _d(String id, String island, int n) => Dialogue.fromJson({
      'id': id,
      'region': 'R1',
      'island': island,
      'turns': [
        for (var i = 1; i <= n; i++) {'num': i, 'speaker': i.isOdd ? 'A' : 'B', 'zh': '文$id$i', 'ko': '뜻$id$i'}
      ],
    });

void main() {
  planTests();
  group('점수 80% 경계', () {
    test('소수점 버림', () {
      expect(scorePercent(7, 9), 77);
      expect(scorePercent(2, 3), 66);
      expect(scorePercent(0, 0), 0);
    });
    test('80% 이상만 통과', () {
      expect(isPass(8, 10), isTrue);
      expect(isPass(79, 100), isFalse);
      expect(isPass(4, 5), isTrue);
      expect(isPass(23, 29), isFalse); // 79.3 → 79
      expect(isPass(24, 30), isTrue);
    });
    test('시험 기록 — 통과면 편 통과, 아니면 틀린 편 연습 다시', () {
      final st = CurriculumState(course: Course('c', ['a', 'b'], practiced: ['a', 'b']));
      expect(st.recordExam(7, 10, {'b'}, '2026-11-22'), isFalse);
      expect(st.course!.practiced, ['a']);
      expect(st.passedDialogues, isEmpty);
      st.course!.practiced.add('b');
      expect(st.recordExam(8, 10, {}, '2026-11-23'), isTrue);
      expect(st.course!.passedAt, '2026-11-23');
      expect(st.passedDialogues, ['a', 'b']);
      expect(st.course!.examScores, [70, 80]);
    });
  });

  group('간격 반복 날짜', () {
    test('1일 → 3일 → 7일 → 졸업', () {
      final st = CurriculumState();
      st.enqueue('x#1', '2026-11-22');
      expect(st.review.single.due, '2026-11-23');
      st.grade('x#1', true, '2026-11-23');
      expect(st.review.single.due, '2026-11-26');
      st.grade('x#1', true, '2026-11-26');
      expect(st.review.single.due, '2026-12-03');
      st.grade('x#1', true, '2026-12-03');
      expect(st.review, isEmpty);
    });
    test('틀리면 1일 뒤 처음 간격으로', () {
      final st = CurriculumState();
      st.enqueue('x#1', '2026-11-22');
      st.grade('x#1', true, '2026-11-23');
      st.grade('x#1', false, '2026-11-26');
      expect(st.review.single.step, 0);
      expect(st.review.single.due, '2026-11-27');
    });
    test('달·해 넘김', () {
      expect(addDays('2026-12-30', 3), '2027-01-02');
      expect(addDays('2028-02-28', 1), '2028-02-29');
    });
  });

  group('하루 분량·연속', () {
    test('새 편 목표를 채우고 복습이 없으면 끝, 연속 일수', () {
      final st = CurriculumState(dailyGoal: 1, course: Course('c', ['a', 'b']));
      expect(st.dayDone('2026-11-22'), isFalse);
      st.markPracticed('a', [1, 2], '2026-11-22');
      expect(st.dayDone('2026-11-22'), isTrue);
      expect(st.streakShown('2026-11-22'), 1);
      // 다음 날: 복습 2줄 + 새 편 1
      expect(st.dueReview('2026-11-23').length, 2);
      st.grade('a#1', true, '2026-11-23');
      st.grade('a#2', true, '2026-11-23');
      st.markPracticed('b', [1], '2026-11-23');
      expect(st.todayReview, 2);
      expect(st.streakShown('2026-11-23'), 2);
      expect(st.streakShown('2026-11-25'), 0);
    });
    test('저장 형식 왕복', () {
      final st = CurriculumState(level: 'R1', course: Course('c', ['a']));
      st.markPracticed('a', [1], '2026-11-22');
      final back = CurriculumState.fromJson(st.toJson());
      expect(back.toJson(), st.toJson());
      expect(st.toJson().keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
    });
  });

  group('문제·추천', () {
    test('편마다 줄 수만큼, 최대 10, 보기 4개 중 정답 1', () {
      final a = _d('a', 'friends', 12), b = _d('b', 'life', 4);
      final qs = buildQuestions(a, limit: 10, pool: [b]);
      expect(qs.length, 10);
      for (final q in qs) {
        expect(q.choices.length, 4);
        expect(q.choices.toSet().length, 4);
        expect(q.choices[q.answer], '뜻a${q.turn}');
      }
      expect(buildQuestions(b, limit: 10, pool: [a]).length, 4);
    });
    test('시험 문제 수: 편당 최소 3, 전체 최대 30', () {
      expect(examPerDialogue(3), 10);
      expect(examPerDialogue(5), 6);
      expect(examPerDialogue(10), 3);
    });
    test('추천 = 안 한 편, 주제 겹치지 않게', () {
      final list = [_d('f1', 'friends', 2), _d('f2', 'friends', 2), _d('l1', 'life', 2), _d('w1', 'work', 2)];
      final r = recommend(list, {'l1'}, {}, 3);
      expect(r, ['f1', 'w1', 'f2']);
    });
  });

  testWidgets('시험 화면 — 고르고 결과까지', (t) async {
    final a = _d('a', 'friends', 5);
    final qs = buildQuestions(a, limit: 2);
    await t.pumpWidget(MaterialApp(home: CurriculumQuizScreen(title: 'T', questions: qs, mode: QuizMode.exam)));
    for (var i = 0; i < 2; i++) {
      await t.tap(find.text(qs[i].choices[qs[i].answer]));
      await t.pump();
      await t.tap(find.byType(FilledButton).last);
      await t.pump();
    }
    expect(find.textContaining('100'), findsOneWidget);
  });

  for (final w in [300.0, 390.0]) {
    testWidgets('코스 고르기 줄 — 폭 $w 에서 넘치지 않음', (t) async {
      await t.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: SizedBox(width: w, child: CoursePickBar(count: 5, onCount: (_) {}, onRecommend: () {})))),
      ));
      expect(t.takeException(), isNull);
      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });
  }
}

// ── §12 단계·HSK 준비(서버 판) ──
const _plan = '''{"rev": 1, "stages": [
  {"n": 1, "title": "1단계", "dialogueIds": ["a1", "a2", "없는편"]},
  {"n": 2, "title": "2단계", "dialogueIds": ["없는편"]},
  {"n": 3, "title": "3단계", "dialogueIds": ["b1"]}],
 "prep": [{"id": "hsk", "title": "HSK 준비", "levels": [{"id": "HSK1", "title": "HSK 1급", "dialogueIds": ["a1"]}, {"id": "HSK2", "title": "HSK 2급", "dialogueIds": []}]}]}''';

void planTests() {
  test('§12 덧붙임: 판의 pick·pass·daily 를 읽고, 없으면 3·5·10 / 80 / 1·2·3 — 통과 판정에 pass 를 씀', () {
    final p = CurriculumPlan.parse('{"rev":1,"stages":[{"n":1,"title":"1단계","dialogueIds":["a1"],"pick":[2,4],"pass":70,"daily":{"light":2,"normal":4,"focus":6}},{"n":2,"dialogueIds":["a2"]}]}')!;
    final a = p.stages.first, b = p.stages.last;
    expect((a.pick.join(','), a.pass, a.daily.toString()), ('2,4', 70, {1: 2, 2: 4, 3: 6}.toString()));
    expect((b.pick.join(','), b.pass, b.daily.toString(), b.title), ('3,5,10', 80, {1: 1, 2: 2, 3: 3}.toString(), '2단계'));
    final st = CurriculumState(level: '1')
      ..dailyMap = a.daily
      ..passPercent = a.pass
      ..course = Course('c', ['x']);
    expect(st.newLeft('2026-11-23'), 4); // 보통 = 판의 normal 4
    expect(st.recordExam(7, 10, {}, '2026-11-23'), isTrue); // 70점 = 이 단계 통과
    st.passPercent = 80;
    st.course = Course('c2', ['y']);
    expect(st.recordExam(7, 10, {'y'}, '2026-11-23'), isFalse);
  });

  test('§12 HSK 단어 섞기: 서버 wordMix(없으면 0.5) 비율, 상한 30, 단어 문제는 편 id 없음', () {
    final p = CurriculumPlan.parse(_plan.replaceFirst('"dialogueIds": ["a1"]}', '"dialogueIds": ["a1"], "wordSet": "hsk1", "wordMix": 0.25}'))!;
    expect((p.prepLevels.first.wordSet, p.prepLevels.first.wordMix, p.prepLevels.last.wordMix), ('hsk1', 0.25, 0.5));
    final words = [for (var i = 0; i < 40; i++) (zh: '词$i', rd: 'c$i', ko: '뜻$i')];
    final dq = [for (var i = 0; i < 10; i++) CurQuestion('d$i', 1, 'meaning', '你好', '', const ['a', 'b', 'c', 'd'], 0)];
    final m = mixWords(dq, words, 0.5, seed: 1);
    expect(m.length, 20);
    final w = m.where((q) => q.kind == 'word').toList();
    expect(w.length, 10);
    expect(w.every((q) => q.dialogueId.isEmpty && q.choices.toSet().length == 4 && q.choices[q.answer] == '뜻${q.prompt.substring(1)}'), isTrue);
    final big = mixWords([...dq, ...dq, ...dq], words, 0.5, seed: 2);
    expect((big.length, big.where((q) => q.kind == 'word').length), (30, 15));
    expect(mixWords(dq, words, 0, seed: 3).length, 10);
    expect(mixWords(dq, words.take(3).toList(), 0.5).length, 10); // 단어가 모자라면 안 섞음
  });

  test('§12 판: 앱에 없는 편은 건너뛰고, 편 없는 단계·급수는 숨김, 옛 R 값은 단계로', () {
    final p = CurriculumPlan.parse(_plan)!;
    expect(p.stages.map((u) => u.key), ['1', '2', '3']);
    expect(p.prepLevels.map((u) => u.key), ['HSK1', 'HSK2']);
    expect(CurriculumPlan.parse('{"stages": []}'), isNull);
    expect(CurriculumPlan.parse('깨진 JSON'), isNull);
    expect([stageOfRegion('R0'), stageOfRegion('R1'), stageOfRegion('R4'), stageOfRegion('3')], ['1', '1', '4', '3']);
    final svc = CurriculumService.instance;
    DialogueService.instance.debugSetDialogues([
      for (final id in ['a1', 'a2', 'b1'])
        Dialogue.fromJson({'id': id, 'region': 'R1', 'title': id, 'turns': [{'num': 1, 'speaker': 'A', 'zh': '你好', 'ko': '안녕'}]}),
    ]);
    svc.plan = p;
    expect(svc.stageKeys, ['1', '3']);
    expect(svc.levelList('1').map((d) => d.id), ['a1', 'a2']);
    expect(svc.prepKeys, ['HSK1']);
    expect(svc.prepTitle, 'HSK 준비');
    expect(svc.unitTitle('3'), '3단계');
    expect(svc.nextLevel('1'), '3');
    expect(svc.nextLevel('HSK1'), isNull);
    svc.plan = null;
    expect(svc.unitTitle('R1'), 'R1 초보');
  });

  test('§12 서버 판: rev 가 더 높을 때만 바꿔 씀, 서버 없으면 그대로', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = CurriculumService.instance;
    svc.plan = CurriculumPlan.parse(_plan);
    svc.debugFetch = (_) async => null;
    expect(await svc.refreshPlan(), isFalse);
    svc.debugFetch = (_) async => _plan; // 같은 rev
    expect(await svc.refreshPlan(), isFalse);
    svc.debugFetch = (_) async => _plan.replaceFirst('"rev": 1', '"rev": 2').replaceFirst('"3단계"', '"새 3단계"');
    expect(await svc.refreshPlan(), isTrue);
    expect(svc.unitTitle('3'), '새 3단계');
    svc.debugFetch = null;
    svc.plan = null;
  });
}
