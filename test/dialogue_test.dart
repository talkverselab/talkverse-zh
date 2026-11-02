import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chinese_universe/screens/dialogue_screen.dart';
import 'package:chinese_universe/services/dialogue_service.dart';

final _latin = RegExp(r'[A-Za-zāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜü]');

Dialogue _ep(String id, String region) => Dialogue.fromJson({
      'id': id,
      'region': region,
      'island': 'love',
      'kind': 'long',
      'title': id,
      'scene': 'scene',
      'speakers': {'A': 'A', 'B': 'B'},
      'turns': [
        {'num': 1, 'speaker': 'A', 'zh': '你好！', 'pinyin': 'Nǐ hǎo!', 'ko': '안녕!'},
        {'num': 2, 'speaker': 'B', 'zh': '谢谢。', 'pinyin': 'Xièxie.', 'ko': '고마워.', 'rd': '셰셰.'},
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('회화 애셋: R 폴더 편을 읽고, 독음(rd)을 병음에서 만든다', () async {
    final svc = DialogueService.instance;
    await svc.ensureLoaded();
    expect(svc.all.length, greaterThan(100));
    expect(svc.count('R0'), 0);
    expect(svc.count('R1'), 0);
    // R0·R1 이 비어 있으면 편이 있는 가장 낮은 레벨부터
    expect(svc.startLevel, 'R2');
    var turns = 0, bad = <String>[];
    for (final d in svc.all) {
      for (final t in d.turns) {
        turns++;
        expect(t.zh, isNotEmpty);
        if (t.rd.isEmpty || _latin.hasMatch(t.rd)) bad.add('${d.id}#${t.num}: ${t.pinyin} → ${t.rd}');
      }
    }
    // 병음을 음절로 못 나눈 줄은 원문이 남는다 — 거의 없어야 한다
    expect(bad.length, lessThan(turns ~/ 100), reason: bad.take(10).join('\n'));
  });

  test('턴: rd 가 있으면 그대로, 없으면 병음에서', () {
    final d = _ep('x', 'R2');
    expect(d.turns[0].rd, '니 하오!');
    expect(d.turns[1].rd, '셰셰.');
  });

  testWidgets('빈 레벨은 「준비 중」, 오늘의 컷은 편이 있는 레벨에서', (tester) async {
    DialogueService.instance.debugSetDialogues([_ep('r3_love_t1', 'R3')]);
    await tester.pumpWidget(const MaterialApp(home: DialogueHomeScreen()));
    await tester.pump();
    expect(find.textContaining('준비 중'), findsWidgets); // R1(사용자 모드)·R2·R4 는 비어 있음
    expect(find.text('오늘의 컷'), findsOneWidget);
    expect(find.textContaining('r3_love_t1'), findsWidgets);
    await tester.pump(const Duration(seconds: 1));
  });
}
