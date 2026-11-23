import 'package:chinese_universe/screens/sense_course_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_universe/data/entitlement.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 과정 데이터 읽기가 실제 비동기로 돈다 — pumpAndSettle 대신 실제 시간으로 기다린다(일본어앱 시험과 같은 꼴).
Future<void> settle(WidgetTester t, Finder until) async {
  for (var i = 0; i < 100 && until.evaluate().isEmpty; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump();
  }
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final w in const [320.0, 900.0]) {
    testWidgets('언어감각 목록 폭 $w — 급마다 외울 대화 1회 + 참고, 넘침 없음', (t) async {
      t.view.physicalSize = Size(w, 6000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: SenseCourseScreen()));
      await settle(t, find.text('L1  어순 익히기 (동사가 먼저)'));
      expect(t.takeException(), isNull);
      for (var n = 1; n <= 10; n++) {
        expect(find.byKey(ValueKey('sense-L$n-talk')), findsOneWidget);
        expect(find.byKey(ValueKey('sense-L$n-ref')), findsOneWidget);
      }
      expect(find.text('0/10회 마침'), findsOneWidget);
    });
  }

  testWidgets('암기 회차 — 영상 없으면 칸 숨김·안내, 색 표시가 글자에 안 남음, 마침 → 참고를 건너뛰고 L2', (t) async {
    await Entitlement.set(true); // L2 는 이용권(PAYWALL_SPEC) — 이 시험은 다음 급으로 넘어가는 흐름을 본다
    addTearDown(() => Entitlement.set(false));
    t.view.physicalSize = const Size(320, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: SenseLessonScreen(index: 0)));
    await settle(t, find.byKey(const ValueKey('sense-finish')));
    expect(t.takeException(), isNull);
    expect(find.byKey(const ValueKey('memorize-video')), findsNothing); // 영상이 비어 있으면 칸을 숨긴다(11/22)
    expect(find.textContaining('일부러 어순을 설명하지 않았어요'), findsOneWidget);
    expect(find.textContaining('{', findRichText: true), findsNothing);
    expect(plainMarked('我{喝|1}{咖啡|2}'), '我喝咖啡');
    await t.tap(find.byKey(const ValueKey('sense-finish')));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(await SenseCourse.done(), contains('L1-talk'));
    expect(find.textContaining('钱包', findRichText: true), findsWidgets);
  });

  testWidgets('참고 — 닫기는 기록 안 함', (t) async {
    t.view.physicalSize = const Size(320, 8000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: SenseLessonScreen(index: 1)));
    await settle(t, find.text('닫기'));
    expect(t.takeException(), isNull);
    expect(find.text('문장 + 吗？'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('sense-finish')));
    await t.pump(const Duration(milliseconds: 300));
    expect(await SenseCourse.done(), isNot(contains('L1-ref')));
  });
}
