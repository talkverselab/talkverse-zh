import 'dart:math' as math;

import 'contour.dart';
import 'mandarin.dart';
import 'tracker.dart';

/// 낱말·짧은 구(2~4음절)의 성조를 음절마다 채점한다.
/// 흐름: 사전 성조 → [surfaceTones](이어 말할 때 실제로 나는 꼴) → [splitSyllables] → 음절별 채점.

/// 실제로 내야 하는 한 음절의 목표.
class SyllableTarget {
  const SyllableTarget(this.lexical, this.accepted, {this.half = false});

  /// 사전 성조 0(경성)~4.
  final int lexical;

  /// 통과로 치는 성조(1~4). 경성이면 빈 집합.
  final Set<int> accepted;

  /// 반3성(뒤에 1·2·4·경성이 와서 낮게만 깔리는 3성).
  final bool half;

  bool get neutral => lexical == 0;

  /// 화면에 그릴 대표 성조.
  int get shown => neutral ? 0 : accepted.first;
}

/// 이어 말할 때의 변조를 적용한다.
/// - 3성+3성 → 앞이 2성(셋 이상 이어지면 맨 앞쪽은 2성·낮은 3성 둘 다 통과).
/// - 3성 + 1·2·4·경성 → 반3성(낮게).
/// - 不(4성) + 4성 → 2성. ([hanzi] 를 줬을 때만)
/// 一 의 변조는 서수·숫자에서 안 일어나므로 여기서 하지 않는다 — 자료가 바뀐 성조로 적어 준다.
List<SyllableTarget> surfaceTones(List<int> tones, {List<String>? hanzi}) {
  final n = tones.length;
  final out = <SyllableTarget>[];
  for (var i = 0; i < n; i++) {
    final t = tones[i];
    final next = i + 1 < n ? tones[i + 1] : null;
    if (t == 0) {
      out.add(const SyllableTarget(0, {}));
    } else if (t == 3 && next == 3) {
      final nextNext = i + 2 < n ? tones[i + 2] : null;
      out.add(SyllableTarget(3, nextNext == 3 ? {2, 3} : {2}));
    } else if (t == 3 && next != null) {
      out.add(const SyllableTarget(3, {3}, half: true));
    } else if (t == 4 && next == 4 && hanzi != null && hanzi[i] == '不') {
      out.add(const SyllableTarget(4, {2}));
    } else {
      out.add(SyllableTarget(t, {t}));
    }
  }
  return out;
}

class _Run {
  _Run(this.from, this.to);
  int from; // 칸 번호(포함)
  int to; // 칸 번호(포함)
  int get length => to - from + 1;
}

/// 음높이 기록을 [n] 음절로 나눈다.
/// 무성 자음(t·sh·x…)이 만든 끊김을 먼저 경계로 쓰고, 유성음으로 이어진 곳(m·n·l·y·w)은
/// 소리 세기가 꺼지는 골에서 나눈다. 말소리가 없으면 빈 목록.
List<PitchTrack> splitSyllables(PitchTrack track, int n) {
  final f = track.frames;
  final runs = <_Run>[];
  var i = 0;
  while (i < f.length) {
    if (!f[i].voiced) {
      i++;
      continue;
    }
    var j = i;
    while (j + 1 < f.length && f[j + 1].voiced) {
      j++;
    }
    // 2칸(20ms) 이하 끊김은 같은 음절로 본다.
    if (runs.isNotEmpty && i - runs.last.to - 1 <= 2) {
      runs.last.to = j;
    } else {
      runs.add(_Run(i, j));
    }
    i = j + 1;
  }
  if (runs.isEmpty || n < 1) return const [];

  while (runs.length > n) {
    var best = 0;
    var gap = 1 << 30;
    for (var k = 0; k + 1 < runs.length; k++) {
      final g = runs[k + 1].from - runs[k].to;
      if (g < gap) {
        gap = g;
        best = k;
      }
    }
    runs[best].to = runs[best + 1].to;
    runs.removeAt(best + 1);
  }

  // 모자라면 긴 구간부터 음절 수를 더 준다.
  final count = List<int>.filled(runs.length, 1);
  for (var extra = n - runs.length; extra > 0; extra--) {
    var best = 0;
    var size = -1.0;
    for (var k = 0; k < runs.length; k++) {
      final s = runs[k].length / count[k];
      if (s > size) {
        size = s;
        best = k;
      }
    }
    count[best]++;
  }

  final out = <PitchTrack>[];
  for (var k = 0; k < runs.length; k++) {
    final r = runs[k];
    final cuts = <int>[r.from];
    for (var c = 1; c < count[k]; c++) {
      final expect = r.from + (r.length * c / count[k]).round();
      final w = math.max(2, (r.length * 0.3 / count[k]).round());
      var at = expect;
      var low = double.infinity;
      for (var x = math.max(r.from + 3, expect - w);
          x <= math.min(r.to - 3, expect + w);
          x++) {
        final e = (f[x - 1].rms + f[x].rms + f[x + 1].rms) / 3;
        if (e < low) {
          low = e;
          at = x;
        }
      }
      cuts.add(at);
    }
    cuts.add(r.to + 1);
    for (var c = 0; c + 1 < cuts.length; c++) {
      out.add(PitchTrack(f.sublist(cuts[c], cuts[c + 1]), track.hopSeconds));
    }
  }
  return out;
}

/// 한 음절의 결과.
class SyllableScore {
  const SyllableScore({
    required this.target,
    required this.verdict,
    required this.from,
    required this.to,
    this.contour,
    this.tone,
  });
  final SyllableTarget target;
  final ToneVerdict verdict;

  /// 음절 구간(초).
  final double from;
  final double to;

  /// 그 사람 평소 음높이 기준 반음 곡선(너무 짧으면 null).
  final Contour? contour;

  /// 성조 채점(경성은 null).
  final ToneScore? tone;
}

class SequenceScore {
  const SequenceScore(this.syllables, this.refHz);
  final List<SyllableScore> syllables;

  /// 채점 기준으로 쓴 평소 음높이.
  final double refHz;

  /// 말소리를 못 찾았거나 음절 수가 안 맞음.
  bool get valid => syllables.isNotEmpty;
  bool get passed =>
      valid && syllables.every((s) => s.verdict == ToneVerdict.good);

  /// 0~1.
  double get score => valid
      ? syllables
              .map((s) => s.verdict == ToneVerdict.good
                  ? 1.0
                  : s.verdict == ToneVerdict.close
                      ? 0.5
                      : 0.0)
              .reduce((a, b) => a + b) /
          syllables.length
      : 0;
}

/// [tones] = 사전 성조(0~4) 목록. [speakerMedianHz] 가 없으면 이 발화의 가운뎃값을 쓴다
/// (그러면 "전체가 높은지 낮은지"는 못 가린다 — 누적한 [SpeakerRange] 를 주는 것이 원칙).
SequenceScore scoreMandarinSequence(
  PitchTrack track,
  List<int> tones, {
  List<String>? hanzi,
  double? speakerMedianHz,
}) {
  final hz = track.voicedHz;
  if (hz.isEmpty) return const SequenceScore([], 0);
  final ref = speakerMedianHz ?? (([...hz]..sort())[hz.length ~/ 2]);
  final parts = splitSyllables(track, tones.length);
  if (parts.length != tones.length) return SequenceScore(const [], ref);
  final targets = surfaceTones(tones, hanzi: hanzi);
  final connected = tones.length > 1;

  final out = <SyllableScore>[];
  for (var i = 0; i < parts.length; i++) {
    final p = parts[i];
    final c = Contour.fromTrack(p, refHz: ref, minVoicedFrames: 4);
    final from = p.frames.first.time, to = p.frames.last.time;
    final tg = targets[i];
    if (tg.neutral) {
      // 경성: 짧고 가볍게 — 앞 음절보다 길지 않으면 통과.
      final prev = i > 0 ? parts[i - 1].frames.length : null;
      final ok = prev == null || p.frames.length <= prev * 1.1;
      out.add(SyllableScore(
          target: tg,
          verdict: ok ? ToneVerdict.good : ToneVerdict.close,
          from: from,
          to: to,
          contour: c));
      continue;
    }
    if (c == null) {
      out.add(SyllableScore(
          target: tg, verdict: ToneVerdict.off, from: from, to: to));
      continue;
    }
    ToneScore? best;
    for (final t in tg.accepted) {
      final s = scoreMandarinTone(c, t, connected: connected);
      if (best == null || s.verdict.index < best.verdict.index) best = s;
    }
    out.add(SyllableScore(
        target: tg,
        verdict: best!.verdict,
        from: from,
        to: to,
        contour: c,
        tone: best));
  }
  return SequenceScore(out, ref);
}
