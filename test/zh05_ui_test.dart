import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chinese_universe/core/theme.dart';
import 'package:chinese_universe/screens/font_licenses_screen.dart';
import 'package:chinese_universe/services/dialogue_service.dart';
import 'package:chinese_universe/services/hanzi_family.dart';
import 'package:chinese_universe/services/ko_reading.dart';
import 'package:chinese_universe/services/pinyin_hangul.dart';
import 'package:chinese_universe/services/shared_hanja_service.dart';
import 'package:chinese_universe/widgets/episode_play_pane.dart';
import 'package:chinese_universe/widgets/selectable_hanzi.dart';
import 'package:chinese_universe/widgets/tone_pinyin.dart';

/// 시안 zh05(2026-11-03) — 성조 색 병음 · 발음부 가족 구리 테두리 규칙 · 리더의 접힌 줄.

Dialogue _ep() => Dialogue.fromJson({
      'id': 'r3_life_zz',
      'region': 'R3',
      'island': 'life',
      'kind': 'long',
      'title': 'zz',
      'scene': 'scene',
      'speakers': {'A': 'Mark', 'B': '小丽'},
      'turns': [
        {'num': 1, 'speaker': 'B', 'zh': '你起床了没？', 'pinyin': 'Nǐ qǐchuáng le méi?', 'ko': '일어났어?'},
        {'num': 2, 'speaker': 'A', 'zh': '起了起了。', 'pinyin': 'Qǐ le qǐ le.', 'ko': '일어났어 일어났어.'},
        {'num': 3, 'speaker': 'B', 'zh': '骗人！', 'pinyin': 'Piàn rén!', 'ko': '거짓말!'},
        {'num': 4, 'speaker': 'A', 'zh': '好吧。', 'pinyin': 'Hǎo ba.', 'ko': '알았어.'},
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('성조 색 병음', () {
    test('붙여 쓴 낱말도 음절마다 성조', () {
      final runs = pinyinRuns('Nǐ qǐchuáng le méi?').where((r) => r.$2 != null).toList();
      expect(runs.map((r) => r.$1), ['Nǐ', 'qǐ', 'chuáng', 'le', 'méi']);
      expect(runs.map((r) => r.$2), [3, 3, 2, 0, 2]);
    });

    test('한 음절에 성조 부호는 하나 · 얼화 r 은 마지막 음절에', () {
      expect(PinyinHangul.splitSyllables('Xīān'), ['Xī', 'ān']);
      expect(PinyinHangul.splitSyllables('yìdiǎnr'), ['yì', 'diǎnr']);
      expect(PinyinHangul.splitSyllables('xyz'), isNull);
    });

    test('문장부호·공백은 색 없음', () {
      final runs = pinyinRuns('Hǎo, ba.');
      expect(runs.where((r) => r.$2 == null).map((r) => r.$1).join(), ', .');
    });
  });

  group('발음부 가족', () {
    test('같은 소리 = 음절이 같으면(성조는 달라도)', () {
      expect(sameSound('qíng', 'qīng'), isTrue);
      expect(sameSound('qīng', 'qīng'), isTrue);
      expect(sameSound('cāi', 'qīng'), isFalse);
      expect(sameSound('', 'qīng'), isFalse);
    });

    test('공용 DB 색인에서 글자의 가족을 찾는다(발음부 자신도)', () {
      final idx = SharedHanjaIndex.fromCache({
        'chars': {
          'U9751': {'code': 'U9751', 'kr': '靑', 'cn': '青', 'pinyin': ['qīng']},
          'U6DF8': {'code': 'U6DF8', 'kr': '淸', 'cn': '清', 'pinyin': ['qīng'], 'phonetic': 'U9751', 'zh_cliff_rank': 500},
          'U60C5': {'code': 'U60C5', 'kr': '情', 'cn': '情', 'pinyin': ['qíng'], 'phonetic': 'U9751', 'zh_cliff_rank': 300},
        },
        'alias': {'清': ['U6DF8']},
      });
      final f = familyFor('清', index: idx)!;
      expect(f.phonetic, '青');
      expect(f.members, ['情', '清']);
      expect(f.row('清'), ['青', '情', '清']);
      expect(familyFor('青', index: idx)!.members, ['情', '清']);
      expect(familyFor('好', index: idx), isNull);
    });

    test('한 줄이 넘치면 지금 글자는 남긴다', () {
      const f = HanziFamily('青', ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']);
      final row = f.row('h', max: 4);
      expect(row.length, 4);
      expect(row.first, '青');
      expect(row, contains('h'));
    });

    testWidgets('팝업 가족 줄: 같은 소리만 구리 테두리, 다른 소리·발음부는 테두리 없음, 누르면 패밀리 한자', (tester) async {
      const py = {'青': 'qīng', '清': 'qīng', '情': 'qíng', '猜': 'cāi'};
      var opened = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HanziFamilyStrip(
            phonetic: '青',
            phoneticPinyin: 'qīng',
            chars: const ['青', '清', '情', '猜'],
            current: '情',
            total: 4,
            pinyinOf: (c) => py[c] ?? '',
            onOpen: () => opened++,
          ),
        ),
      ));
      FamilyGlyphTile tile(String c) => tester.widget<FamilyGlyphTile>(find.byKey(ValueKey('fam-$c')));
      Border? border(String c) {
        final box = tester.widget<Container>(find.descendant(of: find.byKey(ValueKey('fam-$c')), matching: find.byType(Container)).first);
        return (box.decoration as BoxDecoration?)?.border as Border?;
      }

      expect(tile('清').sameSound, isTrue);
      expect(tile('情').sameSound, isTrue);
      expect(tile('猜').sameSound, isFalse);
      expect(tile('青').sameSound, isFalse); // 발음부 자신은 표시하지 않음
      expect(border('清')!.top.color, AppColors.copper);
      expect(border('情')!.top.color, AppColors.copper);
      expect(border('猜'), isNull);
      expect(border('青'), isNull);
      expect(tile('情').current, isTrue);

      await tester.tap(find.byKey(const ValueKey('fam-猜')));
      expect(opened, 1);
    });
  });

  group('회화 리더(확 트인 배치)', () {
    testWidgets('지금 줄만 병음·번역, 앞뒤 줄은 중국어만 접혀 있고 스크립트는 눌러야 펼친다', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final d = _ep();
      KoReadingPrefs.show.value = true; // 읽기 보조는 기본 꺼짐(2026-11-07 §6) — 이 시험은 켠 상태에서 본다
      addTearDown(() => KoReadingPrefs.show.value = false);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: EpisodePlayPane(dialogue: d, initialIndex: 1, autoPlay: false))));
      await tester.pump();

      // 지금 줄(2번): 병음·번역이 보인다
      expect(find.byType(NowLine), findsOneWidget);
      expect(find.text('일어났어 일어났어.'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is TonePinyinText && w.text == 'Qǐ le qǐ le.'), findsOneWidget);

      // 앞 줄 하나·뒤 줄 둘은 중국어 한 줄로만
      expect(find.byType(CollapsedLine), findsNWidgets(3));
      expect(find.text('你起床了没？'), findsOneWidget);
      expect(find.text('일어났어?'), findsNothing);
      expect(find.byWidgetPredicate((w) => w is TonePinyinText && w.text.startsWith('Nǐ')), findsNothing);

      // 전체 스크립트는 접혀 있다가 펼친다
      expect(find.text('骗人！'), findsOneWidget);
      await tester.tap(find.textContaining('전체 스크립트 ·'));
      await tester.pump();
      expect(find.text('骗人！'), findsNWidgets(2)); // 접힌 줄 + 스크립트
      expect(find.text('스크립트 접기'), findsOneWidget);

      // 접힌 줄을 누르면 그 줄이 지금 줄
      await tester.tap(find.widgetWithText(CollapsedLine, '你起床了没？'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400)); // 지금 줄 전환(AnimatedSwitcher) 끝
      expect(find.text('일어났어?'), findsNWidgets(2)); // 지금 줄 + 펼친 스크립트의 지금 줄
      expect(find.text('일어났어 일어났어.'), findsNothing); // 앞 줄이 된 2번은 번역이 접힌다
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });

  test('글꼴 라이선스: OFL 전문 네 벌이 애셋으로 들어 있다', () async {
    expect(FontLicensesScreen.fonts.length, 4);
    for (final (_, _, path) in FontLicensesScreen.fonts) {
      final text = await rootBundle.loadString(path);
      expect(text, contains('SIL Open Font License'), reason: path);
    }
  });
}
