// 포팅 from adverbs_200_screen.dart (339 줄) — 부사·표현 200 (MN, ZH 룸 reference).
//
// dart 원본:
//   * data.json (200 entry: mn, pron(한글), ko, key) + audio_manifest.json
//   * 한국어 (앞) → 탭 → 본토 + pron + key (뒤) + Azure mn-MN TTS 자동재생
//   * 컨트롤 3개: 이전 / 듣기(primary) / 다음
//
// VI 룸은 실제 adverbs_mn 데이터 없으므로 placeholder + UI 구조 보존.
import { useState, useRef } from 'react';
import {
  StyleSheet, View, Pressable, Text as RNText,
  PanResponder, ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack } from 'expo-router';
import { colors } from '@talkverse/ui-core';

const BRAND_ZH = colors.brand.zh;

const SAMPLE: Array<{ num: number; mn: string; pron: string; ko: string; key: string }> = [
  { num: 1, mn: '(데이터 준비 중)', pron: '', ko: '부사·표현 200 — 곧 출시', key: 'ZH 룸 placeholder' },
];

export default function Adverbs200Screen() {
  const entries = SAMPLE;
  const [index, setIndex] = useState(0);
  const [showBack, setShowBack] = useState(false);
  const [autoPlay, setAutoPlay] = useState(true);

  const speak = () => {
    // eslint-disable-next-line no-console
    console.log(`[Adverbs] play ${entries[index]?.mn}`);
  };

  const next = () => {
    if (index < entries.length - 1) {
      setIndex(index + 1);
      setShowBack(false);
    }
  };
  const prev = () => {
    if (index > 0) {
      setIndex(index - 1);
      setShowBack(false);
    }
  };
  const flip = () => {
    setShowBack((b) => {
      const v = !b;
      if (v && autoPlay) setTimeout(speak, 200);
      return v;
    });
  };

  const panResponder = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_, g) => Math.abs(g.dx) > 20 && Math.abs(g.dy) < 40,
      onPanResponderRelease: (_, g) => {
        if (g.vx > 0.5 || g.dx > 80) prev();
        else if (g.vx < -0.5 || g.dx < -80) next();
      },
    })
  ).current;

  const e = entries[index];

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: '🎯 부사·표현 200',
          headerStyle: { backgroundColor: colors.background },
          headerTintColor: colors.ink,
          headerRight: () => (
            <Pressable onPress={() => setAutoPlay((v) => !v)} style={{ padding: 8 }}>
              <RNText style={{ color: autoPlay ? BRAND_ZH : colors.inkFaint, fontSize: 18 }}>
                {autoPlay ? '🔊' : '🔇'}
              </RNText>
            </Pressable>
          ),
        }}
      />
      <View style={styles.container}>
        <View style={styles.headRow}>
          <RNText style={{ fontSize: 14, color: colors.inkSecondary }}>
            {index + 1} / {entries.length}
          </RNText>
          <RNText style={{ fontSize: 12, color: colors.inkSecondary }}>
            {showBack ? '본토어 정답' : '뜻 보고 → 탭'}
          </RNText>
        </View>
        <View style={[styles.progressBar, { backgroundColor: '#E0E0E0' }]}>
          <View style={[styles.progressFill, { width: `${((index + 1) / entries.length) * 100}%`, backgroundColor: BRAND_ZH }]} />
        </View>
        <View style={{ height: 24 }} />
        <View {...panResponder.panHandlers} style={{ flex: 1 }}>
          <Pressable onPress={flip} style={{ flex: 1 }}>
            <View
              style={[
                styles.card,
                { backgroundColor: showBack ? BRAND_ZH + '0F' : '#FFFFFF' },
              ]}
            >
              <ScrollView contentContainerStyle={styles.cardInner}>
                {showBack ? (
                  <>
                    <RNText style={styles.viBig}>{e.mn}</RNText>
                    {e.pron.length > 0 && <RNText style={styles.pron}>{e.pron}</RNText>}
                    {e.key.length > 0 && <RNText style={styles.keyText}>{e.key}</RNText>}
                  </>
                ) : (
                  <RNText style={styles.ko}>{e.ko}</RNText>
                )}
              </ScrollView>
            </View>
          </Pressable>
        </View>
        <View style={{ height: 16 }} />
        <View style={styles.controls}>
          <CtrlButton label="이전" icon="◀" onPress={index > 0 ? prev : undefined} />
          <CtrlButton label="본토어 듣기" icon="🔊" primary onPress={speak} />
          <CtrlButton label="다음" icon="▶" onPress={index < entries.length - 1 ? next : undefined} />
        </View>
      </View>
    </SafeAreaView>
  );
}

function CtrlButton({
  label, icon, primary = false, onPress,
}: { label: string; icon: string; primary?: boolean; onPress?: () => void }) {
  const disabled = !onPress;
  const color = disabled ? colors.inkFaint : primary ? BRAND_ZH : colors.ink;
  return (
    <View style={{ alignItems: 'center' }}>
      <Pressable
        onPress={onPress}
        disabled={disabled}
        style={[
          styles.iconBtn,
          primary && !disabled && { backgroundColor: BRAND_ZH + '1A' },
        ]}
      >
        <RNText style={{ fontSize: 28, color }}>{icon}</RNText>
      </Pressable>
      <RNText style={{ fontSize: 11, color, marginTop: 2 }}>{label}</RNText>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  container: { flex: 1, padding: 20 },
  headRow: { flexDirection: 'row', justifyContent: 'space-between' },
  progressBar: { height: 4, marginTop: 12, borderRadius: 2, overflow: 'hidden' },
  progressFill: { height: '100%' },
  card: {
    flex: 1,
    borderRadius: 20,
    padding: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 12,
    elevation: 4,
  },
  cardInner: { flexGrow: 1, alignItems: 'center', justifyContent: 'center' },
  ko: { fontSize: 22, fontWeight: 'bold', color: colors.ink, textAlign: 'center', lineHeight: 32 },
  viBig: { fontSize: 22, fontWeight: 'bold', color: BRAND_ZH, textAlign: 'center', lineHeight: 32 },
  pron: { fontSize: 16, color: colors.inkSecondary, textAlign: 'center', marginTop: 12 },
  keyText: { fontSize: 13, fontStyle: 'italic', color: colors.inkSecondary, textAlign: 'center', marginTop: 16 },
  controls: { flexDirection: 'row', justifyContent: 'space-evenly' },
  iconBtn: {
    padding: 12,
    borderRadius: 50,
  },
});
