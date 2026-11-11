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

/// 메뉴 한 줄 = 성조 조합(1성 1성, 1성 2성 …) — 묶음 3개(낱말 12개).
class DrillCombo {
  DrillCombo(this.cell, this.rounds);
  final String cell;
  final List<DrillRound> rounds;
  List<DrillWord> get words => [for (final r in rounds) ...r.words];
}

class ToneDrillData {
  ToneDrillData(this.combos);
  final List<DrillCombo> combos;
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
  // 진도(2026-11-11 사용자 지시): 판정은 참고용 — 통과가 아니라 연습한 횟수로. 낱말마다 5번, 단 하루에 한 번만 세서 5일에 나눠 하면 완료.
  static const _kDays = 'pitch_coach_days_v1'; // {낱말: [yyyy-mm-dd …]}
  static const daysToFinish = 5;

  ToneDrillData? _data;
  List<double> _hz = [];
  Map<String, List<String>> _days = {};
  bool _loaded = false;

  Future<ToneDrillData> data() async {
    if (_data != null) return _data!;
    final j = jsonDecode(await rootBundle.loadString('assets/data/tone_drill.json')) as Map<String, dynamic>;
    List<DrillWord> ws(List l) => [for (final w in l) DrillWord.fromJson(w)];
    return _data = ToneDrillData([
      for (final c in j['combos'])
        DrillCombo(c['cell'], [for (final r in c['rounds']) DrillRound(ws(r['words']), DrillSentence.fromJson(r['sentence']))]),
    ]);
  }

  Future<void> _load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    _hz = [for (final v in p.getStringList(_kHz) ?? const <String>[]) double.tryParse(v) ?? 0]..removeWhere((v) => v <= 0);
    try {
      final j = jsonDecode(p.getString(_kDays) ?? '{}') as Map<String, dynamic>;
      _days = {for (final e in j.entries) e.key: [for (final d in e.value) d as String]};
    } catch (_) {
      _days = {};
    }
    _loaded = true;
  }

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// 연습한 날 수(최대 5).
  Future<int> days(String word) async {
    await _load();
    return (_days[word]?.length ?? 0).clamp(0, daysToFinish);
  }

  /// 오늘 이미 센 낱말인가.
  Future<bool> countedToday(String word) async {
    await _load();
    return _days[word]?.contains(_today()) ?? false;
  }

  /// 한 번 말해 보면(판정과 무관하게) 오늘 연습으로 센다 — 하루 한 번만.
  Future<void> countPractice(String word) async {
    await _load();
    final l = _days.putIfAbsent(word, () => []);
    if (l.contains(_today())) return;
    l.add(_today());
    (await SharedPreferences.getInstance()).setString(_kDays, jsonEncode(_days));
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
