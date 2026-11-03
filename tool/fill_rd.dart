// 편 JSON 의 턴마다 병음(pinyin)에서 한글 독음(rd)을 채운다 — 앱과 같은 변환기(lib/services/pinyin_hangul.dart).
//   dart run tool/fill_rd.dart <편.json> [...]
// rd_manual: true 인 턴은 건드리지 않는다.
import 'dart:convert';
import 'dart:io';

import '../lib/services/pinyin_hangul.dart';

void main(List<String> args) {
  for (final path in args) {
    final f = File(path);
    final j = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    var n = 0;
    for (final t in (j['turns'] as List).cast<Map<String, dynamic>>()) {
      if (t['rd_manual'] == true) continue;
      final rd = PinyinHangul.convert((t['pinyin'] as String?) ?? '');
      if (rd != t['rd']) {
        t['rd'] = rd;
        n++;
      }
    }
    f.writeAsStringSync('${const JsonEncoder.withIndent(' ').convert(j)}\n');
    stdout.writeln('$path: rd $n줄');
  }
}
