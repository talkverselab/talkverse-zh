// 포팅 from widgets/talky_mascot.dart — Talky 마스코트 7단계 (daysInactive 기반).
// dart: 0=웃음, 1=화이팅, 2=결심, 3=걱정, 4=꼬라봄, 5=무릎꿇음, 6+=체념
import { Text as RNText } from 'react-native';

export interface TalkyMascotProps {
  daysInactive: number;
  size?: number;
  opacity?: number;
}

export function stageFor(daysInactive: number): number {
  if (daysInactive <= 0) return 1;
  if (daysInactive >= 6) return 7;
  return daysInactive + 1;
}

function emojiFor(stage: number): string {
  switch (stage) {
    case 1: return '😄';
    case 2: return '💪';
    case 3: return '🔥';
    case 4: return '😅';
    case 5: return '😒';
    case 6: return '🥺';
    case 7:
    default: return '😴';
  }
}

export function TalkyMascot({ daysInactive, size = 56, opacity = 0.92 }: TalkyMascotProps) {
  const stage = stageFor(daysInactive);
  return (
    <RNText style={{ fontSize: size, opacity }}>
      {emojiFor(stage)}
    </RNText>
  );
}
