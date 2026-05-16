// 포팅 from textbook_screen.dart (751 줄) — 단국대 교재 (MN 30 챕터, ZH 룸 reference).
//
// dart 원본:
//   * TextbookScreen: chapters_meta.json (30 chapter, A1 1-15 / A2 16-30)
//   * TextbookChapterScreen: 본문 audio, 핵심회화 audio, 단어/문장/회화 플래시카드
//   * TextbookFlashcardScreen: word/sentence/dialogue 모드 + 자동 Azure mp3
//   * audio_manifest.json (md5 hash → pre-gen mp3)
//
// VI 룸은 실제 textbook_mn 데이터 없으므로 시각적 placeholder + nav structure.
import { useState } from 'react';
import { ScrollView, StyleSheet, View, Pressable, Text as RNText } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack } from 'expo-router';
import { colors } from '@talkverse/ui-core';

const BRAND_ZH = colors.brand.zh;

// dart: chapters_meta.json — mock 30 chapter
const CHAPTERS: Array<{ chapter: number; level: 1 | 2; title: string; word_count: number; sentence_count: number }> = [
  ...Array.from({ length: 15 }, (_, i) => ({
    chapter: i + 1, level: 1 as const, title: `A1 제${i + 1}과`, word_count: 0, sentence_count: 0,
  })),
  ...Array.from({ length: 15 }, (_, i) => ({
    chapter: i + 16, level: 2 as const, title: `A2 제${i + 16}과`, word_count: 0, sentence_count: 0,
  })),
];

export default function TextbookScreen() {
  const [selectedChapter, setSelectedChapter] = useState<number | null>(null);

  if (selectedChapter !== null) {
    return <TextbookChapterView chapter={selectedChapter} onBack={() => setSelectedChapter(null)} />;
  }

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: '📚 교과서 공부 (단국대)',
          headerStyle: { backgroundColor: colors.background },
          headerTintColor: colors.ink,
        }}
      />
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <SectionHeader label="A1 — 초급 (제1~15과)" />
        {CHAPTERS.filter((c) => c.level === 1).map((c) => (
          <ChapterCard key={c.chapter} meta={c} onPress={() => setSelectedChapter(c.chapter)} />
        ))}
        <View style={{ height: 16 }} />
        <SectionHeader label="A2 — 초급 (제16~30과)" />
        {CHAPTERS.filter((c) => c.level === 2).map((c) => (
          <ChapterCard key={c.chapter} meta={c} onPress={() => setSelectedChapter(c.chapter)} />
        ))}
        <View style={{ height: 24 }} />
        <RNText style={{ fontSize: 11, color: colors.inkSecondary, textAlign: 'center' }}>
          단국대학교 특수외국어진흥사업 교재 (무료 배포)
        </RNText>
      </ScrollView>
    </SafeAreaView>
  );
}

function SectionHeader({ label }: { label: string }) {
  return (
    <View style={{ paddingVertical: 8, paddingHorizontal: 4 }}>
      <RNText style={{ fontSize: 14, fontWeight: 'bold', color: colors.ink }}>{label}</RNText>
    </View>
  );
}

function ChapterCard({
  meta, onPress,
}: {
  meta: { chapter: number; level: 1 | 2; title: string; word_count: number; sentence_count: number };
  onPress: () => void;
}) {
  const code = `A${meta.level}-${String(meta.chapter).padStart(2, '0')}`;
  const hasContent = meta.word_count > 0 || meta.sentence_count > 0;
  return (
    <Pressable style={styles.chapterCard} onPress={onPress}>
      <View style={[
        styles.chapterAvatar,
        { backgroundColor: hasContent ? BRAND_ZH : colors.inkSecondary },
      ]}>
        <RNText style={{ color: '#FFFFFF', fontWeight: 'bold' }}>{meta.chapter}</RNText>
      </View>
      <View style={{ flex: 1, marginLeft: 12 }}>
        <RNText style={{ fontWeight: 'bold', color: colors.ink }}>{code} 과</RNText>
        <RNText style={{ fontSize: 12, color: colors.inkSoft }} numberOfLines={1}>
          {meta.title.length > 0 ? meta.title : '(추출 데이터 없음 — 오디오만 가용)'}
        </RNText>
      </View>
      <View style={{ alignItems: 'flex-end' }}>
        <RNText style={{ fontSize: 11, color: colors.inkSecondary }}>단어 {meta.word_count}</RNText>
        <RNText style={{ fontSize: 11, color: colors.inkSecondary }}>문장 {meta.sentence_count}</RNText>
      </View>
    </Pressable>
  );
}

function TextbookChapterView({ chapter, onBack }: { chapter: number; onBack: () => void }) {
  const code = `A${chapter <= 15 ? 1 : 2}-${String(chapter).padStart(2, '0')}`;
  const [playingTag, setPlayingTag] = useState<string | null>(null);

  const toggleAudio = (tag: string) => {
    setPlayingTag((p) => (p === tag ? null : tag));
  };

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: `${code} 과`,
          headerStyle: { backgroundColor: colors.background },
          headerTintColor: colors.ink,
          headerLeft: () => (
            <Pressable onPress={onBack} style={{ padding: 8 }}>
              <RNText style={{ fontSize: 22, color: colors.ink }}>‹</RNText>
            </Pressable>
          ),
        }}
      />
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <AudioCard
          emoji="📖"
          label="본문 듣기"
          isPlaying={playingTag === 'main'}
          onPress={() => toggleAudio('main')}
        />
        <View style={{ height: 8 }} />
        <AudioCard
          emoji="💬"
          label="핵심회화 듣기"
          isPlaying={playingTag === 'dialogue'}
          onPress={() => toggleAudio('dialogue')}
        />
        <View style={{ height: 16 }} />
        <StudyCard emoji="🔤" label="단어 플래시카드" count={0} onPress={() => {}} />
        <View style={{ height: 8 }} />
        <StudyCard emoji="✏️" label="문장 플래시카드" count={0} onPress={() => {}} />
        <View style={{ height: 8 }} />
        <StudyCard emoji="🎤" label="핵심회화 플래시카드" count={0} onPress={() => {}} />
      </ScrollView>
    </SafeAreaView>
  );
}

function AudioCard({
  emoji, label, isPlaying, onPress,
}: { emoji: string; label: string; isPlaying: boolean; onPress: () => void }) {
  return (
    <Pressable style={styles.listCard} onPress={onPress}>
      <RNText style={{ fontSize: 28 }}>{emoji}</RNText>
      <View style={{ flex: 1, marginLeft: 12 }}>
        <RNText style={{ fontWeight: 'bold', color: colors.ink }}>{label}</RNText>
      </View>
      <RNText style={{ fontSize: 28, color: BRAND_ZH }}>{isPlaying ? '⏹' : '▶'}</RNText>
    </Pressable>
  );
}

function StudyCard({
  emoji, label, count, onPress,
}: { emoji: string; label: string; count: number; onPress: () => void }) {
  return (
    <Pressable style={styles.listCard} onPress={count > 0 ? onPress : undefined}>
      <RNText style={{ fontSize: 28 }}>{emoji}</RNText>
      <View style={{ flex: 1, marginLeft: 12 }}>
        <RNText style={{ fontWeight: 'bold', color: colors.ink }}>{label}</RNText>
        <RNText style={{ fontSize: 12, color: colors.inkSecondary }}>{count} 항목</RNText>
      </View>
      <RNText style={{ fontSize: 22, color: colors.inkMuted }}>›</RNText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  chapterCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    marginVertical: 4,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 2,
  },
  chapterAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  listCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 14,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 2,
  },
});
