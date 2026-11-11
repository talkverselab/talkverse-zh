import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkverse_pitch/talkverse_pitch.dart';

import 'tone_analyzer.dart';

/// 성조연습 자료 한 낱말(tools/build_tone_drill.py → assets/data/tone_drill.json).
class DrillWord {
  DrillWord(this.zh, this.rd, this.ko, this.tones, [this.cell = '']);
  final String zh, rd, ko;

  /// 성조 칸 '1-4'(뒤 0 = 경성).
  final String cell;

  /// 글자별 사전 성조(경성 0).
  final List<int> tones;
  factory DrillWord.fromJson(Map<String, dynamic> j) =>
      DrillWord(j['zh'], j['rd'], j['ko'], [for (final t in j['t']) t as int], j['cell'] ?? '');
}

class DrillSentence {
  DrillSentence(this.ep, this.turn, this.zh, this.pinyin, this.ko, this.ref);
  final String ep, zh, pinyin, ko;
  final int turn;

  /// 기준 음성 곡선(가운뎃값 기준 반음 50점).
  final Contour ref;
  factory DrillSentence.fromJson(Map<String, dynamic> j) => DrillSentence(j['ep'], j['turn'], j['zh'], j['pinyin'], j['ko'],
      Contour([for (final v in j['ref']['st']) (v as num).toDouble()], (j['ref']['dur'] as num).toDouble()));
}

/// 묶음 = 낱말 4개(처음 2개 → 3개 → 4개) + 문장.
class DrillRound {
  DrillRound(this.words, this.sentence);
  final List<DrillWord> words;
  final DrillSentence sentence;
}

class ToneDrillData {
  ToneDrillData(this.cells, this.rounds);

  /// '1-4' → 그 칸 낱말(진도 지도·듣기용).
  final Map<String, List<DrillWord>> cells;
  final List<DrillRound> rounds;
}

class SentenceResult {
  SentenceResult(this.mine, this.match);
  final Contour? mine;
  final ContourMatch? match;
}

/// 마이크 녹음 → talkverse_pitch 채점. 녹음은 기기 안에서만 처리한다(서버 전송 없음).
class PitchCoach {
  PitchCoach._();
  static final PitchCoach instance = PitchCoach._();

  static const _kHz = 'pitch_coach_hz_v1'; // 그 사람 평소 음높이 — 최근 유성 칸 Hz(최대 3000개)
  static const _kDone = 'pitch_coach_done_v1'; // 끝낸 칸·낱말 묶음

  ToneDrillData? _data;
  List<double> _hz = [];
  Set<String> _done = {};
  bool _loaded = false;

  Future<ToneDrillData> data() async {
    if (_data != null) return _data!;
    final j = jsonDecode(await rootBundle.loadString('assets/data/tone_drill.json')) as Map<String, dynamic>;
    List<DrillWord> ws(List l) => [for (final w in l) DrillWord.fromJson(w)];
    return _data = ToneDrillData(
      {for (final e in (j['cells'] as Map<String, dynamic>).entries) e.key: ws(e.value)},
      [for (final r in j['rounds']) DrillRound(ws(r['words']), DrillSentence.fromJson(r['sentence']))],
    );
  }

  Future<void> _load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    _hz = [for (final v in p.getStringList(_kHz) ?? const <String>[]) double.tryParse(v) ?? 0]..removeWhere((v) => v <= 0);
    _done = (p.getStringList(_kDone) ?? const <String>[]).toSet();
    _loaded = true;
  }

  Future<bool> isDone(String key) async {
    await _load();
    return _done.contains(key);
  }

  Future<Set<String>> doneKeys() async {
    await _load();
    return {..._done};
  }

  Future<void> markDone(String key) async {
    await _load();
    if (_done.add(key)) (await SharedPreferences.getInstance()).setStringList(_kDone, _done.toList());
  }

  /// 기기에 모인 평소 음높이. 처음 몇 번은 없다(그때는 발화 가운뎃값으로 대신).
  double? get medianHz => _hz.length < 60 ? null : SpeakerRange.fromHz(_hz).medianHz;

  Future<void> _remember(PitchTrack t) async {
    final v = t.voicedHz;
    if (v.length < 10) return;
    _hz = [..._hz, ...v];
    if (_hz.length > 3000) _hz = _hz.sublist(_hz.length - 3000);
    (await SharedPreferences.getInstance()).setStringList(_kHz, [for (final x in _hz) x.toStringAsFixed(1)]);
  }

  Future<PitchTrack> _record(double seconds, void Function(double)? onLevel) async {
    final Uint8List b = await ToneAnalyzer.instance.recordPcm(seconds: seconds, onLevel: onLevel);
    return const PitchTracker().track(pcm16ToFloat(b));
  }

  /// 낱말 녹음 길이 = 0.8초 + 음절당 0.5초.
  static double wordSeconds(int syllables) => 0.8 + 0.5 * syllables;

  Future<SequenceScore> scoreWord(DrillWord w, {void Function(double)? onLevel}) async {
    await _load();
    final t = await _record(wordSeconds(w.tones.length), onLevel);
    final r = scoreMandarinSequence(t, w.tones, hanzi: w.zh.split(''), speakerMedianHz: medianHz);
    await _remember(t);
    return r;
  }

  /// 문장: 음절별 판정 없이 기준 곡선과 모양만 견준다(참고 점수).
  Future<SentenceResult> scoreSentence(DrillSentence s, {void Function(double)? onLevel}) async {
    await _load();
    final t = await _record(s.ref.duration + 1.5, onLevel);
    final hz = t.voicedHz;
    if (hz.length < 10) return SentenceResult(null, null);
    final med = ([...hz]..sort())[hz.length ~/ 2];
    final mine = Contour.fromTrack(t, refHz: med, points: s.ref.st.length);
    await _remember(t);
    return SentenceResult(mine, mine == null ? null : compareContoursWarped(mine, s.ref));
  }
}
