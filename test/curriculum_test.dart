import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chinese_universe/screens/curriculum_screen.dart';
import 'package:chinese_universe/services/curriculum_service.dart';
import 'package:chinese_universe/services/dialogue_service.dart';

Dialogue _ep(String id, String island, int n) => Dialogue.fromJson({
      'id': id,
      'region': 'R1',
      'island': island,
      'title': id,
      'turns': [
        for (var i = 1; i <= n; i++)
          {
            'num': i,
            'speaker': i.isOdd ? 'A' : 'B',
            'zh': '我们$id第$i句话吃饭',
            'pinyin': 'p$i',
            'ko': '$id 뜻 $i',
            'lemmas': [
              ['我们', '我们', 'wǒmen'],
              ['吃饭', '吃饭', 'chīfàn'],
              ['句话$i$id', '句话', 'jùhuà'],
            ],
          },
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('점수: 소수점 버림, 80% 경계', () {
    expect(scorePercent(4, 5), 80);
    expect(isPass(4, 5), isTrue);
    expect(scorePercent(23, 29), 79); // 79.31 → 79
    expect(isPass(23, 29), isFalse);
    expect(isPass(24, 30), isTrue); // 정확히 80
    expect(isPass(7, 9), isFalse); // 77
    expect(isPass(0, 0), isFalse);
  });

  test('간격 반복: 1일 → 3일 → 7일 → 졸업, 틀리면 1일로', () {
    final s = CurriculumState();
    const id = 'ep#1';
    s.grade(id, true, '2026-11-22'); // 처음 = 대기열에 1일 뒤
    expect(s.review.single.due, '2026-11-23');
    s.grade(id, true, '2026-11-23');
    expect((s.review.single.due, s.review.single.step), ('2026-11-26', 1));
    s.grade(id, false, '2026-11-26');
    expect((s.review.single.due, s.review.single.step), ('2026-11-27', 0));
    s.grade(id, true, '2026-11-27');
    s.grade(id, true, '2026-11-30');
    expect((s.review.single.due, s.review.single.step), ('2026-12-07', 2)); // 달 넘김
    s.grade(id, true, '2026-12-07');
    expect(s.review, isEmpty);
    expect(addDays('2026-12-31', 1), '2027-01-01');
    expect(addDays('2027-03-01', -1), '2027-02-28');
  });

  test('코스: 연습 → 시험 80% 미만이면 틀린 편만 다시, 통과면 편 통과', () {
    final s = CurriculumState(level: 'R1', dailyGoal: 'light');
    s.course = Course(id: 'c', dialogueIds: ['a', 'b']);
    s.practiceDone('a', ['a#1', 'a#2'], {'a#2'}, '2026-11-22');
    expect(s.todayNew, 1);
    expect(s.review.length, 2);
    expect(s.doneToday('2026-11-22'), isTrue); // 가볍게 = 새 편 1, 밀린 복습 없음
    expect(s.streakCount, 1);
    s.practiceDone('b', ['b#1'], {}, '2026-11-22');
    expect(s.course!.allPracticed, isTrue);
    expect(s.examDone(7, 10, {'b'}, '2026-11-22'), isFalse);
    expect(s.course!.practiced, ['a']);
    expect(s.course!.examScores, [70]);
    s.practiceDone('b', ['b#1'], {}, '2026-11-22');
    expect(s.examDone(8, 10, {}, '2026-11-22'), isTrue);
    expect(s.course!.passedAt, '2026-11-22');
    expect(s.passedDialogues, ['a', 'b']);
    // 다음 날 복습이 밀려 있으면 오늘 분량이 남는다, 연속 일수는 이어진다
    expect(s.dueOn('2026-11-23').length, 3);
    expect(s.doneToday('2026-11-23'), isFalse);
    for (final id in ['a#1', 'a#2', 'b#1']) {
      s.reviewDone(id, true, '2026-11-23');
    }
    expect(s.dueOn('2026-11-23'), isEmpty);
    expect(s.newLeft('2026-11-23'), 1);
    s.course = Course(id: 'c2', dialogueIds: ['c']);
    s.practiceDone('c', ['c#1'], {}, '2026-11-23');
    expect(s.streakCount, 2);
    expect(s.streakShown('2026-11-25'), 0);
  });

  test('저장 형식 왕복(curriculum_v1)', () {
    final s = CurriculumState(level: 'R2', dailyGoal: 'focus', course: Course(id: 'x', dialogueIds: ['a'], practiced: ['a'], examScores: [90], passedAt: '2026-11-22')
, passedDialogues: ['a'], review: [ReviewItem('a#1', '2026-11-23', 1)], streakCount: 3, streakLastDay: '2026-11-22');
    final j = json.decode(json.encode(s.toJson())) as Map<String, dynamic>;
    expect(j.keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
    expect((j['course'] as Map).keys, containsAll(['id', 'dialogueIds', 'practiced', 'examScores', 'passedAt']));
    final b = CurriculumState.fromJson(j);
    expect((b.level, b.dailyGoal, b.course!.examScores.join(','), b.review.single.step, b.streakCount), ('R2', 'focus', '90', 1, 3));
    expect(CurriculumService.prefKey, 'curriculum_v1');
  });

  test('문제: 편 줄 수만큼 최대 10, 보기 4개 · 정답 하나, 시험은 편당 3 이상 최대 30', () {
    final pool = [for (var i = 0; i < 12; i++) _ep('e$i', DialogueService.islands[i % 8], 6 + i)];
    final rnd = Random(1);
    final q6 = practiceQuestions(pool[0], pool, rnd: rnd);
    expect(q6.length, 6);
    final q17 = practiceQuestions(pool[11], pool, rnd: rnd);
    expect(q17.length, 10);
    for (final q in [...q6, ...q17]) {
      expect(q.options.length, 4);
      expect(q.options.toSet().length, 4);
      expect(q.answer, inInclusiveRange(0, 3));
      if (q.kind == 'blank') expect(q.prompt, contains('＿＿'));
    }
    expect(q17.any((q) => q.kind == 'blank'), isTrue);
    expect(examQuestions(pool.take(3).toList(), pool, rnd: rnd).length, 21); // 6+7+8 ≤ 편당 10
    expect(examQuestions(pool.take(10).toList(), pool, rnd: rnd).length, 30);
  });

  test('추천으로 채우기: 통과한 편 빼고, 주제가 겹치지 않게', () {
    final list = [_ep('a1', 'love', 2), _ep('a2', 'love', 2), _ep('b1', 'work', 2), _ep('c1', 'life', 2), _ep('c2', 'life', 2)];
    final r = recommend(list, {'b1'}, [], 3);
    expect(r, ['a1', 'c1', 'a2']);
    expect(recommend(list, {}, ['a1'], 3), ['a1', 'b1', 'c1']);
  });

  testWidgets('홈 카드: 처음이면 안내, 커리큘럼 화면은 레벨 고르기부터', (tester) async {
    CurriculumService.instance.debugReset();
    DialogueService.instance.debugSetDialogues([for (var i = 0; i < 6; i++) _ep('e$i', 'love', 4)]);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CurriculumHomeCard())));
    await tester.pumpAndSettle();
    expect(find.text('토크버스 커리큘럼'), findsOneWidget);
    await tester.tap(find.byType(CurriculumHomeCard));
    await tester.pumpAndSettle();
    expect(find.text('레벨 고르기'), findsOneWidget);
    await tester.tap(find.textContaining('R1'));
    await tester.pumpAndSettle();
    expect(find.text('추천으로 채우기'), findsOneWidget);
    await tester.tap(find.text('추천으로 채우기'));
    await tester.pump();
    expect(find.text('5/5 고름'), findsOneWidget);
  });
}
