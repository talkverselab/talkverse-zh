import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../widgets/chinese_decor.dart';
import 'hanzi_quiz_screen.dart';

/// 한자 허브 — 회화 시작점 209자 / HSK 1~5급 1,500자 선택.
class HanziHubScreen extends StatelessWidget {
  const HanziHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: const Text('한자')),
      body: SafeArea(
        // 아이폰 홈 표시줄·갤럭시 제스처 바 아래로 내용이 깔리지 않게
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HubCard(
              seal: '209',
              title: '회화 시작점 한자 209',
              sub: '20자 × 10단계 · 회화 토큰 89% 청취 커버',
              color: AppColors.zhuHong,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HanziStagesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _HubCard(
              seal: 'HSK',
              title: 'HSK 1~5급 한자 1500',
              sub: '회화 빈도순 5단계 × 300자 · 20자씩 75소단계',
              color: const Color(0xFFC62828),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HanziStagesScreen(
                    asset: 'assets/data/hanzi/hanzi_hsk1500.json',
                    seal: '1500',
                    kicker: 'HSK 1-5 · 1,500 chars',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String seal, title, sub;
  final Color color;
  final VoidCallback onTap;
  const _HubCard({
    required this.seal,
    required this.title,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.xuanZhi,
          border: Border.all(color: AppColors.jin.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.mo.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SealStamp(text: seal, size: 52, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mo)),
                  const SizedBox(height: 4),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.moLight, height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.moLight),
          ],
        ),
      ),
    );
  }
}

/// 한자 단계 목록. JSON `stages[]` 필수, `phases[]` 있으면 큰 단계로 묶어 표시.
class HanziStagesScreen extends StatefulWidget {
  final String asset;
  final String seal;
  final String kicker;
  const HanziStagesScreen({
    super.key,
    this.asset = 'assets/data/hanzi/hanzi_stages.json',
    this.seal = '209',
    this.kicker = 'Phase 2 sweet spot',
  });

  @override
  State<HanziStagesScreen> createState() => _HanziStagesScreenState();
}

class _HanziStagesScreenState extends State<HanziStagesScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  int _openPhase = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(widget.asset);
    setState(() {
      _data = json.decode(raw) as Map<String, dynamic>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _data?['title'] as String? ?? '한자';
    final subtitle = _data?['subtitle'] as String? ?? '';
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.mo,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.moLight, fontSize: 10, letterSpacing: 1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        // 아이폰 홈 표시줄·갤럭시 제스처 바 아래로 내용이 깔리지 않게
        top: false,
        child: _loading || _data == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.zhuHong))
            : _buildBody(),
      ),
    );
  }

  Widget _header(List stages) {
    final total = _data!['total'] ?? stages.fold<int>(
        0, (s, e) => s + ((e as Map)['chars'] as List).length);
    final phases = (_data!['phases'] as List?) ?? const [];
    final headline = phases.isEmpty
        ? '20자 × ${stages.length}단계'
        : '${phases.length}단계 × 300자';
    final desc = phases.isEmpty
        ? '누적 4지선다 — 회화 토큰 89% 청취 커버'
        : '회화 빈도순 · 1단계 300자만 익혀도 회화 한자 ${(phases.first as Map)['coverage_pct']}% 커버';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.zhuHongDeep, AppColors.zhuHong],
        ),
        border: Border.all(color: AppColors.jin, width: 1.2),
      ),
      child: Row(
        children: [
          SealStamp(text: widget.seal, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kicker,
                  style: const TextStyle(
                    color: AppColors.jinBright,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$headline · $total자',
                  style: const TextStyle(
                    color: AppColors.xuanZhi,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: AppColors.xuanZhi.withValues(alpha: 0.9),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final stages = (_data!['stages'] as List?) ?? [];
    final phases = (_data!['phases'] as List?) ?? const [];
    final children = <Widget>[_header(stages), const SizedBox(height: 12)];

    if (phases.isEmpty) {
      children.addAll(List.generate(stages.length, (i) {
        final s = stages[i] as Map<String, dynamic>;
        return _StageRow(stageData: s, allStages: stages);
      }));
    } else {
      for (final p in phases.cast<Map>()) {
        final n = p['phase'] as int;
        final mine = stages
            .cast<Map<String, dynamic>>()
            .where((s) => s['phase'] == n)
            .toList();
        final open = _openPhase == n;
        children.add(
          InkWell(
            onTap: () => setState(() => _openPhase = open ? 0 : n),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: open ? AppColors.zhuHong : AppColors.xuanZhiDeep,
                border: Border.all(color: AppColors.jin.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Text(
                    '$n단계',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: open ? AppColors.xuanZhi : AppColors.mo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${p['from']}~${p['to']}번째 한자 · 누적 커버 ${p['coverage_pct']}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: open
                            ? AppColors.xuanZhi.withValues(alpha: 0.9)
                            : AppColors.moLight,
                      ),
                    ),
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more,
                      color: open ? AppColors.xuanZhi : AppColors.moLight),
                ],
              ),
            ),
          ),
        );
        if (open) {
          children.addAll(
              mine.map((s) => _StageRow(stageData: s, allStages: stages)));
          children.add(const SizedBox(height: 6));
        }
      }
    }
    children.add(const SizedBox(height: 20));
    return ListView(padding: const EdgeInsets.all(16), children: children);
  }
}

class _StageRow extends StatelessWidget {
  final Map<String, dynamic> stageData;
  final List allStages;

  const _StageRow({required this.stageData, required this.allStages});

  @override
  Widget build(BuildContext context) {
    final stage = stageData['stage'] as int;
    final chars = (stageData['chars'] as List?) ?? [];
    final preview =
        chars.take(8).map((c) => (c as Map)['char'] as String).join(' ');
    final cov = stageData['coverage_pct'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HanziQuizScreen(stage: stage, allStages: allStages),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.xuanZhi,
            border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.mo.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  color: AppColors.zhuHong,
                  child: Text(
                    '$stage',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.xuanZhi,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '단계 $stage',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mo,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            color: AppColors.jin.withValues(alpha: 0.2),
                            child: Text(
                              '${chars.length}자',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.mo,
                              ),
                            ),
                          ),
                          if (cov != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '누적 $cov%',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.moLight),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$preview …',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.mo,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.quiz, color: AppColors.zhuHong),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
