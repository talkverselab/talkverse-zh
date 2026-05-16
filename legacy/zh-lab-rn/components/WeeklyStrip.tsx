// 포팅 from widgets/weekly_strip.dart — 7일 주간 활동 strip.
// dart: 완료(sage) / 오늘 미완(peach) / 미래·과거 미완(bgDeep)
import { View, Text as RNText, StyleSheet } from 'react-native';
import { colors } from '@talkverse/ui-core';

export interface WeeklyStripProps {
  // dart: UserStats().last7Days() — { date, count } x 7
  last7?: Array<{ date: Date; count: number }>;
  dailyGoal?: number;
}

const KO_WEEKDAYS = ['월', '화', '수', '목', '금', '토', '일'];

function defaultLast7(): Array<{ date: Date; count: number }> {
  const today = new Date();
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(today);
    d.setDate(d.getDate() - (6 - i));
    return { date: d, count: 0 };
  });
}

export function WeeklyStrip({ last7, dailyGoal = 20 }: WeeklyStripProps) {
  const data = last7 ?? defaultLast7();
  const today = new Date();
  const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const completed = data.filter((d) => d.count >= dailyGoal).length;

  return (
    <View>
      <View style={styles.headerRow}>
        <RNText style={styles.headerLabel}>이번 주</RNText>
        <RNText style={styles.headerCount}>{completed} / 7 완료</RNText>
      </View>
      <View style={styles.cellRow}>
        {data.map((d, i) => {
          const isToday =
            d.date.getFullYear() === today.getFullYear() &&
            d.date.getMonth() === today.getMonth() &&
            d.date.getDate() === today.getDate();
          const reached = d.count >= dailyGoal;
          const isPast = d.date.getTime() < todayStart.getTime();

          let bg: string, fg: string, iconLabel: string;
          let shadowColor: string | undefined;
          let shadowOffset: { width: number; height: number } | undefined;
          let shadowOpacity: number | undefined;
          let shadowRadius: number | undefined;
          let borderColor: string | undefined;

          if (reached) {
            bg = colors.sage200;
            fg = colors.sage700;
            shadowColor = colors.sage400;
            shadowOffset = { width: 0, height: 3 };
            shadowOpacity = 0.45;
            shadowRadius = 8;
            iconLabel = '✓';
          } else if (isToday) {
            bg = colors.peach300;
            fg = colors.peach600;
            shadowColor = colors.peach400;
            shadowOffset = { width: 0, height: 3 };
            shadowOpacity = 0.45;
            shadowRadius = 10;
            iconLabel = '✓';
          } else {
            bg = colors.bg;
            fg = colors.inkFaint;
            borderColor = colors.bgDeep;
            iconLabel = isPast ? '–' : '🔒';
          }

          const weekdayIdx = (d.date.getDay() + 6) % 7; // dart: weekday 1-7 (Mon=1)
          return (
            <View
              key={i}
              style={[
                styles.cell,
                {
                  backgroundColor: bg,
                  shadowColor,
                  shadowOffset,
                  shadowOpacity,
                  shadowRadius,
                  borderColor,
                  borderWidth: borderColor ? 1 : 0,
                  marginLeft: i === 0 ? 0 : 4,
                  marginRight: i === 6 ? 0 : 4,
                  elevation: reached || isToday ? 3 : 0,
                },
              ]}
            >
              <RNText style={[styles.weekday, { color: fg, opacity: 0.7 }]}>
                {KO_WEEKDAYS[weekdayIdx]}
              </RNText>
              <RNText style={[styles.icon, { color: fg }]}>{iconLabel}</RNText>
            </View>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  headerRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'baseline' },
  headerLabel: { fontSize: 13, fontWeight: '800', color: colors.ink },
  headerCount: { fontSize: 11, fontWeight: '700', color: colors.inkFaint },
  cellRow: { flexDirection: 'row', marginTop: 8 },
  cell: {
    flex: 1,
    height: 64,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  weekday: { fontSize: 10, fontWeight: '800' },
  icon: { fontSize: 18, marginTop: 2 },
});
