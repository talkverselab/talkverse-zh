// 포팅 from data/conversation_200_keyboard_pool.dart.
// dart: rootBundle.loadString(...) → assets/conv200_{dialect}.json
// RN: require() 정적 import.

import conv200North from '../assets/conv200_north.json';
import conv200South from '../assets/conv200_south.json';

export type ViDialect = 'north' | 'south';

export interface Conv200Entry {
  num: number;
  vi: string;
  pron?: string;
  ko: string;
  key?: string;
  speaker?: string;
}

export interface Conv200KeyboardWord {
  id: string;
  type: 'sentence';
  target: string;
  korean: string;
  romanization: string;
  category: 'conv200';
  course: 1;
  tags: string[];
  notes: string;
  turnOrder: number;
  tier: 'beginner';
}

function rawEntriesFor(dialect: ViDialect): Conv200Entry[] {
  const raw = dialect === 'north' ? (conv200North as any) : (conv200South as any);
  const entries = (raw?.entries ?? []) as Conv200Entry[];
  return entries;
}

export function loadConversation200Entries(dialect: ViDialect): Conv200Entry[] {
  return rawEntriesFor(dialect);
}

export function loadConversation200Title(dialect: ViDialect): string {
  const raw = dialect === 'north' ? (conv200North as any) : (conv200South as any);
  return (raw?.title as string | undefined) ?? '중국어 기초 회화 200';
}

export function loadConversation200KeyboardPool(dialect: ViDialect): Conv200KeyboardWord[] {
  return rawEntriesFor(dialect).map((e) => ({
    id: `vi:conv200:${e.num.toString().padStart(3, '0')}`,
    type: 'sentence',
    target: e.vi ?? '',
    korean: e.ko ?? '',
    romanization: e.pron ?? '',
    category: 'conv200',
    course: 1,
    tags: ['conv200', 'keyboard'],
    notes: e.key ?? '',
    turnOrder: e.num,
    tier: 'beginner',
  }));
}
