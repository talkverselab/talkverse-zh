// 포팅 from data/conversation_200_learning_planner.dart — 누적 복습 SRS 플래너.
// dart 의 LearningPhase + Conv200LearningPlanner 1:1 변환.

export type LearningPhase = 'studyNew' | 'reviewBlock' | 'reviewCumulative' | 'finished';

export interface Conv200PlannerOptions {
  isKnown: (n: number) => boolean;
  isFavorite: (n: number) => boolean;
  blockSize?: number;
  totalBlocks?: number;
  exposureCap?: number;
}

export class Conv200LearningPlanner {
  readonly blockSize: number;
  readonly totalBlocks: number;
  readonly exposureCap: number;
  readonly isKnown: (n: number) => boolean;
  readonly isFavorite: (n: number) => boolean;

  private _currentBlock = 0;
  private _phase: LearningPhase = 'studyNew';
  private _queue: number[] = [];
  private _exposed = new Set<number>();
  private _exposureCount = new Map<number, number>();
  private _passed = new Set<number>();

  constructor(opts: Conv200PlannerOptions) {
    this.isKnown = opts.isKnown;
    this.isFavorite = opts.isFavorite;
    this.blockSize = opts.blockSize ?? 10;
    this.totalBlocks = opts.totalBlocks ?? 20;
    this.exposureCap = opts.exposureCap ?? 5;
  }

  get phase(): LearningPhase { return this._phase; }
  get currentBlock(): number { return this._currentBlock; }
  get queueLength(): number { return this._queue.length; }
  get exposed(): ReadonlySet<number> { return this._exposed; }
  get passed(): ReadonlySet<number> { return this._passed; }

  start(): void {
    this._currentBlock = 0;
    this._phase = 'studyNew';
    this._refillQueue();
  }

  next(): number | null {
    while (this._queue.length === 0 && this._phase !== 'finished') {
      this._advancePhase();
    }
    if (this._queue.length === 0) return null;
    const n = this._queue.shift()!;
    this._exposed.add(n);
    const cnt = (this._exposureCount.get(n) ?? 0) + 1;
    this._exposureCount.set(n, cnt);
    if (cnt >= this.exposureCap && !this.isKnown(n)) {
      this._passed.add(n);
    }
    return n;
  }

  onKnown(n: number): void {
    this._passed.delete(n);
    this._exposureCount.delete(n);
  }

  phaseLabel(): string {
    switch (this._phase) {
      case 'studyNew': return `새 블록 ${this._currentBlock + 1}/${this.totalBlocks} 학습`;
      case 'reviewBlock': return `블록 ${this._currentBlock + 1} 복습`;
      case 'reviewCumulative': return `1~${this._currentBlock} 누적 복습`;
      case 'finished': return '🎉 모든 블록 완료';
    }
  }

  get progress(): number {
    if (this._phase === 'finished') return 1.0;
    return (this._currentBlock + (this._phase === 'studyNew' ? 0 : 0.5)) / this.totalBlocks;
  }

  private _advancePhase(): void {
    switch (this._phase) {
      case 'studyNew':
        this._phase = 'reviewBlock';
        this._refillQueue();
        return;
      case 'reviewBlock':
        if (this._currentBlock >= 1) {
          this._phase = 'reviewCumulative';
          this._refillQueue();
        } else {
          this._moveToNextBlock();
        }
        return;
      case 'reviewCumulative':
        this._moveToNextBlock();
        return;
      case 'finished': return;
    }
  }

  private _moveToNextBlock(): void {
    this._currentBlock++;
    if (this._currentBlock >= this.totalBlocks) {
      this._phase = 'finished';
      this._queue = [];
      return;
    }
    this._phase = 'studyNew';
    this._refillQueue();
  }

  private _eligibleForReview(n: number): boolean {
    if (this.isFavorite(n)) return true;
    if (!this._exposed.has(n)) return false;
    if (this.isKnown(n)) return false;
    if (this._passed.has(n)) return false;
    return true;
  }

  private _refillQueue(): void {
    this._queue = [];
    switch (this._phase) {
      case 'studyNew':
        for (let i = 1; i <= this.blockSize; i++) {
          this._queue.push(this._currentBlock * this.blockSize + i);
        }
        break;
      case 'reviewBlock':
        for (let i = 1; i <= this.blockSize; i++) {
          const n = this._currentBlock * this.blockSize + i;
          if (this._eligibleForReview(n)) this._queue.push(n);
        }
        break;
      case 'reviewCumulative':
        for (let b = 0; b < this._currentBlock; b++) {
          for (let i = 1; i <= this.blockSize; i++) {
            const n = b * this.blockSize + i;
            if (this._eligibleForReview(n)) this._queue.push(n);
          }
        }
        break;
      case 'finished': break;
    }
  }
}
