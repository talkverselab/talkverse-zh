import 'hanzi_info_service.dart';
import 'lexicon_service.dart';
import 'pinyin_util.dart';
import 'shared_hanja_service.dart';

/// 발음부(声旁) 가족 — 한자 팝업 「가족 한 줄」과 「패밀리 한자」가 같은 규칙을 쓴다.
/// 데이터는 한자 공용 DB(`SharedHanjaIndex.families()`) 우선, 없으면 앱 큐레이션(`HanziInfoService`).

/// 글자 → 성조 부호 병음(첫 읽기). 공용 DB → 앱 사전 순.
String pinyinOf(String ch) {
  final h = SharedHanjaService.instance.index.lookup(ch);
  if (h != null && h.pinyin.isNotEmpty) return h.pinyin.first;
  return LexiconService.instance.lookup(ch)?.pinyin.split(RegExp(r'[\s,/]')).first ?? '';
}

/// 같은 소리(성조는 달라도 음절이 같음)인가 — 구리 테두리 규칙.
bool sameSound(String memberPy, String rootPy) {
  if (memberPy.isEmpty || rootPy.isEmpty) return false;
  return PinyinUtil.stripTones(memberPy.split(RegExp(r'[\s,/]')).first) == PinyinUtil.stripTones(rootPy.split(RegExp(r'[\s,/]')).first);
}

/// 한 글자가 속한 발음부 가족(발음부 글자 + 구성원, 회화 빈도순).
class HanziFamily {
  final String phonetic;
  final List<String> members; // 발음부 자신 제외
  const HanziFamily(this.phonetic, this.members);

  /// 발음부를 맨 앞에 둔 한 줄(최대 [max]자). [current] 는 잘리더라도 넣는다.
  List<String> row(String current, {int max = 7}) {
    final all = [phonetic, ...members.where((m) => m != phonetic)];
    if (all.length <= max) return all;
    final out = all.take(max).toList();
    if (all.contains(current) && !out.contains(current)) out[max - 1] = current;
    return out;
  }
}

Map<String, List<String>>? _famCache;
SharedHanjaIndex? _famOf;

/// [ch] 의 발음부 가족. 공용 DB 에 없으면 앱 큐레이션, 그래도 없으면 null.
/// [ch] 가 발음부 자신이면 그 가족.
HanziFamily? familyFor(String ch, {SharedHanjaIndex? index}) {
  final idx = index ?? SharedHanjaService.instance.index;
  if (!idx.isEmpty) {
    final fam = identical(idx, _famOf) && _famCache != null ? _famCache! : (_famCache = idx.families());
    _famOf = idx;
    final p = idx.phoneticFor(ch);
    if (p != null && (fam[p]?.isNotEmpty ?? false)) return HanziFamily(p, fam[p]!);
    if (fam[ch]?.isNotEmpty ?? false) return HanziFamily(ch, fam[ch]!);
  }
  if (index != null) return null; // 주어진 색인만 본다(테스트)
  final info = HanziInfoService.instance.lookup(ch);
  final phon = info?.phonetic;
  if (phon == null) return null;
  final members = HanziInfoService.instance.charsSharing(phon).where((c) => c != phon).toList();
  if (members.isEmpty) return null;
  return HanziFamily(phon, members);
}
