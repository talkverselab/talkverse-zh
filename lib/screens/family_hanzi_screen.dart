import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/hanzi_family.dart';
import '../services/hanzi_info_service.dart';
import '../services/lexicon_service.dart';
import '../services/pinyin_util.dart';
import '../services/shared_hanja_service.dart';
import '../widgets/selectable_hanzi.dart';

/// 「패밀리 한자」 — 소리 부품(声旁)이 같은 한자 가족을 병음·성조 색으로 보여 준다(읽기 전용, 2026-11-02).
/// 데이터는 한자 공용 DB(`SharedHanjaIndex.families()`: 간체 한 글자 = 발음부 하나, 가족 안은 회화 빈도순)를 그대로 쓴다.
/// 글자를 누르면 한자 팝업. 가족 데이터·규칙은 한자 세션 소관이라 여기서 만들거나 고치지 않는다.
/// 시안 zh05(2026-11-03): 카드 상자 없이 여백으로 가족을 나눈다. 같은 소리 = 구리 테두리, 다른 소리 = 테두리 없음.
/// [focus] = 한자 팝업의 가족 줄에서 들어올 때 그 발음부 — 맨 위에 두고 표시한다.
class FamilyHanziScreen extends StatefulWidget {
  final String? focus;
  const FamilyHanziScreen({super.key, this.focus});

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
    if (q.isEmpty) return focusFirst(_all, widget.focus);
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
                          textAlign: TextAlign.center, style: AppFonts.uiText(color: AppColors.muted, height: 1.5)),
                    ),
                  )
                : LayoutBuilder(builder: (context, c) {
                    final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 600 ? 2 : 1);
                    return CustomScrollView(slivers: [
                      SliverToBoxAdapter(child: _header()),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 28, crossAxisSpacing: 28, mainAxisExtent: 168),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _FamilyCard(group: list[i], focused: list[i].phonetic == widget.focus),
                            childCount: list.length,
                          ),
                        ),
                      ),
                    ]);
                  }),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(trf('소리 부품이 같은 한자 가족 {0}개 · 글자를 누르면 한자 정보', [_all.length]), style: AppFonts.uiText(size: 13)),
          const SizedBox(height: 6),
          Wrap(spacing: 12, runSpacing: 4, children: [
            for (var t = 1; t <= 4; t++) _legend(trf('{0}성', [t]), toneColor(t)),
            _legend(tr('경성'), AppColors.toneNeutral),
            _legend(tr('▢ 구리 테두리 = 소리 같음'), AppColors.copper),
          ]),
          const SizedBox(height: 4),
          Text(tr('동음자 = 소리·성조 같음 · 형제 = 성조만 다름 · 친척 = 소리 다름'), style: AppFonts.captionText(size: 11)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            style: AppFonts.uiText(size: 14, color: AppColors.mo),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.xuanZhiDeep,
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.muted),
              hintText: tr('한자로 찾기 (예: 青)'),
              hintStyle: AppFonts.uiText(size: 13, color: AppColors.muted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ]),
      );

  Widget _legend(String t, Color c) => Text(t, style: AppFonts.captionText(size: 11, weight: FontWeight.w600, color: c));
}

/// [focus] 발음부 가족을 맨 앞으로(없으면 그대로).
List<FamilyGroup> focusFirst(List<FamilyGroup> all, String? focus) {
  if (focus == null) return all;
  final i = all.indexWhere((f) => f.phonetic == focus);
  if (i <= 0) return all;
  return [all[i], ...all.take(i), ...all.skip(i + 1)];
}

int? _toneOf(String py) {
  if (py.isEmpty) return null;
  final n = PinyinUtil.toNumbered(py);
  final t = int.tryParse(n.substring(n.length - 1));
  return t == null || t > 4 ? 0 : t;
}

/// 가족 하나 — 상자 없이: 발음부(큰 자형·병음·글자 수) 한 줄 + 구성원 타일.
class _FamilyCard extends StatelessWidget {
  final FamilyGroup group;
  final bool focused;
  const _FamilyCard({required this.group, this.focused = false});

  @override
  Widget build(BuildContext context) {
    final pPy = pinyinOf(group.phonetic);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
        onTap: () => showHanziSheet(context, group.phonetic),
        borderRadius: BorderRadius.circular(10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(group.phonetic, style: AppFonts.glyphText(size: 32, color: focused ? AppColors.copper : AppColors.copperDeep, height: 1)),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(pPy, style: AppFonts.pinyinText(size: 13, weight: FontWeight.w600, color: toneColor(_toneOf(pPy)))),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(trf('소리 부품 · {0}자', [group.members.length]), style: AppFonts.captionText(size: 11)),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: SingleChildScrollView(
          // 수준: 동음자(소리·성조 같음) → 형제(성조만 다름) → 친척(소리 다름)
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (k, label) in [(0, tr('동음자')), (1, tr('형제')), (2, tr('친척'))])
              if (group.members.any((m) => kinship(pinyinOf(m), pPy) == k)) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(label, style: AppFonts.captionText(size: 11, weight: FontWeight.w700, color: k == 2 ? AppColors.muted : AppColors.copperDeep)),
                ),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final m in group.members.where((m) => kinship(pinyinOf(m), pPy) == k))
                    FamilyGlyphTile(
                      ch: m,
                      pinyin: pinyinOf(m),
                      sameSound: k < 2,
                      onTap: () => showHanziSheet(context, m),
                    ),
                ]),
                const SizedBox(height: 10),
              ],
          ]),
        ),
      ),
    ]);
  }
}
