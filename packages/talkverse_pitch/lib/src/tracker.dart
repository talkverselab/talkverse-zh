import 'dart:math' as math;
import 'dart:typed_data';

/// 10ms 단위 한 칸의 음높이.
class PitchFrame {
  const PitchFrame(this.time, this.hz, this.clarity, this.rms);

  /// 칸 가운데 시각(초).
  final double time;

  /// 음높이(Hz). 무음·무성음이면 null.
  final double? hz;

  /// 주기성 0~1(1 에 가까울수록 또렷한 유성음).
  final double clarity;
  final double rms;
  bool get voiced => hz != null;
}

class PitchTrack {
  PitchTrack(this.frames, this.hopSeconds);
  final List<PitchFrame> frames;
  final double hopSeconds;

  List<double> get voicedHz => [
        for (final f in frames)
          if (f.hz != null) f.hz!
      ];

  /// 음절 구간만 잘라 낼 때(구간 시각은 앱이 준다).
  PitchTrack slice(double from, double to) => PitchTrack(
        [
          for (final f in frames)
            if (f.time >= from && f.time <= to) f
        ],
        hopSeconds,
      );
}

/// 16비트 리틀엔디언 PCM(마이크 스트림) → -1~1 실수.
Float64List pcm16ToFloat(Uint8List bytes) {
  final bd = ByteData.sublistView(bytes);
  final n = bytes.length ~/ 2;
  final out = Float64List(n);
  for (var i = 0; i < n; i++) {
    out[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
  }
  return out;
}

/// YIN(차이 함수 + 누적 평균 정규화) 음높이 추적.
class PitchTracker {
  const PitchTracker({
    this.sampleRate = 16000,
    this.minHz = 70,
    this.maxHz = 500,
    this.hopSeconds = 0.01,
    this.threshold = 0.15,
    this.voicingCutoff = 0.3,
    this.relativeSilence = 0.1,
    this.absoluteSilence = 0.003,
    this.minRunFrames = 3,
  });

  final int sampleRate;
  final double minHz;
  final double maxHz;
  final double hopSeconds;

  /// 첫 골짜기를 고르는 기준(YIN 논문의 0.1~0.15).
  final double threshold;

  /// 이 값보다 주기성이 나쁘면 무성음으로 본다.
  final double voicingCutoff;

  /// 가장 큰 칸의 세기 대비 이 비율 밑은 무음.
  final double relativeSilence;
  final double absoluteSilence;

  /// 이보다 짧은 유성 구간은 버린다(튀는 값).
  final int minRunFrames;

  PitchTrack track(Float64List x) {
    final tauMin = math.max(2, (sampleRate / maxHz).floor());
    final tauMax = (sampleRate / minHz).ceil();
    final w = math.max(tauMax, (0.025 * sampleRate).round());
    final hop = math.max(1, (hopSeconds * sampleRate).round());
    final need = w + tauMax;
    final d = Float64List(tauMax + 1);

    final times = <double>[];
    final hzs = <double>[];
    final dmins = <double>[];
    final rmss = <double>[];
    var maxRms = 0.0;

    for (var s = 0; s + need <= x.length; s += hop) {
      var e = 0.0;
      for (var j = 0; j < w; j++) {
        e += x[s + j] * x[s + j];
      }
      final rms = math.sqrt(e / w);
      if (rms > maxRms) maxRms = rms;

      for (var tau = 1; tau <= tauMax; tau++) {
        var sum = 0.0;
        for (var j = 0; j < w; j++) {
          final v = x[s + j] - x[s + j + tau];
          sum += v * v;
        }
        d[tau] = sum;
      }
      var running = 0.0;
      d[0] = 1;
      for (var tau = 1; tau <= tauMax; tau++) {
        running += d[tau];
        d[tau] = running > 0 ? d[tau] * tau / running : 1.0;
      }

      var best = -1;
      for (var tau = tauMin; tau <= tauMax; tau++) {
        if (d[tau] < threshold) {
          while (tau + 1 <= tauMax && d[tau + 1] < d[tau]) {
            tau++;
          }
          best = tau;
          break;
        }
      }
      if (best < 0) {
        var m = double.infinity;
        for (var tau = tauMin; tau <= tauMax; tau++) {
          if (d[tau] < m) {
            m = d[tau];
            best = tau;
          }
        }
      }
      var tauF = best.toDouble();
      if (best > 1 && best < tauMax) {
        final a = d[best - 1], b = d[best], c = d[best + 1];
        final den = a - 2 * b + c;
        if (den.abs() > 1e-12) tauF += 0.5 * (a - c) / den;
      }
      times.add((s + need / 2) / sampleRate);
      hzs.add(sampleRate / tauF);
      dmins.add(d[best]);
      rmss.add(rms);
    }

    final n = times.length;
    final gate = math.max(absoluteSilence, relativeSilence * maxRms);
    final hz = List<double?>.generate(
      n,
      (i) => (rmss[i] >= gate && dmins[i] <= voicingCutoff) ? hzs[i] : null,
    );

    // 옥타브 튐 바로잡기: 둘레(±4칸) 가운뎃값의 두 배·절반 근처면 되돌린다.
    final fixed = List<double?>.from(hz);
    for (var i = 0; i < n; i++) {
      final h = hz[i];
      if (h == null) continue;
      final near = <double>[];
      for (var k = math.max(0, i - 4); k <= math.min(n - 1, i + 4); k++) {
        final v = hz[k];
        if (v != null) near.add(v);
      }
      if (near.length < 3) continue;
      near.sort();
      final ratio = h / near[near.length ~/ 2];
      if (ratio > 1.7 && ratio < 2.3) {
        fixed[i] = h / 2;
      } else if (ratio > 0.43 && ratio < 0.6) {
        fixed[i] = h * 2;
      }
    }

    // 너무 짧은 유성 구간 버리기.
    var i = 0;
    while (i < n) {
      if (fixed[i] == null) {
        i++;
        continue;
      }
      var j = i;
      while (j < n && fixed[j] != null) {
        j++;
      }
      if (j - i < minRunFrames) {
        for (var k = i; k < j; k++) {
          fixed[k] = null;
        }
      }
      i = j;
    }

    return PitchTrack(
      [
        for (var k = 0; k < n; k++)
          PitchFrame(times[k], fixed[k], (1 - dmins[k]).clamp(0.0, 1.0), rmss[k])
      ],
      hop / sampleRate,
    );
  }
}
