/// CC-CEDICT 번호 성조 → 병음 성조 변환
/// 'ni3 hao3' → 'nǐ hǎo'
class PinyinUtil {
  static const Map<String, List<String>> _marks = {
    'a': ['ā', 'á', 'ǎ', 'à'],
    'e': ['ē', 'é', 'ě', 'è'],
    'i': ['ī', 'í', 'ǐ', 'ì'],
    'o': ['ō', 'ó', 'ǒ', 'ò'],
    'u': ['ū', 'ú', 'ǔ', 'ù'],
    'ü': ['ǖ', 'ǘ', 'ǚ', 'ǜ'],
    'A': ['Ā', 'Á', 'Ǎ', 'À'],
    'E': ['Ē', 'É', 'Ě', 'È'],
    'I': ['Ī', 'Í', 'Ǐ', 'Ì'],
    'O': ['Ō', 'Ó', 'Ǒ', 'Ò'],
    'U': ['Ū', 'Ú', 'Ǔ', 'Ù'],
  };

  static String toTonedPinyin(String input) {
    return input.split(' ').map(_convertSyllable).join(' ');
  }

  static String _convertSyllable(String syl) {
    if (syl.isEmpty) return syl;
    // u: → ü
    syl = syl.replaceAll('u:', 'ü').replaceAll('U:', 'Ü');

    // 끝 숫자 추출
    final m = RegExp(r'^([A-Za-zü:Ü]+)(\d)$').firstMatch(syl);
    if (m == null) return syl;
    final letters = m.group(1)!;
    final tone = int.parse(m.group(2)!);
    if (tone < 1 || tone > 4) return letters; // 5/0 = neutral, no mark

    final i = _markIndex(letters);
    if (i < 0) return letters;
    final ch = letters[i];
    final marked = _marks[ch]?[tone - 1] ?? ch;
    return letters.replaceRange(i, i + 1, marked);
  }

  /// 성조 마크가 들어갈 글자의 인덱스 결정.
  /// 우선순위: a > e > o > 그 외 (i/u 는 후행 모음).
  static int _markIndex(String letters) {
    final l = letters.toLowerCase();
    final iA = l.indexOf('a');
    if (iA >= 0) return iA;
    final iE = l.indexOf('e');
    if (iE >= 0) return iE;
    final iO = l.indexOf('o');
    if (iO >= 0) return iO;
    // iu → u 에 마크, ui → i 에 마크 — 늦은 모음 우선
    for (var i = l.length - 1; i >= 0; i--) {
      final c = l[i];
      if ('iouü'.contains(c)) return i;
    }
    return -1;
  }

  /// 성조 마크 제거 → 기본 음절.
  /// 'mǎ' → 'ma',  'xiào' → 'xiao'
  static String stripTones(String pinyin) {
    const tonedToBase = {
      'ā': 'a', 'á': 'a', 'ǎ': 'a', 'à': 'a',
      'ē': 'e', 'é': 'e', 'ě': 'e', 'è': 'e',
      'ī': 'i', 'í': 'i', 'ǐ': 'i', 'ì': 'i',
      'ō': 'o', 'ó': 'o', 'ǒ': 'o', 'ò': 'o',
      'ū': 'u', 'ú': 'u', 'ǔ': 'u', 'ù': 'u',
      'ǖ': 'ü', 'ǘ': 'ü', 'ǚ': 'ü', 'ǜ': 'ü',
      'Ā': 'A', 'Á': 'A', 'Ǎ': 'A', 'À': 'A',
      'Ē': 'E', 'É': 'E', 'Ě': 'E', 'È': 'E',
      'Ī': 'I', 'Í': 'I', 'Ǐ': 'I', 'Ì': 'I',
      'Ō': 'O', 'Ó': 'O', 'Ǒ': 'O', 'Ò': 'O',
      'Ū': 'U', 'Ú': 'U', 'Ǔ': 'U', 'Ù': 'U',
    };
    final buf = StringBuffer();
    for (final ch in pinyin.split('')) {
      buf.write(tonedToBase[ch] ?? ch);
    }
    return buf.toString().toLowerCase().trim();
  }

  /// 두 병음의 일치 정도.
  /// 0 = 완전공유 (성조까지 같음)
  /// 1 = 부분공유 (성조만 다름)
  /// 2 = 일부음차차이 (음절 자체 다름)
  static int compareLevel(String a, String b) {
    final pa = a.split(' ').first.trim();
    final pb = b.split(' ').first.trim();
    if (pa.toLowerCase() == pb.toLowerCase()) return 0;
    if (stripTones(pa) == stripTones(pb)) return 1;
    return 2;
  }
}
