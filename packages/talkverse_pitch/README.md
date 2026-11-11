# talkverse_pitch

발화 음높이(F0) 측정·성조 채점 공용 모듈. 순수 Dart(플랫폼 의존 없음) — 마이크 녹음은 앱이 하고 16kHz 모노 PCM 을 넘긴다.

```dart
final track = const PitchTracker().track(pcm16ToFloat(bytes));      // 10ms 단위 음높이
final r = scoreMandarinSequence(track, [1, 1], hanzi: ['今', '天'],   // 사전 성조(경성 0)
    speakerMedianHz: range.medianHz);                                // 그 사람 평소 음높이
r.passed;                 // 전부 통과?
r.syllables[i].verdict;   // good / close / off
r.syllables[i].tone?.heard, .hints;   // 어느 성조로 들렸나, 고칠 점(keep_level·higher·end_higher·middle_lower·fall_more·start_higher)
r.syllables[i].contour?.st;           // 겹쳐 그릴 곡선(평소 음높이 기준 반음, 20점)
```

- `surfaceTones` — 변조: 3+3 → 2+3, 반3성, 不+4성. 一 의 변조는 자료가 바뀐 성조로 적어 준다.
- `splitSyllables` — 무성 자음의 끊김 → 세기 골 순으로 음절을 나눈다. 2~4음절용. 문장은 음절별 채점을 하지 않는다.
- `compareContoursWarped` — 문장: 기준 음성 곡선과 모양 비교(참고용 점수 + 겹쳐 보기).
- `SpeakerRange.fromHz` — 그 사람 음역(5·50·95 백분위). 녹음할 때마다 유성 칸을 모아 갱신해 저장한다. 없으면 그 발화의 가운뎃값으로 대신하지만 "전체가 높은지"는 못 가린다(1성+1성 낱말).
- `bin/contour.dart` — 기준 음성에서 곡선 자료 뽑기: `ffmpeg -v error -i a.mp3 -f s16le -ar 16000 -ac 1 - | dart run talkverse_pitch:contour 50`

한계: 문턱값은 합성음으로 맞춘 처음 값이다. 실제 학습자 녹음으로 다시 맞춰야 한다. 곡선 겹쳐 보기는 보조 수단이고, 판정은 성조를 가르는 특징(끝이 시작보다 높은가 등)으로 한다.

시험: `dart test` (합성음 — 2음절 20칸, 3·4음절, 틀린 음절 짚기, 문장 비교).
