import 'package:chinese_universe/screens/hanzi_practice_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('한자 연습 — 공용 DB 가 비어도 목록 화면이 뜬다', (t) async {
    t.view.physicalSize = const Size(320, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: KanjiPracticeScreen()));
    for (var i = 0; i < 50 && find.byKey(const ValueKey('kp-review')).evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await t.pump();
    }
    expect(t.takeException(), isNull);
    expect(find.byKey(const ValueKey('kp-review')), findsOneWidget);
  });

  testWidgets('하루 화면 — 패밀리 보기 → 문제 → 마침 기록', (t) async {
    t.view.physicalSize = const Size(320, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    KanjiPractice.roots = const ['青', '马', '巴', '方'];
    await t.pumpWidget(const MaterialApp(home: KanjiPracticeDayScreen(day: 1, families: [KFamily('青', 'qīng', '청', ['请', '情', '晴'])])));
    await t.pump();
    expect(find.text('「青」 패밀리'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('kp-action')));
    await t.pump();
    for (var q = 0; q < 3; q++) {
      await t.tap(find.byKey(const ValueKey('kp-opt-青')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('kp-next')));
      await t.pump();
    }
    expect(find.text('3문제 중 3개 맞힘'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('kp-action')));
    await t.pump();
    expect(await KanjiPractice.done(), contains('1'));
  });
}
