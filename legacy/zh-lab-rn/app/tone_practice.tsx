// 포팅 from tone_practice_vi_screen.dart (562 줄) — 6 성조 녹음 → 평가 모드.
//
// dart 원본:
//   * data.json: tones[] + entries[]
//   * 흐름: 단어 표시 → 표준 듣기 → 🎤 녹음 → 1.5초 wait → 4단계 mock 평가
//   * 4단계: 👎👎(0)/👎(1)/👍(2)/👍👍(3) — coral / peach / sage400 / sage700
//   * 결과 화면: 누적 점수 + 등급 emoji + 다시 시작/홈
import { useState, useEffect, useCallback } from 'react';
import { StyleSheet, View, Pressable, Text as RNText, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack, useRouter } from 'expo-router';
import { colors } from '@talkverse/ui-core';

const BRAND_ZH = colors.brand.zh;

// dart 의 data.json (assets/tone_practice_vi/data.json) — 임시 inline.
// 6 성조 + 12 단어 (실제 데이터 도착 시 require() 로 교체)
const TONES = [
  { id: 'ngang', ko: '평성', symbol: '∅', hint: '평탄' },
  { id: 'huyen', ko: '하강', symbol: '`', hint: '점차 내려감' },
  { id: 'sac', ko: '상승', symbol: '´', hint: '점차 올라감' },
  { id: 'hoi', ko: '의문', symbol: '?', hint: '내렸다 올라감' },
  { id: 'nga', ko: '파열', symbol: '~', hint: '끊겼다 다시' },
  { id: 'nang', ko: '저성', symbol: '.', hint: '짧고 낮게' },
];

const QUESTIONS = [
  { num: 1, vi: 'ma', tone: 'ngang', ko: '귀신' },
  { num: 2, vi: 'mà', tone: 'huyen', ko: '그러나' },
  { num: 3, vi: 'má', tone: 'sac', ko: '엄마' },
  { num: 4, vi: 'mả', tone: 'hoi', ko: '무덤' },
  { num: 5, vi: 'mã', tone: 'nga', ko: '말(馬)' },
  { num: 6, vi: 'mạ', tone: 'nang', ko: '벼 모종' },
  { num: 7, vi: 'la', tone: 'ngang', ko: '외치다' },
  { num: 8, vi: 'là', tone: 'huyen', ko: '~이다' },
  { num: 9, vi: 'lá', tone: 'sac', ko: '잎' },
  { num: 10, vi: 'lả', tone: 'hoi', ko: '지친' },
  { num: 11, vi: 'lã', tone: 'nga', ko: '맹맹한' },
  { num: 12, vi: 'lạ', tone: 'nang', ko: '낯선' },
];

function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export default function TonePracticeScreen() {
  const router = useRouter();
  const [questions, setQuestions] = useState<typeof QUESTIONS>(() => shuffle(QUESTIONS));
  const [index, setIndex] = useState(0);
  const [totalScore, setTotalScore] = useState(0);
  /// null=녹음전, -1=분석중, 0~3=결과
  const [evalScore, setEvalScore] = useState<number | null>(null);

  // dart: _playReference — TtsService.speak(q.vi)
  const playReference = useCallback(() => {
    if (questions.length === 0) return;
    // eslint-disable-next-line no-console
    console.log(`[Tone] play ${questions[index]?.vi}`);
  }, [questions, index]);

  useEffect(() => {
    const t = setTimeout(playReference, 500);
    return () => clearTimeout(t);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // dart: _onRecord — 1.5초 wait → 가중 random (10/20/45/25%)
  const onRecord = useCallback(() => {
    setEvalScore(-1);
    setTimeout(() => {
      const r = Math.random();
      const score = r < 0.10 ? 0 : r < 0.30 ? 1 : r < 0.75 ? 2 : 3;
      setEvalScore(score);
      setTotalScore((s) => s + score);
    }, 1500);
  }, []);

  const onNext = () => {
    if (index < questions.length - 1) {
      setIndex(index + 1);
      setEvalScore(null);
      setTimeout(playReference, 300);
    } else {
      // 결과 화면 트리거 (index 를 length 로 설정)
      setIndex(index + 1);
    }
  };

  const restart = () => {
    setQuestions(shuffle(QUESTIONS));
    setIndex(0);
    setTotalScore(0);
    setEvalScore(null);
    setTimeout(playReference, 500);
  };

  const total = questions.length;
  const maxScore = total * 3;
  const isFinished = index >= total;

  if (questions.length === 0) {
    return (
      <SafeAreaView style={styles.safe}>
        <Stack.Screen options={{ title: '🎵 성조 연습' }} />
        <View style={styles.center}><ActivityIndicator color={BRAND_ZH} /></View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: '🎵 성조 연습',
          headerStyle: { backgroundColor: colors.bg },
          headerTintColor: colors.ink,
          headerRight: () => !isFinished ? (
            <RNText style={{ color: BRAND_ZH, fontSize: 14, fontWeight: 'bold', paddingRight: 12 }}>
              {totalScore} / {maxScore}
            </RNText>
          ) : null,
        }}
      />
      <View style={styles.container}>
        {isFinished ? (
          <ResultView total={total} maxScore={maxScore} totalScore={totalScore} onRestart={restart} onHome={() => router.back()} />
        ) : (
          <QuestionView
            index={index}
            total={total}
            question={questions[index]}
            tone={TONES.find((t) => t.id === questions[index].tone) ?? TONES[0]}
            evalScore={evalScore}
            onPlay={playReference}
            onRecord={onRecord}
            onNext={onNext}
            isLast={index === total - 1}
          />
        )}
      </View>
    </SafeAreaView>
  );
}

function QuestionView({
  index, total, question, tone, evalScore, onPlay, onRecord, onNext, isLast,
}: {
  index: number;
  total: number;
  question: { num: number; vi: string; ko: string; tone: string };
  tone: { id: string; ko: string; symbol: string; hint: string };
  evalScore: number | null;
  onPlay: () => void;
  onRecord: () => void;
  onNext: () => void;
  isLast: boolean;
}) {
  return (
    <>
      <View style={styles.headRow}>
        <RNText style={{ fontSize: 13, color: colors.inkFaint }}>{index + 1} / {total}</RNText>
        <RNText style={{ fontSize: 12, color: colors.inkFaint }}>녹음 → 평가</RNText>
      </View>
      <View style={[styles.progressBar, { backgroundColor: colors.bgDeep }]}>
        <View style={[styles.progressFill, { width: `${((index + 1) / total) * 100}%`, backgroundColor: BRAND_ZH }]} />
      </View>
      <View style={{ height: 20 }} />
      <View style={[styles.wordCard, { shadowColor: BRAND_ZH }]}>
        <RNText style={styles.viBig}>{question.vi}</RNText>
        <RNText style={styles.koMid}>{question.ko}</RNText>
        <RNText style={styles.toneInfo}>{tone.id} · {tone.ko} · {tone.hint}</RNText>
        <Pressable style={styles.listenBtn} onPress={onPlay}>
          <RNText style={{ color: BRAND_ZH, fontWeight: 'bold' }}>🔊 표준 듣기</RNText>
        </Pressable>
      </View>
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <RecordZone evalScore={evalScore} onRecord={onRecord} />
      </View>
      {evalScore !== null && evalScore >= 0 && (
        <Pressable style={styles.nextBtn} onPress={onNext}>
          <RNText style={{ color: '#FFFFFF', fontSize: 15, fontWeight: 'bold' }}>
            {isLast ? '결과 보기' : '다음 단어'}
          </RNText>
        </Pressable>
      )}
    </>
  );
}

function RecordZone({ evalScore, onRecord }: { evalScore: number | null; onRecord: () => void }) {
  if (evalScore === null) {
    return (
      <View style={{ alignItems: 'center' }}>
        <Pressable style={styles.micButton} onPress={onRecord}>
          <RNText style={{ color: '#FFFFFF', fontSize: 48 }}>🎤</RNText>
        </Pressable>
        <RNText style={{ marginTop: 12, fontSize: 14, fontWeight: '700', color: colors.inkSoft }}>
          🎤 발음을 녹음해보세요
        </RNText>
        <RNText style={{ marginTop: 4, fontSize: 10, color: colors.inkFaint }}>
          (베타 — 평가 시스템 튜닝 중)
        </RNText>
      </View>
    );
  }
  if (evalScore === -1) {
    return (
      <View style={{ alignItems: 'center' }}>
        <ActivityIndicator size="large" color={BRAND_ZH} />
        <RNText style={{ marginTop: 16, fontSize: 14, fontWeight: '700', color: colors.inkSoft }}>
          분석 중...
        </RNText>
      </View>
    );
  }
  return <ScoreResult score={evalScore} onRetry={onRecord} />;
}

function ScoreResult({ score, onRetry }: { score: number; onRetry: () => void }) {
  const config = [
    { emoji: '👎👎', title: '투썸 아래', msg: '다시 해봐요', color: colors.coral500 },
    { emoji: '👎', title: '원썸 아래', msg: '조금 더!', color: colors.peach400 },
    { emoji: '👍', title: '원썸 위', msg: '좋아요', color: colors.sage400 },
    { emoji: '👍👍', title: '투썸 위', msg: '완벽해요!', color: colors.sage700 },
  ][score];
  return (
    <View style={{ alignItems: 'center' }}>
      <RNText style={{ fontSize: 80, lineHeight: 86 }}>{config.emoji}</RNText>
      <RNText style={{ fontSize: 22, fontWeight: '900', color: config.color, marginTop: 14 }}>
        {config.title}
      </RNText>
      <RNText style={{ fontSize: 14, fontWeight: '600', color: colors.inkSoft, marginTop: 6 }}>
        {config.msg}
      </RNText>
      <Pressable onPress={onRetry} style={{ marginTop: 16 }}>
        <RNText style={{ color: colors.inkFaint, fontSize: 13 }}>🔄 다시 녹음</RNText>
      </Pressable>
    </View>
  );
}

function ResultView({
  total, maxScore, totalScore, onRestart, onHome,
}: {
  total: number; maxScore: number; totalScore: number; onRestart: () => void; onHome: () => void;
}) {
  void total; // dart: 사용 안 함
  const pct = Math.round((totalScore / maxScore) * 100);
  const emoji = pct >= 90 ? '🎉' : pct >= 70 ? '👏' : pct >= 50 ? '👍' : '💪';
  const msg = pct >= 90 ? '완벽해요!' : pct >= 70 ? '잘했어요!' : pct >= 50 ? '꾸준히 연습해요' : '한 번 더 도전!';
  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      <RNText style={{ fontSize: 64 }}>{emoji}</RNText>
      <RNText style={{ fontSize: 22, fontWeight: 'bold', color: colors.ink, marginTop: 16 }}>{msg}</RNText>
      <View style={[styles.resultBox, { shadowColor: BRAND_ZH }]}>
        <RNText style={{ fontSize: 13, color: colors.inkFaint }}>점수</RNText>
        <RNText style={{ fontSize: 40, fontWeight: 'bold', color: BRAND_ZH, marginTop: 4 }}>
          {totalScore} / {maxScore}
        </RNText>
        <RNText style={{ fontSize: 14, color: colors.inkFaint }}>{pct}%</RNText>
      </View>
      <View style={{ flexDirection: 'row', gap: 12, marginTop: 32 }}>
        <Pressable style={styles.outlinedBtn} onPress={onRestart}>
          <RNText style={{ color: BRAND_ZH, fontWeight: 'bold' }}>🔄 다시 시작</RNText>
        </Pressable>
        <Pressable style={[styles.filledBtn, { backgroundColor: BRAND_ZH }]} onPress={onHome}>
          <RNText style={{ color: '#FFFFFF', fontWeight: 'bold' }}>🏠 홈으로</RNText>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.bg },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  container: { flex: 1, padding: 20 },
  headRow: { flexDirection: 'row', justifyContent: 'space-between' },
  progressBar: { height: 3, borderRadius: 2, marginTop: 8, overflow: 'hidden' },
  progressFill: { height: '100%' },
  wordCard: {
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 20,
    paddingVertical: 24,
    borderRadius: 20,
    alignItems: 'center',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.6,
    shadowRadius: 14,
    elevation: 5,
  },
  viBig: { fontSize: 56, fontWeight: 'bold', color: BRAND_ZH, lineHeight: 60 },
  koMid: { fontSize: 13, color: colors.inkSoft, marginTop: 8 },
  toneInfo: { fontSize: 12, color: colors.inkFaint, fontStyle: 'italic', marginTop: 6 },
  listenBtn: {
    marginTop: 14,
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: colors.bgSoft,
    borderRadius: 20,
  },
  micButton: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: BRAND_ZH,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: BRAND_ZH,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.3,
    shadowRadius: 16,
    elevation: 8,
  },
  nextBtn: {
    backgroundColor: BRAND_ZH,
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 12,
  },
  resultBox: {
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 32,
    paddingVertical: 20,
    borderRadius: 20,
    alignItems: 'center',
    marginTop: 24,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.5,
    shadowRadius: 12,
    elevation: 5,
  },
  outlinedBtn: {
    paddingHorizontal: 18,
    paddingVertical: 10,
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: BRAND_ZH,
  },
  filledBtn: {
    paddingHorizontal: 18,
    paddingVertical: 10,
    borderRadius: 12,
    alignItems: 'center',
  },
});
