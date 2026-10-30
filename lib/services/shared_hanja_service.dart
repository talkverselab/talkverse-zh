import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 한자 공용 DB(한자유니버스가 관리하는 Cloudflare D1 `hanja-db` 의 `hanja_chars` · `hanja_alias` · `hanja_mnemonic`)를
/// 읽기 전용으로 받아 기기에 캐시한다. 규칙은 한자 세션의 SHARED_DB.md (§1 코드, §10 자형별 GIF,
/// §11 간체 발음부, §12 쓰기 범위, §13 외우는 방법, §15 읽기 주소). 읽기 API 는 PostgREST 와 같은 모양이다.
///
/// - 코드 = `U` + 한국 정자 코드포인트. 이 앱은 간체(`cn`)로 찾는다.
/// - 네트워크·서버가 안 되면 캐시를 그대로 쓰고, 캐시도 없으면 비어 있는 채로 둔다
///   (그때 화면은 번들 데이터 `hanzi_info.json` · `phonetic_ext.json` 만 쓴다).
class SharedHanjaService {
  SharedHanjaService._();
  static final SharedHanjaService instance = SharedHanjaService._();

  // 2026-10-26 Supabase → Cloudflare 이관 (SHARED_DB.md §15). 공개 읽기라 키가 없다.
  static const _base = 'https://hanja-api.talkverse-lab.workers.dev';
  // GIF 저장소는 Cloudflare R2 (SHARED_DB.md §14)
  static const gifBase = 'https://gif.talkverse.uk/';
  static const bCutBase =
      'https://raw.githubusercontent.com/talkverselab/talkversehanja/main/claude_b/';
  static const _cacheName = 'shared_hanja_v1.json';
  static const _syncEvery = Duration(hours: 12);
  static const _pageSize = 1000;

  static const _charCols = 'code,kr,cn,kr_hun,pinyin,hsk,hsk_w,liushu,phonetic,'
      'phonetic_cn,phonetic_src,explain,components,gif,gif_status,gif_cn,'
      'gif_cn_status,family_status,zh_cliff_band,zh_cliff_rank,b_kr,b_cn,updated_at';

  SharedHanjaIndex _index = SharedHanjaIndex.empty();
  Map<String, dynamic> _cache = {};
  bool _loaded = false;
  Future<bool>? _syncing;

  SharedHanjaIndex get index => _index;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final f = await _cacheFile();
      if (await f.exists()) {
        _cache = json.decode(await f.readAsString()) as Map<String, dynamic>;
        _index = SharedHanjaIndex.fromCache(_cache);
      }
    } catch (_) {
      _cache = {};
      _index = SharedHanjaIndex.empty();
    }
    _loaded = true;
  }

  /// 마지막 동기화가 [_syncEvery] 보다 오래됐으면 서버에서 바뀐 행만 받아 캐시를 갱신한다.
  /// 무언가 바뀌었으면 true. 실패해도 예외를 던지지 않는다.
  Future<bool> syncIfStale({bool force = false}) {
    return _syncing ??= _sync(force).whenComplete(() => _syncing = null);
  }

  Future<bool> _sync(bool force) async {
    await ensureLoaded();
    final last = DateTime.tryParse(_cache['synced_at'] as String? ?? '');
    if (!force && last != null && DateTime.now().difference(last) < _syncEvery) {
      return false;
    }
    try {
      final chars = Map<String, dynamic>.from(_cache['chars'] as Map? ?? {});
      final since = _cache['chars_max_updated'] as String?;
      final rows = await _fetchAll('hanja_chars', _charCols, since: since);
      var maxUpdated = since;
      for (final r in rows) {
        final code = r['code'] as String?;
        if (code == null) continue;
        chars[code] = _slim(r);
        final u = r['updated_at'] as String?;
        if (u != null && (maxUpdated == null || u.compareTo(maxUpdated) > 0)) {
          maxUpdated = u;
        }
      }
      final changed = rows.isNotEmpty;

      var alias = _cache['alias'] as Map? ?? {};
      if (changed || alias.isEmpty) {
        final a = await _fetchAll('hanja_alias', 'ch,code,langs');
        final m = <String, List<String>>{};
        for (final r in a) {
          final langs = (r['langs'] as List?)?.cast<String>() ?? const [];
          if (langs.isNotEmpty && !langs.contains('cn')) continue;
          final ch = r['ch'] as String?;
          final code = r['code'] as String?;
          if (ch == null || code == null) continue;
          (m[ch] ??= []).add(code);
        }
        alias = m;
      }

      // 외우는 방법 — 표가 아직 없을 수 있다(요청 중). 없으면 지난 값을 둔다.
      var mnemonic = Map<String, dynamic>.from(_cache['mnemonic'] as Map? ?? {});
      var mnChanged = false;
      try {
        final mSince = _cache['mnemonic_max_updated'] as String?;
        final mr = await _fetchAll(
            'hanja_mnemonic', 'code,lang,form,origin,tip,updated_at',
            since: mSince);
        var mMax = mSince;
        for (final r in mr) {
          final code = r['code'] as String?;
          if (code == null) continue;
          final key = '$code|${r['lang'] ?? 'ko'}|${r['form'] ?? 'kr'}';
          mnemonic[key] = {'origin': r['origin'], 'tip': r['tip']};
          final u = r['updated_at'] as String?;
          if (u != null && (mMax == null || u.compareTo(mMax) > 0)) mMax = u;
        }
        mnChanged = mr.isNotEmpty;
        _cache['mnemonic_max_updated'] = mMax;
      } catch (_) {}

      _cache
        ..['chars'] = chars
        ..['chars_max_updated'] = maxUpdated
        ..['alias'] = alias
        ..['mnemonic'] = mnemonic
        ..['synced_at'] = DateTime.now().toIso8601String();
      await (await _cacheFile()).writeAsString(json.encode(_cache));
      if (changed || mnChanged) _index = SharedHanjaIndex.fromCache(_cache);
      return changed || mnChanged;
    } catch (_) {
      return false; // 오프라인·서버 제한 — 다음 실행 때 다시
    }
  }

  /// 캐시에 둘 열만 남긴다.
  static Map<String, dynamic> _slim(Map<String, dynamic> r) {
    const keep = [
      'code', 'kr', 'cn', 'kr_hun', 'pinyin', 'hsk', 'hsk_w', 'liushu',
      'phonetic', 'phonetic_cn', 'phonetic_src', 'explain', 'components', 'gif',
      'gif_status', 'gif_cn', 'gif_cn_status', 'family_status', 'zh_cliff_band',
      'zh_cliff_rank', 'b_kr', 'b_cn',
    ];
    return {for (final k in keep) if (r[k] != null) k: r[k]};
  }

  Future<List<Map<String, dynamic>>> _fetchAll(String table, String select,
      {String? since}) async {
    final out = <Map<String, dynamic>>[];
    for (var offset = 0;; offset += _pageSize) {
      final q = <String, String>{
        'select': select,
        'order': table == 'hanja_alias' ? 'ch,code' : 'updated_at,code',
        'limit': '$_pageSize',
        'offset': '$offset',
        if (since != null) 'updated_at': 'gt.$since',
      };
      final page = await _get(table, q);
      out.addAll(page.cast<Map<String, dynamic>>());
      if (page.length < _pageSize) break;
    }
    return out;
  }

  Future<List> _get(String table, Map<String, String> query) async {
    final uri = Uri.parse('$_base/rest/v1/$table').replace(queryParameters: query);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 30));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) throw _HttpError(res.statusCode, body);
      return json.decode(body) as List;
    } finally {
      client.close(force: true);
    }
  }

  /// 테스트에서 캐시 폴더를 바꿀 때만 쓴다.
  static Directory? debugCacheDir;

  Future<File> _cacheFile() async {
    final dir = debugCacheDir ?? await getApplicationSupportDirectory();
    return File('${dir.path}/$_cacheName');
  }
}

class _HttpError implements Exception {
  final int status;
  final String body;
  _HttpError(this.status, this.body);
  @override
  String toString() => 'HTTP $status $body';
}

/// 공용 DB 한 글자(코드) 행.
class SharedHanja {
  final String code;
  final String kr;
  final String cn;
  final String? krHun;
  final List<String> pinyin; // 성조 부호 표기 (예: 'qīng')
  final int? hsk;
  final int? hskW; // 손글씨 1 초등 · 2 중등 · 3 고등 · null 읽기만
  final String? liushu;
  final String? phonetic; // 정자 기준 발음부 코드
  final String? phoneticCn; // 간체 기준 발음부 글자 (있으면 우선)
  final String? phoneticSrc; // R1 | zh | 추정
  final String? explain; // gif | compose | family
  final List<Map<String, dynamic>> components;
  final String? gif, gifStatus, gifCn, gifCnStatus, familyStatus;
  final int? zhCliffBand, zhCliffRank;
  final String? bKr, bCn;

  SharedHanja({
    required this.code,
    required this.kr,
    required this.cn,
    this.krHun,
    this.pinyin = const [],
    this.hsk,
    this.hskW,
    this.liushu,
    this.phonetic,
    this.phoneticCn,
    this.phoneticSrc,
    this.explain,
    this.components = const [],
    this.gif,
    this.gifStatus,
    this.gifCn,
    this.gifCnStatus,
    this.familyStatus,
    this.zhCliffBand,
    this.zhCliffRank,
    this.bKr,
    this.bCn,
  });

  factory SharedHanja.fromJson(Map<String, dynamic> j) {
    int? i(String k) => (j[k] as num?)?.toInt();
    final kr = (j['kr'] as String?) ?? '';
    return SharedHanja(
      code: j['code'] as String,
      kr: kr,
      cn: (j['cn'] as String?) ?? kr,
      krHun: j['kr_hun'] as String?,
      pinyin: (j['pinyin'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      hsk: i('hsk'),
      hskW: i('hsk_w'),
      liushu: j['liushu'] as String?,
      phonetic: j['phonetic'] as String?,
      phoneticCn: j['phonetic_cn'] as String?,
      phoneticSrc: j['phonetic_src'] as String?,
      explain: j['explain'] as String?,
      components: (j['components'] as List?)
              ?.whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList() ??
          const [],
      gif: j['gif'] as String?,
      gifStatus: j['gif_status'] as String?,
      gifCn: j['gif_cn'] as String?,
      gifCnStatus: j['gif_cn_status'] as String?,
      familyStatus: j['family_status'] as String?,
      zhCliffBand: i('zh_cliff_band'),
      zhCliffRank: i('zh_cliff_rank'),
      bKr: j['b_kr'] as String?,
      bCn: j['b_cn'] as String?,
    );
  }

  bool get formDiffers => cn != kr;

  /// 한국 한자음 (훈음 '맑을 청' 의 마지막 말).
  String? get koReading {
    final h = krHun?.trim();
    if (h == null || h.isEmpty) return null;
    return h.split(RegExp(r'\s+')).last;
  }

  /// SHARED_DB §10: 자형이 다르면 gif_cn(ok)만, 같으면 gif(ok). 정자 GIF 로 대신하지 않는다.
  String? get gifUrl {
    if (formDiffers) {
      return gifCnStatus == 'ok' && gifCn != null ? SharedHanjaService.gifBase + gifCn! : null;
    }
    return gifStatus == 'ok' && gif != null ? SharedHanjaService.gifBase + gif! : null;
  }

  /// 정자 B컷(楷書 글자 이미지) — b_cn 없으면 자형이 같다는 뜻이라 b_kr (SHARED_DB 2026-10-18).
  String? get bCutUrl {
    final v = bCn ?? (formDiffers ? null : bKr);
    return v == null ? null : SharedHanjaService.bCutBase + v;
  }

  /// SHARED_DB §12: 목표 HSK 급(1~9)에서 쓰기까지 해야 하는 글자인지.
  bool writeRequiredFor(int targetHsk) {
    final w = hskW;
    if (w == null) return false;
    if (targetHsk <= 3) return w == 1;
    if (targetHsk <= 6) return w <= 2;
    return true;
  }

  /// 발음부 정보가 사람이 확인한 값인지(R1 검토값 · 이 앱 큐레이션 zh · 字源 대조 · 가족 승인).
  bool get phoneticConfirmed =>
      familyStatus == 'ok' ||
      phoneticSrc == 'R1' ||
      phoneticSrc == 'zh' ||
      phoneticSrc == '대조' ||
      phoneticCn != null;
}

/// 캐시 → 간체 기준 조회 색인. 네트워크와 무관해서 테스트하기 쉽게 따로 둔다.
class SharedHanjaIndex {
  final Map<String, SharedHanja> byCode;
  final Map<String, List<String>> _codesByCn;
  final Map<String, dynamic> _mnemonic;

  SharedHanjaIndex(this.byCode, this._codesByCn, this._mnemonic);

  factory SharedHanjaIndex.empty() => SharedHanjaIndex({}, {}, {});

  factory SharedHanjaIndex.fromCache(Map<String, dynamic> cache) {
    final rows = (cache['chars'] as Map?)?.values.whereType<Map>() ?? const [];
    final byCode = <String, SharedHanja>{};
    for (final r in rows) {
      final h = SharedHanja.fromJson(r.cast<String, dynamic>());
      byCode[h.code] = h;
    }
    final codesByCn = <String, List<String>>{};
    (cache['alias'] as Map?)?.forEach((ch, codes) {
      codesByCn[ch as String] = (codes as List).cast<String>().where(byCode.containsKey).toList();
    });
    for (final h in byCode.values) {
      final l = codesByCn[h.cn] ??= [];
      if (!l.contains(h.code)) l.add(h.code);
    }
    return SharedHanjaIndex(
        byCode, codesByCn, Map<String, dynamic>.from(cache['mnemonic'] as Map? ?? {}));
  }

  bool get isEmpty => byCode.isEmpty;

  /// 간체 한 글자에 해당하는 행들. 간체 하나가 정자 둘에 걸리면(钟 = 鐘·鍾) 둘 다.
  List<SharedHanja> rowsFor(String cn) =>
      (_codesByCn[cn] ?? const []).map((c) => byCode[c]).whereType<SharedHanja>().toList();

  /// 대표 행 — 간체가 그대로 `cn` 인 행 가운데 회화 빈도가 높은 것.
  SharedHanja? lookup(String cn) {
    final rows = rowsFor(cn);
    if (rows.isEmpty) return null;
    rows.sort((a, b) {
      final ea = a.cn == cn ? 0 : 1, eb = b.cn == cn ? 0 : 1;
      if (ea != eb) return ea - eb;
      return (a.zhCliffRank ?? 1 << 30).compareTo(b.zhCliffRank ?? 1 << 30);
    });
    return rows.first;
  }

  /// SHARED_DB §11: 간체 기준 발음부 글자 — phonetic_cn 이 있으면 그것, 없으면 phonetic 코드의 간체.
  String? phoneticOf(SharedHanja h) {
    if (h.phoneticCn != null && h.phoneticCn!.isNotEmpty) return h.phoneticCn;
    final p = h.phonetic;
    if (p == null) return null;
    final ph = byCode[p];
    if (ph != null) return ph.cn;
    // 공용 DB 에 없는 부품 코드면 코드포인트를 그대로 글자로
    final cp = int.tryParse(p.startsWith('U') ? p.substring(1) : p, radix: 16);
    return cp == null ? null : String.fromCharCode(cp);
  }

  /// 간체 한 글자의 발음부(같은 글자가 발음부면 null). 간체 하나가 정자 둘에 걸리면(钟 = 鐘·鍾)
  /// 간체 기준 값(phonetic_cn)이 있는 행을 먼저 본다 — 鍾 의 정자 발음부 重 보다 钟 의 中.
  String? phoneticFor(String cn) {
    final rows = rowsFor(cn).where((h) => h.cn == cn).toList();
    if (rows.isEmpty) return null;
    for (final h in rows) {
      final p = h.phoneticCn;
      if (p != null && p.isNotEmpty && p != cn) return p;
    }
    for (final h in rows) {
      final p = phoneticOf(h);
      if (p != null && p != cn) return p;
    }
    return null;
  }

  /// 발음부 글자(간체) → 그 발음부를 쓰는 간체 글자들(발음부 자신 제외, 회화 빈도순).
  /// 간체 한 글자는 발음부 하나에만 들어간다([phoneticFor]).
  Map<String, List<String>> families({bool Function(SharedHanja)? where}) {
    final rank = <String, int>{};
    for (final h in byCode.values) {
      if (where != null && !where(h)) continue;
      final r = h.zhCliffRank ?? 1 << 30;
      final old = rank[h.cn];
      if (old == null || r < old) rank[h.cn] = r;
    }
    final out = <String, List<String>>{};
    for (final cn in rank.keys) {
      final p = phoneticFor(cn);
      if (p == null) continue;
      (out[p] ??= []).add(cn);
    }
    for (final l in out.values) {
      l.sort((a, b) => rank[a]!.compareTo(rank[b]!));
    }
    return out;
  }

  /// 외우는 방법 — 자형이 다르면 간체판(form = cn)만. 정자판으로 대신하지 않는다.
  ({String? origin, String? tip})? mnemonicFor(SharedHanja h, String lang) {
    final form = h.formDiffers ? 'cn' : 'kr';
    final m = _mnemonic['${h.code}|$lang|$form'];
    if (m is! Map) return null;
    final origin = m['origin'] as String?, tip = m['tip'] as String?;
    if ((origin == null || origin.isEmpty) && (tip == null || tip.isEmpty)) return null;
    return (origin: origin, tip: tip);
  }
}
