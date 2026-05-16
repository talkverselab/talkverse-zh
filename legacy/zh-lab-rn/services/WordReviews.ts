// 포팅 from services/word_reviews.dart.
// SRS stage 0-6 (dart 와 동일). AsyncStorage 기반.
//
// key 형식:
//   wordReviews.{num}.stage  — 0-6
//   wordReviews.{num}.due    — ISO date (다음 복습일)
import AsyncStorage from '@react-native-async-storage/async-storage';

// dart: _intervals — SRS 간격 (일).
const INTERVALS = [1, 1, 2, 4, 7, 14, 30];

type Listener = () => void;

class WordReviewsImpl {
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

  private _stageKey(num: number): string {
    return `wordReviews.${num}.stage`;
  }

  private _dueKey(num: number): string {
    return `wordReviews.${num}.due`;
  }

  async getStage(num: number): Promise<number> {
    const v = await AsyncStorage.getItem(this._stageKey(num));
    return v ? parseInt(v, 10) || 0 : 0;
  }

  async recordKnown(num: number): Promise<number> {
    const cur = await this.getStage(num);
    const next = Math.min(cur + 1, 6);
    const days = INTERVALS[next] ?? 30;
    const due = new Date();
    due.setDate(due.getDate() + days);
    await AsyncStorage.setMany({
      [this._stageKey(num)]: String(next),
      [this._dueKey(num)]: due.toISOString(),
    });
    this._notify();
    return next;
  }

  async recordUnknown(num: number): Promise<void> {
    const due = new Date();
    due.setDate(due.getDate() + 1);
    await AsyncStorage.setMany({
      [this._stageKey(num)]: '0',
      [this._dueKey(num)]: due.toISOString(),
    });
    this._notify();
  }

  /// 오늘 복습 due 인 단어 수 — main 화면 표시용.
  async reviewDueCount(): Promise<number> {
    const keys = await AsyncStorage.getAllKeys();
    const dueKeys = keys.filter((k) => k.startsWith('wordReviews.') && k.endsWith('.due'));
    if (dueKeys.length === 0) return 0;
    const pairs = await AsyncStorage.getMany(dueKeys);
    const now = Date.now();
    let cnt = 0;
    for (const k of dueKeys) {
      const v = pairs[k];
      if (!v) continue;
      const t = Date.parse(v);
      if (!isNaN(t) && t <= now) cnt++;
    }
    return cnt;
  }
}

export const WordReviews = new WordReviewsImpl();
