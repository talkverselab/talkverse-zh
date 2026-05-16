// 포팅 from chat_dialogue_list_screen.dart (590 줄) — 정밀 1:1.
//
// dart 원본:
//   * ChatDialogueListScreen — list view, 호칭 토글 (anh/em)
//   * ChatDialogueDetailScreen — 카톡 버블 (좌측=B(상대) 우측=A(나))
//   * AddressPreferenceService.substitute — {ME}/{YOU} placeholder 치환
//   * 자동 mp3 (vi/{dialect}_{gender}/chat_NN_NN.mp3)
//   * bottomNavigationBar: "문장 외우기" 버튼 → ChatDialogueMemorizeScreen
import { useEffect, useState, useCallback } from 'react';
import {
  ScrollView, StyleSheet, View, Pressable, ActivityIndicator,
  Text as RNText, Dimensions, FlatList,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack, useRouter } from 'expo-router';
import { colors } from '@talkverse/ui-core';
import { AddressPreferenceService } from '../services/AddressPreferenceService';
import { AudioPlayer } from '../services/AudioPlayer';
import dialoguesSouth from '../assets/chat_dialogues_south.json';
import dialoguesNorth from '../assets/chat_dialogues_north.json';

const BRAND_ZH = colors.brand.zh;
const screenWidth = Dimensions.get('window').width;

// dart: ChatDialogue / ChatTurn
type ChatTurn = {
  num: number;
  speaker: string; // 'anh' or 'em' (raw json) — A=나 / B=상대 매핑
  vi: string;
  pron?: string;
  ko: string;
  key?: string;
};
type ChatDialogue = {
  id: number;
  dialogue_id?: string;
  title: string;
  tag?: 'scenario' | 'friend' | string;
  tone?: string;
  scenario?: string;
  header?: string;
  turns: ChatTurn[];
};

type ViDialect = 'north' | 'south';

function normalizeDialogues(json: any): ChatDialogue[] {
  const arr = (json?.dialogues ?? []) as any[];
  return arr.map((d, i) => {
    const id = typeof d.dialogue_id === 'string'
      ? parseInt(d.dialogue_id.replace(/[^0-9]/g, ''), 10) || (i + 1)
      : (d.id ?? i + 1);
    const turns = (d.turns ?? []).map((t: any) => ({
      num: t.num,
      speaker: t.speaker,
      vi: t.vi ?? '',
      pron: t.pron ?? '',
      ko: t.ko ?? '',
      key: t.key ?? '',
    })) as ChatTurn[];
    const header = d.scenario ?? d.header ?? '';
    const tag = d.tone === '긍정' ? 'friend' : 'scenario';
    return {
      id,
      dialogue_id: d.dialogue_id,
      title: d.title ?? `대화 ${id}`,
      tag,
      tone: d.tone,
      scenario: d.scenario,
      header,
      turns,
    };
  });
}

export default function ChatDialogueListScreen() {
  const router = useRouter();
  const [dialect] = useState<ViDialect>('south');
  const [dialogues, setDialogues] = useState<ChatDialogue[]>([]);
  const [loading, setLoading] = useState(true);
  const [meRole, setMeRole] = useState<'anh' | 'em'>(
    AddressPreferenceService.meRole
  );
  const [selected, setSelected] = useState<ChatDialogue | null>(null);

  useEffect(() => {
    setLoading(true);
    const raw = dialect === 'south' ? dialoguesSouth : dialoguesNorth;
    setDialogues(normalizeDialogues(raw));
    setLoading(false);
  }, [dialect]);

  useEffect(() => {
    const listener = () => setMeRole(AddressPreferenceService.meRole);
    AddressPreferenceService.addListener(listener);
    return () => AddressPreferenceService.removeListener(listener);
  }, []);

  if (selected) {
    return <ChatDialogueDetailScreen
      dialogue={selected}
      dialect={dialect}
      meRole={meRole}
      onBack={() => setSelected(null)}
      router={router}
    />;
  }

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: '💬 채팅 (Level 2)',
          headerStyle: { backgroundColor: colors.bg },
          headerTintColor: colors.ink,
          headerRight: () => (
            <Pressable
              onPress={() => {
                const next = meRole === 'anh' ? 'em' : 'anh';
                AddressPreferenceService.setMeRole(next);
              }}
              style={styles.meTogglePill}
            >
              <RNText style={{ color: BRAND_ZH, fontSize: 12, fontWeight: 'bold' }}>
                {meRole === 'anh' ? '🧔 내가 anh' : '👩 내가 em'}
              </RNText>
            </Pressable>
          ),
        }}
      />
      {loading ? (
        <View style={styles.center}><ActivityIndicator color={BRAND_ZH} /></View>
      ) : dialogues.length === 0 ? (
        <View style={styles.center}>
          <RNText style={{ color: colors.inkSecondary }}>
            {dialect === 'south' ? '보통화 채팅 데이터 준비 중' : '채팅 데이터 없음'}
          </RNText>
        </View>
      ) : (
        <FlatList
          data={dialogues}
          keyExtractor={(d) => String(d.id)}
          contentContainerStyle={{ padding: 14 }}
          renderItem={({ item: d }) => {
            const isScenario = d.tag === 'scenario';
            const color = isScenario ? colors.coral500 : colors.sage500;
            return (
              <Pressable
                onPress={() => setSelected(d)}
                style={[styles.dialogueCard, { shadowColor: color }]}
              >
                <View style={[styles.circleBadge, { backgroundColor: color + '26' }]}>
                  <RNText style={{ fontSize: 14, fontWeight: '900', color }}>{d.id}</RNText>
                </View>
                <View style={{ flex: 1, marginLeft: 12 }}>
                  <RNText style={{ fontSize: 14, fontWeight: '800', color: colors.ink }}>{d.title}</RNText>
                  {d.header ? (
                    <RNText
                      style={{ fontSize: 11, color: colors.inkSoft, marginTop: 2 }}
                      numberOfLines={1}
                    >
                      {d.header}
                    </RNText>
                  ) : null}
                </View>
                <View style={[styles.tagBox, { backgroundColor: color + '1F' }]}>
                  <RNText style={{ fontSize: 10, fontWeight: '800', color }}>
                    {isScenario ? '시나리오' : '친구'}
                  </RNText>
                </View>
              </Pressable>
            );
          }}
        />
      )}
    </SafeAreaView>
  );
}

// === Detail screen — 카톡 버블 ===
function ChatDialogueDetailScreen({
  dialogue,
  dialect,
  meRole,
  onBack,
  router,
}: {
  dialogue: ChatDialogue;
  dialect: ViDialect;
  meRole: 'anh' | 'em';
  onBack: () => void;
  router: ReturnType<typeof useRouter>;
}) {
  const [showPron, setShowPron] = useState(true);
  const [showKo, setShowKo] = useState(true);
  const [playingTurn, setPlayingTurn] = useState<number | null>(null);

  const displayVi = (raw: string) => AddressPreferenceService.substitute(raw);

  const playTurn = useCallback((t: ChatTurn) => {
    const gender = t.speaker === 'anh' ? 'male' : 'female';
    const idStr = String(dialogue.id).padStart(2, '0');
    const turnStr = String(t.num).padStart(2, '0');
    const voiceDir = `${dialect}_${gender}`;
    const key = `chat_${idStr}_${turnStr}`;
    setPlayingTurn(t.num);
    AudioPlayer.play(voiceDir, key).catch(() => {});
    setTimeout(() => setPlayingTurn(null), 1500);
  }, [dialogue.id, dialect]);

  const isMine = (speaker: string) => speaker === meRole;

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: dialogue.title,
          headerStyle: { backgroundColor: colors.bg },
          headerTintColor: colors.ink,
          headerLeft: () => (
            <Pressable onPress={onBack} style={{ padding: 8 }}>
              <RNText style={{ fontSize: 22, color: colors.ink }}>‹</RNText>
            </Pressable>
          ),
          headerRight: () => (
            <View style={{ flexDirection: 'row', gap: 6, paddingRight: 8 }}>
              <Pressable onPress={() => setShowPron((v) => !v)} style={{ padding: 6 }}>
                <RNText style={{ color: showPron ? BRAND_ZH : colors.inkFaint, fontWeight: 'bold' }}>훈</RNText>
              </Pressable>
              <Pressable onPress={() => setShowKo((v) => !v)} style={{ padding: 6 }}>
                <RNText style={{ color: showKo ? BRAND_ZH : colors.inkFaint, fontWeight: 'bold' }}>한</RNText>
              </Pressable>
            </View>
          ),
        }}
      />
      {dialogue.header && dialogue.header.length > 0 && (
        <View style={styles.headerBox}>
          <RNText style={{ fontSize: 11, color: colors.inkSoft }}>{dialogue.header}</RNText>
        </View>
      )}
      <ScrollView contentContainerStyle={{ paddingHorizontal: 14, paddingTop: 6, paddingBottom: 100 }}>
        {dialogue.turns.map((t) => {
          const mine = isMine(t.speaker);
          const isPlay = playingTurn === t.num;
          return (
            <View
              key={t.num}
              style={[styles.turnRow, { justifyContent: mine ? 'flex-end' : 'flex-start' }]}
            >
              {!mine && <ChatAvatar speaker="B" />}
              {!mine && <View style={{ width: 6 }} />}
              <Pressable
                onPress={() => playTurn(t)}
                style={[
                  styles.bubble,
                  {
                    backgroundColor: mine ? BRAND_ZH : '#FFFFFF',
                    borderBottomLeftRadius: mine ? 16 : 4,
                    borderBottomRightRadius: mine ? 4 : 16,
                    maxWidth: screenWidth * 0.72,
                  },
                ]}
              >
                <View style={{ flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap' }}>
                  {isPlay && (
                    <RNText style={{ fontSize: 12, color: mine ? '#FFFFFF' : BRAND_ZH, marginRight: 6 }}>
                      🔊
                    </RNText>
                  )}
                  <RNText
                    style={{
                      fontSize: 14, fontWeight: '600',
                      color: mine ? '#FFFFFF' : colors.ink,
                      lineHeight: 20, flexShrink: 1,
                    }}
                  >
                    {displayVi(t.vi)}
                  </RNText>
                </View>
                {showPron && (t.pron ?? '').length > 0 && (
                  <RNText
                    style={{
                      fontSize: 11, marginTop: 4, lineHeight: 14,
                      color: mine ? 'rgba(255,255,255,0.8)' : colors.inkFaint,
                    }}
                  >
                    {displayVi(t.pron!)}
                  </RNText>
                )}
                {showKo && (t.ko ?? '').length > 0 && (
                  <RNText
                    style={{
                      fontSize: 12, marginTop: 4, lineHeight: 16,
                      color: mine ? 'rgba(255,255,255,0.92)' : colors.inkSoft,
                    }}
                  >
                    {displayVi(t.ko)}
                  </RNText>
                )}
                {(t.key ?? '').length > 0 && (
                  <View
                    style={{
                      marginTop: 5,
                      paddingHorizontal: 6,
                      paddingVertical: 3,
                      borderRadius: 6,
                      backgroundColor: mine ? 'rgba(255,255,255,0.18)' : colors.bgSoft,
                      alignSelf: 'flex-start',
                    }}
                  >
                    <RNText
                      style={{
                        fontSize: 9, lineHeight: 12,
                        color: mine ? 'rgba(255,255,255,0.85)' : colors.inkFaint,
                      }}
                    >
                      {t.key}
                    </RNText>
                  </View>
                )}
              </Pressable>
              {mine && <View style={{ width: 6 }} />}
              {mine && <ChatAvatar speaker="A" />}
            </View>
          );
        })}
      </ScrollView>
      <View style={styles.memorizeBar}>
        <Pressable
          style={styles.memorizeButton}
          onPress={() => {
            router.push({
              pathname: '/chat_dialogue_memorize',
              params: { dialogueId: String(dialogue.id) },
            } as any);
          }}
        >
          <RNText style={{ color: '#FFFFFF', fontSize: 14, fontWeight: 'bold' }}>
            🎓 문장 외우기 ({dialogue.turns.length}문장)
          </RNText>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}

function ChatAvatar({ speaker }: { speaker: 'A' | 'B' }) {
  const color = speaker === 'A' ? BRAND_ZH : colors.coral500;
  return (
    <View style={[styles.avatar, { backgroundColor: color + '26' }]}>
      <RNText style={{ fontSize: 11, fontWeight: '900', color }}>
        {speaker === 'A' ? '나' : '상'}
      </RNText>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.bg },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 20 },
  meTogglePill: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.cardBorder,
    marginRight: 12,
  },
  dialogueCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 14,
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    marginBottom: 10,
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.4,
    shadowRadius: 10,
    elevation: 3,
  },
  circleBadge: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tagBox: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 10,
  },
  headerBox: {
    marginHorizontal: 14,
    marginTop: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: colors.bgSoft,
    borderRadius: 10,
  },
  turnRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    marginBottom: 12,
  },
  bubble: {
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 1,
  },
  avatar: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  memorizeBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: 14,
    backgroundColor: colors.bg,
  },
  memorizeButton: {
    backgroundColor: BRAND_ZH,
    paddingVertical: 14,
    borderRadius: 14,
    alignItems: 'center',
  },
});
