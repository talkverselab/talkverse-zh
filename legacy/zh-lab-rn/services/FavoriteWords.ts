// 포팅 from services/favorite_words.dart.
// AsyncStorage 기반 즐겨찾기 단어 (num) 집합.
//
// key:
//   favoriteWords.numbers  — JSON array (number[])
import AsyncStorage from '@react-native-async-storage/async-storage';

const K = 'favoriteWords.numbers';

type Listener = () => void;

class FavoriteWordsImpl {
  private _cache: Set<number> | null = null;
  private _listeners: Listener[] = [];

  addListener(l: Listener): void {
    this._listeners.push(l);
  }

  removeListener(l: Listener): void {
    this._listeners = this._listeners.filter((x) => x !== l);
  }

  private _notify(): void {
    this._listeners.forEach((l) => l());
  }

  private async _load(): Promise<Set<number>> {
    if (this._cache !== null) return this._cache;
    const raw = await AsyncStorage.getItem(K);
    if (!raw) {
      this._cache = new Set();
      return this._cache;
    }
    try {
      const arr = JSON.parse(raw) as number[];
      this._cache = new Set(arr);
    } catch {
      this._cache = new Set();
    }
    return this._cache;
  }

  private async _save(): Promise<void> {
    if (!this._cache) return;
    const arr = Array.from(this._cache);
    await AsyncStorage.setItem(K, JSON.stringify(arr));
  }

  async count(): Promise<number> {
    const s = await this._load();
    return s.size;
  }

  async has(num: number): Promise<boolean> {
    const s = await this._load();
    return s.has(num);
  }

  async toggle(num: number): Promise<boolean> {
    const s = await this._load();
    if (s.has(num)) s.delete(num);
    else s.add(num);
    await this._save();
    this._notify();
    return s.has(num);
  }

  async all(): Promise<number[]> {
    const s = await this._load();
    return Array.from(s).sort((a, b) => a - b);
  }
}

export const FavoriteWords = new FavoriteWordsImpl();
