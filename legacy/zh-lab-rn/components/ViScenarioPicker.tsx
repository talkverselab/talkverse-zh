// 포팅 from widgets/vi_scenario_picker.dart — 호칭 시나리오 선택.
// dart: 1~5 옵션 (em→anh / em→chị / 친구 tớ→cậu 등)
// dart 의 DropdownButton 는 RN 에서 단순 가로 chip toggle 로 근사.
import { useState } from 'react';
import { View, Text as RNText, Pressable, StyleSheet, ScrollView } from 'react-native';
import { colors } from '@talkverse/ui-core';

export interface ViScenarioPickerProps {
  value?: number; // 1~5
  onChange?: (id: number) => void;
}

const OPTIONS: Array<{ id: number; label: string }> = [
  { id: 1, label: '여 연하 → 남 연상 (em → anh)' },
  { id: 2, label: '여 연하 → 여 연상 (em → chị)' },
  { id: 3, label: '남 연하 → 남 연상 (em → anh)' },
  { id: 4, label: '남 연하 → 여 연상 (em → chị)' },
  { id: 5, label: '동년배 친구 (tớ → cậu)' },
];

export function ViScenarioPicker({ value = 1, onChange }: ViScenarioPickerProps) {
  const [open, setOpen] = useState(false);
  const current = OPTIONS.find((o) => o.id === value) ?? OPTIONS[0];
  return (
    <View style={styles.outer}>
      <Pressable style={styles.bar} onPress={() => setOpen((v) => !v)}>
        <RNText style={styles.icon}>🗣️ 호칭 </RNText>
        <RNText style={styles.currentLabel}>{current.id}. {current.label}</RNText>
        <RNText style={styles.chev}>{open ? '▲' : '▼'}</RNText>
      </Pressable>
      {open && (
        <ScrollView style={styles.menu}>
          {OPTIONS.map((o) => (
            <Pressable
              key={o.id}
              style={[styles.menuItem, o.id === value && styles.menuItemSelected]}
              onPress={() => {
                onChange?.(o.id);
                setOpen(false);
              }}
            >
              <RNText style={styles.menuItemText}>{o.id}. {o.label}</RNText>
            </Pressable>
          ))}
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  outer: { alignSelf: 'center' },
  bar: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 20,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.cardBorder,
  },
  icon: { fontSize: 13 },
  currentLabel: { fontSize: 13, color: colors.ink },
  chev: { marginLeft: 6, fontSize: 10, color: colors.inkFaint },
  menu: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.cardBorder,
    marginTop: 6,
    maxHeight: 200,
  },
  menuItem: { paddingHorizontal: 12, paddingVertical: 8 },
  menuItemSelected: { backgroundColor: 'rgba(218,37,29,0.08)' },
  menuItemText: { fontSize: 13, color: colors.ink },
});
