// 포팅 from vi_main_screen.dart (857 줄) — VI main 화면 정밀 1:1.
//
// dart 원본:
//   * 상단 우측 IconButton 바: 즐겨찾기 / 통계 / 내정보
//   * _VietnameseRegionToggle (북부/남부 pill)
//   * HeroCard (오늘의 목표 + Talky)
//   * WeeklyStrip (7일 요일 활동)
//   * _StreakGoalCard (문법 + 오늘 progress)
//   * 2열 그리드 — 기초회화200/문법/키보드/회화연습/성조/복습 (1.15 aspectRatio)
//   * _SquareMenuCard: 3D pop shadow (colored lip + soft glow)
//   * admin _WideMenuCard (관리자만)
import { useEffect, useState } from 'react';
import { ScrollView, StyleSheet, View, Pressable, Text as RNText } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, Stack } from 'expo-router';
import { Text, colors, spacing } from '@talkverse/ui-core';
import { HeroCard } from '../components/HeroCard';
import { WeeklyStrip } from '../components/WeeklyStrip';
import { UserStats } from '../services/UserStats';
import { FavoriteWords } from '../services/FavoriteWords';

const BRAND_ZH = colors.brand.zh;

type ViRegion = 'north' | 'south';

// dart: squareCards — 2열 그리드 (vi 전용 1·2·5 카드 포함)
const SQUARE_CARDS: Array<{
  icon: string;
  title: string;
  subtitle: string;
  color: string;
  route: string;
}> = [
  { icon: '💬', title: '기초 회화 200', subtitle: '', color: '#B35F00', route: '/conversation_200' },
  { icon: '📖', title: '문법', subtitle: '읽기만 하세요', color: colors.purpleDark, route: '/grammar' },
  { icon: '⌨️', title: '키보드 연습', subtitle: '기초 회화 200 입력 연습', color: colors.successDark, route: '/keyboard' },
  { icon: '💬', title: '회화 연습', subtitle: '상황별 회화', color: colors.purpleDark, route: '/chat_dialogue_list' },
  { icon: '🎵', title: '성조 연습', subtitle: '6 성조 듣고 맞히기', color: '#7B1FA2', route: '/tone_practice' },
  { icon: '🔄', title: '복습', subtitle: '학습 후 노출', color: colors.dangerDark, route: '/review' },
];

export default function ViMainScreen() {
  const router = useRouter();
  // dart: LanguageService.viRegion ValueListenable<String>
  const [region, setRegion] = useState<ViRegion>('south');
  // dart: UserStats() / GrammarProgress — real connect (AsyncStorage)
  const [streak, setStreak] = useState(0);
  const [today, setToday] = useState(0);
  const [goal, setGoal] = useState(20);
  const [favCount, setFavCount] = useState(0);

  useEffect(() => {
    let alive = true;
    const refresh = () => {
      UserStats.getStreak().then((v) => alive && setStreak(v));
      UserStats.getToday().then((v) => alive && setToday(v));
      UserStats.getGoal().then((v) => alive && setGoal(v));
      FavoriteWords.count().then((v) => alive && setFavCount(v));
    };
    refresh();
    UserStats.addListener(refresh);
    FavoriteWords.addListener(refresh);
    return () => {
      alive = false;
      UserStats.removeListener(refresh);
      FavoriteWords.removeListener(refresh);
    };
  }, []);

  const reached = today >= goal;
  const progress = goal > 0 ? Math.min(today / goal, 1) : 0;
  const gDay = 0;
  const gTotal = 8;
  const gFrac = 0;

  return (
    <SafeAreaView edges={['bottom']} style={styles.safe}>
      <Stack.Screen options={{ title: '🇨🇳 중국어 학습' }} />
      <ScrollView contentContainerStyle={styles.container}>
        {/* 상단 우측 아이콘 바 (즐겨찾기 / 통계 / 내정보) — dart: Row + IconButton x3 */}
        <View style={styles.topIconBar}>
          <Pressable style={styles.iconBtn}>
            <RNText style={styles.iconText}>♡</RNText>
            {favCount > 0 && (
              <View style={styles.favBadge}>
                <RNText style={styles.favBadgeText}>{favCount}</RNText>
              </View>
            )}
          </Pressable>
          <Pressable style={styles.iconBtn}>
            <RNText style={styles.iconText}>📊</RNText>
          </Pressable>
          <Pressable style={styles.iconBtn}>
            <RNText style={styles.iconText}>👤</RNText>
          </Pressable>
        </View>

        {/* VI region 토글 — dart: _VietnameseRegionToggle */}
        <View style={styles.regionToggle}>
          <RegionPill
            label="● 베이징 표준"
            selected={region === 'north'}
            onPress={() => setRegion('north')}
          />
          <View style={{ width: 4 }} />
          <RegionPill
            label="▲ 상하이"
            selected={region === 'south'}
            onPress={() => setRegion('south')}
            selectedColor={colors.coral500}
          />
        </View>

        {/* Hero card — dart: HeroCard (gradient + Talky 마스코트 + CTA pill) */}
        <HeroCard
          label="오늘의 목표"
          title="문장 20개"
          daysInactive={0}
          ctaLabel="시작하기"
          onPress={() => router.push('/conversation_200')}
        />

        {/* Weekly strip — dart: WeeklyStrip */}
        <WeeklyStrip dailyGoal={goal} />

        {/* Streak / Goal card — dart: _StreakGoalCard */}
        <View style={styles.streakCard}>
          <View style={styles.streakHead}>
            <RNText style={{ fontSize: 20 }}>{streak > 0 ? '🔥' : '💤'}</RNText>
            <Text size="sm" weight="bold" style={{ marginLeft: 6, flex: 1 }}>
              {streak > 0 ? `${streak}일 연속` : '오늘 시작해요'}
            </Text>
          </View>
          <View style={styles.streakRow}>
            <Text size="xxs" color={colors.inkSecondary}>📖 문법 읽기</Text>
            <Text
              size="xxs"
              weight="bold"
              color={gDay >= gTotal ? colors.successDark : colors.ink}
            >
              {gDay >= gTotal ? `✅ ${gDay}/${gTotal}` : `${gDay} / ${gTotal}`}
            </Text>
          </View>
          <View style={styles.progressBar}>
            <View
              style={[
                styles.progressFill,
                {
                  width: `${gFrac * 100}%`,
                  backgroundColor: gDay >= gTotal ? colors.success : colors.purpleDark,
                },
              ]}
            />
          </View>
          <View style={styles.streakRow}>
            <Text size="xxs" color={colors.inkSecondary}>오늘 목표</Text>
            <Text
              size="xxs"
              weight="bold"
              color={reached ? colors.successDark : colors.ink}
            >
              {reached ? `✅ ${today}/${goal}` : `${today} / ${goal}`}
            </Text>
          </View>
          <View style={styles.progressBar}>
            <View
              style={[
                styles.progressFill,
                {
                  width: `${progress * 100}%`,
                  backgroundColor: reached ? colors.success : BRAND_ZH,
                },
              ]}
            />
          </View>
        </View>

        {/* 2열 그리드 — dart: GridView crossAxisCount: 2, aspectRatio: 1.15 */}
        <View style={styles.grid}>
          {SQUARE_CARDS.map((c) => (
            <SquareMenuCard
              key={c.route}
              icon={c.icon}
              title={c.title}
              subtitle={c.subtitle}
              color={c.color}
              onPress={() => router.push(c.route as any)}
            />
          ))}
        </View>

        {/* 현재 dialect 표시 (region toggle 영향) */}
        <Text
          size="xxs"
          color={colors.inkMuted}
          style={{ textAlign: 'center', marginTop: spacing.md }}
        >
          현재 dialect: {region === 'north' ? '베이징 표준' : '상하이'}
        </Text>
      </ScrollView>
    </SafeAreaView>
  );
}

/// dart: _RegionPill
function RegionPill({
  label,
  selected,
  onPress,
  selectedColor,
}: {
  label: string;
  selected: boolean;
  onPress: () => void;
  selectedColor?: string;
}) {
  const activeColor = selectedColor ?? BRAND_ZH;
  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.pill,
        selected && { backgroundColor: activeColor },
      ]}
    >
      <RNText
        style={{
          fontSize: 12,
          fontWeight: selected ? 'bold' : 'normal',
          color: selected ? '#FFFFFF' : colors.inkSecondary,
        }}
      >
        {label}
      </RNText>
    </Pressable>
  );
}

/// dart: _SquareMenuCard — 3D pop shadow (colored lip + soft glow)
function SquareMenuCard({
  icon,
  title,
  subtitle,
  color,
  onPress,
}: {
  icon: string;
  title: string;
  subtitle: string;
  color: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.squareCard,
        {
          shadowColor: color,
        },
      ]}
    >
      <RNText style={{ fontSize: 38, color }}>{icon}</RNText>
      <RNText
        style={{
          fontSize: 15,
          fontWeight: '900',
          color,
          textAlign: 'center',
          marginTop: 8,
        }}
      >
        {title}
      </RNText>
      {subtitle.length > 0 && (
        <RNText
          style={{
            fontSize: 11,
            fontWeight: '600',
            color: colors.inkFaint,
            textAlign: 'center',
            marginTop: 2,
          }}
          numberOfLines={2}
        >
          {subtitle}
        </RNText>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  container: { padding: 20, gap: 12 },
  topIconBar: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: spacing.md,
  },
  iconBtn: { padding: 6 },
  iconText: { fontSize: 20, color: colors.inkSecondary },
  favBadge: {
    position: 'absolute',
    right: -4,
    top: -2,
    backgroundColor: colors.danger,
    paddingHorizontal: 4,
    borderRadius: 8,
  },
  favBadgeText: { color: '#FFFFFF', fontSize: 10, fontWeight: 'bold' },
  regionToggle: {
    flexDirection: 'row',
    justifyContent: 'center',
    paddingHorizontal: 4,
    paddingVertical: 4,
    backgroundColor: colors.surface,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: colors.cardBorder,
    alignSelf: 'center',
  },
  pill: {
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 16,
  },
  streakCard: {
    padding: 14,
    backgroundColor: colors.surface,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.cardBorder,
    gap: 3,
  },
  streakHead: { flexDirection: 'row', alignItems: 'center', marginBottom: 4 },
  streakRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 4,
  },
  progressBar: {
    height: 6,
    borderRadius: 4,
    backgroundColor: colors.surface,
    overflow: 'hidden',
    marginTop: 3,
  },
  progressFill: { height: '100%' },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
    marginTop: spacing.md,
  },
  squareCard: {
    backgroundColor: '#FFFFFF',
    width: '47%',
    aspectRatio: 1.15,
    padding: 14,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    // dart: boxShadow 2단 (colored lip + soft glow)
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.45,
    shadowRadius: 14,
    elevation: 5,
  },
});
