// 포팅 from services/address_preference_service.dart.
// dart: ChangeNotifier + SharedPreferences. RN 은 in-memory listener mock (AsyncStorage 추후 추가).

export type MeRole = 'anh' | 'em';

type Listener = () => void;

class AddressPreferenceServiceImpl {
  private _meRole: MeRole = 'em'; // 기본 = em (dart: MeRole.em)
  private _listeners: Listener[] = [];

  get meRole(): MeRole {
    return this._meRole;
  }

  /// {ME} placeholder 치환값.
  get meText(): string {
    return this._meRole === 'anh' ? 'anh' : 'em';
  }

  /// {YOU} placeholder 치환값 — anh ↔ em 거울값.
  get youText(): string {
    return this._meRole === 'anh' ? 'em' : 'anh';
  }

  /// TTS mp3 gender prefix — speaker A/B 별.
  ttsGenderForSpeaker(speaker: string): 'male' | 'female' {
    const role = speaker === 'A' ? this._meRole : this._opposite();
    return role === 'anh' ? 'male' : 'female';
  }

  private _opposite(): MeRole {
    return this._meRole === 'anh' ? 'em' : 'anh';
  }

  setMeRole(role: MeRole): void {
    if (this._meRole === role) return;
    this._meRole = role;
    this._listeners.forEach((l) => l());
  }

  addListener(l: Listener): void {
    this._listeners.push(l);
  }

  removeListener(l: Listener): void {
    this._listeners = this._listeners.filter((x) => x !== l);
  }

  /// dart: substitute — {ME}/{YOU} placeholder 치환 (첫 단어면 대문자).
  substitute(text: string): string {
    if (!text.includes('{')) return text;
    return text
      .replace(/\{ME\}/g, this._cap(text, '{ME}', this.meText))
      .replace(/\{YOU\}/g, this._cap(text, '{YOU}', this.youText));
  }

  private _cap(text: string, placeholder: string, value: string): string {
    const idx = text.indexOf(placeholder);
    if (idx <= 0) return value[0].toUpperCase() + value.substring(1);
    return value;
  }
}

export const AddressPreferenceService = new AddressPreferenceServiceImpl();
