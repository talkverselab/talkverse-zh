import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/achievement_service.dart';
import '../services/art_service.dart';
import '../services/content_sync.dart';
import '../services/dialogue_audio.dart';
import '../services/dialogue_service.dart';
import '../services/learner_prefs.dart';
import '../services/tts_service.dart';
import '../widgets/chinese_decor.dart';
import '../widgets/lemma_text.dart';
import '../services/ko_reading.dart';

/// 편의 문장 플래시카드(일본어앱에서 옮김) — 앞면은 그림 + **한국어 뜻 크게**(무엇을 말할지 알고 중국어로, 2026-11-04), 탭하면 중국어·병음·독음·한국어·레마 칩.
/// 그림 = 턴 장면 그림(`art`) → 핵심 단어 그림 → 장면 카드. 틀림/맞음 2단계, 틀린 카드는 끝에 다시.
class DialogueCardScreen extends StatefulWidget {
  final Dialogue dialogue;
  const DialogueCardScreen({super.key, required this.dialogue});
  @override
  State<DialogueCardScreen> createState() => _DialogueCardScreenState();
}

class _DialogueCardScreenState extends State<DialogueCardScreen> {
  late final List<int> _order = List.generate(widget.dialogue.turns.length, (i) => i);
  int _pos = 0;
  bool _flipped = false;
  final List<int> _retry = [];
  int _right = 0;

  Dialogue get d => widget.dialogue;
  DialogueTurn get t => d.turns[_order[_pos]];

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _mark(bool ok) {
    if (ok) {
      _right++;
    } else if (!_retry.contains(_order[_pos])) {
      _retry.add(_order[_pos]);
    }
    if (_pos < _order.length - 1) {
      setState(() {
        _pos++;
        _flipped = false;
      });
    } else if (_retry.isNotEmpty) {
      setState(() {
        _order.addAll(_retry);
        _retry.clear();
        _pos++;
        _flipped = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('틀린 카드를 다시 봅니다')), backgroundColor: AppColors.copper, duration: const Duration(seconds: 1)));
    } else {
      AchievementService.instance.markCards(d.id, _right, d.turns.length); // 성과: 핵심 표현 맞음
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trf('끝! 맞음 {0} / {1}', [_right, d.turns.length])), backgroundColor: AppColors.feiCui));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final art = _CardArt(key: ValueKey('${d.id}:${t.num}:art'), d: d, t: t);
    final text = _CardText(d: d, t: t, flipped: _flipped);
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${d.emoji} ${d.title}', style: const TextStyle(color: AppColors.mo, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          Text('${_pos + 1} / ${_order.length}', style: const TextStyle(color: AppColors.muted, fontSize: 10, letterSpacing: 2)),
        ]),
        actions: const [KoReadingToggleAction(), SizedBox(width: 4)],
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _flipped = !_flipped),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: wide
                  ? Row(children: [
                      Expanded(flex: 5, child: art),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: text),
                    ])
                  : Column(children: [
                      Expanded(flex: 5, child: art),
                      const SizedBox(height: 12),
                      Expanded(flex: 6, child: text),
                    ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _Btn(icon: Icons.close, label: tr('틀렸어요'), color: AppColors.copper, onTap: () => _mark(false)),
            _Btn(icon: Icons.volume_up, label: tr('듣기'), color: AppColors.zhuHong, onTap: () => speakTurn(d, t)),
            _Btn(icon: Icons.check, label: tr('맞았어요'), color: AppColors.feiCui, onTap: () => _mark(true)),
          ]),
        ),
      ]),
      ),
    );
  }
}

class _CardArt extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn t;
  const _CardArt({super.key, required this.d, required this.t});

  Future<String?> _url() async {
    if (t.art != null) return t.art;
    for (final w in t.pictureWords) {
      final u = await ArtService.instance.urlFor(w);
      if (u != null) return u;
    }
    final inText = await ArtService.instance.urlInText(t.zh);
    if (inText != null) return inText.value;
    return d.art;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
        future: _url(),
        builder: (context, snap) => Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: AppColors.xuanZhiDeep, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(18), boxShadow: kCardShadow),
          child: snap.data == null
              ? Center(child: Text(t.stamp ?? d.emoji, style: const TextStyle(fontSize: 72)))
              : Image(image: artProvider(snap.data!), fit: BoxFit.contain, errorBuilder: (_, _, _) => Center(child: Text(d.emoji, style: const TextStyle(fontSize: 72)))),
        ),
      );
}

class _CardText extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn t;
  final bool flipped;
  const _CardText({required this.d, required this.t, required this.flipped});

  @override
  Widget build(BuildContext context) {
    final name = d.speakerName(t.speaker);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: flipped ? AppColors.xuanZhi : AppColors.xuanZhiDeep, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(18)),
      child: flipped
          ? SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$name · ${t.num}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                const SizedBox(height: 8),
                LemmaText(text: DialogueAudio.instance.textOf(d.id, t.num) ?? LearnerPrefs.fill(t.zh), lemmas: t.lemmas, style: AppFonts.zhText(size: 24, weight: FontWeight.w600, color: AppColors.copper, height: 1.3)),
                // 읽기 보조(병음·독음) — 전역 설정, 기본 꺼짐(2026-11-07 §6)
                ValueListenableBuilder<bool>(
                  valueListenable: KoReadingPrefs.show,
                  builder: (_, on, _) => !on
                      ? const SizedBox.shrink()
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (t.pinyin.isNotEmpty) ...[const SizedBox(height: 6), Text(LearnerPrefs.fill(t.pinyin), style: const TextStyle(fontSize: 15, color: AppColors.zhuHong, fontWeight: FontWeight.w700))],
                          if (AppLangPrefs.isKo && t.rd.isNotEmpty) Text(LearnerPrefs.fill(t.rd, ko: true), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                        ]),
                ),
                const SizedBox(height: 12),
                const WordmarkDivider(height: 2),
                const SizedBox(height: 10),
                Text(LearnerPrefs.fill(t.ko, ko: true), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.mo, height: 1.4)),
                if (t.note.isNotEmpty) ...[const SizedBox(height: 10), Text('💡 ${t.note}', style: const TextStyle(fontSize: 12, color: AppColors.copperDeep, height: 1.4))],
              ]),
            )
          : Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.mo)),
                const SizedBox(height: 10),
                // 앞면에 한국어 뜻 — 무엇을 말할지 알고 중국어로(사용자 지시 2026-11-04 "한국말로 보여줘야지")
                Text(LearnerPrefs.fill(t.ko, ko: true), textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.mo, height: 1.4)),
                const SizedBox(height: 12),
                Text(tr('이 말을 중국어로 해 보세요'), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 4),
                Text(tr('탭해서 확인'), style: const TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 2)),
              ]),
            ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(border: Border.all(color: color, width: 1.5), borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.mo)),
          ]),
        ),
      );
}
