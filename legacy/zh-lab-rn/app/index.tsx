// 6-card 그리드 홈 (사용자 결정 2026-05-17 — Hero/Weekly/Streak 제거, pure grid).
//
// 이전: vi_journey_screen.dart 5 카드 ListView + 상단 main hub 진입 버튼
// 현재: 6 카드 2-열 그리드만 (필수회화 200·문법·키보드·회화 연습·성조·복습)
import { ScrollView, StyleSheet, View, Pressable, Text as RNText } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, Stack } from 'expo-router';
import { Text, colors, spacing } from '@talkverse/ui-core';

const BRAND_ZH = colors.brand.zh;

const CARDS: Array<{
  icon: string;
  title: string;
  subtitle: string;
  color: string;
  route: string;
}> = [
  { icon: '💬', title: '필수 회화 200', subtitle: '5 ep × 40 turn', color: BRAND_ZH, route: '/conversation_200' },
  { icon: '📖', title: '문법', subtitle: '8 Day 코스', color: colors.purpleDark, route: '/grammar' },
  { icon: '⌨️', title: '키보드 연습', subtitle: '필수 회화 입력', color: colors.successDark, route: '/keyboard' },
  { icon: '💬', title: '회화 연습', subtitle: '상황별 회화', color: '#7B1FA2', route: '/chat_dialogue_list' },
  { icon: '🎵', title: '성조 연습', subtitle: '4성 + 경성', color: '#B8860B', route: '/tone_practice' },
  { icon: '🔄', title: '복습', subtitle: '학습 후 노출', color: colors.dangerDark, route: '/review' },
];

export default function Home() {
  const router = useRouter();
  return (
    <SafeAreaView edges={['bottom']} style={styles.safe}>
      <Stack.Screen
        options={{
          title: '중국어유니버스',
          headerStyle: { backgroundColor: BRAND_ZH },
          headerTintColor: '#FFFFFF',
        }}
      />
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.grid}>
          {CARDS.map((c) => (
            <Pressable
              key={c.route}
              style={[styles.card, {
                shadowColor: c.color,
              }]}
              onPress={() => router.push(c.route as any)}
            >
              <RNText style={[styles.icon, { color: c.color }]}>{c.icon}</RNText>
              <Text size="md" weight="bold" style={{ color: c.color, textAlign: 'center' }}>
                {c.title}
              </Text>
              {c.subtitle ? (
                <Text size="xs" color={colors.inkFaint} style={{ textAlign: 'center', marginTop: 2 }}>
                  {c.subtitle}
                </Text>
              ) : null}
            </Pressable>
          ))}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  container: { padding: 16, paddingBottom: 32 },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    gap: 12,
  },
  card: {
    width: '48%',
    aspectRatio: 1.05,
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.22,
    shadowRadius: 12,
    elevation: 4,
  },
  icon: {
    fontSize: 38,
    marginBottom: 8,
  },
});
