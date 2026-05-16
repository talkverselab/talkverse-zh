// 포팅 from chat_dialogue_memorize_screen.dart (311 줄) — dialogue 문장 외우기 플래시카드.
//
// dart 원본:
//   * props: ChatDialogue
//   * turn 단위 플래시카드 (앞=ko, 뒤=vi+pron+key)
//   * 호칭 placeholder 자동 치환
//   * 3 컨트롤: 이전 / 탭하면 답 / 다음(or 완료)
//   * 카드 height = 42% screen
import { useState, useRef } from 'react';
import {
  StyleSheet, View, Pressable, Text as RNText,
  Dimensions, PanResponder, ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { colors } from '@talkverse/ui-core';
import { AddressPreferenceService } from '../services/AddressPreferenceService';
import dialoguesSouth from '../assets/chat_dialogues_south.json';
import dialoguesNorth from '../assets/chat_dialogues_north.json';

const BRAND_ZH = colors.brand.zh;

type ChatTurn = { num: number; speaker: string; vi: string; pron?: string; ko: string; key?: string };

function loadDialogue(dialogueId: number, dialect: 'north' | 'south') {
  const raw: any = dialect === 'south' ? dialoguesSouth : dialoguesNorth;
  const arr = (raw?.dialogues ?? []) as any[];
  const idx = arr.findIndex((d) => {
    const id = typeof d.dialogue_id === 'string'
      ? parseInt(d.dialogue_id.replace(/[^0-9]/g, ''), 10)
      : (d.id ?? -1);
    return id === dialogueId;
  });
  if (idx < 0) return null;
  const d = arr[idx];
  const turns: ChatTurn[] = (d.turns ?? []).map((t: any) => ({
    num: t.num, speaker: t.speaker,
    vi: t.vi ?? '', pron: t.pron ?? '', ko: t.ko ?? '', key: t.key ?? '',
  }));
  return { id: dialogueId, title: d.title ?? `대화 ${dialogueId}`, turns };
}

export default function ChatDialogueMemorizeScreen() {
  const params = useLocalSearchParams<{ dialogueId?: string }>();
  const router = useRouter();
  const dialogueId = parseInt(params.dialogueId ?? '1', 10);
  const dialect: 'north' | 'south' = 'south';

  const dialogue = loadDialogue(dialogueId, dialect);
  const [index, setIndex] = useState(0);
  const [showBack, setShowBack] = useState(false);

  if (!dialogue) {
    return (
      <SafeAreaView style={styles.safe}>
        <Stack.Screen options={{ title: '문장 외우기' }} />
        <View style={styles.center}><RNText style={{ color: colors.inkSoft }}>대화를 찾을 수 없습니다</RNText></View>
      </SafeAreaView>
    );
  }

  const sub = (s: string) => AddressPreferenceService.substitute(s);
  const flip = () => setShowBack((v) => !v);

  const goNext = () => {
    if (index < dialogue.turns.length - 1) {
      setIndex(index + 1);
      setShowBack(false);
    } else {
      router.back();
    }
  };
  const goPrev = () => {
    if (index > 0) {
      setIndex(index - 1);
      setShowBack(false);
    }
  };

  const panResponder = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_, g) =>
        Math.abs(g.dx) > 20 && Math.abs(g.dy) < 40,
      onPanResponderRelease: (_, g) => {
        if (g.vx > 0.5 || g.dx > 80) goPrev();
        else if (g.vx < -0.5 || g.dx < -80) goNext();
      },
    })
  ).current;

  const t = dialogue.turns[index];
  const cardHeight = Math.round(Dimensions.get('window').height * 0.42);

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: `${dialogue.title} — 문장 외우기`,
          headerStyle: { backgroundColor: colors.bg },
          headerTintColor: colors.ink,
        }}
      />
      <View style={styles.container}>
        <View style={styles.headRow}>
          <RNText style={{ fontSize: 12, color: colors.inkFaint }}>
            {index + 1} / {dialogue.turns.length}
          </RNText>
          <RNText
            style={{
              fontSize: 11,
              fontWeight: '700',
              color: t.speaker === 'anh' ? BRAND_ZH : colors.coral500,
            }}
          >
            {t.speaker === 'anh' ? '🧔 anh' : '👩 em'} 차례
          </RNText>
        </View>
        <View style={[styles.progressBar, { backgroundColor: colors.bgDeep }]}>
          <View
            style={[
              styles.progressFill,
              {
                width: `${((index + 1) / dialogue.turns.length) * 100}%`,
                backgroundColor: BRAND_ZH,
              },
            ]}
          />
        </View>
        <View style={{ height: 12 }} />
        <View {...panResponder.panHandlers}>
          <Pressable onPress={flip}>
            <View
              style={[
                styles.card,
                {
                  height: cardHeight,
                  backgroundColor: showBack ? BRAND_ZH + '0F' : '#FFFFFF',
                },
              ]}
            >
              <ScrollView contentContainerStyle={styles.cardInner}>
                {showBack ? (
                  <>
                    <RNText style={styles.vi} numberOfLines={3} adjustsFontSizeToFit>
                      {sub(t.vi)}
                    </RNText>
                    {(t.pron ?? '').length > 0 && (
                      <RNText style={styles.pron}>{sub(t.pron!)}</RNText>
                    )}
                    {(t.key ?? '').length > 0 && (
                      <View style={styles.keyHint}>
                        <RNText style={styles.keyHintText}>{t.key}</RNText>
                      </View>
                    )}
                  </>
                ) : (
                  <RNText style={styles.ko} numberOfLines={3} adjustsFontSizeToFit>
                    {sub(t.ko)}
                  </RNText>
                )}
              </ScrollView>
            </View>
          </Pressable>
        </View>
        <View style={{ flex: 1 }} />
        <View style={styles.controlRow}>
          <CtrlButton icon="◀" label="이전" color={colors.inkFaint} onPress={index > 0 ? goPrev : undefined} />
          <CtrlButton icon="👆" label="탭하면 답" color={BRAND_ZH} primary onPress={flip} />
          <CtrlButton
            icon={index < dialogue.turns.length - 1 ? '▶' : '✓'}
            label={index < dialogue.turns.length - 1 ? '다음' : '완료'}
            color={colors.sage500}
            onPress={goNext}
          />
        </View>
      </View>
    </SafeAreaView>
  );
}

function CtrlButton({
  icon, label, color, primary = false, onPress,
}: {
  icon: string; label: string; color: string; primary?: boolean; onPress?: () => void;
}) {
  const disabled = !onPress;
  return (
    <Pressable onPress={onPress} disabled={disabled} style={{ alignItems: 'center' }}>
      <View
        style={[
          styles.ctrlBtn,
          {
            width: primary ? 56 : 48,
            height: primary ? 56 : 48,
            backgroundColor: primary ? '#FFFFFF' : colors.bgSoft,
            shadowColor: disabled ? 'transparent' : color,
            shadowOffset: { width: 0, height: 3 },
            shadowOpacity: disabled ? 0 : 0.55,
            shadowRadius: 10,
            elevation: disabled ? 0 : 5,
          },
        ]}
      >
        <RNText style={{ fontSize: primary ? 22 : 18, color: disabled ? colors.inkFaint : color }}>
          {icon}
        </RNText>
      </View>
      <RNText
        style={{
          fontSize: 11,
          fontWeight: '700',
          color: disabled ? colors.inkFaint : colors.inkSoft,
          marginTop: 4,
        }}
      >
        {label}
      </RNText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.bg },
  container: { flex: 1, paddingHorizontal: 14, paddingTop: 8, paddingBottom: 14 },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  headRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  progressBar: { height: 3, borderRadius: 2, overflow: 'hidden', marginTop: 6 },
  progressFill: { height: '100%' },
  card: {
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
  cardInner: { flexGrow: 1, alignItems: 'center', justifyContent: 'center' },
  ko: { fontSize: 22, fontWeight: 'bold', color: colors.ink, textAlign: 'center', lineHeight: 30 },
  vi: { fontSize: 22, fontWeight: 'bold', color: BRAND_ZH, textAlign: 'center', lineHeight: 30 },
  pron: { fontSize: 14, color: colors.inkSoft, textAlign: 'center', marginTop: 10, lineHeight: 18 },
  keyHint: { marginTop: 10, paddingHorizontal: 10, paddingVertical: 6, backgroundColor: colors.bgSoft, borderRadius: 8 },
  keyHintText: { fontSize: 10, color: colors.inkFaint, textAlign: 'center', lineHeight: 14 },
  controlRow: { flexDirection: 'row', justifyContent: 'space-evenly' },
  ctrlBtn: { borderRadius: 999, alignItems: 'center', justifyContent: 'center' },
});
