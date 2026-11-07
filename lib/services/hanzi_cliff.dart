/// 한자 절벽 경계 — 2026-11-07 재산출(영화·드라마 대사 한자 빈도, 단어 절벽과 같은 말뭉치·공식: 누적 55/60/70/80% 첫 순위).
/// 경계는 여기 한 곳에만 둔다. 자료 `assets/data/hanzi/hanzi_cliff.json`·`cliff/hanzi_cliff_zh.tsv` 는 `tools/hanzi_cliff_build.py` 가 같은 값으로 만든다.
class HanziCliff {
  HanziCliff._();
  /// R1~R4 끝 순위, R5 상한 2,000.
  static const bounds = [96, 129, 226, 411, 2000];
  static const labels = ['R1', 'R2', 'R3', 'R4', 'R5'];
  /// 각 구간 끝의 누적 커버리지(%).
  static const coverage = [55.0, 60.1, 70.0, 80.0, 98.4];
  static const top = 2000;

  /// 순위 → 'R1'…'R5'(2,000 밖은 null).
  static String? regionOf(int? rank) {
    if (rank == null || rank <= 0) return null;
    for (var i = 0; i < bounds.length; i++) {
      if (rank <= bounds[i]) return labels[i];
    }
    return null;
  }

  /// 구간 번호(1~5) — DB `hanzi.phase`.
  static int? phaseOf(int? rank) {
    final r = regionOf(rank);
    return r == null ? null : labels.indexOf(r) + 1;
  }

  static int countOf(int i) => i == 0 ? bounds[0] : bounds[i] - bounds[i - 1];
}
