import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:chinese_universe/screens/sense_course_screen.dart';
import 'package:chinese_universe/services/grammar_steps.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => GrammarSteps.debugLoad = null);

  test('묶음 원고: 스텝 틀 15칸, 내용 있는 L1 만 보인다', () async {
    final idx = json.decode(await GrammarSteps.content(GrammarSteps.indexFile).then(json.encode)) as Map<String, dynamic>;
    expect((idx['steps'] as List).length, 15);
    final v = await GrammarSteps.visible();
    expect(v.map((s) => s.step), [1]);
    expect(v.single.file, 'grammar/lesson1.json');
  });

  test('서버 원고가 있으면 그것: 목록·제목을 덮어쓰고, 빈 스텝·없는 파일은 숨김, 15 넘어도 그린다', () async {
    final files = {
      'grammar/steps.json': json.encode({
        'steps': [
          {'step': 3, 'title': '서버 L3', 'file': 'grammar/lesson3.json'},
          {'step': 1, 'title': '서버 L1', 'subtitle': '새 설명', 'file': 'grammar/lesson1.json'},
          {'step': 2, 'title': '빈 스텝', 'file': 'grammar/lesson2.json'},
          {'step': 4, 'title': '파일 없음', 'file': 'grammar/lesson4.json'},
          {'step': 16, 'title': '열여섯', 'file': 'grammar/lesson16.json'},
        ],
      }),
      'grammar/lesson1.json': json.encode({'patterns': [{'id': 'p'}]}),
      'grammar/lesson2.json': json.encode({'patterns': [], 'stages': []}),
      'grammar/lesson3.json': json.encode({'stages': [{'n': 1}]}),
      'grammar/lesson16.json': json.encode({'sentences': [{'zh': '你好'}]}),
    };
    GrammarSteps.debugLoad = (rel) async => files[rel] ?? (throw StateError('없음 $rel'));
    final v = await GrammarSteps.visible();
    expect(v.map((s) => (s.step, s.title)), [(1, '서버 L1'), (3, '서버 L3'), (16, '열여섯')]);
    expect(v.first.subtitle, '새 설명');
  });

  test('서버 목록에서 스텝을 빼면 묶음에 파일이 있어도 안 보이고, 서버를 못 받으면 묶음 목록', () async {
    final lesson1 = await GrammarSteps.content('grammar/lesson1.json');
    GrammarSteps.debugLoad = (rel) async => rel == 'grammar/steps.json'
        ? json.encode({'steps': [{'step': 2, 'title': 'L2', 'file': 'grammar/lesson2.json'}]})
        : rel == 'grammar/lesson1.json' ? json.encode(lesson1) : json.encode({'patterns': [1]});
    expect((await GrammarSteps.visible()).map((s) => s.step), [2]);
    GrammarSteps.debugLoad = null; // 서버 판 없음 = 묶음 원고
    expect((await GrammarSteps.visible()).map((s) => s.step), [1]);
  });

  test('언어감각: 빈 회차·빈 급은 숨김, 급 수는 데이터대로', () {
    final d = SenseCourse.withoutEmpty({
      'levels': [
        {'id': 'L1', 'lessons': [{'id': 'a', 'sentences': [{'zh': '我'}]}, {'id': 'b', 'points': []}]},
        {'id': 'L2', 'lessons': [{'id': 'c', 'sentences': []}]},
        {'id': 'L15', 'lessons': [{'id': 'd', 'kind': 'ref', 'points': [{'tip': 't'}]}]},
      ],
    });
    final lv = (d['levels'] as List).cast<Map<String, dynamic>>();
    expect(lv.map((l) => l['id']), ['L1', 'L15']);
    expect((lv.first['lessons'] as List).length, 1);
  });
}
