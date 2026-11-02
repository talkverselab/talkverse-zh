/// 성조 병음 → 한글 독음(한국인 학습자용 읽기) — 2026-11-02.
///
/// 새 회화 JSON 에는 `rd`(한글 독음)가 없어서 앱이 `pinyin` 에서 만든다.
/// 기준은 외래어 표기법(중국어 음절 표기)에 가깝게: zh/j → ㅈ, ch/q/c → ㅊ, sh/x → ㅅ, z → ㅉ, s → ㅆ,
/// zhi·chi·shi·ri·zi·ci·si → 즈·츠·스·르·쯔·츠·쓰, j/q 뒤 y-모음은 홑모음(jia 자, qie 체, jiu 주).
/// 성조 부호는 읽기에 넣지 않는다. 단어 안 음절은 붙이고, 띄어쓰기·문장부호는 그대로 둔다.
/// 음절로 나눌 수 없는 토큰은 원문 그대로 남긴다.
class PinyinHangul {
  PinyinHangul._();

  // 초성 인덱스(ㄱ0 ㄲ1 ㄴ2 ㄷ3 ㄸ4 ㄹ5 ㅁ6 ㅂ7 ㅃ8 ㅅ9 ㅆ10 ㅇ11 ㅈ12 ㅉ13 ㅊ14 ㅋ15 ㅌ16 ㅍ17 ㅎ18)
  static const Map<String, int> _initials = {
    'b': 7, 'p': 17, 'm': 6, 'f': 17, 'd': 3, 't': 16, 'n': 2, 'l': 5,
    'g': 0, 'k': 15, 'h': 18, 'j': 12, 'q': 14, 'x': 9,
    'zh': 12, 'ch': 14, 'sh': 9, 'r': 5, 'z': 13, 'c': 14, 's': 10,
  };

  // 운모 → ㅇ 초성으로 읽은 한글(첫 음절의 초성을 성모로 바꾼다)
  static const Map<String, String> _finals = {
    'a': '아', 'o': '오', 'e': '어', 'ai': '아이', 'ei': '에이', 'ao': '아오', 'ou': '어우',
    'an': '안', 'en': '언', 'ang': '앙', 'eng': '엉', 'ong': '웅',
    'i': '이', 'ia': '야', 'ie': '예', 'iao': '야오', 'iu': '유', 'ian': '옌', 'in': '인',
    'iang': '양', 'ing': '잉', 'iong': '융',
    'u': '우', 'ua': '와', 'uo': '워', 'uai': '와이', 'ui': '우이', 'uan': '완', 'un': '운', 'uang': '왕',
    'ü': '위', 'üe': '웨', 'üan': '위안', 'ün': '윈',
  };

  // 성모 없는 음절(y·w 표기 포함)
  static const Map<String, String> _zero = {
    'a': '아', 'o': '오', 'e': '어', 'ai': '아이', 'ei': '에이', 'ao': '아오', 'ou': '어우',
    'an': '안', 'en': '언', 'ang': '앙', 'eng': '엉', 'er': '얼',
    'yi': '이', 'ya': '야', 'ye': '예', 'yo': '요', 'yao': '야오', 'you': '유', 'yan': '옌', 'yin': '인',
    'yang': '양', 'ying': '잉', 'yong': '융', 'yu': '위', 'yue': '웨', 'yuan': '위안', 'yun': '윈',
    'wu': '우', 'wa': '와', 'wo': '워', 'wai': '와이', 'wei': '웨이', 'wan': '완', 'wen': '원',
    'wang': '왕', 'weng': '웡',
    'ng': '응', 'hng': '흥', 'hm': '흠', // 감탄사
  };

  // 성모 무리별로 붙을 수 있는 운모(대략 — 잘못 나누는 것을 막는 정도)
  static const _velarFinals = ['a', 'e', 'ai', 'ei', 'ao', 'ou', 'an', 'en', 'ang', 'eng', 'ong', 'u', 'ua', 'uo', 'uai', 'ui', 'uan', 'un', 'uang'];
  static const _sibilantFinals = ['a', 'e', 'ai', 'ei', 'ao', 'ou', 'an', 'en', 'ang', 'eng', 'ong', 'i', 'u', 'ua', 'uo', 'uai', 'ui', 'uan', 'un', 'uang'];
  static const _palatalFinals = ['i', 'ia', 'ie', 'iao', 'iu', 'ian', 'in', 'iang', 'ing', 'iong', 'u', 'ue', 'uan', 'un', 'ü', 'üe', 'üan', 'ün'];
  static const _labialFinals = ['a', 'o', 'e', 'ai', 'ei', 'ao', 'ou', 'an', 'en', 'ang', 'eng', 'i', 'ie', 'iao', 'iu', 'ian', 'in', 'ing', 'u'];
  static const _alveolarFinals = ['a', 'o', 'e', 'ai', 'ei', 'ao', 'ou', 'an', 'en', 'ang', 'eng', 'ong', 'i', 'ia', 'ie', 'iao', 'iu', 'ian', 'in', 'iang', 'ing', 'u', 'uo', 'ui', 'uan', 'un', 'ü', 'üe'];

  static Map<String, String>? _table; // 음절 → 한글

  static Map<String, String> get _syllables => _table ??= _build();

  static Map<String, String> _build() {
    final out = <String, String>{..._zero};
    void add(String ini, List<String> finals) {
      for (final f0 in finals) {
        // j/q/x 뒤 u 는 ü (ju = jü)
        final f = ('jqx'.contains(ini) && f0.startsWith('u')) ? 'ü${f0.substring(1)}' : f0;
        final base = _finals[f] ?? (f == 'üe' ? '웨' : null);
        if (base == null) continue;
        out['$ini$f0'] = _attach(ini, f, base);
        if (f != f0) out['$ini$f'] = out['$ini$f0']!; // jü 표기도 받는다
      }
    }
    for (final i in ['g', 'k', 'h']) {
      add(i, _velarFinals);
    }
    for (final i in ['z', 'c', 's', 'zh', 'ch', 'sh', 'r']) {
      add(i, _sibilantFinals);
    }
    for (final i in ['j', 'q', 'x']) {
      add(i, _palatalFinals);
    }
    for (final i in ['b', 'p', 'm', 'f']) {
      add(i, _labialFinals);
    }
    for (final i in ['d', 't', 'n', 'l']) {
      add(i, _alveolarFinals);
    }
    // n/l + ü 는 nv·lv 로도 쓴다
    for (final i in ['n', 'l']) {
      out['${i}v'] = out['$iü']!;
      out['${i}ve'] = out['$iüe']!;
    }
    return out;
  }

  /// ㅇ 초성 한글의 첫 음절 초성을 성모로 바꾼다(+ 규칙: 舌尖 i → ㅡ, j/q 뒤 y-모음 → 홑모음).
  static String _attach(String ini, String fin, String base) {
    final l = _initials[ini]!;
    final first = base.codeUnitAt(0) - 0xAC00;
    var v = (first ~/ 28) % 21;
    final t = first % 28;
    if (fin == 'i' && const ['z', 'c', 's', 'zh', 'ch', 'sh', 'r'].contains(ini)) v = 18; // ㅡ
    if (ini == 'j' || ini == 'q') {
      const simple = {2: 0, 3: 1, 6: 4, 7: 5, 12: 8, 17: 13}; // ㅑㅒㅕㅖㅛㅠ → ㅏㅐㅓㅔㅗㅜ
      v = simple[v] ?? v;
    }
    return String.fromCharCode(0xAC00 + (l * 21 + v) * 28 + t) + base.substring(1);
  }

  static const Map<String, String> _toneless = {
    'ā': 'a', 'á': 'a', 'ǎ': 'a', 'à': 'a',
    'ē': 'e', 'é': 'e', 'ě': 'e', 'è': 'e', 'ê': 'e',
    'ī': 'i', 'í': 'i', 'ǐ': 'i', 'ì': 'i',
    'ō': 'o', 'ó': 'o', 'ǒ': 'o', 'ò': 'o',
    'ū': 'u', 'ú': 'u', 'ǔ': 'u', 'ù': 'u',
    'ǖ': 'ü', 'ǘ': 'ü', 'ǚ': 'ü', 'ǜ': 'ü',
    'ń': 'n', 'ň': 'n', 'ǹ': 'n', 'ḿ': 'm',
  };

  static final _letters = RegExp(r"[A-Za-zāáǎàēéěèêīíǐìōóǒòūúǔùǖǘǚǜüÜńňǹḿĀÁǍÀĒÉĚÈĪÍǏÌŌÓǑÒŪÚǓÙ]+");
  static final _placeholder = RegExp(r'\{[a-z_]+\}');

  /// 병음 문장 → 한글 독음. 예) 'Nǐ hǎo, wǒ jiào Xiǎolì.' → '니 하오, 워 자오 샤오리.'
  static String convert(String pinyin) {
    if (pinyin.trim().isEmpty) return '';
    final out = StringBuffer();
    var i = 0;
    // `{name}` 같은 자리표시는 그대로 둔다
    for (final m in _placeholder.allMatches(pinyin)) {
      out.write(_convertPlain(pinyin.substring(i, m.start)));
      out.write(m.group(0));
      i = m.end;
    }
    out.write(_convertPlain(pinyin.substring(i)));
    return out.toString();
  }

  static String _convertPlain(String s) =>
      s.replaceAllMapped(_letters, (m) => word(m.group(0)!) ?? m.group(0)!);

  /// 한 단어(붙여 쓴 음절들). 나눌 수 없으면 null.
  static String? word(String w) {
    final buf = StringBuffer();
    for (final ch in w.toLowerCase().split('')) {
      buf.write(_toneless[ch] ?? ch);
    }
    var s = buf.toString().replaceAll('v', 'ü');
    // 얼화(儿化): 끝의 r 이 음절로 안 나뉘면 떼어 두었다가 받침 ㄹ 로 붙인다
    var erhua = false;
    var parts = _segment(s, 0);
    if (parts == null && s.length > 2 && s.endsWith('r')) {
      parts = _segment(s.substring(0, s.length - 1), 0);
      erhua = parts != null;
    }
    if (parts == null) return null;
    final hangul = parts.map((p) => _syllables[p]!).join();
    if (!erhua) return hangul;
    final last = hangul.codeUnitAt(hangul.length - 1) - 0xAC00;
    if (last >= 0 && last % 28 == 0) {
      return hangul.substring(0, hangul.length - 1) + String.fromCharCode(0xAC00 + last + 8); // ㄹ 받침
    }
    return '$hangul얼';
  }

  /// 붙여 쓴 병음 한 단어를 음절로 나눈다(원래 글자·성조 부호 그대로). 예) 'qǐchuáng' → ['qǐ', 'chuáng'].
  /// 한 음절에 성조 부호는 하나까지(→ 'Xīān' 은 'Xī'+'ān'). 끝의 얼화 r 은 마지막 음절에 붙인다. 나눌 수 없으면 null.
  static List<String>? splitSyllables(String w) {
    if (w.isEmpty) return null;
    final buf = StringBuffer();
    for (final ch in w.toLowerCase().split('')) {
      buf.write(_toneless[ch] ?? ch);
    }
    final plain = buf.toString().replaceAll('v', 'ü');
    if (plain.length != w.length) return null; // 1:1 대응이 깨지면(합성 문자 등) 나누지 않는다
    List<int>? seg(int from, int end) {
      if (from == end) return [];
      for (var len = (end - from).clamp(0, 6); len >= 1; len--) {
        final cand = plain.substring(from, from + len);
        if (!_syllables.containsKey(cand)) continue;
        if (_marks(w.substring(from, from + len)) > 1) continue;
        final rest = seg(from + len, end);
        if (rest != null) return [len, ...rest];
      }
      return null;
    }

    var lens = seg(0, plain.length);
    var erhua = false;
    if (lens == null && plain.length > 2 && plain.endsWith('r')) {
      lens = seg(0, plain.length - 1);
      erhua = lens != null;
    }
    if (lens == null) return null;
    final out = <String>[];
    var i = 0;
    for (final l in lens) {
      out.add(w.substring(i, i + l));
      i += l;
    }
    if (erhua) out[out.length - 1] = out.last + w.substring(i);
    return out;
  }

  static int _marks(String s) => s.split('').where((c) => _toneless.containsKey(c) || _toneless.containsKey(c.toLowerCase())).length;

  /// 가장 긴 음절부터 시도하고, 나머지가 안 나뉘면 되돌아간다.
  static List<String>? _segment(String s, int from) {
    if (from == s.length) return [];
    final table = _syllables;
    for (var len = (s.length - from).clamp(0, 6); len >= 1; len--) {
      final cand = s.substring(from, from + len);
      if (!table.containsKey(cand)) continue;
      final rest = _segment(s, from + len);
      if (rest != null) return [cand, ...rest];
    }
    return null;
  }
}
