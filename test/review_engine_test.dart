import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chinese_universe/review/review_engine.dart';
import 'package:chinese_universe/review/review_service.dart';
import 'package:chinese_universe/review/review_ui.dart';

void main() {
  var day = DateTime(2026, 11, 2, 10);
  final e = ReviewEngine(clock: () => day);

  test('맞음: 레벨별 간격 1·2·4·8·16·32·64 → 졸업 128', () {
    final it = ReviewItem('deck:1');
    final got = <int>[];
    for (var i = 0; i < 8; i++) {
      e.correct(it);
      got.add(DateTime.parse(it.due).difference(DateTime(2026, 11, 2)).inDays);
    }
    expect(got, [1, 2, 4, 8, 16, 32, 64, 128]);
    expect(it.graduated, isTrue);
  });

  test('틀림: 레벨 1·오늘 due, 재출제 맞음은 레벨 그대로 내일', () {
    final it = ReviewItem('deck:2', level: 4, due: '2026-11-02');
    e.wrong(it);
    expect(it.level, 1);
    expect(it.due, '2026-11-02');
    expect(it.lapses, 1);
    e.correct(it, sameSessionRetry: true);
    expect(it.level, 1);
    expect(it.due, '2026-11-03');
  });

  test('세션 끝에 또 틀려 남은 카드는 내일로', () {
    final it = ReviewItem('deck:3', level: 2, due: '2026-11-02');
    e.wrong(it);
    e.closeSession([it]);
    expect(it.due, '2026-11-03');
  });

  test('오늘 계획: 복습은 높은 레벨부터, 새 카드 상한·범주·동음 하루 1개', () {
    final items = {
      'a': ReviewItem('a', level: 2, due: '2026-11-01'),
      'b': ReviewItem('b', level: 6, due: '2026-11-02'),
      'c': ReviewItem('c', level: 3, due: '2026-11-05'), // 아직
    };
    final cands = [
      for (var i = 0; i < 10; i++) ReviewCandidate('n$i', category: i < 4 ? 'food' : null, soundKey: i == 5 || i == 6 ? 'kami' : null),
    ];
    final p = e.plan(items, cands, newPerDay: 5, rng: Random(1));
    expect(p.review, ['b', 'a']);
    expect(p.fresh.length, 5);
    expect(p.fresh.where((x) => ['n0', 'n1', 'n2', 'n3'].contains(x)).length, lessThanOrEqualTo(1));
    expect(p.fresh.where((x) => ['n5', 'n6'].contains(x)).length, lessThanOrEqualTo(1));
    final p2 = e.plan(items, cands, newPerDay: 5, startedToday: 4, rng: Random(1));
    expect(p2.fresh.length, 1);
  });

  test('빠른 분류·옛 알아요 이전', () {
    final a = ReviewItem('x'), b = ReviewItem('y');
    e.markKnown(a);
    e.migrateKnown(b);
    expect(a.level, 5);
    expect(b.level, 3);
    expect(b.due, '2026-11-06');
  });

  test('서비스: 저장·다시 읽기·하루 시작 수', () async {
    SharedPreferences.setMockInitialValues({});
    final dir = await Directory.systemTemp.createTemp('rv');
    final f = File('${dir.path}/review_items.json');
    final s = ReviewService.instance..resetForTest(ReviewEngine(clock: () => day));
    s.autosave = true;
    await s.load(file: f);
    s.answer('deck:1', true);
    s.answer('deck:2', false);
    s.setHint('deck:2', '  고양이 = 네코  ');
    expect(s.startedToday, 2);
    await s.save();
    s.resetForTest(ReviewEngine(clock: () => day));
    await s.load(file: f);
    expect(s.peek('deck:1')!.level, 1);
    expect(s.peek('deck:2')!.hint, '고양이 = 네코');
    expect(s.startedToday, 2);
  });

  testWidgets('세션 화면: 정답 보기 → 틀림 → 끝에 다시 → 맞음 → 요약', (t) async {
    SharedPreferences.setMockInitialValues({});
    final dir = (await t.runAsync(() => Directory.systemTemp.createTemp("rv2")))!;
    final s = ReviewService.instance..resetForTest(ReviewEngine(clock: () => day))..autosave = false;
    await t.runAsync(() => s.load(file: File('${dir.path}/r.json')));
    final faces = {'deck:a': const ReviewFace(prompt: '고양이', target: '猫', reading: '네코')};
    await t.pumpWidget(MaterialApp(home: ReviewSessionScreen(ids: const ['deck:a'], resolve: (id) => faces[id])));
    expect(find.text('고양이'), findsOneWidget);
    await t.tap(find.text('정답 보기'));
    await t.pump();
    expect(find.text('猫'), findsOneWidget);
    await t.tap(find.text('틀림'));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('2 / 2'), findsOneWidget);
    await t.tap(find.text('정답 보기'));
    await t.pump();
    await t.tap(find.text('맞음'));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('오늘 카드 끝!'), findsOneWidget);
    expect(s.peek('deck:a')!.level, 1);
    expect(s.peek('deck:a')!.due, '2026-11-03');
  });
}
