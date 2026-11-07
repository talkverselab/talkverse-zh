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

  AudioLine? line(String episodeId, int turn) => ContentSync.instance.audioIndex[episodeId]?[turn]?[LearnerPrefs.isFemale ? 'f' : 'm'];

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
