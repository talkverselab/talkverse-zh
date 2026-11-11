import 'dart:math' as math;
import 'dart:typed_data';

import 'package:talkverse_pitch/talkverse_pitch.dart';
import 'package:test/test.dart';

const sr = 16000;

/// 이어 말할 때의 음절 모양(평소 음높이 기준 반음). 3h = 반3성, 0 = 경성.
const shapes = <String, List<List<double>>>{
  '1': [[0, 3], [1, 3]],
  '2': [[0, -1], [1, 3]],
  '3': [[0, -1], [0.5, -5], [1, -0.5]],
  '3h': [[0, -2], [1, -5]],
  '4': [[0, 4], [1, -2]],
  '0': [[0, -1], [1, -2]],
};

/// 낱말 합성. [gap] = true 면 음절 사이에 무성 자음(60ms 무음), false 면 유성음으로 이어지고 세기만 꺼진다.
Float64List word(double medianHz, List<String> syl, {required bool gap, int seed = 1}) {
  final rnd = math.Random(seed);
  final out = <double>[];
  void silence(double sec) => out.addAll(List.filled((sec * sr).round(), 0.0));
  silence(0.1);
  var phase = 0.0;
  for (var s = 0; s < syl.length; s++) {
    final path = shapes[syl[s]]!;
    final n = ((syl[s] == '0' ? 0.14 : 0.26) * sr).round();
    for (var i = 0; i < n; i++) {
      final p = i / (n - 1);
      var k = 0;
      while (k + 1 < path.length - 1 && path[k + 1][0] < p) {
        k++;
      }
      final a = ((p - path[k][0]) / (path[k + 1][0] - path[k][0])).clamp(0.0, 1.0);
      final st = path[k][1] + (path[k + 1][1] - path[k][1]) * a;
      phase += 2 * math.pi * medianHz * math.pow(2, st / 12) / sr;
      var v = 0.0;
      for (var h = 1; h <= 5; h++) {
        v += math.sin(phase * h) / h;
      }
      final edge = math.min(i, n - 1 - i) / (0.04 * sr);
      final env = gap ? math.min(1.0, edge / 0.5) : 0.3 + 0.7 * math.min(1.0, edge);
      out.add(0.3 * v * env);
    }
    if (gap && s < syl.length - 1) silence(0.06);
  }
  silence(0.1);
  return Float64List.fromList([for (final v in out) v + 0.01 * (rnd.nextDouble() * 2 - 1)]);
}

/// 사전 성조 → 합성에 쓸 모양(변조 적용).
List<String> spoken(List<int> tones) => [
      for (var i = 0; i < tones.length; i++)
        if (tones[i] == 3 && i + 1 < tones.length)
          (tones[i + 1] == 3 ? '2' : '3h')
        else
          '${tones[i]}'
    ];

SequenceScore run(List<int> tones, double median, {required bool gap, List<String>? say}) {
  final x = word(median, say ?? spoken(tones), gap: gap);
  final track = const PitchTracker(sampleRate: sr).track(x);
  return scoreMandarinSequence(track, tones, speakerMedianHz: median);
}

void main() {
  test('변조: 3-3, 반3성, 不', () {
    expect(surfaceTones([3, 3]).map((t) => t.accepted).toList(), [{2}, {3}]);
    expect(surfaceTones([3, 3, 3]).map((t) => t.accepted).toList(), [{2, 3}, {2}, {3}]);
    expect(surfaceTones([3, 1]).first.half, isTrue);
    expect(surfaceTones([3]).first.half, isFalse);
    expect(surfaceTones([4, 4], hanzi: ['不', '是']).first.accepted, {2});
    expect(surfaceTones([4, 4], hanzi: ['再', '见']).first.accepted, {4});
    expect(surfaceTones([2, 0]).last.neutral, isTrue);
  });

  for (final gap in [true, false]) {
    final kind = gap ? '무성 자음으로 끊김' : '유성음으로 이어짐';
    test('2음절 16칸 + 경성 4칸 ($kind)', () {
      for (final median in [120.0, 210.0]) {
        for (var a = 1; a <= 4; a++) {
          for (var b = 0; b <= 4; b++) {
            final r = run([a, b], median, gap: gap);
            expect(r.valid, isTrue, reason: '$a-$b $median');
            expect(r.syllables.length, 2);
            expect(r.passed, isTrue,
                reason: '$a-$b $median → ${[for (final s in r.syllables) '${s.verdict.name} ${s.tone?.scores}']}');
          }
        }
      }
    });

    test('3·4음절 ($kind)', () {
      for (final tones in [
        [4, 1, 2], [1, 3, 4], [3, 3, 3], [2, 4, 0], [3, 2, 1],
        [1, 2, 3, 4], [4, 4, 2, 1], [2, 3, 3, 4], [3, 1, 4, 2],
      ]) {
        final r = run(tones, 170, gap: gap);
        expect(r.syllables.length, tones.length, reason: '$tones');
        expect(r.passed, isTrue,
            reason: '$tones → ${[for (final s in r.syllables) '${s.verdict.name} ${s.tone?.scores}']}');
      }
    });
  }

  test('틀린 음절만 짚는다', () {
    // 今天(1-1)을 1-4 로 말함 → 둘째만 불통.
    final r = run([1, 1], 180, gap: true, say: ['1', '4']);
    expect(r.syllables[0].verdict, ToneVerdict.good);
    expect(r.syllables[1].verdict, isNot(ToneVerdict.good));
    expect(r.syllables[1].tone!.heard, 4);
    // 你好(3-3)를 변조 없이 낮게-낮게 → 첫째 불통.
    final r2 = run([3, 3], 180, gap: false, say: ['3h', '3']);
    expect(r2.syllables[0].verdict, isNot(ToneVerdict.good));
    expect(r2.passed, isFalse);
  });

  test('말소리가 없으면 무효', () {
    final track = const PitchTracker(sampleRate: sr).track(Float64List(sr));
    expect(scoreMandarinSequence(track, [1, 2]).valid, isFalse);
  });

  test('문장 비교: 느리게 말해도 같은 모양이면 통과, 다른 모양이면 낮음', () {
    Contour c(List<String> syl, double median, {int seed = 1}) {
      final track = const PitchTracker(sampleRate: sr).track(word(median, syl, gap: false, seed: seed));
      return Contour.fromTrack(track, refHz: median, points: 50)!;
    }

    final ref = c(['2', '3h', '4', '1', '4'], 220);
    final same = c(['2', '3h', '4', '1', '4'], 125, seed: 5);
    final other = c(['4', '1', '2', '4', '2'], 125, seed: 5);
    expect(compareContoursWarped(same, ref).score, greaterThan(0.8));
    expect(compareContoursWarped(other, ref).score, lessThan(0.4));
  });
}
