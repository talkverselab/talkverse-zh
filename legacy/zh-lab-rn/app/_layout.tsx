import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <Stack
        screenOptions={{
          headerStyle: { backgroundColor: '#DE2910' },
          headerTintColor: '#FFFFFF',
        }}
      >
        <Stack.Screen name="index" options={{ title: '🇨🇳 중국어 학습' }} />
        <Stack.Screen name="main" options={{ title: '🇨🇳 ZH 메인' }} />
        <Stack.Screen name="conversation_200" options={{ title: '🎯 기초 회화 200' }} />
        <Stack.Screen name="chat_dialogue_list" options={{ title: '💬 채팅 (L2)' }} />
        <Stack.Screen name="chat_dialogue_memorize" options={{ title: '문장 외우기' }} />
        <Stack.Screen name="tone_practice" options={{ title: '🎵 성조 연습' }} />
        <Stack.Screen name="textbook" options={{ title: '📚 교과서 공부' }} />
        <Stack.Screen name="adverbs_200" options={{ title: '🎯 부사·표현 200' }} />
      </Stack>
      <StatusBar style="light" />
    </SafeAreaProvider>
  );
}
