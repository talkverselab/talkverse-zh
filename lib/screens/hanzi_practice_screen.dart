import 'dart:math';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../services/shared_hanja_service.dart';
import '../services/tts_service.dart';
import '../widgets/selectable_hanzi.dart' show showHanziSheet;

/// 한자 연습 — 일본어앱 「한자 연습」을 옮김(2026-11-18 사용자 지시 「지금 일본어 앱만큼」, 일본어앱 2026-11-17 하루 3자).
/// 소리 부품(声旁)이 같은 글자가 3자 이상인 패밀리를 큰 가족부터, **하루 3자씩**. 하루치 = 그날 글자가 든 패밀리 조각들.
/// 하루 = 패밀리 보기(가족 글자는 회화 빈도순) → 「이 글자의 패밀리는?」 문제 → 마침 기록.
/// 가족 데이터는 한자 공용 DB(`SharedHanjaIndex.families()`) 그대로 — 패밀리 한자 화면과 같은 출처.
const int kCharsPerDay = 3;
const int kMinMembers = 3;
const int kMaxRank = 2000;
const _kDone = 'hanzi_practice_done_v1';
const _kWrong = 'hanzi_practice_wrong'; // 틀린 글자(맞히면 빠짐) — 누적 복습에서 먼저 낸다
const int kReviewSize = 20;

class KFamily {
  final String root;
  final String on; // 발음부의 병음
  final String ko; // 발음부의 한국 한자음
  final List<String> members; // 소리 부품 글자 제외, 회화 빈도순
  const KFamily(this.root, this.on, this.ko, this.members);
}

SharedHanjaIndex get _idx => SharedHanjaService.instance.index;

class KanjiPractice {
  static List<List<KFamily>>? _days;
  static List<String> roots = const [];

  static Future<List<List<KFamily>>> days() async {
    if (_days != null) return _days!;
    final svc = SharedHanjaService.instance;
    await svc.ensureLoaded();
    if (svc.index.isEmpty) await svc.syncIfStale(); // 첫 실행이면 받아 본다(실패하면 빈 채로)
    int rank(String c) => _idx.lookup(c)?.zhCliffRank ?? 1 << 30;
    final fams = <KFamily>[];
    // 글자 범위 = 앱의 절벽 한자 2,000자(회화 빈도 순위) — 일본어앱이 상용한자 안에서만 내는 것과 같게
    _idx.families(where: (h) => (h.zhCliffRank ?? 1 << 30) <= kMaxRank).forEach((r, m) {
      final mem = [for (final c in m) if (c != r) c];
      if (mem.length < kMinMembers) return;
      final h = _idx.lookup(r);
      fams.add(KFamily(r, (h?.pinyin.isNotEmpty ?? false) ? h!.pinyin.first : '', h?.kr ?? '', mem));
    });
    // 큰 가족부터, 같으면 회화에서 많이 쓰는 글자가 있는 가족부터
    fams.sort((a, b) {
      final c = b.members.length.compareTo(a.members.length);
      return c != 0 ? c : rank(a.members.first).compareTo(rank(b.members.first));
    });
    KanjiPractice.roots = [for (final f in fams) f.root];
    final pairs = [for (final f in fams) for (final m in f.members) (f, m)];
    final days = <List<KFamily>>[];
    for (var i = 0; i < pairs.length; i += kCharsPerDay) {
      final day = <KFamily>[];
      for (final (f, m) in pairs.sublist(i, min(i + kCharsPerDay, pairs.length))) {
        if (day.isNotEmpty && day.last.root == f.root) {
          day.last.members.add(m);
        } else {
          day.add(KFamily(f.root, f.on, f.ko, [m]));
        }
      }
      days.add(day);
    }
    return _days = days;
  }

  static Future<Set<String>> done() async => ((await Prefs.getInstance()).getStringList(_kDone) ?? const []).toSet();
  static Future<Set<String>> wrong() async => ((await Prefs.getInstance()).getStringList(_kWrong) ?? const []).toSet();
  static Future<void> answer(String c, bool ok) async {
    final p = await Prefs.getInstance();
    final s = (p.getStringList(_kWrong) ?? <String>[]).toSet();
    ok ? s.remove(c) : s.add(c);
    await p.setStringList(_kWrong, s.toList());
  }

  static Future<void> markDone(int day) async {
    final p = await Prefs.getInstance();
    await p.setStringList(_kDone, {...?p.getStringList(_kDone), '$day'}.toList());
  }
}

String _readingOf(String c) {
  final h = _idx.lookup(c);
  return h == null || h.pinyin.isEmpty ? '' : h.pinyin.first;
}

String _meaningOf(String c) {
  final h = _idx.lookup(c);
  if (h == null) return '';
  final hun = h.krHun ?? '';
  return hun.isNotEmpty ? hun : h.kr;
}

class KanjiPracticeScreen extends StatefulWidget {
  const KanjiPracticeScreen({super.key});
  @override
  State<KanjiPracticeScreen> createState() => _KanjiPracticeScreenState();
}

class _KanjiPracticeScreenState extends State<KanjiPracticeScreen> {
  List<List<KFamily>>? _days;
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await KanjiPractice.days();
    final done = await KanjiPractice.done();
    if (mounted) {
      setState(() {
        _days = d;
        _done = done;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(tr('한자 연습'))),
      body: days == null ? const Center(child: CircularProgressIndicator()) : _body(days),
    );
  }

  Widget _body(List<List<KFamily>> days) {
    final fams = days.expand((d) => d).map((f) => f.root).toSet().length;
    final chars = days.expand((d) => d).fold<int>(0, (a, f) => a + f.members.length);
    final next = List.generate(days.length, (i) => i + 1).firstWhere((n) => !_done.contains('$n'), orElse: () => -1);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
      children: [
        Text(tr('패밀리가 큰 한자부터 — 소리 부품 하나로 여러 글자를 한 번에'), style: const TextStyle(fontSize: 13, color: AppColors.moLight)),
        const SizedBox(height: 4),
        Text(trf('{0}패밀리 · {1}자 · 하루 {2}자 · {3}일', [fams, chars, kCharsPerDay, days.length]),
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        Text(trf('{0}/{1}일 마침', [_done.length, days.length]), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 10),
        _reviewButton(days),
        const SizedBox(height: 10),
        for (var i = 0; i < days.length; i++) _dayRow(i + 1, days[i], next == i + 1),
      ],
    );
  }

  /// 누적 복습 — 마친 날의 패밀리 전부에서 20문제, 틀린 글자 먼저.
  Widget _reviewButton(List<List<KFamily>> days) {
    final learned = [for (var i = 0; i < days.length; i++) if (_done.contains('${i + 1}')) ...days[i]];
    final n = learned.fold<int>(0, (a, f) => a + f.members.length);
    return FilledButton.icon(
      key: const ValueKey('kp-review'),
      style: FilledButton.styleFrom(backgroundColor: AppColors.copperDeep, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: learned.isEmpty
          ? null
          : () async {
              await openFull(context, (_) => KanjiReviewScreen(learned: learned, all: days.expand((d) => d).toList()));
              _load();
            },
      icon: const Icon(Icons.replay),
      label: Text(learned.isEmpty ? tr('누적 복습 — 1일차를 마치면 열려요') : trf('누적 복습 · {0}패밀리 {1}자에서 {2}문제', [learned.map((f) => f.root).toSet().length, n, min(kReviewSize, n)]),
          style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  Widget _dayRow(int n, List<KFamily> fams, bool isNext) {
    final isDone = _done.contains('$n');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isNext ? AppColors.xuanZhiDeep : AppColors.xuanZhi,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isNext ? AppColors.zhuHong : AppColors.line, width: isNext ? 1.4 : 1)),
        child: InkWell(
          key: ValueKey('kp-day-$n'),
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await openFull(context, (_) => KanjiPracticeDayScreen(day: n, families: fams));
            _load();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(children: [
              SizedBox(width: 56, child: Text(trf('{0}일차', [n]), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.zhuHong))),
              Expanded(
                child: Text(fams.expand((f) => f.members).join('  '), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.mo)),
              ),
              Flexible(child: Text(fams.map((f) => trf('「{0}」 패밀리', [f.root])).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.moLight))),
              const SizedBox(width: 8),
              if (isDone)
                const Icon(Icons.check_circle, color: AppColors.feiCui, size: 20)
              else if (isNext)
                Text(tr('다음'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.zhuHong)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 하루 — 패밀리 보기 → 문제.
class KanjiPracticeDayScreen extends StatefulWidget {
  final int day;
  final List<KFamily> families;
  const KanjiPracticeDayScreen({super.key, required this.day, required this.families});
  @override
  State<KanjiPracticeDayScreen> createState() => _KanjiPracticeDayScreenState();
}

class _KanjiPracticeDayScreenState extends State<KanjiPracticeDayScreen> {
  bool _quiz = false;
  late List<(String, KFamily, List<String>)> _qs;
  int _i = 0;
  String? _picked;
  int _right = 0;

  void _startQuiz() {
    // 보기 = 정답 + 그날의 다른 패밀리 + 모자라면 전체 패밀리에서 채워 4개
    List<String> opts(KFamily f) {
      final o = <String>{f.root, ...widget.families.map((x) => x.root)};
      for (final r in [...KanjiPractice.roots]..shuffle()) {
        if (o.length >= 4) break;
        o.add(r);
      }
      return o.toList()..shuffle();
    }
    _qs = [for (final f in widget.families) for (final m in f.members) (m, f, opts(f))]..shuffle();
    setState(() {
      _quiz = true;
      _i = 0;
      _picked = null;
      _right = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final finished = _quiz && _i >= _qs.length;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text('${trf('{0}일차', [widget.day])}  ${widget.families.expand((f) => f.members).join(' ')}')),
      body: !_quiz
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [for (final f in widget.families) _FamilyCard(f)],
            )
          : finished
              ? _summary()
              : _question(),
      bottomNavigationBar: _quiz && !finished
          ? null
          : Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
              child: FilledButton(
                key: const ValueKey('kp-action'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.zhuHong, minimumSize: const Size.fromHeight(48)),
                onPressed: finished
                    ? () async {
                        await KanjiPractice.markDone(widget.day);
                        if (context.mounted) Navigator.of(context).maybePop();
                      }
                    : _startQuiz,
                child: Text(finished ? tr('마침') : tr('문제 풀기')),
              ),
            ),
    );
  }

  Widget _summary() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(trf('{0}문제 중 {1}개 맞힘', [_qs.length, _right]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.mo)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _startQuiz, child: Text(tr('한 번 더'))),
        ]),
      );

  Widget _question() {
    final (c, fam, options) = _qs[_i];
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset(context)),
      child: Column(children: [
        Text('${_i + 1} / ${_qs.length}', style: const TextStyle(fontSize: 12, color: AppColors.moLight)),
        const SizedBox(height: 16),
        Text(c, style: AppFonts.zhText(size: 96, weight: FontWeight.w700)),
        if (_picked != null) Text('${_readingOf(c)}  ${_meaningOf(c)}', style: const TextStyle(fontSize: 15, color: AppColors.zhuHong, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(tr('이 글자의 패밀리(소리 부품)는?'), style: const TextStyle(fontSize: 14, color: AppColors.mo)),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
          for (final o in options)
            SizedBox(
              width: 88,
              height: 72,
              child: OutlinedButton(
                key: ValueKey('kp-opt-$o'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _picked == null ? null : (o == fam.root ? const Color(0x3336A35B) : (o == _picked ? const Color(0x33D83A3A) : null)),
                  side: BorderSide(color: _picked != null && o == fam.root ? AppColors.feiCui : AppColors.line, width: 1.4),
                ),
                onPressed: _picked != null
                    ? null
                    : () {
                        TtsService.instance.speak(c);
                        KanjiPractice.answer(c, o == fam.root);
                        setState(() {
                          _picked = o;
                          if (o == fam.root) _right++;
                        });
                      },
                child: Text(o, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.mo)),
              ),
            ),
        ]),
        const Spacer(),
        if (_picked != null)
          FilledButton(
            key: const ValueKey('kp-next'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.mo, minimumSize: const Size.fromHeight(48)),
            onPressed: () => setState(() {
              _i++;
              _picked = null;
            }),
            child: Text(tr('다음 →')),
          ),
      ]),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final KFamily f;
  const _FamilyCard(this.f);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.xuanZhi, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line), boxShadow: kCardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Tile(f.root, big: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trf('「{0}」 패밀리', [f.root]), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.mo)),
                Text(trf('소리 {0} · 한국음 {1}', [f.on, f.ko]), style: const TextStyle(fontSize: 12.5, color: AppColors.zhuHong, fontWeight: FontWeight.w700)),
                Text(tr('이 부품이 들어간 글자는 소리가 비슷해요'), style: const TextStyle(fontSize: 11.5, color: AppColors.moLight)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final m in f.members) _Tile(m)]),
        ]),
      );
}

class _Tile extends StatelessWidget {
  final String c;
  final bool big;
  const _Tile(this.c, {this.big = false});
  @override
  Widget build(BuildContext context) {
    final r = _readingOf(c), mean = _meaningOf(c);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => showHanziSheet(context, c),
      child: Container(
        width: big ? 64 : 76,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
            color: big ? AppColors.xuanZhiDeep : AppColors.xuanZhi, borderRadius: BorderRadius.circular(10), border: Border.all(color: big ? AppColors.copper : AppColors.line, width: big ? 1.4 : 1)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(c, style: TextStyle(fontSize: big ? 34 : 28, fontWeight: FontWeight.w900, color: AppColors.mo)),
          if (!big && r.isNotEmpty) Text(r, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.zhuHong, fontWeight: FontWeight.w700)),
          if (!big && mean.isNotEmpty) Text(mean, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.moLight)),
        ]),
      ),
    );
  }
}

/// 누적 복습 — 지금까지 마친 패밀리의 글자를 섞어 [kReviewSize] 문제. 틀린 적 있는 글자부터, 보기는 정답 + 배운 패밀리 3개(모자라면 전체에서).
class KanjiReviewScreen extends StatefulWidget {
  final List<KFamily> learned;
  final List<KFamily> all;
  const KanjiReviewScreen({super.key, required this.learned, required this.all});
  @override
  State<KanjiReviewScreen> createState() => _KanjiReviewScreenState();
}

class _KanjiReviewScreenState extends State<KanjiReviewScreen> {
  final _rnd = Random();
  List<(String, KFamily, List<String>)>? _qs;
  int _i = 0;
  String? _picked;
  int _right = 0;
  final Set<String> _missed = {};

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final wrong = await KanjiPractice.wrong();
    final pairs = [for (final f in widget.learned) for (final m in f.members) (m, f)]..shuffle(_rnd);
    pairs.sort((a, b) => (wrong.contains(b.$1) ? 1 : 0) - (wrong.contains(a.$1) ? 1 : 0)); // 틀린 글자 먼저(안에서는 섞인 채)
    final picked = pairs.take(kReviewSize).toList()..shuffle(_rnd);
    List<String> opts(KFamily f) {
      final others = {for (final o in widget.learned) if (o.root != f.root) o.root}.toList()..shuffle(_rnd);
      if (others.length < 3) others.addAll(({for (final o in widget.all) if (o.root != f.root && !others.contains(o.root)) o.root}.toList()..shuffle(_rnd)).take(3 - others.length));
      return [f.root, ...others.take(3)]..shuffle(_rnd);
    }
    if (mounted) setState(() => _qs = [for (final p in picked) (p.$1, p.$2, opts(p.$2))]);
  }

  void _again() => setState(() {
        _qs = null;
        _i = 0;
        _picked = null;
        _right = 0;
        _missed.clear();
        _build();
      });

  @override
  Widget build(BuildContext context) {
    final qs = _qs;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(tr('누적 복습'))),
      body: qs == null
          ? const Center(child: CircularProgressIndicator())
          : _i >= qs.length
              ? _summary(qs.length)
              : _question(qs[_i], qs.length),
    );
  }

  Widget _summary(int n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(trf('{0}문제 중 {1}개 맞힘', [n, _right]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.mo)),
            if (_missed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(tr('틀린 글자 — 다음 복습에 먼저 나와요'), style: const TextStyle(fontSize: 12, color: AppColors.moLight)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                for (final c in _missed)
                  ActionChip(label: Text(c, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), onPressed: () => showHanziSheet(context, c)),
              ]),
            ],
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton(key: const ValueKey('kr-again'), onPressed: _again, child: Text(tr('한 번 더'))),
              const SizedBox(width: 10),
              FilledButton(onPressed: () => Navigator.of(context).maybePop(), style: FilledButton.styleFrom(backgroundColor: AppColors.mo), child: Text(tr('나가기'))),
            ]),
          ]),
        ),
      );

  Widget _question((String, KFamily, List<String>) q, int n) {
    final (c, fam, options) = q;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset(context)),
      child: Column(children: [
        Text('${_i + 1} / $n', style: const TextStyle(fontSize: 12, color: AppColors.moLight)),
        const SizedBox(height: 16),
        Text(c, style: AppFonts.zhText(size: 96, weight: FontWeight.w700)),
        if (_picked != null) Text('${_readingOf(c)}  ${_meaningOf(c)}', style: const TextStyle(fontSize: 15, color: AppColors.zhuHong, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(tr('이 글자의 패밀리(소리 부품)는?'), style: const TextStyle(fontSize: 14, color: AppColors.mo)),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
          for (final o in options)
            SizedBox(
              width: 88,
              height: 72,
              child: OutlinedButton(
                key: ValueKey('kr-opt-$o'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _picked == null ? null : (o == fam.root ? const Color(0x3336A35B) : (o == _picked ? const Color(0x33D83A3A) : null)),
                  side: BorderSide(color: _picked != null && o == fam.root ? AppColors.feiCui : AppColors.line, width: 1.4),
                ),
                onPressed: _picked != null
                    ? null
                    : () {
                        final ok = o == fam.root;
                        TtsService.instance.speak(c);
                        KanjiPractice.answer(c, ok);
                        setState(() {
                          _picked = o;
                          if (ok) {
                            _right++;
                          } else {
                            _missed.add(c);
                          }
                        });
                      },
                child: Text(o, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.mo)),
              ),
            ),
        ]),
        const Spacer(),
        if (_picked != null)
          FilledButton(
            key: const ValueKey('kr-next'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.mo, minimumSize: const Size.fromHeight(48)),
            onPressed: () => setState(() {
              _i++;
              _picked = null;
            }),
            child: Text(tr('다음 →')),
          ),
      ]),
    );
  }
}
