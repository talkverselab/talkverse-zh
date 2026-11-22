import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'content_sync.dart';
import 'dialogue_service.dart';
import 'learner_prefs.dart';
import 'tts_service.dart';

/// 회화 턴의 생성 음성(mp4) — 일본어앱 `dialogue_audio.dart`(구조 = `docs/DIALOGUE_AUDIO.md`)를 옮김(2026-11-07).
/// 목록은 `ContentSync.audioIndex`(편 → 턴 → 판 m·f). 기기에 받은 파일이 있으면 파일, 없으면 주소로 재생.
/// 음성이 없는 턴은 기기 음성(TTS). 음성이 D1 에 올라오면 앱은 다음 시작 때 매니페스트로 받아 쓴다(재빌드 불필요).
class DialogueAudio {
  DialogueAudio._();
  static final DialogueAudio instance = DialogueAudio._();

  AudioPlayer? _player;
  Completer<void>? _wait;
  int _gen = 0;

  /// 그 턴의 녹음 음성. 대사가 바뀌어 녹음 본문이 지금 대사와 다르면(옛 음성) 없는 것으로 본다 → 기기 TTS·지금 대사.
  /// 새 녹음이 서버에 올라오면 본문이 맞아 다시 녹음이 먼저 나온다(11/22 사용자 「음성이 없는건 TTS로」).
  AudioLine? line(String episodeId, int turn) {
    final l = ContentSync.instance.audioIndex[episodeId]?[turn]?[LearnerPrefs.isFemale ? 'f' : 'm'];
    if (l == null || l.text.isEmpty) return l;
    final d = DialogueService.instance.byId(episodeId);
    if (d == null) return l;
    for (final t in d.turns) {
      if (t.num == turn) return sameLine(l.text, t.zh) ? l : null;
    }
    return l;
  }

  static final _paren = RegExp(r'[（(][^)）]*[)）]');
  static final _nonHan = RegExp(r'[^\u4e00-\u9fff]');
  static String _han(String s) => s.replaceAll(_paren, '').replaceAll(_nonHan, '');

  /// 녹음 본문과 지금 대사가 같은 말인가 — 한자만 견주고, {name} 자리는 이름(한자 0~4자) 아무거나.
  static bool sameLine(String audioText, String zh) {
    final parts = zh.replaceAll(_paren, '').split('{name}').map(_han).map(RegExp.escape);
    return RegExp('^${parts.join('[\\u4e00-\\u9fff]{0,4}')}\$').hasMatch(_han(audioText));
  }

  /// 음성이 있는 턴은 그 음성의 본문(이름이 든 학습자 성별판) — 듣는 말과 글이 같아야 한다. 없으면 null.
  String? textOf(String episodeId, int turn) {
    final t = line(episodeId, turn)?.text;
    return t == null || t.isEmpty ? null : t;
  }

  /// 이름 자리가 있는 턴마다 음성이 있는가(있으면 이름을 묻지 않는다).
  bool covers(Dialogue d) => d.turns.every((t) => !t.zh.contains('{name}') || line(d.id, t.num) != null);

  /// 음성을 끝까지 재생. 음성이 없거나 실패하면 false(부르는 쪽이 TTS 로 넘긴다).
  Future<bool> play(String episodeId, int turn, {double rate = 1.0}) async {
    final l = line(episodeId, turn);
    if (l == null) return false;
    final my = ++_gen;
    try {
      await TtsService.instance.stop();
      final p = _player ??= AudioPlayer();
      await p.stop();
      _wait?.complete();
      final done = _wait = Completer<void>();
      final sub = p.onPlayerComplete.listen((_) {
        if (!done.isCompleted) done.complete();
      });
      try {
        final url = '${ContentSync.instance.base}/${l.key}';
        final f = ContentSync.instance.localFile(url);
        await p.setPlaybackRate(rate);
        await p.play(f != null ? DeviceFileSource(f.path) : UrlSource(url)).timeout(const Duration(seconds: 12));
        if (my != _gen) return true;
        await p.setPlaybackRate(rate); // 일부 기기는 재생을 시작한 뒤에야 속도가 먹는다
        await done.future.timeout(Duration(milliseconds: (l.ms / rate).round() + 6000), onTimeout: () {});
      } finally {
        await sub.cancel();
      }
      return true;
    } catch (e) {
      debugPrint('DialogueAudio: 재생 실패 $episodeId/$turn $e');
      return false;
    }
  }

  Future<void> stop() async {
    _gen++;
    final w = _wait;
    if (w != null && !w.isCompleted) w.complete();
    try {
      await _player?.stop();
    } catch (_) {}
    await TtsService.instance.stop();
  }
}

/// 턴 하나 읽기: 생성 음성이 있으면 그것, 없으면 기기 음성(화자 성별). 끝날 때까지 기다린다. rate 1.0 = 보통.
Future<void> speakTurn(Dialogue d, DialogueTurn t, {double rate = 1.0}) async {
  if (await DialogueAudio.instance.play(d.id, t.num, rate: rate)) return;
  final s = LearnerPrefs.fill(t.zh).replaceAll(RegExp(r'[（(][^)）]*[)）]'), '').trim();
  if (s.isNotEmpty) await TtsService.instance.speakAs(s, gender: LearnerPrefs.voiceGender(t.speaker), rate: 0.45 * rate);
}
