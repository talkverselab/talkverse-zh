import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/hanzi_info_service.dart';
import '../services/lexicon_service.dart';
import '../services/pinyin_util.dart';
import '../services/shared_hanja_service.dart';
import '../widgets/selectable_hanzi.dart';

/// 「패밀리 한자」 — 소리 부품(声旁)이 같은 한자 가족을 병음·성조 색으로 보여 준다(읽기 전용, 2026-11-02).
/// 데이터는 한자 공용 DB(`SharedHanjaIndex.families()`: 간체 한 글자 = 발음부 하나, 가족 안은 회화 빈도순)를 그대로 쓴다.
/// 글자를 누르면 한자 팝업. 가족 데이터·규칙은 한자 세션 소관이라 여기서 만들거나 고치지 않는다.
class FamilyHanziScreen extends StatefulWidget {
  const FamilyHanziScreen({super.key});

  @override
  State<FamilyHanziScreen> createState() => _FamilyHanziScreenState();
}

class FamilyGroup {
  final String phonetic;
  final List<String> members;
  const FamilyGroup(this.phonetic, this.members);
}

/// 가족 목록: 두 글자 이상인 가족만, 가장 흔한 구성원이 앞선 가족부터.
List<FamilyGroup> buildFamilies(SharedHanjaIndex idx) {
  final fam = idx.families();
  int rankOf(String ch) => idx.lookup(ch)?.zhCliffRank ?? 1 << 30;
  final out = [
    for (final e in fam.entries)
      if (e.value.length >= 2) FamilyGroup(e.key, e.value),
  ];
  out.sort((a, b) => rankOf(a.members.first).compareTo(rankOf(b.members.first)));
  return out;
}

class _FamilyHanziScreenState extends State<FamilyHanziScreen> {
  bool _loading = true;
  List<FamilyGroup> _all = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = SharedHanjaService.instance;
    await svc.ensureLoaded();
    if (svc.index.isEmpty) await svc.syncIfStale(); // 첫 실행이면 받아 본다(실패하면 빈 채로)
    await LexiconService.instance.ensureLoaded();
    await HanziInfoService.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _all = buildFamilies(svc.index);
      _loading = false;
    });
  }

  List<FamilyGroup> get _shown {
    final q = _query.trim();
    if (q.isEmpty) return _all;
    return _all.where((f) => f.phonetic.contains(q) || f.members.any(q.contains)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _shown;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(tr('패밀리 한자'))),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.copper))
            : _all.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(tr('준비 중 — 한자 공용 DB 를 아직 받지 못했어요. 인터넷에 연결한 뒤 다시 열어 주세요.'),
                          textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.5)),
                    ),
                  )
                : LayoutBuilder(builder: (context, c) {
                    final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 600 ? 2 : 1);
                    return CustomScrollView(slivers: [
                      SliverToBoxAdapter(child: _header()),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 176),
                          delegate: SliverChildBuilderDelegate((context, i) => _FamilyCard(group: list[i]), childCount: list.length),
                        ),
                      ),
                    ]);
                  }),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(trf('소리 부품이 같은 한자 가족 {0}개 · 글자를 누르면 한자 정보', [_all.length]),
              style: const TextStyle(fontSize: 12.5, color: AppColors.moLight, height: 1.4)),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 4, children: [
            for (var t = 1; t <= 4; t++) _legend(trf('{0}성', [t]), toneColor(t)),
            _legend(tr('경성'), AppColors.toneNeutral),
            _legend(tr('● 소리 같음'), AppColors.copper),
          ]),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: tr('한자로 찾기 (예: 青)'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
            ),
          ),
        ]),
      );

  Widget _legend(String t, Color c) => Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c));
}

/// 글자 → 성조 부호 병음(첫 읽기). 공용 DB → 앱 사전 순.
String pinyinOf(String ch) {
  final h = SharedHanjaService.instance.index.lookup(ch);
  if (h != null && h.pinyin.isNotEmpty) return h.pinyin.first;
  return LexiconService.instance.lookup(ch)?.pinyin.split(RegExp(r'[\s,/]')).first ?? '';
}

int? _toneOf(String py) {
  if (py.isEmpty) return null;
  final n = PinyinUtil.toNumbered(py);
  final t = int.tryParse(n.substring(n.length - 1));
  return t == null || t > 4 ? 0 : t;
}

class _FamilyCard extends StatelessWidget {
  final FamilyGroup group;
  const _FamilyCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final pPy = pinyinOf(group.phonetic);
    final pBase = PinyinUtil.stripTones(pPy);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.xuanZhi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14), boxShadow: kCardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          InkWell(
            onTap: () => showHanziSheet(context, group.phonetic),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(gradient: AppColors.wordmark, borderRadius: BorderRadius.circular(10)),
              child: Text(group.phonetic, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pPy, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: toneColor(_toneOf(pPy)))),
              Text(trf('소리 부품 · {0}자', [group.members.length]), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final m in group.members) _MemberChip(ch: m, sameSound: pBase.isNotEmpty && PinyinUtil.stripTones(pinyinOf(m)) == pBase),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final String ch;
  final bool sameSound;
  const _MemberChip({required this.ch, required this.sameSound});

  @override
  Widget build(BuildContext context) {
    final py = pinyinOf(ch);
    final c = toneColor(_toneOf(py));
    return InkWell(
      onTap: () => showHanziSheet(context, ch),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.06),
          border: Border.all(color: sameSound ? AppColors.copper : c.withValues(alpha: 0.5), width: sameSound ? 1.4 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(ch, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.mo, height: 1.15)),
          Text(py.isEmpty ? '·' : py, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c)),
        ]),
      ),
    );
  }
}
