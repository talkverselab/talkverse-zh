// AudioPlayer — expo-av wrapper for vi-lab.
// dart: AudioService — RN/Expo 의 Audio.Sound singleton.
//
// 사용:
//   AudioPlayer.play('south_male', 'conv200_001');
// 내부적으로 data/audioMap.ts 의 require() 결과 lookup → Audio.Sound.createAsync.
// 동시 재생 차단 (이전 sound stop + unload 후 새 sound 생성).
import { Audio } from 'expo-av';
import { lookupAudio } from '../data/audioMap';

class AudioPlayerImpl {
  private _sound: Audio.Sound | null = null;
  private _playing = false;
  private _modeInited = false;

  async _ensureMode(): Promise<void> {
    if (this._modeInited) return;
    try {
      await Audio.setAudioModeAsync({
        allowsRecordingIOS: false,
        playsInSilentModeIOS: true,
        shouldDuckAndroid: true,
      });
      this._modeInited = true;
    } catch {
      // Web 환경 등 — 무시.
    }
  }

  async stop(): Promise<void> {
    if (this._sound) {
      try {
        await this._sound.stopAsync();
        await this._sound.unloadAsync();
      } catch {
        // ignore
      }
      this._sound = null;
    }
    this._playing = false;
  }

  async play(voiceDir: string, key: string): Promise<boolean> {
    const asset = lookupAudio(voiceDir, key);
    if (asset == null) {
      // eslint-disable-next-line no-console
      console.warn(`[AudioPlayer] no asset for ${voiceDir}/${key}.mp3`);
      return false;
    }
    await this._ensureMode();
    await this.stop();
    try {
      const { sound } = await Audio.Sound.createAsync(asset, { shouldPlay: true });
      this._sound = sound;
      this._playing = true;
      sound.setOnPlaybackStatusUpdate((status) => {
        if (!status.isLoaded) return;
        if (status.didJustFinish) {
          this._playing = false;
          sound.unloadAsync().catch(() => {});
          if (this._sound === sound) this._sound = null;
        }
      });
      return true;
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn(`[AudioPlayer] play failed ${voiceDir}/${key}`, e);
      this._playing = false;
      return false;
    }
  }

  get isPlaying(): boolean {
    return this._playing;
  }
}

export const AudioPlayer = new AudioPlayerImpl();
