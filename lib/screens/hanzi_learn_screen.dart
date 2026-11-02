import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/hanzi_info_service.dart';
import '../services/lexicon_service.dart';
import '../services/tts_service.dart';
import '../widgets/selectable_hanzi.dart';
import 'hanzi_quiz_screen.dart';

/// 「한자 배우기」 — 일본어앱 `kanji_learn_screen.dart` 를 옮김(2026-11-02).
/// 단계(20자)를 한 글자씩 **먼저 배우고**(병음·뜻·발음부 가족 + 한자 공용 DB: 그림·외우는 방법·쓰기 범위),
/// 다 보면 그 단계 4지선다(`HanziQuizScreen`)로 간다. 글자 정보는 한자 팝업과 같은 [HanziInfoBody].
/// 폰: 한 글자 한 페이지(좌우 넘김). 넓은 화면(가로 720 이상): 왼쪽 20자 격자 · 오른쪽 글자 정보.
/// 시안 zh05(2026-11-03): 큰 자형(LXGW WenKai 60) + 가족 한 줄, 격자·하단은 상자·테두리 없이.
class HanziLearnStageScreen extends StatefulWidget {
  final int stage;
  final List allStages; // hanzi_stages.json 의 stages[] 그대로
  const HanziLearnStageScreen({super.key, required this.stage, required this.allStages});

  @override
  State<HanziLearnStageScreen> createState() => _HanziLearnStageScreenState();
}

class _HanziLearnStageScreenState extends State<HanziLearnStageScreen> {
  late final List<Map> _chars = [
    for (final s in widget.allStages)
      if ((s as Map)['stage'] == widget.stage)
        for (final c in (s['chars'] as List? ?? const [])) c as Map,
  ];
  late final PageController _page = PageController();
  final Set<int> _seen = {0};
  int _idx = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.wait([HanziInfoService.instance.ensureLoaded(), LexiconService.instance.ensureLoaded()]).whenComplete(() {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _page.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  String _ch(int i) => _chars[i]['char'] as String? ?? '';

  void _go(int i) {
    if (i < 0 || i >= _chars.length) return;
    setState(() {
      _idx = i;
      _seen.add(i);
    });
    if (!isWide(context) && _page.hasClients) {
      _page.animateToPage(i, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  void _quiz() => Navigator.push(context, MaterialPageRoute(builder: (_) => HanziQuizScreen(stage: widget.stage, allStages: widget.allStages)));

  Widget _body(int i) => HanziInfoBody(
        key: ValueKey(_ch(i)),
        char: _ch(i),
        info: HanziInfoService.instance.lookup(_ch(i)),
        lex: LexiconService.instance.lookup(_ch(i)),
        showClose: false,
        initiallyExpanded: true, // 배우는 화면이라 외우는 방법까지 펼쳐 둔다
      );

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final allSeen = _seen.length >= _chars.length;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(trf('한자 배우기 · 단계 {0}', [widget.stage]), style: AppFonts.titleText(size: 18)),
          const SizedBox(height: 1),
          Text('${_idx + 1} / ${_chars.length}', style: AppFonts.captionText(size: 10.5)),
        ]),
        actions: [
          TextButton.icon(
            onPressed: _quiz,
            icon: const Icon(Icons.quiz_outlined, size: 18),
            label: Text(tr('문제 풀기'), style: AppFonts.captionText(size: 12, weight: FontWeight.w600, color: allSeen ? AppColors.copper : AppColors.muted)),
            style: TextButton.styleFrom(foregroundColor: allSeen ? AppColors.copper : AppColors.muted),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _chars.isEmpty
            ? Center(child: Text(tr('준비 중'), style: const TextStyle(color: AppColors.muted)))
            : !_ready
                ? const Center(child: CircularProgressIndicator(color: AppColors.copper))
                : Column(children: [
                    Expanded(
                      child: wide
                          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              SizedBox(width: 300, child: _Grid(chars: _chars, idx: _idx, seen: _seen, onTap: _go)),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(32, 14, 32, 24),
                                  child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: _body(_idx))),
                                ),
                              ),
                            ])
                          : PageView.builder(
                              controller: _page,
                              itemCount: _chars.length,
                              onPageChanged: (i) => setState(() {
                                _idx = i;
                                _seen.add(i);
                              }),
                              itemBuilder: (context, i) => SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                                child: _body(i),
                              ),
                            ),
                    ),
                    _Bottom(
                      idx: _idx,
                      total: _chars.length,
                      allSeen: allSeen,
                      onPrev: () => _go(_idx - 1),
                      onNext: () => _go(_idx + 1),
                      onSpeak: () => TtsService.instance.speak(_ch(_idx)),
                      onQuiz: _quiz,
                    ),
                  ]),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Map> chars;
  final int idx;
  final Set<int> seen;
  final ValueChanged<int> onTap;
  const _Grid({required this.chars, required this.idx, required this.seen, required this.onTap});

  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.9),
        itemCount: chars.length,
        itemBuilder: (context, i) {
          final on = i == idx;
          final done = seen.contains(i);
          final c = chars[i];
          final meaning = (c['meaning'] as String? ?? '').split(RegExp(r'[·,(]')).first.trim();
          return InkWell(
            onTap: () => onTap(i),
            borderRadius: BorderRadius.circular(12),
            // 상자 없이: 지금 글자만 연한 구리 바탕, 본 글자는 아래 점
            child: Container(
              decoration: BoxDecoration(
                color: on ? AppColors.copper.withValues(alpha: 0.10) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(c['char'] as String? ?? '', style: AppFonts.glyphText(size: AppFonts.glyphTile, color: on ? AppColors.copperDeep : AppColors.mo)),
                const SizedBox(height: 2),
                Text(meaning, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.captionText(size: 10.5)),
                const SizedBox(height: 2),
                Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: done ? AppColors.feiCui : Colors.transparent)),
              ]),
            ),
          );
        },
      );
}

class _Bottom extends StatelessWidget {
  final int idx, total;
  final bool allSeen;
  final VoidCallback onPrev, onNext, onSpeak, onQuiz;
  const _Bottom({required this.idx, required this.total, required this.allSeen, required this.onPrev, required this.onNext, required this.onSpeak, required this.onQuiz});

  @override
  Widget build(BuildContext context) {
    final last = idx >= total - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset(context)),
      color: AppColors.xuanZhi,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          IconButton(onPressed: idx > 0 ? onPrev : null, icon: const Icon(Icons.chevron_left), color: AppColors.mo),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: LinearProgressIndicator(value: total == 0 ? 0 : (idx + 1) / total, minHeight: 2, color: AppColors.copper, backgroundColor: AppColors.line),
            ),
          ),
          IconButton(onPressed: onSpeak, icon: const Icon(Icons.volume_up), color: AppColors.copper),
          IconButton(onPressed: !last ? onNext : null, icon: const Icon(Icons.chevron_right), color: AppColors.mo),
        ]),
        if (last || allSeen)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onQuiz,
              style: FilledButton.styleFrom(backgroundColor: AppColors.copper, foregroundColor: Colors.white, shape: const StadiumBorder()),
              icon: const Icon(Icons.quiz),
              label: Text(allSeen ? tr('다 봤어요 — 이 단계 문제 풀기') : tr('이 단계 문제 풀기'), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          )
        else
          Text(trf('{0}자 더 보면 문제 풀기', [total - idx - 1]), style: AppFonts.captionText(size: 11)),
      ]),
    );
  }
}
