import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/script_sync.dart';
import 'package:video_player/video_player.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../data/entitlement.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';

/// 언어감각 익히기 — 정규과정. 일본어앱 같은 화면을 옮김(2026-11-18 사용자 지시 「지금 일본어 앱만큼」). L1~L10, 급마다 외울 대화 1회 + 참고.
/// 회차 = 문법 짧은 설명(points.tip) → 감 익히는 문장(points.sentences). 데이터 `assets/data/grammar/sense_course.json`(tools/sense/build_sense_course.py).
/// 내용은 간단하게 시작해 차차 늘린다 — 회차를 늘리려면 JSON 에 lessons 만 더하면 된다.
/// 메인 메뉴에 보일지 — 외울 대화를 Grok 대사로 바꾼 뒤 true(2026-11-18).
const kShowSenseCourse = true;

const _kDoneKey = 'sense_course_done';
const _kAsset = 'assets/data/grammar/sense_course.json';

class SenseCourse {
  static Map<String, dynamic>? _cache;
  static Future<Map<String, dynamic>> load() async =>
      // loadString 은 큰 파일을 다른 isolate 에서 풀어 위젯 테스트가 멈춘다 — 바이트로 읽어 여기서 푼다.
      _cache ??= withoutEmpty(json.decode(await ScriptSync.instance.load(_kAsset.substring('assets/data/'.length))) as Map<String, dynamic>);

  /// 내용 없는 회차·급은 뺀다 — 급 수·제목·순서는 데이터(서버 원고 우선)가 정하고, 빈 급은 「준비 중」 없이 숨김(11/23).
  static Map<String, dynamic> withoutEmpty(Map<String, dynamic> d) {
    bool has(Map<String, dynamic> ls) =>
        ls['open'] != null || ((ls['sentences'] as List?)?.isNotEmpty ?? false) || ((ls['points'] as List?)?.isNotEmpty ?? false);
    final levels = <Map<String, dynamic>>[];
    for (final lv in ((d['levels'] as List?) ?? const []).whereType<Map>()) {
      final ls = [for (final l in ((lv['lessons'] as List?) ?? const []).whereType<Map>()) if (has(l.cast<String, dynamic>())) l.cast<String, dynamic>()];
      if (ls.isNotEmpty) levels.add({...lv.cast<String, dynamic>(), 'lessons': ls});
    }
    return {...d, 'levels': levels};
  }

  @visibleForTesting
  static void debugClear() => _cache = null;

  static Future<Set<String>> done() async => ((await Prefs.getInstance()).getStringList(_kDoneKey) ?? const []).toSet();

  static Future<void> markDone(String id) async {
    final p = await Prefs.getInstance();
    final s = (p.getStringList(_kDoneKey) ?? <String>[]).toSet()..add(id);
    await p.setStringList(_kDoneKey, s.toList());
  }

  /// 회차 [index] 가 속한 급의 순번(1부터) — 언어감각 2급부터 이용권(PAYWALL_SPEC, 서버 freeSenseLevels).
  static int levelNo(Map<String, dynamic> d, int index) {
    final lvs = (d['levels'] as List).cast<Map<String, dynamic>>();
    final f = flat(d);
    return index < f.length ? lvs.indexOf(f[index].$1) + 1 : 1;
  }

  /// 모든 회차를 순서대로 (레벨, 회차) 쌍으로.
  static List<(Map<String, dynamic>, Map<String, dynamic>)> flat(Map<String, dynamic> d) => [
        for (final lv in (d['levels'] as List).cast<Map<String, dynamic>>())
          for (final ls in (lv['lessons'] as List).cast<Map<String, dynamic>>()) (lv, ls),
      ];
}

class SenseCourseScreen extends StatefulWidget {
  const SenseCourseScreen({super.key});

  @override
  State<SenseCourseScreen> createState() => _SenseCourseScreenState();
}

class _SenseCourseScreenState extends State<SenseCourseScreen> {
  Map<String, dynamic>? _data;
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await SenseCourse.load();
    final done = await SenseCourse.done();
    if (!mounted) return;
    setState(() {
      _data = d;
      _done = done;
    });
  }

  Future<void> _open(int index) async {
    final d = _data;
    if (d != null && !await Entitlement.gate(context, Entitlement.senseLevelFree(SenseCourse.levelNo(d, index)))) return;
    if (!mounted) return;
    await openFull(context, (_) => SenseLessonScreen(index: index));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(tr('언어감각 익히기'))),
      body: d == null ? const Center(child: CircularProgressIndicator()) : _body(d),
    );
  }

  Widget _body(Map<String, dynamic> d) {
    final all = SenseCourse.flat(d);
    bool isRef(Map<String, dynamic> l) => l['kind'] == 'ref';
    final next = all.indexWhere((e) => !isRef(e.$2) && !_done.contains(e.$2['id']));
    final real = all.where((e) => !isRef(e.$2)).toList();
    final children = <Widget>[
      Text(tr('영상을 보고, 대화를 통째로 외워요. 규칙은 참고에만 있어요.'),
          style: const TextStyle(fontSize: 13, color: AppColors.moLight)),
      const SizedBox(height: 4),
      Text(trf('{0}/{1}회 마침', [real.where((e) => _done.contains(e.$2['id'])).length, real.length]),
          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ];
    var i = 0, lvNo = 0;
    for (final lv in (d['levels'] as List).cast<Map<String, dynamic>>()) {
      lvNo++;
      final locked = !Entitlement.senseLevelFree(lvNo) && !Entitlement.premium;
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
        child: Text('${lv['id']}  ${lv['title']}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.mo)),
      ));
      var n = 1;
      for (final ls in (lv['lessons'] as List).cast<Map<String, dynamic>>()) {
        final idx = i;
        final isDone = _done.contains(ls['id']);
        final isNext = idx == next;
        if (ls['open'] != null) {
          // 다른 메뉴로 가는 버튼(회차 아님)
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              key: ValueKey('sense-${ls['id']}'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.zhuHong, side: const BorderSide(color: AppColors.zhuHong), minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => _open(idx),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(tr(ls['title'] as String), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ));
          i++;
          continue;
        }
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isNext ? AppColors.xuanZhiDeep : AppColors.xuanZhi,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isNext ? AppColors.zhuHong : AppColors.line, width: isNext ? 1.4 : 1),
            ),
            child: InkWell(
              key: ValueKey('sense-${ls['id']}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _open(idx),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(children: [
                  SizedBox(
                    width: 44,
                    child: Text(isRef(ls) ? tr('참고') : trf('{0}회', [n]),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.zhuHong)),
                  ),
                  Expanded(
                    child: Text(ls['title'] as String,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.mo)),
                  ),
                  if (locked)
                    const LockBadge(size: 18)
                  else if (isDone)
                    const Icon(Icons.check_circle, color: AppColors.feiCui, size: 20)
                  else if (isNext)
                    Text(tr('다음'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.zhuHong)),
                ]),
              ),
            ),
          ),
        ));
        i++;
        if (!isRef(ls)) n++;
      }
    }
    return ListView(padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)), children: children);
  }
}

/// 한 회차 — 문법 설명 → 문장. 아래 「마침 · 다음 회」 버튼.
class SenseLessonScreen extends StatefulWidget {
  final int index;
  const SenseLessonScreen({super.key, required this.index});

  @override
  State<SenseLessonScreen> createState() => _SenseLessonScreenState();
}

class _SenseLessonScreenState extends State<SenseLessonScreen> {
  List<(Map<String, dynamic>, Map<String, dynamic>)>? _all;

  @override
  void initState() {
    super.initState();
    SenseCourse.load().then((d) {
      if (mounted) setState(() => _all = SenseCourse.flat(d));
    });
  }

  Future<void> _finish() async {
    final all = _all!;
    if (all[widget.index].$2['kind'] == 'ref') {
      Navigator.of(context).pop(); // 참고는 기록하지 않는다
      return;
    }
    await SenseCourse.markDone(all[widget.index].$2['id'] as String);
    if (!mounted) return;
    var nextIdx = widget.index + 1;
    while (nextIdx < all.length && all[nextIdx].$2['kind'] == 'ref') {
      nextIdx++;
    }
    final d = await SenseCourse.load();
    if (!mounted) return;
    if (nextIdx < all.length && !Entitlement.senseLevelFree(SenseCourse.levelNo(d, nextIdx)) && !Entitlement.premium) {
      Navigator.of(context).pop(); // 다음 급은 이용권 — 목록으로 돌아가 자물쇠를 보게
      return;
    }
    if (nextIdx < all.length) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SenseLessonScreen(index: nextIdx)));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    if (all == null) {
      return const Scaffold(backgroundColor: AppColors.xuanZhi, body: Center(child: CircularProgressIndicator()));
    }
    final (lv, ls) = all[widget.index];
    final lessons = (lv['lessons'] as List);
    final isRef = ls['kind'] == 'ref';
    final n = lessons.take(lessons.indexOf(ls) + 1).where((l) => (l as Map)['kind'] != 'ref').length;
    final points = ((ls['points'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final memorize = ls['kind'] == 'memorize';
    final last = !all.skip(widget.index + 1).any((e) => e.$2['kind'] != 'ref');
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Text('${lv['id']} · ${isRef ? tr('참고') : trf('{0}회', [n])}  ${ls['title']}', overflow: TextOverflow.ellipsis),
        actions: const [KoReadingToggleAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: memorize ? [_Memorize(lesson: ls)] : [for (final p in points) _Point(point: p)],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
        child: FilledButton(
          key: const ValueKey('sense-finish'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.zhuHong, minimumSize: const Size.fromHeight(48)),
          onPressed: _finish,
          child: Text(isRef ? tr('닫기') : (last ? tr('마침') : tr('마침 · 다음 회'))),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final Map<String, dynamic> point;
  const _Point({required this.point});

  @override
  Widget build(BuildContext context) {
    final sentences = (point['sentences'] as List).cast<Map<String, dynamic>>();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.xuanZhi,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: kCardShadow,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(point['head'] as String,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.zhuHong)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.xuanZhiDeep, borderRadius: BorderRadius.circular(8)),
          child: Text('💡 ${point['tip']}', style: const TextStyle(fontSize: 13, color: AppColors.mo, height: 1.45)),
        ),
        const SizedBox(height: 6),
        for (final s in sentences)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s['zh'] as String, style: AppFonts.zhText(size: 18, weight: FontWeight.w700, height: 1.35)),
                  if (s['pinyin'] != null)
                    KoReadingText(s['pinyin'] as String, style: const TextStyle(fontSize: 12, color: AppColors.moLight, fontStyle: FontStyle.italic)),
                  Text(s['ko'] as String,
                      style: const TextStyle(fontSize: 13, color: AppColors.zhuHong, fontWeight: FontWeight.w600)),
                ]),
              ),
              IconButton(
                tooltip: tr('듣기'),
                icon: const Icon(Icons.volume_up, color: AppColors.zhuHong, size: 22),
                onPressed: () => TtsService.instance.speak(s['zh'] as String),
              ),
            ]),
          ),
      ]),
    );
  }
}

/// 「5문장을 암기하세요」 회차 — 영상 → 안내 한 줄 → 문장만(조사 설명 없음).
/// 문장 표시 `{글자|번호}` = 견줄 자리. 같은 번호는 중국어·한국어에서 같은 색 — 두 말을 견줘 보게(일본어앱 2026-11-11 사용자 지시와 같은 꼴).
const _kMarkColors = [
  Color(0xFFD83A3A), Color(0xFF2F6FDB), Color(0xFF1E9E5A), Color(0xFFE08A00), Color(0xFF8E44AD),
  Color(0xFF00897B), Color(0xFFC2185B), Color(0xFF5D4037), Color(0xFF3949AB), Color(0xFF7CB342),
];

final _kMark = RegExp(r'\{([^|}]+)\|(\d+)\}');

/// 표시 없앤 본문(듣기용).
String plainMarked(String s) => s.replaceAllMapped(_kMark, (m) => m.group(1)!);

List<InlineSpan> markedSpans(String s, TextStyle base) {
  final out = <InlineSpan>[];
  var i = 0;
  for (final m in _kMark.allMatches(s)) {
    if (m.start > i) out.add(TextSpan(text: s.substring(i, m.start)));
    final c = _kMarkColors[(int.parse(m.group(2)!) - 1) % _kMarkColors.length];
    out.add(TextSpan(
        text: m.group(1),
        style: TextStyle(color: c, fontWeight: FontWeight.w900, decoration: TextDecoration.underline, decorationColor: c.withValues(alpha: 0.5), decorationThickness: 2)));
    i = m.end;
  }
  if (i < s.length) out.add(TextSpan(text: s.substring(i)));
  return out;
}

class _Memorize extends StatelessWidget {
  final Map<String, dynamic> lesson;
  const _Memorize({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final sentences = (lesson['sentences'] as List).cast<Map<String, dynamic>>();
    final video = (lesson['video'] as String?) ?? '';
    final jaStyle = AppFonts.zhText(size: 19, weight: FontWeight.w700);
    const koStyle = TextStyle(fontSize: 14, color: AppColors.mo, height: 1.45);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (video.isNotEmpty) ...[LessonVideo(url: video), const SizedBox(height: 12)],   // 영상이 없으면 빈 「영상 준비 중」 칸을 안 보인다(11/22 심사 대비)
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.xuanZhiDeep, borderRadius: BorderRadius.circular(10)),
        child: Text('💡 ${lesson['note'] ?? ''}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.mo, height: 1.45)),
      ),
      const SizedBox(height: 6),
      for (var i = 0; i < sentences.length; i++)
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(color: AppColors.xuanZhi, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line), boxShadow: kCardShadow),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${i + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.zhuHong)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (sentences[i]['who'] != null) Text(sentences[i]['who'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.moLight)),
                Text.rich(TextSpan(style: jaStyle, children: markedSpans(sentences[i]['zh'] as String, jaStyle))),
                if (sentences[i]['pinyin'] != null)
                  KoReadingText(sentences[i]['pinyin'] as String, style: const TextStyle(fontSize: 12, color: AppColors.moLight, fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Text.rich(TextSpan(style: koStyle, children: markedSpans(sentences[i]['ko'] as String, koStyle))),
              ]),
            ),
            IconButton(
              tooltip: tr('듣기'),
              icon: const Icon(Icons.volume_up, color: AppColors.zhuHong, size: 22),
              onPressed: () => TtsService.instance.speak(plainMarked(sentences[i]['zh'] as String)),
            ),
          ]),
        ),
      if ((lesson['footnotes'] as List?)?.isNotEmpty ?? false) ...[
        const SizedBox(height: 16),
        Text(tr('한국어와 다른 곳만 잠깐'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.moLight)),
        const SizedBox(height: 4),
        for (final f in (lesson['footnotes'] as List).cast<String>())
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('· $f', style: const TextStyle(fontSize: 11.5, color: AppColors.moLight, height: 1.45)),
          ),
      ],
    ]);
  }
}

/// 회차 영상 — 주소가 비었으면 「영상 준비 중」 칸, 있으면 서버에서 바로 틀기(앱에 넣지 않는다). 탭 = 재생/멈춤.
class LessonVideo extends StatefulWidget {
  final String url;
  const LessonVideo({super.key, required this.url});
  @override
  State<LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends State<LessonVideo> {
  VideoPlayerController? _c;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.url.isEmpty) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _c = c;
    c.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((Object e) {
      debugPrint('LessonVideo: $e');
      if (mounted) setState(() => _failed = true);
    });
    c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Widget _box(Widget child) => Container(
        key: const ValueKey('memorize-video'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: AppColors.xuanZhiDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        alignment: Alignment.center,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null || _failed) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _box(Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎬', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          Text(_failed ? tr('영상을 불러오지 못했어요') : tr('영상 준비 중'), style: const TextStyle(fontSize: 12, color: AppColors.moLight)),
        ])),
      );
    }
    final v = c.value;
    if (!v.isInitialized) return AspectRatio(aspectRatio: 16 / 9, child: _box(const CircularProgressIndicator()));
    return AspectRatio(
      aspectRatio: v.aspectRatio,
      child: GestureDetector(
        onTap: () {
          if (v.position >= v.duration) c.seekTo(Duration.zero);
          v.isPlaying ? c.pause() : c.play();
        },
        child: _box(Stack(fit: StackFit.expand, children: [
          VideoPlayer(c),
          if (!v.isPlaying) const Center(child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white70)),
          Align(alignment: Alignment.bottomCenter, child: VideoProgressIndicator(c, allowScrubbing: true)),
        ])),
      ),
    );
  }
}
