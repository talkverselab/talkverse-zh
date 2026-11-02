import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_universe/services/pinyin_hangul.dart';

void main() {
  test('병음 문장 → 한글 독음', () {
    expect(PinyinHangul.convert('Nǐ hǎo, wǒ jiào Xiǎolì.'), '니 하오, 워 자오 샤오리.');
    expect(PinyinHangul.convert('Xièxie!'), '셰셰!');
    expect(PinyinHangul.convert('Zhōngguó rén'), '중궈 런');
    expect(PinyinHangul.convert('shāngliang'), '상량');
    expect(PinyinHangul.convert('Wǒmen de shì, yào bu yào gàosu péngyoumen?'), '워먼 더 스, 야오 부 야오 가오쑤 펑유먼?');
    expect(PinyinHangul.convert('qù xuéxiào'), '취 쉐샤오');
    expect(PinyinHangul.convert('Tiān\'ānmén'), '톈\'안먼');
    expect(PinyinHangul.convert('jiějie zhīdào'), '제제 즈다오');
  });

  test('자리표시·못 나누는 토큰은 그대로', () {
    expect(PinyinHangul.convert('{name}, nǐ hǎo'), '{name}, 니 하오');
    expect(PinyinHangul.convert('OK'), 'OK');
    expect(PinyinHangul.convert(''), '');
  });

  test('얼화', () {
    expect(PinyinHangul.convert('yìdiǎnr'), '이뎬얼');
    expect(PinyinHangul.convert('wánr'), '완얼');
    expect(PinyinHangul.convert('nàr'), '날');
  });
}
