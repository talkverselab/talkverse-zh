import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../screens/dialogue_card_screen.dart';
import '../services/achievement_service.dart';
import '../services/art_service.dart';
import '../services/dialogue_service.dart';
import '../services/ko_reading.dart';
import '../services/learner_prefs.dart';
import '../services/tts_service.dart';
import 'achievement_desk.dart';
import 'selectable_hanzi.dart';

/// 「모든 문장 듣기」 재생 패널 — UX 시안 02 「만화책 읽기형」.
///
/// 일본어앱 `episode_play_pane.dart` 를 옮김(2026-11-02). 장면 컷이 주인공. 넓은 칸: 왼쪽 = 대화 스크립트(번호·화자·중국어·병음·독음·한국어),
/// 오른쪽 = 큰 장면 컷(말풍선) + 현재 문장 캡션(한자 팝업). 좁은 칸·폰: 컷 위·스크립트 아래.
/// 하단 고정 컨트롤 = ▶ 재생 · 진행 슬라이더 · 속도 · 자막(中文 고정/병음/독음/한국어). 독음은 한국어 화면에서만.
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
  late final List<GlobalKey> _keys = List.generate(widget.dialogue.turns.length, (_) => GlobalKey());

  Dialogue get d => widget.dialogue;
  DialogueTurn get turn => d.turns[_i];

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) WidgetsBinding.instance.addPostFrameCallback((_) => _play());
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
    final ctx = _keys[i].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.3);
  }

  String _ttsText(DialogueTurn t) => ttsTextOf(t);

  String _gender(String sp) => LearnerPrefs.voiceGender(sp); // A = 학습자 프로필 성별

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final script = _Script(
      d: d,
      current: _i,
      keys: _keys,
      showPy: _showPy,
      showRd: _showRd,
      showKo: _showKo,
      onTap: (i) => _goto(i, play: true),
      onSpeak: _speakOne,
    );
    final cut = _CutPanel(d: d, turn: turn, showPy: _showPy, showRd: _showRd, showKo: _showKo, onSpeak: () => _speakOne(turn));
    final controls = _ControlBar(
      playing: _playing,
      index: _i,
      total: d.turns.length,
      rate: _rate,
      showPy: _showPy,
      showRd: _showRd,
      showKo: _showKo,
      onPlay: _playing ? _pause : _play,
      onSeek: (v) => _goto(v),
      onRate: () => setState(() => _rate = _rate >= 1.25 ? 0.75 : (_rate + 0.25)),
      onPy: () => setState(() => _showPy = !_showPy),
      onRd: () => setState(() => _showRd = !_showRd),
      onKo: () => setState(() => _showKo = !_showKo),
    );
    return LayoutBuilder(builder: (context, c) {
      // 칸이 넓으면(아이패드 가로·전체 화면 900 이상) 좌 스크립트 · 우 컷, 좁으면(아이패드 세로 오른쪽 칸·폰) 컷 위 · 스크립트 아래
      final sideBySide = wide && c.maxWidth >= 900;
      final body = Column(children: [
        Expanded(
          child: sideBySide
              ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(flex: 4, child: script),
                  const VerticalDivider(width: 1, color: AppColors.line),
                  Expanded(flex: 6, child: cut),
                ])
              : Column(children: [
                  SizedBox(height: (c.maxHeight * 0.44).clamp(240, 520), child: cut),
                  const Divider(height: 1, color: AppColors.line),
                  Expanded(child: script),
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
}

/// 왼쪽 「대화 스크립트」 목록.
class _Script extends StatelessWidget {
  final Dialogue d;
  final int current;
  final List<GlobalKey> keys;
  final bool showPy, showRd, showKo;
  final void Function(int) onTap;
  final void Function(DialogueTurn) onSpeak;
  const _Script({required this.d, required this.current, required this.keys, required this.showPy, required this.showRd, required this.showKo, required this.onTap, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Row(children: [
          const Icon(Icons.volume_up_outlined, size: 16, color: AppColors.mo),
          const SizedBox(width: 6),
          Text(tr('대화 스크립트'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.mo)),
          const Spacer(),
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.mo, width: 1.2)),
            child: Text('${d.turns.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.mo)),
          ),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(12, 4, 12, 12 + bottomInset(context)),
          itemCount: d.turns.length,
          itemBuilder: (context, i) {
            final t = d.turns[i];
            final on = i == current;
            final me = t.speaker == 'A';
            return Padding(
              key: keys[i],
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
                  decoration: BoxDecoration(
                    color: on ? AppColors.copper.withValues(alpha: 0.07) : AppColors.xuanZhi,
                    border: Border.all(color: on ? AppColors.copper : AppColors.line, width: on ? 1.6 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${t.num}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: on ? AppColors.copper : AppColors.muted, height: 1.5)),
                    const SizedBox(width: 8),
                    _SpeakerDot(name: d.speakerName(t.speaker), me: me, on: on),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(LearnerPrefs.fill(t.zh), style: TextStyle(fontSize: on ? 16.5 : 15, fontWeight: FontWeight.w800, color: AppColors.mo, height: 1.35)),
                        if (showPy && t.pinyin.isNotEmpty) Text(LearnerPrefs.fill(t.pinyin), style: const TextStyle(fontSize: 11.5, color: AppColors.zhuHong, fontWeight: FontWeight.w700)),
                        if (showRd && AppLangPrefs.isKo && t.rd.isNotEmpty) Text(LearnerPrefs.fill(t.rd, ko: true), style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                        if (showKo) Text(LearnerPrefs.fill(t.ko, ko: true), style: const TextStyle(fontSize: 12.5, color: AppColors.moLight, height: 1.35)),
                        if (on && t.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('💡 ${t.note}', style: const TextStyle(fontSize: 11, color: AppColors.copperDeep, height: 1.35))),
                      ]),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onSpeak(t),
                      icon: Icon(Icons.volume_up_outlined, size: 18, color: on ? AppColors.copper : AppColors.mo),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _SpeakerDot extends StatelessWidget {
  final String name;
  final bool me, on;
  const _SpeakerDot({required this.name, required this.me, required this.on});
  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: me ? AppColors.copper : AppColors.mo),
        child: Text(me ? 'A' : (name.isEmpty ? '?' : name.characters.first), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
      );
}

/// 오른쪽(또는 위) 장면 컷 + 캡션.
class _CutPanel extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn turn;
  final bool showPy, showRd, showKo;
  final VoidCallback onSpeak;
  const _CutPanel({required this.d, required this.turn, required this.showPy, required this.showRd, required this.showKo, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 16 : 12, 10, wide ? 16 : 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (wide)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.image_outlined, size: 16, color: AppColors.mo),
              const SizedBox(width: 6),
              Text(tr('회화 장면'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.mo)),
              const Spacer(),
              Text(d.speakerName(turn.speaker), style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
            ]),
          ),
        Expanded(child: SceneCut(dialogue: d, turn: turn, bubble: true)),
        const SizedBox(height: 10),
        _Caption(d: d, turn: turn, showPy: showPy, showRd: showRd, showKo: showKo, onSpeak: onSpeak),
      ]),
    );
  }
}

/// 현재 문장 캡션(한자를 누르면 한자 팝업).
class _Caption extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn turn;
  final bool showPy, showRd, showKo;
  final VoidCallback onSpeak;
  const _Caption({required this.d, required this.turn, required this.showPy, required this.showRd, required this.showKo, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(turn.num),
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, wide ? 12 : 10, 12, wide ? 12 : 10),
        decoration: BoxDecoration(color: AppColors.xuanZhi, border: Border.all(color: AppColors.copper, width: 1.3), borderRadius: BorderRadius.circular(14), boxShadow: kCardShadow),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SelectableHanziText(text: LearnerPrefs.fill(turn.zh), style: TextStyle(fontSize: wide ? 20 : 17, fontWeight: FontWeight.w800, color: AppColors.mo, height: 1.35)),
              if (showPy && turn.pinyin.isNotEmpty) Text(LearnerPrefs.fill(turn.pinyin), style: const TextStyle(fontSize: 12.5, color: AppColors.zhuHong, fontWeight: FontWeight.w700)),
              if (showRd && AppLangPrefs.isKo && turn.rd.isNotEmpty) Text(LearnerPrefs.fill(turn.rd, ko: true), style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
              if (showKo) Padding(padding: const EdgeInsets.only(top: 2), child: Text(LearnerPrefs.fill(turn.ko, ko: true), style: const TextStyle(fontSize: 13.5, color: AppColors.moLight, height: 1.35))),
            ]),
          ),
          IconButton(onPressed: onSpeak, icon: const Icon(Icons.volume_up, color: AppColors.copper, size: 26)),
        ]),
      ),
    );
  }
}

/// 하단 고정 컨트롤: ▶ 재생 · 진행 슬라이더 · 속도 · 자막 단계.
class _ControlBar extends StatelessWidget {
  final bool playing, showPy, showRd, showKo;
  final int index, total;
  final double rate;
  final VoidCallback onPlay, onRate, onPy, onRd, onKo;
  final ValueChanged<int> onSeek;
  const _ControlBar({
    required this.playing,
    required this.index,
    required this.total,
    required this.rate,
    required this.showPy,
    required this.showRd,
    required this.showKo,
    required this.onPlay,
    required this.onSeek,
    required this.onRate,
    required this.onPy,
    required this.onRd,
    required this.onKo,
  });

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    Widget chip(String t, bool on, VoidCallback? tap, {bool fixed = false}) => Padding(
          padding: const EdgeInsets.only(left: 6),
          child: InkWell(
            onTap: tap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: fixed ? AppColors.copper : (on ? AppColors.zhuHong.withValues(alpha: 0.10) : Colors.transparent),
                border: Border.all(color: fixed ? AppColors.copper : (on ? AppColors.zhuHong : AppColors.line)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: fixed ? Colors.white : (on ? AppColors.zhuHong : AppColors.muted))),
            ),
          ),
        );
    final rateLabel = '${rate.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}x';
    final playBtn = Row(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: playing ? AppColors.copper : AppColors.xuanZhi, border: Border.all(color: AppColors.copper, width: 1.6)),
          child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: playing ? Colors.white : AppColors.copper, size: 28),
        ),
      ),
      const SizedBox(width: 8),
      Text(playing ? tr('일시정지') : tr('재생'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.mo)),
    ]);
    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbColor: AppColors.copper, activeTrackColor: AppColors.copper, inactiveTrackColor: AppColors.line, overlayShape: SliderComponentShape.noOverlay, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7)),
      child: Slider(value: index.toDouble(), min: 0, max: (total - 1).clamp(1, 999).toDouble(), divisions: total > 1 ? total - 1 : 1, onChanged: (v) => onSeek(v.round())),
    );
    final subs = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(tr('자막'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.mo)),
      const SizedBox(width: 4),
      chip('中文', true, null, fixed: true),
      chip(tr('병음'), showPy, onPy),
      if (AppLangPrefs.isKo) chip(tr('독음'), showRd, onRd),
      chip(tr('한국어'), showKo, onKo),
    ]);
    final speed = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(tr('속도'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.mo)),
      chip(rateLabel, true, onRate),
    ]);
    return LayoutBuilder(builder: (context, c) => Container(
      padding: EdgeInsets.fromLTRB(16, 8, 12, 8 + bottomInset(context)),
      decoration: const BoxDecoration(color: AppColors.xuanZhi, border: Border(top: BorderSide(color: AppColors.line))),
      child: wide && c.maxWidth >= 900
          ? Row(children: [
              playBtn,
              const SizedBox(width: 10),
              Expanded(child: slider),
              Text('${index + 1}/$total', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              const SizedBox(width: 12),
              speed,
              const SizedBox(width: 10),
              subs,
            ])
          : Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [playBtn, const SizedBox(width: 6), Expanded(child: slider), Text('${index + 1}/$total', style: const TextStyle(fontSize: 11, color: AppColors.muted))]),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [speed, const SizedBox(width: 8), subs])),
            ]),
    ));
  }
}

/// 장면 컷: 장면 그림 → 단어 그림 → 장면 카드. 둥근 틀, 컷 전환 400ms 페이드, 말풍선(현재 대사) 오버레이.
class SceneCut extends StatelessWidget {
  final Dialogue dialogue;
  final DialogueTurn turn;
  final bool bubble;
  const SceneCut({super.key, required this.dialogue, required this.turn, this.bubble = false});

  Future<_ArtPick?> _pick() async {
    if (turn.art != null) return _ArtPick(turn.art!, null);
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
        return LayoutBuilder(builder: (context, c) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Container(
            key: ValueKey('${turn.num}:${p?.url}'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.xuanZhiDeep, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(18), boxShadow: kCardShadow),
            child: Stack(fit: StackFit.expand, children: [
              if (p == null)
                _SceneCard(dialogue: dialogue, turn: turn)
              else
                Image.network(p.url, fit: BoxFit.contain, errorBuilder: (_, _, _) => _SceneCard(dialogue: dialogue, turn: turn)),
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
              if (bubble)
                Positioned(
                  top: 12,
                  left: me ? null : 12,
                  right: me ? 12 : null,
                  child: _SpeechBubble(text: LearnerPrefs.fill(turn.zh), tail: me ? _Tail.right : _Tail.left, maxWidth: c.maxWidth * 0.72, small: c.maxHeight < 220),
                ),
            ]),
          ),
        ));
      },
    );
  }
}

enum _Tail { left, right }

class _SpeechBubble extends StatelessWidget {
  final String text;
  final _Tail tail;
  final double maxWidth;
  final bool small;
  const _SpeechBubble({required this.text, required this.tail, required this.maxWidth, this.small = false});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(120, 360)),
        child: Container(
          padding: EdgeInsets.fromLTRB(small ? 10 : 14, small ? 6 : 10, small ? 10 : 14, small ? 6 : 10),
          decoration: BoxDecoration(
            color: AppColors.xuanZhi.withValues(alpha: 0.96),
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(tail == _Tail.left ? 4 : 18),
              bottomRight: Radius.circular(tail == _Tail.right ? 4 : 18),
            ),
            boxShadow: kCardShadow,
          ),
          child: Text(text, maxLines: small ? 2 : 4, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: small ? 12 : 15, fontWeight: FontWeight.w800, color: AppColors.mo, height: 1.35)),
        ),
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
