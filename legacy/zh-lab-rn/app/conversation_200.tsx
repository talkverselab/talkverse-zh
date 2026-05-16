// 포팅 from conversation_200_vi_screen.dart (664 줄) — 정밀 1:1.
//
// dart 원본 핵심:
//   * 동그라미 20개 (10x2) — block stage 7단계 색상
//   * 카드 flip (ko ↔ vi+pron+key) + horizontal drag → prev/next
//   * AppBar actions: 별표 / 코스모드 / 한글독음 / 자동재생
//   * 컨트롤 4개: 이전 / 탭하면답·다시듣기 / 알아요 / 다음
//   * cream 톤 _ToneButton — colored shadow + inner highlight
//   * SRS planner — phase label ("새 블록 1/20 학습" 등)
//   * mp3 자동재생 (south_male/south_female)
import { useEffect, useState, useRef, useCallback } from 'react';
import {
  StyleSheet, View, Pressable, ActivityIndicator,
  Text as RNText, Dimensions, PanResponder,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack } from 'expo-router';
import { colors } from '@talkverse/ui-core';
import { Conv200LearningPlanner } from '../data/conversation200LearningPlanner';
import {
  loadConversation200Entries, loadConversation200Title,
  type ViDialect, type Conv200Entry,
} from '../data/conversation200KeyboardPool';
import { AudioPlayer } from '../services/AudioPlayer';
import { WordReviews } from '../services/WordReviews';
import { FavoriteWords } from '../services/FavoriteWords';
import { UserStats } from '../services/UserStats';

const BRAND_ZH = colors.brand.zh;

// dart: _stageColors — 7단계 동그라미 색상
const STAGE_COLORS = [
  '#EAEAEA', '#FFD7D7', '#FFB0B0', '#FF8585',
  '#EF5050', '#D42020', '#9C0000',
];

export default function Conversation200ViScreen() {
  // dart: LanguageService.viRegion.value — 현재 in-memory 'south' (TODO: shared state)
  const [dialect] = useState<ViDialect>('south');

  const [entries, setEntries] = useState<Conv200Entry[] | null>(null);
  const [title, setTitle] = useState('중국어 기초 회화 200');

  const [index, setIndex] = useState(0);
  const [showBack, setShowBack] = useState(false);
  const [autoPlay, setAutoPlay] = useState(true);
  const [showPron, setShowPron] = useState(true);

  // dart: Map<int,int> _stages — num → SRS stage
  const [stages, setStages] = useState<Record<number, number>>({});
  // dart: FavoriteWords — num set
  const [favs, setFavs] = useState<Set<number>>(new Set());

  // dart: _planMode + Conv200LearningPlanner
  const [planMode, setPlanMode] = useState(true);
  const plannerRef = useRef<Conv200LearningPlanner | null>(null);
  const [phaseLabel, setPhaseLabel] = useState('새 블록 1/20 학습');

  // === planner init ===
  if (plannerRef.current === null) {
    plannerRef.current = new Conv200LearningPlanner({
      isKnown: (n) => (stages[n] ?? 0) >= 1,
      isFavorite: (n) => favs.has(n),
    });
    plannerRef.current.start();
  }

  // dart: _loadDataIfNeeded
  useEffect(() => {
    const list = loadConversation200Entries(dialect);
    setEntries(list);
    setTitle(loadConversation200Title(dialect));
  }, [dialect]);

  // dart: _applyPlannerNext — plan 모드 시 다음 sentence 결정
  const applyPlannerNext = useCallback(() => {
    if (!planMode) return;
    const planner = plannerRef.current;
    if (!planner) return;
    const n = planner.next();
    if (n == null) return;
    setIndex(n - 1);
    setShowBack(false);
    setPhaseLabel(planner.phaseLabel());
  }, [planMode]);

  useEffect(() => {
    if (entries && entries.length > 0) {
      const t = setTimeout(applyPlannerNext, 0);
      return () => clearTimeout(t);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [entries]);

  // dart: _speakVi — mp3 path 결정 + expo-av 재생
  const speakVi = useCallback(() => {
    if (!entries || entries.length === 0) return;
    const entry = entries[index];
    if (!entry) return;
    const num = entry.num ?? 0;
    const maleSpeakers = ['John', 'Trang 아빠', 'Trang ba', 'Linh 아빠'];
    const isMale = maleSpeakers.includes(entry.speaker ?? '');
    const voiceDir = isMale ? 'south_male' : 'south_female';
    const paddedNum = String(num).padStart(3, '0');
    const key = `conv200_${paddedNum}`;
    AudioPlayer.play(voiceDir, key).catch(() => {});
  }, [entries, index]);

  const next = useCallback(() => {
    if (!entries) return;
    if (planMode) {
      applyPlannerNext();
      return;
    }
    if (index < entries.length - 1) {
      setIndex(index + 1);
      setShowBack(false);
    }
  }, [entries, index, planMode, applyPlannerNext]);

  const prev = useCallback(() => {
    if (index > 0) {
      setIndex(index - 1);
      setShowBack(false);
    }
  }, [index]);

  // dart: _jumpTo — circle 점프 = 자유 모드 전환
  const jumpTo = useCallback((targetEntry: number) => {
    if (!entries) return;
    if (targetEntry < 0 || targetEntry >= entries.length) return;
    setIndex(targetEntry);
    setShowBack(false);
    setPlanMode(false);
  }, [entries]);

  const toggleFlip = useCallback(() => {
    setShowBack((b) => {
      const nextValue = !b;
      if (nextValue && autoPlay) {
        setTimeout(speakVi, 200);
      }
      return nextValue;
    });
  }, [autoPlay, speakVi]);

  // dart: _onKnown — WordReviews.recordKnown + planner.onKnown + UserStats + auto-next
  const onKnown = useCallback(() => {
    if (!entries || entries.length === 0) return;
    const num = entries[index]?.num ?? 0;
    if (num === 0) return;
    setStages((s) => ({ ...s, [num]: Math.min((s[num] ?? 0) + 1, 6) }));
    plannerRef.current?.onKnown(num);
    WordReviews.recordKnown(num).catch(() => {});
    UserStats.incrementToday(1).catch(() => {});
    setTimeout(() => next(), 250);
  }, [entries, index, next]);

  // dart: _togglePlanMode
  const togglePlanMode = useCallback(() => {
    setPlanMode((m) => {
      const nextMode = !m;
      if (nextMode) {
        plannerRef.current?.start();
        setTimeout(applyPlannerNext, 0);
      }
      return nextMode;
    });
  }, [applyPlannerNext]);

  // dart: toggle favorite
  const toggleFav = useCallback(() => {
    if (!entries) return;
    const num = entries[index]?.num ?? 0;
    if (num === 0) return;
    setFavs((s) => {
      const ns = new Set(s);
      if (ns.has(num)) ns.delete(num); else ns.add(num);
      return ns;
    });
    FavoriteWords.toggle(num).catch(() => {});
  }, [entries, index]);

  // 초기 load: WordReviews stage + FavoriteWords (AsyncStorage).
  useEffect(() => {
    if (!entries || entries.length === 0) return;
    let alive = true;
    (async () => {
      const stagesMap: Record<number, number> = {};
      for (const e of entries) {
        const n = e.num ?? 0;
        if (n === 0) continue;
        const s = await WordReviews.getStage(n);
        if (s > 0) stagesMap[n] = s;
      }
      const favArr = await FavoriteWords.all();
      if (!alive) return;
      setStages((prev) => ({ ...stagesMap, ...prev }));
      setFavs(new Set(favArr));
    })();
    return () => {
      alive = false;
    };
  }, [entries]);

  // dart: _blockStage — 10 개 known 카운트 → 0-6 stage
  const blockStage = (blockIdx: number): number => {
    let known = 0;
    for (let i = 0; i < 10; i++) {
      const n = blockIdx * 10 + i + 1;
      if (n > 200) break;
      if ((stages[n] ?? 0) >= 1) known++;
    }
    if (known === 0) return 0;
    if (known <= 2) return 1;
    if (known <= 4) return 2;
    if (known <= 6) return 3;
    if (known <= 8) return 4;
    if (known <= 9) return 5;
    return 6;
  };

  // dart: _circleRow
  const circleRow = (row: number) => (
    <View style={styles.circleRow}>
      {Array.from({ length: 10 }).map((_, col) => {
        const blockIdx = row * 10 + col;
        const targetEntry = blockIdx * 10;
        const isCurrent = entries !== null && Math.floor(index / 10) === blockIdx;
        const stage = blockStage(blockIdx);
        const fillColor = STAGE_COLORS[stage];
        const textColor = stage >= 4 ? '#FFFFFF' : BRAND_ZH;
        return (
          <Pressable
            key={col}
            onPress={() => jumpTo(targetEntry)}
            style={[
              styles.circle,
              {
                backgroundColor: fillColor,
                borderColor: isCurrent ? BRAND_ZH : 'rgba(0,0,0,0.15)',
                borderWidth: isCurrent ? 2 : 1,
              },
            ]}
          >
            <RNText style={[styles.circleText, { color: textColor }]}>
              {String(blockIdx * 10 + 1).padStart(2, '0')}
            </RNText>
          </Pressable>
        );
      })}
    </View>
  );

  // dart: GestureDetector + onHorizontalDragEnd — PanResponder swipe
  const panResponder = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_, g) =>
        Math.abs(g.dx) > 20 && Math.abs(g.dy) < 40,
      onPanResponderRelease: (_, g) => {
        if (g.vx > 0.5 || g.dx > 80) prev();
        else if (g.vx < -0.5 || g.dx < -80) next();
      },
    })
  ).current;

  if (entries === null) {
    return (
      <SafeAreaView style={styles.safe}>
        <Stack.Screen options={{ title: '🎯 기초 회화 200' }} />
        <View style={styles.center}>
          <ActivityIndicator color={BRAND_ZH} />
        </View>
      </SafeAreaView>
    );
  }
  if (entries.length === 0) {
    return (
      <SafeAreaView style={styles.safe}>
        <Stack.Screen options={{ title: title }} />
        <View style={styles.center}>
          <RNText style={{ color: colors.inkSecondary, textAlign: 'center', padding: 20 }}>
            {dialect === 'south' ? '보통화 데이터 준비 중' : '데이터 없음'}
          </RNText>
        </View>
      </SafeAreaView>
    );
  }

  const entry = entries[index];
  const vi = entry.vi ?? '';
  const pron = entry.pron ?? '';
  const ko = entry.ko ?? '';
  const keyHint = entry.key ?? '';
  const currentNum = entry.num ?? 0;
  const isFav = favs.has(currentNum);
  const cardHeight = Math.round(Dimensions.get('window').height * 0.38);

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: '🎯 기초 회화 200',
          headerStyle: { backgroundColor: colors.bg },
          headerTintColor: colors.ink,
          headerRight: () => (
            <View style={styles.headerActions}>
              <Pressable onPress={toggleFav} style={styles.headerBtn}>
                <RNText style={{ color: isFav ? colors.sun500 : colors.inkFaint, fontSize: 22 }}>
                  {isFav ? '★' : '☆'}
                </RNText>
              </Pressable>
              <Pressable onPress={togglePlanMode} style={styles.headerBtn}>
                <RNText style={{ color: planMode ? BRAND_ZH : colors.inkFaint, fontSize: 18 }}>
                  🎓
                </RNText>
              </Pressable>
              <Pressable onPress={() => setShowPron((v) => !v)} style={styles.headerBtn}>
                <RNText style={{ color: showPron ? BRAND_ZH : colors.inkFaint, fontSize: 16, fontWeight: 'bold' }}>
                  훈
                </RNText>
              </Pressable>
              <Pressable onPress={() => setAutoPlay((v) => !v)} style={styles.headerBtn}>
                <RNText style={{ color: autoPlay ? BRAND_ZH : colors.inkFaint, fontSize: 18 }}>
                  {autoPlay ? '🔊' : '🔇'}
                </RNText>
              </Pressable>
            </View>
          ),
        }}
      />
      <View style={styles.container}>
        {/* 동그라미 20개 (10x2) */}
        {circleRow(0)}
        <View style={{ height: 4 }} />
        {circleRow(1)}
        <View style={{ height: 8 }} />

        <View style={styles.statsRow}>
          <RNText style={{ fontSize: 12, color: colors.inkFaint }}>
            {index + 1} / {entries.length}
          </RNText>
          <RNText
            style={{
              fontSize: 11,
              color: planMode ? BRAND_ZH : colors.inkFaint,
              fontWeight: planMode ? '700' : 'normal',
            }}
          >
            {planMode ? phaseLabel : showBack ? '중국어 정답' : '뜻 보고 → 탭'}
          </RNText>
        </View>

        {/* progress bar */}
        <View style={[styles.progressBar, { backgroundColor: colors.bgDeep }]}>
          <View
            style={[
              styles.progressFill,
              { width: `${((index + 1) / entries.length) * 100}%`, backgroundColor: BRAND_ZH },
            ]}
          />
        </View>

        {/* 플래시카드 — 40% height, swipe + tap */}
        <View {...panResponder.panHandlers}>
          <Pressable onPress={toggleFlip}>
            <View
              style={[
                styles.flashcard,
                {
                  height: cardHeight,
                  backgroundColor: showBack ? BRAND_ZH + '0F' : '#FFFFFF',
                },
              ]}
            >
              {showBack ? (
                <View style={{ alignItems: 'center' }}>
                  <RNText style={styles.viText} numberOfLines={3} adjustsFontSizeToFit>
                    {vi}
                  </RNText>
                  {showPron && pron.length > 0 && (
                    <RNText style={styles.pronText} numberOfLines={2} adjustsFontSizeToFit>
                      {pron}
                    </RNText>
                  )}
                  {keyHint.length > 0 && (
                    <View style={styles.keyHint}>
                      <RNText style={styles.keyHintText}>{keyHint}</RNText>
                    </View>
                  )}
                </View>
              ) : (
                <RNText style={styles.koText} numberOfLines={3} adjustsFontSizeToFit>
                  {ko}
                </RNText>
              )}
            </View>
          </Pressable>
        </View>

        <View style={{ flex: 1 }} />

        {/* 4 컨트롤 버튼 — cream tone */}
        <View style={styles.controlRow}>
          <ToneButton
            label="이전"
            shadowColor={colors.inkFaint}
            onPress={index > 0 ? prev : undefined}
          />
          <ToneButton
            label={showBack ? '다시 듣기' : '탭하면 답'}
            shadowColor={BRAND_ZH}
            isPrimary
            onPress={showBack ? speakVi : toggleFlip}
          />
          <ToneButton
            label="알아요"
            shadowColor={colors.sage500}
            onPress={onKnown}
          />
          <ToneButton
            label="다음"
            shadowColor={colors.inkFaint}
            onPress={index < entries.length - 1 ? next : undefined}
          />
        </View>
        <View style={{ height: 4 }} />
      </View>
    </SafeAreaView>
  );
}

/// dart: _ToneButton — cream + colored shadow + inner light highlight.
function ToneButton({
  label,
  shadowColor,
  isPrimary = false,
  onPress,
}: {
  label: string;
  shadowColor: string;
  isPrimary?: boolean;
  onPress?: () => void;
}) {
  const disabled = !onPress;
  const iconColor = disabled ? colors.inkFaint : shadowColor;
  const labelColor = disabled ? colors.inkFaint : colors.inkSoft;
  return (
    <Pressable onPress={onPress} disabled={disabled} style={{ alignItems: 'center' }}>
      <View
        style={[
          styles.toneBtn,
          {
            width: isPrimary ? 54 : 46,
            height: isPrimary ? 54 : 46,
            backgroundColor: isPrimary ? '#FFFFFF' : colors.bgSoft,
            shadowColor: disabled ? 'transparent' : shadowColor,
            shadowOffset: { width: 0, height: 3 },
            shadowOpacity: disabled ? 0 : 0.55,
            shadowRadius: disabled ? 0 : 10,
            elevation: disabled ? 0 : 5,
          },
        ]}
      >
        <RNText style={{ fontSize: isPrimary ? 22 : 18, color: iconColor }}>
          {label === '이전'
            ? '◀'
            : label === '다음'
            ? '▶'
            : label === '알아요'
            ? '✓'
            : label === '다시 듣기'
            ? '🔊'
            : '👆'}
        </RNText>
      </View>
      <RNText style={[styles.toneLabel, { color: labelColor }]}>{label}</RNText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.bg },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  container: { flex: 1, paddingHorizontal: 14, paddingTop: 4, paddingBottom: 10 },
  headerActions: { flexDirection: 'row', gap: 4, paddingRight: 8 },
  headerBtn: { padding: 6 },
  circleRow: {
    flexDirection: 'row',
    justifyContent: 'space-evenly',
  },
  circle: {
    width: 24,
    height: 24,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  circleText: {
    fontSize: 9,
    fontWeight: 'bold',
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  progressBar: {
    height: 3,
    borderRadius: 2,
    overflow: 'hidden',
    marginBottom: 10,
  },
  progressFill: { height: '100%' },
  flashcard: {
    width: '100%',
    borderRadius: 20,
    padding: 16,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: colors.bgDeep,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.6,
    shadowRadius: 14,
    elevation: 5,
  },
  koText: {
    fontSize: 22,
    fontWeight: 'bold',
    color: colors.ink,
    textAlign: 'center',
    lineHeight: 30,
  },
  viText: {
    fontSize: 22,
    fontWeight: 'bold',
    color: BRAND_ZH,
    textAlign: 'center',
    lineHeight: 30,
  },
  pronText: {
    fontSize: 14,
    color: colors.inkSoft,
    textAlign: 'center',
    marginTop: 8,
    lineHeight: 18,
  },
  keyHint: {
    marginTop: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: colors.bgSoft,
    borderRadius: 8,
  },
  keyHintText: { fontSize: 10, color: colors.inkSoft, textAlign: 'center', lineHeight: 14 },
  controlRow: {
    flexDirection: 'row',
    justifyContent: 'space-evenly',
  },
  toneBtn: {
    borderRadius: 999,
    alignItems: 'center',
    justifyContent: 'center',
  },
  toneLabel: {
    fontSize: 11,
    fontWeight: '700',
    marginTop: 4,
  },
});
