import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../screens/dialogue_card_screen.dart';
import '../services/achievement_service.dart';
import '../services/art_service.dart';
import '../services/content_sync.dart';
import '../services/dialogue_service.dart';
import '../services/ko_reading.dart';
import '../services/learner_prefs.dart';
import '../services/tts_service.dart';
import 'achievement_desk.dart';
import 'learner_setup_dialog.dart';
import 'lemma_chips.dart';
import 'selectable_hanzi.dart';
import 'tone_pinyin.dart';

/// 회화 리더 — 시안 zh05 「확 트인 배치」(2026-11-03, 일본어앱 `episode_play_pane.dart` 에서 출발).
///
/// 한 화면에 주인공 하나: 장면 컷(읽기 칸 높이의 55%) → 지금 대사 하나만 크게(중국어 + 성조 색 병음 + 독음 + 한국어, 한자 팝업)
/// → 앞 한 줄·뒤 두 줄은 중국어만 흐리게 접어 둔다. 전체 스크립트는 필요할 때만 펼친다(넓은 칸 900 이상 = 오른쪽 옆 칸, 좁으면 장면 아래).
/// 하단 컨트롤 = ▶ · 진행 슬라이더 · 속도 · 자막(中文 고정/병음/독음/한국어) · 스크립트 — 상자 없이 아이콘·글자색만. 독음은 한국어 화면에서만.
/// 컷 전환은 400ms 페이드. 그림: 턴 `art`(장면 그림) → 핵심 단어 그림 → 장면 카드. 장면 그림은 나중에 JSON `art` 에 채운다.
/// `autoPlay: false` 면 편 화면(읽기 모드)으로도 쓴다 — 같은 레이아웃에서 ▶ 를 누르면 순차 재생.
class EpisodePlayPane extends StatefulWidget {
  final Dialogue dialogue;
  final int initialIndex;
  final bool autoPlay;
  const EpisodePlayPane({super.key, required this.dialogue, this.initialIndex = 0, this.autoPlay = true});

  @override
  State<EpisodePlayPane> createState() => _EpisodePlayPaneState();
}

class _EpisodePlayPaneState extends State<EpisodePlayPane> {
  late int _i = widget.initialIndex;
  bool _playing = false;
  double _rate = 1.0; // 0.75 / 1.0 / 1.25
  bool _showPy = KoReadingPrefs.show.value; // 앱 전체 병음 표시 설정에서 시작
  bool _showRd = true;
  bool _showKo = true;
  int _session = 0; // 재생 루프 세대(중단 판별)
  bool _done = false; // 완주 연출 표시
  bool _firstDone = false;
  bool _scriptOpen = false; // 전체 스크립트(필요할 때만 펼침)
  bool _side = false; // 스크립트가 옆 칸인가(펼친 스크립트 자동 스크롤은 옆 칸에서만 — 아래로 펼친 것은 장면을 밀어내므로)
  late final List<GlobalKey> _keys = List.generate(widget.dialogue.turns.length, (_) => GlobalKey());

  Dialogue get d => widget.dialogue;
  DialogueTurn get turn => d.turns[_i];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // 대사에 {name} 자리가 있는데 이름이 없으면 먼저 묻는다(앱 켠 뒤 한 번, 2026-11-04)
      await ensureLearnerName(context, needed: widget.dialogue.turns.any((t) => t.zh.contains('{name}')));
      if (mounted) setState(() {});
      if (widget.autoPlay && mounted) _play();
    });
  }

  @override
  void dispose() {
    _session++;
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _play() async {
    final my = ++_session;
    setState(() => _playing = true);
    while (mounted && my == _session && _i < d.turns.length) {
      final t = d.turns[_i];
      _scrollTo(_i);
      await TtsService.instance.speakAs(_ttsText(t), gender: _gender(t.speaker), rate: _rate * 0.45);
      if (!mounted || my != _session) return;
      await Future.delayed(Duration(milliseconds: (650 / _rate).round())); // 턴 사이 숨
      if (!mounted || my != _session) return;
      if (_i >= d.turns.length - 1) {
        // 끝까지 들었다 → 성과 기록 + 순간 연출(시안 02: 확대·구리빛·진동, 폭죽 없음)
        final first = await AchievementService.instance.markEpisodeDone(d.id);
        if (mounted && my == _session) setState(() { _done = true; _firstDone = first; });
        break;
      }
      setState(() => _i++);
    }
    if (mounted && my == _session) setState(() => _playing = false);
  }

  void _pause() {
    _session++;
    TtsService.instance.stop();
    setState(() => _playing = false);
  }

  void _goto(int n, {bool play = false}) {
    n = n.clamp(0, d.turns.length - 1);
    _session++;
    TtsService.instance.stop();
    setState(() {
      _i = n;
      _playing = false;
    });
    _scrollTo(n);
    if (play) _play();
  }

  void _speakOne(DialogueTurn t) => TtsService.instance.speakAs(_ttsText(t), gender: _gender(t.speaker), rate: _rate * 0.45);

  void _scrollTo(int i) {
    if (!_side || !_scriptOpen) return;
    final ctx = _keys[i].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.3);
  }

  String _ttsText(DialogueTurn t) => ttsTextOf(t);

  String _gender(String sp) => LearnerPrefs.voiceGender(sp); // A = 학습자 프로필 성별

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // 칸이 넓으면(아이패드 가로·전체 화면 900 이상) 스크립트를 오른쪽 옆 칸으로, 좁으면 장면 아래로 펼친다.
      final side = isWide(context) && c.maxWidth >= 900;
      _side = side;
      final controls = _ControlBar(
        playing: _playing,
        index: _i,
        total: d.turns.length,
        rate: _rate,
        showPy: _showPy,
        showRd: _showRd,
        showKo: _showKo,
        scriptOpen: _scriptOpen,
        onPlay: _playing ? _pause : _play,
        onSeek: (v) => _goto(v),
        onRate: () => setState(() => _rate = _rate >= 1.25 ? 0.75 : (_rate + 0.25)),
        onPy: () => setState(() => _showPy = !_showPy),
        onRd: () => setState(() => _showRd = !_showRd),
        onKo: () => setState(() => _showKo = !_showKo),
        onScript: _toggleScript,
      );
      final script = _Script(
        d: d,
        current: _i,
        keys: _keys,
        showKo: _showKo,
        scrollable: side,
        onTap: (i) => _goto(i, play: true),
        onClose: side ? _toggleScript : null,
      );
      final stage = _Stage(
        d: d,
        index: _i,
        showPy: _showPy,
        showRd: _showRd,
        showKo: _showKo,
        scriptOpen: _scriptOpen,
        inlineScript: !side && _scriptOpen ? script : null,
        onSpeak: () => _speakOne(turn),
        onTap: (i) => _goto(i, play: true),
        onToggleScript: _toggleScript,
      );
      final body = Column(children: [
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: stage),
            if (side && _scriptOpen) SizedBox(width: (c.maxWidth * 0.32).clamp(300.0, 400.0), child: script),
          ]),
        ),
        controls,
      ]);
      if (!_done) return body;
      return Stack(fit: StackFit.expand, children: [
        body,
        EpisodeDoneOverlay(
          dialogue: d,
          firstTime: _firstDone,
          onCards: () {
            setState(() => _done = false);
            openFull(context, (_) => DialogueCardScreen(dialogue: d));
          },
          onClose: () => setState(() => _done = false),
        ),
      ]);
    });
  }

  void _toggleScript() {
    setState(() => _scriptOpen = !_scriptOpen);
    if (_scriptOpen) WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(_i));
  }
}

/// 장면 컷(화면의 절반 이상) + 지금 대사 하나(크게) + 앞뒤 줄(흐리게, 한 줄씩). 시안 zh05 「확 트인 배치」.
class _Stage extends StatelessWidget {
  final Dialogue d;
  final int index;
  final bool showPy, showRd, showKo, scriptOpen;
  final Widget? inlineScript;
  final VoidCallback onSpeak, onToggleScript;
  final void Function(int) onTap;
  const _Stage({
    required this.d,
    required this.index,
    required this.showPy,
    required this.showRd,
    required this.showKo,
    required this.scriptOpen,
    required this.inlineScript,
    required this.onSpeak,
    required this.onTap,
    required this.onToggleScript,
  });

  @override
  Widget build(BuildContext context) {
    final turn = d.turns[index];
    return LayoutBuilder(builder: (context, c) {
      final roomy = c.maxWidth >= 600;
      final cutH = (c.maxHeight * 0.55).clamp(180.0, 640.0);
      final hp = roomy ? 32.0 : 16.0;
      // 앞 줄 하나 · 뒤 줄 둘 — 지금 줄만 크게, 나머지는 흐리게 접어 둔다
      final around = [
        for (var i = index - 1; i <= index + 2; i++)
          if (i >= 0 && i < d.turns.length && i != index) i,
      ];
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hp, roomy ? 20 : 12, hp, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(height: cutH, child: SceneCut(dialogue: d, turn: turn)),
              SizedBox(height: roomy ? 24 : 18),
              NowLine(d: d, turn: turn, showPy: showPy, showRd: showRd, showKo: showKo, large: roomy, onSpeak: onSpeak),
              SizedBox(height: roomy ? 22 : 18),
              for (final i in around)
                CollapsedLine(
                  key: ValueKey('around-$i'),
                  name: d.speakerName(d.turns[i].speaker),
                  zh: LearnerPrefs.fill(d.turns[i].zh),
                  before: i < index,
                  onTap: () => onTap(i),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onToggleScript,
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted, padding: const EdgeInsets.symmetric(horizontal: 4)),
                  icon: Icon(scriptOpen ? Icons.expand_less : Icons.subject_rounded, size: 18),
                  label: Text(
                    scriptOpen ? tr('스크립트 접기') : trf('전체 스크립트 · {0}줄', [d.turns.length]),
                    style: AppFonts.captionText(size: 12, color: AppColors.muted),
                  ),
                ),
              ),
              ?inlineScript,
            ]),
          ),
        ),
      );
    });
  }
}

/// 지금 대사 — 중국어(크게) + 자막 단계(병음·독음·한국어). 상자 없이 크기·굵기로만.
class NowLine extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn turn;
  final bool showPy, showRd, showKo, large;
  final VoidCallback onSpeak;
  const NowLine({super.key, required this.d, required this.turn, required this.showPy, required this.showRd, required this.showKo, this.large = false, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(turn.num),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(d.speakerName(turn.speaker), style: AppFonts.captionText(weight: FontWeight.w600, color: AppColors.copper)),
            const Spacer(),
            IconButton(
              tooltip: tr('읽기'),
              visualDensity: VisualDensity.compact,
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_outlined, color: AppColors.muted, size: 20),
            ),
          ]),
          SelectableHanziText(
            text: LearnerPrefs.fill(turn.zh),
            style: AppFonts.zhText(size: large ? 24 : 22, weight: FontWeight.w600, height: 1.4),
          ),
          if (showPy && turn.pinyin.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: TonePinyinText(LearnerPrefs.fill(turn.pinyin), size: 13)),
          if (showRd && AppLangPrefs.isKo && turn.rd.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 3), child: Text(LearnerPrefs.fill(turn.rd, ko: true), style: AppFonts.uiText(size: 13.5, color: AppColors.muted))),
          if (showKo)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(LearnerPrefs.fill(turn.ko, ko: true), style: AppFonts.uiText(size: 14))),
          if (turn.note.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text('💡 ${turn.note}', style: AppFonts.captionText(color: AppColors.copperDeep))),
          // 문장 내용어 칩 — 단어장에 있으면 단어 시트, 없으면 회색(2026-11-04)
          if (turn.lemmas.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 10), child: LemmaChips(turn: turn, compact: !large)),
        ],
      ),
    );
  }
}

/// 접힌 줄 — 화자 + 중국어 한 줄(흐리게). 병음·번역은 없다. 누르면 그 줄로.
class CollapsedLine extends StatelessWidget {
  final String name;
  final String zh;
  final bool before;
  final VoidCallback onTap;
  const CollapsedLine({super.key, required this.name, required this.zh, this.before = false, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: before ? 0.45 : 0.7,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
            child: Row(children: [
              SizedBox(width: 56, child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.captionText())),
              Expanded(child: Text(zh, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.zhText(size: AppFonts.line, color: AppColors.moLight))),
            ]),
          ),
        ),
      );
}

/// 전체 스크립트(필요할 때만 펼침). 지금 줄은 왼쪽 구리 선 + 굵게(번역은 한국어 자막이 켜졌을 때만), 나머지는 중국어 한 줄.
class _Script extends StatelessWidget {
  final Dialogue d;
  final int current;
  final List<GlobalKey> keys;
  final bool showKo, scrollable;
  final void Function(int) onTap;
  final VoidCallback? onClose;
  const _Script({required this.d, required this.current, required this.keys, required this.showKo, required this.scrollable, required this.onTap, this.onClose});

  Widget _row(int i) {
    final t = d.turns[i];
    final on = i == current;
    return InkWell(
      key: keys[i],
      onTap: () => onTap(i),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        decoration: BoxDecoration(border: Border(left: BorderSide(color: on ? AppColors.copper : Colors.transparent, width: 2))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(d.speakerName(t.speaker), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.captionText(color: on ? AppColors.copper : AppColors.muted)),
            ),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(LearnerPrefs.fill(t.zh), style: AppFonts.zhText(size: AppFonts.line, weight: on ? FontWeight.w600 : FontWeight.w400, color: on ? AppColors.mo : AppColors.moLight)),
              if (on && showKo) Text(LearnerPrefs.fill(t.ko, ko: true), style: AppFonts.uiText(size: 13)),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!scrollable) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (var i = 0; i < d.turns.length; i++) _row(i)]);
    }
    return Container(
      color: AppColors.xuanZhiDeep,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 4, 4),
          child: Row(children: [
            Text(trf('대화 스크립트 · {0}줄', [d.turns.length]), style: AppFonts.captionText(weight: FontWeight.w600, color: AppColors.moLight)),
            const Spacer(),
            if (onClose != null) IconButton(onPressed: onClose, icon: const Icon(Icons.close, size: 18, color: AppColors.muted)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            itemCount: d.turns.length,
            itemBuilder: (context, i) => _row(i),
          ),
        ),
      ]),
    );
  }
}

/// 하단 컨트롤 — ▶ · 진행 · 속도 · 자막(中文 고정/병음/독음/한국어) · 스크립트. 테두리·상자 없이 아이콘과 글자색만.
class _ControlBar extends StatelessWidget {
  final bool playing, showPy, showRd, showKo, scriptOpen;
  final int index, total;
  final double rate;
  final VoidCallback onPlay, onRate, onPy, onRd, onKo, onScript;
  final ValueChanged<int> onSeek;
  const _ControlBar({
    required this.playing,
    required this.index,
    required this.total,
    required this.rate,
    required this.showPy,
    required this.showRd,
    required this.showKo,
    required this.scriptOpen,
    required this.onPlay,
    required this.onSeek,
    required this.onRate,
    required this.onPy,
    required this.onRd,
    required this.onKo,
    required this.onScript,
  });

  @override
  Widget build(BuildContext context) {
    Widget sub(String t, bool on, VoidCallback? tap, {bool fixed = false}) => InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            child: Text(
              t,
              style: AppFonts.captionText(
                weight: fixed || on ? FontWeight.w600 : FontWeight.w400,
                color: fixed ? AppColors.mo : (on ? AppColors.copper : AppColors.muted.withValues(alpha: 0.7)),
              ),
            ),
          ),
        );
    final rateLabel = '${rate.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}x';
    final playBtn = Tooltip(
      message: playing ? tr('일시정지') : tr('재생'),
      child: InkWell(
        onTap: onPlay,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: playing ? AppColors.copper : null, border: Border.all(color: AppColors.copper, width: 1.2)),
          child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: playing ? Colors.white : AppColors.copper, size: 24),
        ),
      ),
    );
    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbColor: AppColors.copper,
        activeTrackColor: AppColors.copper,
        inactiveTrackColor: AppColors.line,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        tickMarkShape: SliderTickMarkShape.noTickMark,
      ),
      child: Slider(value: index.toDouble(), min: 0, max: (total - 1).clamp(1, 999).toDouble(), divisions: total > 1 ? total - 1 : 1, onChanged: (v) => onSeek(v.round())),
    );
    final count = Text('${index + 1}/$total', style: AppFonts.captionText(size: 11));
    final tools = Row(mainAxisSize: MainAxisSize.min, children: [
      Tooltip(
        message: tr('속도'),
        child: InkWell(
          onTap: onRate,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.speed_rounded, size: 16, color: AppColors.muted),
              const SizedBox(width: 3),
              Text(rateLabel, style: AppFonts.captionText(weight: FontWeight.w600, color: AppColors.moLight)),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Tooltip(message: tr('자막'), child: const Icon(Icons.closed_caption_outlined, size: 16, color: AppColors.muted)),
      sub('中文', true, null, fixed: true),
      sub(tr('병음'), showPy, onPy),
      if (AppLangPrefs.isKo) sub(tr('독음'), showRd, onRd),
      sub(tr('한국어'), showKo, onKo),
      IconButton(
        tooltip: tr('전체 스크립트'),
        visualDensity: VisualDensity.compact,
        onPressed: onScript,
        icon: Icon(Icons.subject_rounded, size: 20, color: scriptOpen ? AppColors.copper : AppColors.muted),
      ),
    ]);
    return LayoutBuilder(builder: (context, c) => Container(
      color: AppColors.xuanZhi,
      padding: EdgeInsets.fromLTRB(16, 6, 10, 6 + bottomInset(context)),
      child: c.maxWidth >= 760
          ? Row(children: [playBtn, const SizedBox(width: 12), Expanded(child: slider), const SizedBox(width: 8), count, const SizedBox(width: 14), tools])
          : Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [playBtn, const SizedBox(width: 10), Expanded(child: slider), const SizedBox(width: 8), count, const SizedBox(width: 6)]),
              Align(alignment: Alignment.centerRight, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: tools)),
            ]),
    ));
  }
}

/// 장면 컷: 장면 그림 → 단어 그림 → 장면 카드. 둥근 틀, 컷 전환 400ms 페이드.
/// `bubble` 이면 현재 대사를 그림 **아래 띠**로(그림을 덮지 않음 — 사용자 지시 2026-11-04). 재생 화면은 아래 문장 칸이 보여 주므로 띠 없음.
class SceneCut extends StatelessWidget {
  final Dialogue dialogue;
  final DialogueTurn turn;
  final bool bubble;
  const SceneCut({super.key, required this.dialogue, required this.turn, this.bubble = false});

  Future<_ArtPick?> _pick() async {
    if (turn.art != null) return _ArtPick(turn.art!, null);
    final i = dialogue.turns.indexOf(turn);
    final scene = i < 0 ? null : await SceneArtService.instance.urlFor(dialogue.id, i);
    if (scene != null) return _ArtPick(scene, null);
    for (final w in turn.pictureWords) {
      final u = await ArtService.instance.urlFor(w);
      if (u != null) return _ArtPick(u, w);
    }
    final inText = await ArtService.instance.urlInText(turn.zh);
    if (inText != null) return _ArtPick(inText.value, inText.key);
    if (dialogue.art != null) return _ArtPick(dialogue.art!, null);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final me = turn.speaker == 'A';
    return FutureBuilder<_ArtPick?>(
      key: ValueKey('${dialogue.id}:${turn.num}'),
      future: _pick(),
      builder: (context, snap) {
        final p = snap.data;
        final pic = Stack(fit: StackFit.expand, children: [
          if (p == null)
            _SceneCard(dialogue: dialogue, turn: turn)
          else
            Image(image: artProvider(p.url), fit: BoxFit.contain, errorBuilder: (_, _, _) => _SceneCard(dialogue: dialogue, turn: turn)),
          if (p?.word != null)
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.xuanZhi.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                child: Text(p!.word!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.mo)),
              ),
            ),
        ]);
        return LayoutBuilder(builder: (context, c) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Container(
            key: ValueKey('${turn.num}:${p?.url}'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.xuanZhiDeep, borderRadius: BorderRadius.circular(18)),
            child: bubble
                ? Column(children: [
                    Expanded(child: pic),
                    _LineStrip(speaker: dialogue.speakerName(turn.speaker), me: me, text: LearnerPrefs.fill(turn.zh), small: c.maxHeight < 220),
                  ])
                : pic,
          ),
        ));
      },
    );
  }
}

/// 그림 아래 대사 띠 — 화자 이름표(학습자 = 구리색, 상대 = 보라) + 한 줄. 그림을 덮지 않는다.
class _LineStrip extends StatelessWidget {
  final String speaker;
  final bool me;
  final String text;
  final bool small;
  const _LineStrip({required this.speaker, required this.me, required this.text, this.small = false});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12, small ? 6 : 8, 12, small ? 6 : 8),
        decoration: const BoxDecoration(color: AppColors.xuanZhi, border: Border(top: BorderSide(color: AppColors.line))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 3, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: me ? AppColors.copper : AppColors.zhuHong, borderRadius: BorderRadius.circular(8)),
            child: Text(speaker, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Expanded(child: Text(text, maxLines: small ? 2 : 3, overflow: TextOverflow.ellipsis, style: AppFonts.zhText(size: small ? 12.5 : 15, weight: FontWeight.w600, height: 1.35))),
        ]),
      );
}

class _ArtPick {
  final String url;
  final String? word;
  const _ArtPick(this.url, this.word);
}

/// 그림이 없을 때의 장면 카드(이모지 + 장면 한 줄 + 화자).
class _SceneCard extends StatelessWidget {
  final Dialogue dialogue;
  final DialogueTurn turn;
  const _SceneCard({required this.dialogue, required this.turn});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final small = c.maxHeight < 220; // 홈 「오늘의 컷」 같은 작은 틀
      return Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFF7F0), Color(0xFFF3F0FF)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        padding: EdgeInsets.fromLTRB(14, small ? 44 : 18, 14, 10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(turn.stamp ?? dialogue.emoji, style: TextStyle(fontSize: small ? 34 : 56)),
          SizedBox(height: small ? 4 : 10),
          Flexible(child: Text(dialogue.scene, textAlign: TextAlign.center, maxLines: small ? 2 : 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: small ? 11 : 13, color: AppColors.moLight, height: 1.4))),
          if (!small) ...[
            const SizedBox(height: 6),
            Text(dialogue.speakerName(turn.speaker), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.copper)),
          ],
        ]),
      );
    });
  }
}

/// TTS 로 읽을 문장 — 괄호 설명·`{name}` 자리표시는 빼고 읽는다.
String ttsTextOf(DialogueTurn t) {
  final s = t.zh.replaceAll(RegExp(r'[（(][^)）]*[)）]'), '').replaceAll(RegExp(r'\{[a-z_]+\}'), '').trim();
  return s.isEmpty ? t.zh : s;
}
