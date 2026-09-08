import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

/// 성조 판정 결과.
class ToneResult {
  /// 0~1 로 시간 정규화된 20점 피치 곡선 (Chao 5도 눈금 1~5).
  final List<double> contour;

  /// 판정된 성조 1~4 (0 = 판정 불가).
  final int tone;

  /// 각 성조 템플릿과의 거리 (작을수록 가까움). index 0 = 1성.
  final List<double> distances;

  /// 유성 구간 길이(초).
  final double voicedSec;

  const ToneResult({
    required this.contour,
    required this.tone,
    required this.distances,
    required this.voicedSec,
  });

  bool get valid => tone != 0;
}

/// 마이크 → YIN 피치 추적 → Chao 5도 정규화 → 4성 템플릿 매칭.
///
/// 오픈소스: `record`(BSD-3, PCM16 스트림) + `pitch_detector_dart`(MIT, TarsosDSP YIN 포팅).
class ToneAnalyzer {
  ToneAnalyzer._();
  static final ToneAnalyzer instance = ToneAnalyzer._();

  static const int sampleRate = 16000;
  static const int _frame = 1024;
  static const int _hop = 256;

  /// 5도 눈금 성조 템플릿 (Chao tone letters) — 20점으로 보간해 사용.
  static const Map<int, List<double>> templates = {
    1: [5, 5, 5, 5],
    2: [3, 3.3, 4, 5],
    3: [2.2, 1.2, 1, 2.6],
    4: [5, 4, 2.5, 1],
  };

  AudioRecorder? _recorder;
  AudioRecorder get _rec => _recorder ??= AudioRecorder();
  final PitchDetector _yin =
      PitchDetector(audioSampleRate: sampleRate.toDouble(), bufferSize: _frame);

  Future<bool> hasPermission() => _rec.hasPermission();

  /// [seconds] 동안 녹음하고 분석. 유성음이 [minVoicedSec] 미만이면 tone 0.
  Future<ToneResult> recordAndAnalyze({
    double seconds = 1.6,
    void Function(double level)? onLevel,
  }) async {
    final stream = await _rec.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
      autoGain: true,
      echoCancel: false,
      noiseSuppress: true,
    ));
    final chunks = <int>[];
    final done = Completer<void>();
    late final StreamSubscription sub;
    sub = stream.listen((bytes) {
      final bd = ByteData.sublistView(bytes);
      double sum = 0;
      for (var i = 0; i + 1 < bytes.length; i += 2) {
        final v = bd.getInt16(i, Endian.little);
        chunks.add(v);
        sum += v * v;
      }
      if (onLevel != null && bytes.length > 2) {
        onLevel(math.sqrt(sum / (bytes.length / 2)) / 32768);
      }
    }, onDone: () {
      if (!done.isCompleted) done.complete();
    });
    await Future.delayed(Duration(milliseconds: (seconds * 1000).round()));
    await _rec.stop();
    await sub.cancel();
    return analyze(chunks);
  }

  Future<void> cancel() async {
    if (await _rec.isRecording()) await _rec.cancel();
  }

  /// PCM16 샘플 → ToneResult.
  Future<ToneResult> analyze(List<int> pcm) async {
    final f0 = <double>[]; // Hz, 무성 = 0
    for (var s = 0; s + _frame <= pcm.length; s += _hop) {
      final buf = List<double>.generate(_frame, (i) => pcm[s + i] / 32768.0);
      // 무음 프레임 스킵
      double e = 0;
      for (final v in buf) {
        e += v * v;
      }
      if (math.sqrt(e / _frame) < 0.01) {
        f0.add(0);
        continue;
      }
      final r = await _yin.getPitchFromFloatBuffer(buf);
      final ok = r.pitched && r.probability > 0.8 && r.pitch > 70 && r.pitch < 500;
      f0.add(ok ? r.pitch : 0);
    }
    return _classify(f0);
  }

  ToneResult _classify(List<double> f0) {
    // 1) 가장 긴 유성 구간 추출 (짧은 끊김 2프레임까지 허용)
    var bestStart = -1, bestLen = 0, curStart = -1, gap = 0;
    for (var i = 0; i <= f0.length; i++) {
      final voiced = i < f0.length && f0[i] > 0;
      if (voiced) {
        if (curStart < 0) curStart = i;
        gap = 0;
      } else if (curStart >= 0) {
        gap++;
        if (gap > 2 || i == f0.length) {
          final len = i - gap - curStart + (i == f0.length && gap <= 2 ? gap : 0);
          if (len > bestLen) {
            bestLen = len;
            bestStart = curStart;
          }
          curStart = -1;
          gap = 0;
        }
      }
    }
    final voicedSec = bestLen * _hop / sampleRate;
    if (bestLen < 6 || voicedSec < 0.12) {
      return ToneResult(
          contour: const [], tone: 0, distances: const [9, 9, 9, 9], voicedSec: voicedSec);
    }
    final seg = f0.sublist(bestStart, bestStart + bestLen);
    // 2) 끊김 보간 + 반음 변환 + 3점 중앙값 필터
    final st = <double>[];
    double last = seg.firstWhere((v) => v > 0);
    for (final v in seg) {
      if (v > 0) last = v;
      st.add(12 * math.log(last / 100) / math.ln2);
    }
    final smooth = List<double>.generate(st.length, (i) {
      final a = st[math.max(0, i - 1)], b = st[i], c = st[math.min(st.length - 1, i + 1)];
      final l = [a, b, c]..sort();
      return l[1];
    });
    // 3) 화자 정규화: 중앙값 기준 ±6 반음 → 1~5 눈금
    final sorted = List<double>.from(smooth)..sort();
    final median = sorted[sorted.length ~/ 2];
    final hi = sorted[(sorted.length * 0.95).floor().clamp(0, sorted.length - 1)];
    final lo = sorted[(sorted.length * 0.05).floor()];
    final span = math.max(4.0, (hi - lo)); // 범위가 작으면(1성) 최소 4반음 기준
    final scaled = smooth
        .map((v) => (3 + (v - median) / span * 4).clamp(1.0, 5.0))
        .toList();
    // 4) 20점 리샘플
    const n = 20;
    final contour = List<double>.generate(n, (i) {
      final x = i * (scaled.length - 1) / (n - 1);
      final i0 = x.floor(), i1 = math.min(scaled.length - 1, i0 + 1);
      return scaled[i0] + (scaled[i1] - scaled[i0]) * (x - i0);
    });
    // 5) 템플릿 거리 (형태 비교: 평균 제거 후 + 절대 레벨 약간 반영)
    final distances = <double>[];
    for (var t = 1; t <= 4; t++) {
      final tpl = interpolate(templates[t]!, n);
      final mc = _mean(contour), mt = _mean(tpl);
      double d = 0;
      for (var i = 0; i < n; i++) {
        final a = contour[i] - mc, b = tpl[i] - mt;
        d += (a - b) * (a - b);
      }
      d = math.sqrt(d / n) + 0.15 * (mc - mt).abs();
      distances.add(d);
    }
    // 1성은 기울기 자체가 작아야 함 — 범위가 크면 벌점
    final range = contour.reduce(math.max) - contour.reduce(math.min);
    if (range > 1.6) distances[0] += (range - 1.6);
    var best = 1;
    for (var t = 2; t <= 4; t++) {
      if (distances[t - 1] < distances[best - 1]) best = t;
    }
    return ToneResult(contour: contour, tone: best, distances: distances, voicedSec: voicedSec);
  }

  static double _mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;

  /// 짧은 템플릿을 [n] 점으로 선형 보간.
  static List<double> interpolate(List<double> src, int n) {
    return List<double>.generate(n, (i) {
      final x = i * (src.length - 1) / (n - 1);
      final i0 = x.floor(), i1 = math.min(src.length - 1, i0 + 1);
      return src[i0] + (src[i1] - src[i0]) * (x - i0);
    });
  }
}
