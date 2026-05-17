import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../widgets/chinese_decor.dart';
import 'hanzi_quiz_screen.dart';

class HanziStagesScreen extends StatefulWidget {
  const HanziStagesScreen({super.key});

  @override
  State<HanziStagesScreen> createState() => _HanziStagesScreenState();
}

class _HanziStagesScreenState extends State<HanziStagesScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/hanzi/hanzi_stages.json');
    setState(() {
      _data = json.decode(raw) as Map<String, dynamic>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('회화 시작점 한자 209',
                style: TextStyle(color: AppColors.mo, fontWeight: FontWeight.w800, fontSize: 15)),
            SizedBox(height: 2),
            Text('20자 × 10단계 · 4지선다 (누적)',
                style: TextStyle(color: AppColors.moLight, fontSize: 10, letterSpacing: 2)),
          ],
        ),
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading || _data == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final stages = (_data!['stages'] as List?) ?? [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.zhuHongDeep, AppColors.zhuHong],
            ),
            border: Border.all(color: AppColors.jin, width: 1.2),
          ),
          child: Row(
            children: [
              const SealStamp(text: '209', size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phase 2 sweet spot',
                      style: TextStyle(
                        color: AppColors.jinBright,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '20자 × 10단계',
                      style: const TextStyle(
                        color: AppColors.xuanZhi,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '누적 4지선다 — 회화 토큰 89% 청취 커버',
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
        ),
        const SizedBox(height: 12),
        ...List.generate(stages.length, (i) {
          final s = stages[i] as Map<String, dynamic>;
          return _StageRow(
            stageData: s,
            allStages: stages,
            isFirst: i == 0,
            isLast: i == stages.length - 1,
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  final Map<String, dynamic> stageData;
  final List allStages;
  final bool isFirst;
  final bool isLast;

  const _StageRow({
    required this.stageData,
    required this.allStages,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final stage = stageData['stage'] as int;
    final chars = (stageData['chars'] as List?) ?? [];
    final preview = chars.take(8).map((c) => (c as Map)['char'] as String).join(' ');

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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
