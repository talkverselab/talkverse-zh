import 'package:flutter_test/flutter_test.dart';

import 'package:chinese_universe/services/pinyin_util.dart';
import 'package:chinese_universe/services/shared_hanja_service.dart';

/// 공용 DB 캐시 모양(SharedHanjaService 가 저장하는 JSON)으로 만든 작은 표.
Map<String, dynamic> _cache() => {
      'chars': {
        'U9751': {'code': 'U9751', 'kr': '靑', 'cn': '青', 'kr_hun': '푸를 청', 'pinyin': ['qīng'], 'hsk': 1},
        'U6DF8': {
          'code': 'U6DF8', 'kr': '淸', 'cn': '清', 'pinyin': ['qīng'], 'hsk': 2, 'hsk_w': 1,
          'phonetic': 'U9751', 'phonetic_src': 'zh', 'gif': 'U6DF8_v1.gif', 'gif_status': 'ok',
          'zh_cliff_rank': 500,
        },
        'U60C5': {
          'code': 'U60C5', 'kr': '情', 'cn': '情', 'pinyin': ['qíng'], 'hsk': 2,
          'phonetic': 'U9751', 'phonetic_src': '추정', 'gif': 'U60C5_v1.gif', 'gif_status': 'ok',
          'zh_cliff_rank': 300,
        },
        // 간체에서만 성립하는 발음부: 認 의 정자 기준은 刃, 간체 认 은 人
        'U8A8D': {'code': 'U8A8D', 'kr': '認', 'cn': '认', 'phonetic': 'U5203', 'phonetic_cn': '人', 'hsk': 1, 'hsk_w': 2},
        'U5203': {'code': 'U5203', 'kr': '刃', 'cn': '刃'},
        // 간체 하나가 정자 둘
        'U9418': {'code': 'U9418', 'kr': '鐘', 'cn': '钟', 'phonetic_cn': '中', 'zh_cliff_rank': 900},
        // 鍾 의 정자 발음부는 重 — 간체 钟 은 phonetic_cn 이 있는 鐘 쪽(中)을 따라야 한다
        'U937E': {'code': 'U937E', 'kr': '鍾', 'cn': '钟', 'phonetic': 'U91CD', 'zh_cliff_rank': 900},
        'U91CD': {'code': 'U91CD', 'kr': '重', 'cn': '重'},
        'U4E2D': {'code': 'U4E2D', 'kr': '中', 'cn': '中', 'pinyin': ['zhōng']},
      },
      'alias': {
        '清': ['U6DF8'],
        '钟': ['U9418', 'U937E'],
      },
      'mnemonic': {
        'U60C5|ko|kr': {'origin': '마음이 뜻, 靑 이 소리', 'tip': '忄 + 靑'},
        'U6DF8|ko|kr': {'origin': '정자판', 'tip': '氵 + 靑'},
        'U6DF8|ko|cn': {'origin': '간체판', 'tip': '氵 + 青'},
      },
    };

void main() {
  final idx = SharedHanjaIndex.fromCache(_cache());

  test('phonetic_cn 이 있으면 그것, 없으면 phonetic 코드의 간체', () {
    expect(idx.phoneticFor('认'), '人');
    expect(idx.phoneticFor('清'), '青');
    expect(idx.phoneticFor('钟'), '中'); // 간체 기준 값 우선
  });

  test('발음부 가족은 간체로 묶고 회화 빈도순', () {
    final f = idx.families();
    expect(f['青'], ['情', '清']);
    expect(f['中'], ['钟']); // 정자 둘이어도 한 번
    expect(f['重'], isNull); // 鍾 의 정자 발음부로 새지 않음
    expect(f['人'], ['认']);
  });

  test('GIF: 자형이 다르면 gif_cn(ok)만 — 정자 GIF 로 대신하지 않음', () {
    expect(idx.lookup('清')!.gifUrl, isNull);
    expect(idx.lookup('情')!.gifUrl, 'https://gif.talkverse.uk/U60C5_v1.gif');
  });

  test('외우는 방법: 자형이 다르면 간체판만', () {
    expect(idx.mnemonicFor(idx.lookup('清')!, 'ko')!.tip, '氵 + 青');
    expect(idx.mnemonicFor(idx.lookup('情')!, 'ko')!.tip, '忄 + 靑');
    expect(idx.mnemonicFor(idx.lookup('认')!, 'ko'), isNull);
  });

  test('쓰기 범위 (SHARED_DB §12)', () {
    final qing = idx.lookup('清')!; // hsk_w 1
    final ren = idx.lookup('认')!; // hsk_w 2
    expect(qing.writeRequiredFor(2), isTrue);
    expect(ren.writeRequiredFor(3), isFalse);
    expect(ren.writeRequiredFor(5), isTrue);
    expect(idx.lookup('情')!.writeRequiredFor(9), isFalse);
  });

  test('추정 표시 대상', () {
    expect(idx.lookup('情')!.phoneticConfirmed, isFalse);
    expect(idx.lookup('清')!.phoneticConfirmed, isTrue);
    expect(idx.lookup('认')!.phoneticConfirmed, isTrue);
  });

  test('빈 캐시', () {
    final e = SharedHanjaIndex.fromCache({});
    expect(e.isEmpty, isTrue);
    expect(e.lookup('清'), isNull);
  });

  test('성조 부호 → 번호', () {
    expect(PinyinUtil.toNumbered('qīng'), 'qing1');
    expect(PinyinUtil.toNumbered('lǜ'), 'lü4');
    expect(PinyinUtil.toNumbered('ma'), 'ma5');
    expect(PinyinUtil.toNumbered('shi2'), 'shi2');
  });
}
