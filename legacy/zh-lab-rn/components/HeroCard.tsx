// 포팅 from widgets/hero_card.dart — 홈 상단 큰 Hero 카드.
// dart: LinearGradient + Pastel Neumorphism 3D pop shadow + 텍스트 + CTA pill + Talky 마스코트
import { Pressable, View, StyleSheet, Text as RNText } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { colors } from '@talkverse/ui-core';
import { TalkyMascot } from './TalkyMascot';

const BRAND_ZH = colors.brand.zh;

export interface HeroCardProps {
  label: string;
  title: string;
  emoji?: string;
  daysInactive?: number;
  ctaLabel?: string;
  onPress?: () => void;
}

// HSL helpers (dart: HSLColor.fromColor(brand).withLightness(...))
function hexToHsl(hex: string): [number, number, number] {
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;
  const max = Math.max(r, g, b), min = Math.min(r, g, b);
  let h = 0, s = 0;
  const l = (max + min) / 2;
  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: h = (g - b) / d + (g < b ? 6 : 0); break;
      case g: h = (b - r) / d + 2; break;
      case b: h = (r - g) / d + 4; break;
    }
    h /= 6;
  }
  return [h, s, l];
}

function hslToHex(h: number, s: number, l: number): string {
  let r: number, g: number, b: number;
  if (s === 0) {
    r = g = b = l;
  } else {
    const hue2rgb = (p: number, q: number, t: number) => {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    };
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    r = hue2rgb(p, q, h + 1 / 3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1 / 3);
  }
  const toHex = (x: number) => Math.round(x * 255).toString(16).padStart(2, '0');
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

function shiftLightness(hex: string, delta: number): string {
  const [h, s, l] = hexToHsl(hex);
  return hslToHex(h, s, Math.max(0, Math.min(1, l + delta)));
}

export function HeroCard({
  label,
  title,
  emoji,
  daysInactive = 0,
  ctaLabel = '시작하기',
  onPress,
}: HeroCardProps) {
  const brand = BRAND_ZH;
  const light = shiftLightness(brand, 0.08);
  const dark = shiftLightness(brand, -0.10);
  // dart: LinearGradient(begin: topLeft, end: bottomRight, colors: [light, brand, dark])
  return (
    <Pressable onPress={onPress} style={[styles.cardShadow, { shadowColor: dark }]}>
      <LinearGradient
        colors={[light, brand, dark]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.card}
      >
        {/* 우측 마스코트 슬롯 */}
        <View style={styles.mascotSlot}>
          {emoji && emoji.length > 0 ? (
            <RNText style={{ fontSize: 48, opacity: 0.85 }}>{emoji}</RNText>
          ) : (
            <TalkyMascot daysInactive={daysInactive} size={48} />
          )}
        </View>
        <View style={styles.row}>
          <View style={styles.textCol}>
            <RNText style={styles.labelText}>{label.toUpperCase()}</RNText>
            <RNText style={styles.titleText}>{title}</RNText>
          </View>
          {/* CTA pill */}
          <View style={styles.ctaPill}>
            <View style={[styles.playCircle, { backgroundColor: dark }]}>
              <RNText style={styles.playArrow}>▶</RNText>
            </View>
            <RNText style={[styles.ctaLabel, { color: dark }]}>{ctaLabel}</RNText>
          </View>
        </View>
      </LinearGradient>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  cardShadow: {
    borderRadius: 28,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.35,
    shadowRadius: 20,
    elevation: 8,
  },
  card: {
    borderRadius: 28,
    paddingHorizontal: 20,
    paddingTop: 10,
    paddingBottom: 12,
    overflow: 'visible',
  },
  mascotSlot: {
    position: 'absolute',
    right: -4,
    top: -4,
  },
  row: { flexDirection: 'row', alignItems: 'center' },
  textCol: { flex: 1 },
  labelText: {
    fontSize: 10,
    fontWeight: '800',
    letterSpacing: 1.0,
    color: 'rgba(255,255,255,0.9)',
  },
  titleText: {
    fontSize: 22,
    fontWeight: '900',
    color: '#FFFFFF',
    lineHeight: 24,
    marginTop: 3,
    textShadowColor: 'rgba(0,0,0,0.4)',
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 0,
  },
  ctaPill: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.55)',
    borderRadius: 999,
    paddingLeft: 3,
    paddingRight: 10,
    paddingVertical: 3,
    marginLeft: 8,
  },
  playCircle: {
    width: 22,
    height: 22,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
  },
  playArrow: { color: '#FFFFFF', fontSize: 10 },
  ctaLabel: { marginLeft: 6, fontSize: 12, fontWeight: '800' },
});
