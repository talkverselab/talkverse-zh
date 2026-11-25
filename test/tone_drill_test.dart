import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkverse_pitch/talkverse_pitch.dart';

import 'package:chinese_universe/screens/tone_drill_screen.dart';
import 'package:chinese_universe/services/dialogue_service.dart';
import 'package:chinese_universe/services/pitch_coach.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 저장소(Prefs)는 한 번 잡으면 그대로 쓰므로, 옛 키 옮기기 시험을 맨 먼저 둔다.
  test('연습 기록: 옛 키(접두 없음)를 zh_ 키로 옮기고 이어서 센다', () async {
    final today = DateTime.now();
    final old = DateTime(today.year, today.month, today.day - 1);
    String ymd(DateTime n) => '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
    SharedPreferences.setMockInitialValues({
      'zh__migrated_v1': true,
      'pitch_coach_days_v1': jsonEncode({'今天': [ymd(old)]}),
    });
    expect(await PitchCoach.instance.days('今天'), 1);
    await PitchCoach.instance.countPractice('今天');
    expect(await PitchCoach.instance.days('今天'), 2);
    final p = await SharedPreferences.getInstance();
    expect(p.containsKey('pitch_coach_days_v1'), isFalse);
    expect((jsonDecode(p.getString('zh_pitch_coach_days_v1')!) as Map)['今天'], hasLength(2));
  });

  test('자료: 조합 20 × 묶음 3 × 낱말 4, 낱말은 칸의 성조 그대로, 문장은 지금 회화 대사와 같고 기준 곡선이 있다', () async {
    SharedPreferences.setMockInitialValues({});
    final d = await PitchCoach.instance.data();
    await DialogueService.instance.ensureLoaded();
    expect(d.combos.length, 20);
    final seen = <String>{};
    for (final c in d.combos) {
      expect(c.rounds.length, 3, reason: c.cell);
      for (final r in c.rounds) {
        expect(r.words.length, 4);
        for (final w in r.words) {
          expect(w.zh.length, 2);
          expect('${w.tones[0]}-${w.tones[1]}', c.cell, reason: w.zh);
          expect(seen.add(w.zh), isTrue, reason: '겹침 ${w.zh}');
        }
        final s = r.sentence;
        final t = DialogueService.instance.byId(s.ep)!.turns.firstWhere((t) => t.num == s.turn);
        expect(s.zh, t.zh, reason: '${s.ep}#${s.turn} 옛 대사');
        expect(s.ref.st.length, 50);
      }
    }
    // 뒤 글자를 경성으로 읽는 낱말은 「앞-뒤 성조」 칸에 두지 않는다(11/25 재검토)
    for (final z in ['东西', '地方', '多少', '知道', '出来', '这里']) {
      expect(seen.contains(z), isFalse, reason: z);
    }
  });

  test('변조: 3성+3성 앞은 2성, 다른 성조 앞 3성은 반3성, 不+4성은 2성 — 이름·안내에 그대로', () {
    final a = surfaceTones([3, 3], hanzi: ['可', '以']);
    expect([surfaceLabel(a[0]), surfaceLabel(a[1])], ['3성 → 2성', '3성']);
    expect(sandhiNote(a, ['可', '以']), contains('2성으로 읽어요'));
    final b = surfaceTones([3, 1], hanzi: ['老', '师']);
    expect([surfaceLabel(b[0]), surfaceLabel(b[1])], ['반3성(낮게)', '1성']);
    expect(sandhiNote(b, ['老', '师']), contains('반3성'));
    final c = surfaceTones([4, 4], hanzi: ['不', '用']);
    expect(surfaceLabel(c[0]), '4성 → 2성');
    expect(sandhiNote(c, ['不', '用']), contains('bú'));
    final d = surfaceTones([1, 3], hanzi: ['机', '场']);
    expect([surfaceLabel(d[0]), surfaceLabel(d[1])], ['1성', '3성']);
    expect(sandhiNote(d, ['机', '场']), isNull);
    expect(surfaceLabel(surfaceTones([4, 0])[1]), '경성');
    expect(comboReading('3-3'), contains('2성 3성'));
    expect(comboReading('1-3'), isNull);
  });

  testWidgets('화면: 조합 20칸이 뜨고, 묶음 화면이 채운 그래프로 그려진다', (t) async {
    SharedPreferences.setMockInitialValues({});
    // 테스트 환경에는 기기 TTS 가 없다 — 채널만 받아 준다
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => c.method == 'getVoices' ? [] : 1);
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() => PitchCoach.instance.data());
    await t.pumpWidget(const MaterialApp(home: ToneDrillHubScreen()));
    for (var i = 0; i < 10; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await t.pump();
    }
    expect(find.text('준비: 한 글자 성조'), findsOneWidget);
    final d = await t.runAsync(() => PitchCoach.instance.data());
    final key = GlobalKey();
    await t.pumpWidget(MaterialApp(
      home: RepaintBoundary(key: key, child: ToneRoundScreen(title: '4-1', round: d!.combos[15].rounds[0], onNext: () {})),
    ));
    await t.pump(const Duration(milliseconds: 300));
    expect(t.takeException(), isNull);
    expect(find.byKey(const ValueKey('target-graph')), findsOneWidget); // 말하기 전에도 목표 곡선이 보인다
    expect(find.byKey(const ValueKey('sandhi-note')), findsNothing); // 4성 1성은 변조 없음
    final out = Platform.environment['TONE_SHOT'];
    if (out != null) {
      await t.runAsync(() async {
        final img = await (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio: 2);
        final b = await img.toByteData(format: ui.ImageByteFormat.png);
        File(out).writeAsBytesSync(b!.buffer.asUint8List());
      });
    }
  });
}
