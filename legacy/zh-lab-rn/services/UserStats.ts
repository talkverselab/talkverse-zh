// 포팅 from services/user_stats.dart.
// AsyncStorage 기반 streak / today / goal 추적.
//
// 기본값:
//   streak=0, today=0, goal=20
//
// 사용:
//   const s = await UserStats.getStreak();
//   UserStats.addListener(() => ...);   // 변경 알림.
import AsyncStorage from '@react-native-async-storage/async-storage';

const K = {
  streak: 'userStats.streak',
  today: 'userStats.today',
  goal: 'userStats.goal',
  lastDay: 'userStats.lastDay', // 'YYYY-MM-DD'
};

type Listener = () => void;

function todayKey(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

class UserStatsImpl {
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

  async getStreak(): Promise<number> {
    const v = await AsyncStorage.getItem(K.streak);
    return v ? parseInt(v, 10) || 0 : 0;
  }

  async getToday(): Promise<number> {
    // Reset if 새 날.
    const last = await AsyncStorage.getItem(K.lastDay);
    const td = todayKey();
    if (last !== td) {
      await AsyncStorage.setItem(K.today, '0');
      await AsyncStorage.setItem(K.lastDay, td);
      return 0;
    }
    const v = await AsyncStorage.getItem(K.today);
    return v ? parseInt(v, 10) || 0 : 0;
  }

  async getGoal(): Promise<number> {
    const v = await AsyncStorage.getItem(K.goal);
    return v ? parseInt(v, 10) || 20 : 20;
  }

  async setGoal(goal: number): Promise<void> {
    await AsyncStorage.setItem(K.goal, String(goal));
    this._notify();
  }

  async incrementToday(by = 1): Promise<number> {
    const cur = await this.getToday();
    const next = cur + by;
    await AsyncStorage.setItem(K.today, String(next));
    // streak += 1 if 처음으로 목표 도달.
    const goal = await this.getGoal();
    if (cur < goal && next >= goal) {
      const streak = await this.getStreak();
      await AsyncStorage.setItem(K.streak, String(streak + 1));
    }
    this._notify();
    return next;
  }
}

export const UserStats = new UserStatsImpl();
