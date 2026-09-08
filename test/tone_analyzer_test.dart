import 'dart:math' as math;

import 'package:chinese_universe/services/tone_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

/// f0 궤적(Hz)을 따라 합성한 사인파 PCM16 (0.5초).
List<int> synth(double Function(double t) f0, {double sec = 0.5}) {
  const sr = ToneAnalyzer.sampleRate;
  final n = (sr * sec).round();
  final out = <int>[];
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / n;
    phase += 2 * math.pi * f0(t) / sr;
    // 배음 조금 섞어 YIN 이 안정적으로 잡게
    final v = 0.6 * math.sin(phase) + 0.25 * math.sin(2 * phase) + 0.1 * math.sin(3 * phase);
    out.add((v * 20000).round());
  }
  // 앞뒤 무음
  final silence = List<int>.filled(sr ~/ 5, 0);
  return [...silence, ...out, ...silence];
}

void main() {
  final a = ToneAnalyzer.instance;

  test('tone 1 flat', () async {
    final r = await a.analyze(synth((t) => 220));
    expect(r.tone, 1);
  });

  test('tone 2 rising', () async {
    final r = await a.analyze(synth((t) => 160 * math.pow(2, 8 * t / 12).toDouble()));
    expect(r.tone, 2);
  });

  test('tone 3 dipping', () async {
    final r = await a.analyze(synth((t) {
      final dip = t < 0.6 ? -6 * (t / 0.6) : -6 + 5 * ((t - 0.6) / 0.4);
      return 180 * math.pow(2, dip / 12).toDouble();
    }));
    expect(r.tone, 3);
  });

  test('tone 4 falling', () async {
    final r = await a.analyze(synth((t) => 260 * math.pow(2, -10 * t / 12).toDouble()));
    expect(r.tone, 4);
  });

  test('silence → invalid', () async {
    final r = await a.analyze(List<int>.filled(16000, 0));
    expect(r.valid, isFalse);
  });
}
