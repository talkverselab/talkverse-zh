import 'package:chinese_universe/services/speak_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exact hanzi passes', () {
    expect(SpeakMatch.pass('我知道你又在想我了', '我知道你又在想我了'), isTrue);
  });

  test('homophone / tone-different hanzi passes (pinyin match)', () {
    // 你好吗 vs 尼浩马 → ni hao ma 동일
    expect(SpeakMatch.pass('你好吗？', '尼浩马'), isTrue);
  });

  test('zh/z, n/l, ing/in fuzz', () {
    expect(SpeakMatch.fuzzy('zhong'), 'zong');
    expect(SpeakMatch.fuzzy('ning'), 'lin');
    expect(SpeakMatch.fuzzy('sheng'), 'sen');
    expect(SpeakMatch.fuzzy('lü'), 'lv');
  });

  test('partial sentence fails, mostly-right passes', () {
    const target = '明天我们一起去看电影吧';
    expect(SpeakMatch.pass(target, '明天我们'), isFalse);
    expect(SpeakMatch.pass(target, '明天我们一起去看电影'), isTrue);
    expect(SpeakMatch.score(target, '明天我们一起去看电影'), closeTo(0.9, 0.01));
  });

  test('digits are read as chinese numerals', () {
    expect(SpeakMatch.pass('三点见', '3点见'), isTrue);
    expect(SpeakMatch.syllables('12'), ['si', 'er']); // 十二 → shi er → si er
  });

  test('short sentences must be complete', () {
    expect(SpeakMatch.pass('谢谢', '谢'), isFalse);
    expect(SpeakMatch.pass('谢谢', '谢谢你'), isTrue);
  });

  test('empty heard fails', () {
    expect(SpeakMatch.pass('你好', ''), isFalse);
  });
}
