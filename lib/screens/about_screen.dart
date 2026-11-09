import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../main.dart' show appDb;
import '../services/hanzi_cliff.dart';
import '../widgets/chinese_decor.dart';

/// 「앱 소개」 — 절벽구간이 무엇이고 어떻게 구했는지(2026-11-07, 일본어앱 §3 와 같은 짜임).
/// 두 화면(가로 720↑)은 레일 맨 아래 ⓘ, 폰은 프로필 → 정보 → 앱 소개.
/// 공개 저장소 규칙: 말뭉치 제공처·작품 이름은 적지 않는다("영화·드라마 자막"까지만).
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _Tier {
  final String name;
  final int from, to;
  final double cov;
  const _Tier(this.name, this.from, this.to, this.cov);
  int get count => to - from + 1;
}

class _AboutScreenState extends State<AboutScreen> {
  List<_Tier> _words = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 단어 구간은 DB `words` 의 region 과 cum_pct 로 — 경계가 바뀌면 표도 따라간다.
  Future<void> _load() async {
    final rows = await (appDb.select(appDb.words)..orderBy([(w) => OrderingTerm.asc(w.rank)])).get();
    final out = <_Tier>[];
    for (final r in ['R1', 'R2', 'R3', 'R4']) {
      final mine = rows.where((w) => w.region == r).toList();
      if (mine.isEmpty) continue;
      out.add(_Tier(r, mine.first.rank, mine.last.rank, mine.last.cumPct ?? 0));
    }
    if (mounted) setState(() => _words = out);
  }

  List<_Tier> get _hanzi => [
        for (var i = 0; i < HanziCliff.labels.length; i++)
          _Tier(HanziCliff.labels[i], i == 0 ? 1 : HanziCliff.bounds[i - 1] + 1, HanziCliff.bounds[i], HanziCliff.coverage[i]),
      ];

  @override
  Widget build(BuildContext context) {
    final w1 = _words.isNotEmpty ? _words.first : null;
    final w4 = _words.length >= 4 ? _words[3] : null;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(tr('앱 소개'))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.paddingOf(context).bottom),
          children: [
            Text('学海无涯', style: AppFonts.glyphText(size: 34, color: AppColors.zhuHong)),
            const SizedBox(height: 10),
            Text(
              w1 == null || w4 == null
                  ? tr('말은 자주 쓰는 소수의 단어가 대부분을 차지합니다. 그 경계가 「절벽」입니다.')
                  : trf('영화·드라마 대사에서 가장 자주 쓰는 {0}개 단어만 알면 들리는 말의 {1}%, {2}개면 {3}%가 됩니다. 그 뒤로는 단어를 아무리 더 외워도 들리는 비율이 더디게 오릅니다 — 이 경계를 「절벽」이라 부르고, 절벽까지를 R1~R4 네 구간으로 나누어 먼저 익히게 합니다.',
                      [w1.to, w1.cov.toStringAsFixed(0), w4.to, w4.cov.toStringAsFixed(0)]),
              style: AppFonts.uiText(size: 14.5, color: AppColors.mo, height: 1.6),
            ),
            _h(tr('1. 단어 기준')),
            if (_words.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.zhuHong))) else _TierTable(tiers: _words, unit: tr('어')),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(tr('중국어는 80% 지점이 2,000위 밖에 있어 R4 가 2,500위까지입니다(R5 없음).'), style: AppFonts.captionText(size: 11.5)),
            ),
            _h(tr('2. 한자 기준')),
            _TierTable(tiers: _hanzi, unit: tr('자')),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(trf('같은 대사에서 글자 하나를 토큰 하나로 다시 셌습니다. R1 {0}자로 한자의 55%, R4 {1}자로 80%, 2,000자로 {2}%를 읽습니다.', [HanziCliff.bounds[0], HanziCliff.bounds[3], HanziCliff.coverage[4].toStringAsFixed(1)]),
                  style: AppFonts.captionText(size: 11.5)),
            ),
            _h(tr('3. 산출 방식')),
            _p(tr('• 말뭉치: 중국어 영화·드라마 자막(영화 9,200편·드라마 5,960편, 한자 1억 2천만 자). 번체는 간체로 바꾸고 숫자·로마자·문장부호는 뺐습니다.')),
            _p(tr('• 빈도: 단어는 형태소 분절 토큰(한자가 든 것), 한자는 그 토큰의 글자. 순위별 누적 커버리지(들리는 말 중 아는 비율)를 구합니다.')),
            _p(tr('• 구간: 누적 55 · 60 · 70 · 80%에 처음 닿는 순위가 R1~R4 의 끝. 네 비율은 19개 언어 공통의 절대 기준이라 언어 간 비교가 됩니다.')),
            _h(tr('4. 앱에서 쓰는 곳')),
            _p(tr('• 절벽 단어 — 구간별 20어 단원, 회화 단어 포함 보기.')),
            _p(tr('• 한자 배우기 → 절벽 한자 R1~R5 — 20자 단원, 4지선다.')),
            _p(tr('• 회화 — 편마다 쓰는 단어의 구간(R1~R4)이 레벨입니다.')),
            _p(tr('• 성과 — 아는 단어 수가 다음 절벽에 얼마나 가까운지.')),
            const SizedBox(height: 20),
            const BrushDivider(),
            const SizedBox(height: 10),
            Center(child: Text(tr('중국어유니버스 · Talkverse'), style: AppFonts.captionText(size: 11, color: AppColors.moLight))),
          ],
        ),
      ),
    );
  }

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 22, 0, 8),
        child: Text(t, style: AppFonts.uiText(size: 15, weight: FontWeight.w600, color: AppColors.zhuHongDeep)),
      );
  Widget _p(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: AppFonts.uiText(size: 13.5, color: AppColors.mo, height: 1.55)),
      );
}

/// 구간표: 이름 · 순위 범위 · 개수 · 누적% + 등폭 5칸 막대.
class _TierTable extends StatelessWidget {
  final List<_Tier> tiers;
  final String unit;
  const _TierTable({required this.tiers, required this.unit});

  @override
  Widget build(BuildContext context) {
    final head = AppFonts.captionText(size: 11, weight: FontWeight.w600, color: AppColors.muted);
    final cell = AppFonts.uiText(size: 13, color: AppColors.mo);
    return Container(
      decoration: BoxDecoration(color: AppColors.xuanZhiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(children: [
        Row(children: [
          SizedBox(width: 36, child: Text(tr('구간'), style: head)),
          Expanded(child: Text(tr('순위'), style: head)),
          SizedBox(width: 64, child: Text(tr('개수'), style: head, textAlign: TextAlign.right)),
          SizedBox(width: 56, child: Text(tr('누적'), style: head, textAlign: TextAlign.right)),
        ]),
        const SizedBox(height: 4),
        for (final t in tiers)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              SizedBox(width: 36, child: Text(t.name, style: cell.copyWith(fontWeight: FontWeight.w600, color: AppColors.zhuHong))),
              Expanded(child: Text('${t.from}~${t.to}', style: cell)),
              SizedBox(width: 64, child: Text('${t.count}$unit', style: cell, textAlign: TextAlign.right)),
              SizedBox(width: 56, child: Text('${t.cov.toStringAsFixed(1)}%', style: cell, textAlign: TextAlign.right)),
            ]),
          ),
        const SizedBox(height: 8),
        // 구간 등폭 막대 — 칸마다 그 구간 끝의 누적%
        Row(children: [
          for (var i = 0; i < tiers.length; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == tiers.length - 1 ? 0 : 3),
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.zhuHong.withValues(alpha: 0.35 + 0.13 * i), borderRadius: BorderRadius.circular(4)),
                child: Text('${tiers[i].cov.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppColors.xuanZhi, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),
      ]),
    );
  }
}
