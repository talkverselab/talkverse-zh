// Talkverse 공통 복습 화면 — 오늘 할 카드 칸 · 전체 화면 세션 · 빠른 분류 · 설정.
// 앱은 카드 내용을 ReviewFaceResolver 로 넘긴다(id → 앞/뒷면). 색은 앱 테마(Theme.of) 를 따른다.
import 'dart:io';

import 'package:flutter/material.dart';
import '../core/embed_env.dart';

import '../services/content_sync.dart';
import 'review_engine.dart';
import 'review_service.dart';

/// 카드 한 장의 내용. prompt = 학습자 언어(한국어) 뜻, target = 목표어.
class ReviewFace {
  final String prompt;
  final String target;
  final String? reading; // 읽기(한글 독음 등)
  final String? asset; // 그림 — 번들 에셋 경로 또는 http(s) 주소(그림 덱)
  final String? note; // 뒷면 보조 설명(품사·예문 등)
  const ReviewFace({required this.prompt, required this.target, this.reading, this.asset, this.note});
}

typedef ReviewFaceResolver = ReviewFace? Function(String id);
typedef ReviewSpeak = void Function(String id, ReviewFace face);

/// 문구 — 앱이 영어 UI 면 ReviewText.en = true
class ReviewText {
  static bool en = false;
  static String t(String ko, String e) => en ? e : ko;
}

/// 복습 탭 맨 위: '오늘 할 카드 N(새 n · 복습 m) → 시작'
class ReviewTodayCard extends StatelessWidget {
  final List<ReviewCandidate> candidates;
  final ReviewFaceResolver resolve;
  final ReviewSpeak? speak;
  final String title;
  const ReviewTodayCard({super.key, required this.candidates, required this.resolve, this.speak, this.title = ''});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: ReviewService.instance.changes,
        builder: (context, _, __) {
          final plan = ReviewService.instance.plan(candidates);
          final cs = Theme.of(context).colorScheme;
          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ReviewText.t('오늘 할 카드 ${plan.total}', 'Today: ${plan.total} cards'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(ReviewText.t('새 ${plan.fresh.length} · 복습 ${plan.review.length}', 'new ${plan.fresh.length} · review ${plan.review.length}'),
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ]),
                ),
                FilledButton(
                  onPressed: plan.total == 0
                      ? null
                      : () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => ReviewSessionScreen(ids: plan.all, freshIds: plan.fresh.toSet(), resolve: resolve, speak: speak, title: title))),
                  child: Text(plan.total == 0 ? ReviewText.t('끝', 'Done') : ReviewText.t('시작', 'Start')),
                ),
              ]),
            ),
          );
        },
      );
}

/// 전체 화면 세션: 앞면(기본 한국어 → 목표어 떠올리기) → 정답 보기 → 틀림/맞음.
/// 틀린 카드는 세션 끝에 다시, 같은 카드를 두 번 연속 틀리면 '내 힌트' 입력을 권한다.
class ReviewSessionScreen extends StatefulWidget {
  final List<String> ids;
  final Set<String> freshIds;
  final ReviewFaceResolver resolve;
  final ReviewSpeak? speak;
  final String title;
  const ReviewSessionScreen({super.key, required this.ids, this.freshIds = const {}, required this.resolve, this.speak, this.title = ''});
  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  final svc = ReviewService.instance;
  late final List<(String, bool)> queue; // (id, retry)
  int pos = 0, okCount = 0, wrongCount = 0;
  bool revealed = false;
  final wrongStreak = <String, int>{};
  final seen = <String>{};

  @override
  void initState() {
    super.initState();
    queue = [for (final id in widget.ids) if (widget.resolve(id) != null) (id, false)];
  }

  bool get flipped => svc.direction == ReviewDirection.targetToLearner;

  Future<void> _answer(bool ok) async {
    final (id, retry) = queue[pos];
    seen.add(id);
    svc.answer(id, ok, retry: retry);
    if (ok) {
      okCount++;
      wrongStreak[id] = 0;
    } else {
      wrongCount++;
      wrongStreak[id] = (wrongStreak[id] ?? 0) + 1;
      queue.add((id, true));
      if (wrongStreak[id]! >= 2 && (svc.peek(id)?.hint == null)) await _askHint(id);
    }
    setState(() {
      pos++;
      revealed = false;
    });
    if (pos >= queue.length) svc.closeSession(seen);
  }

  Future<void> _askHint(String id) async {
    final c = TextEditingController(text: svc.peek(id)?.hint ?? '');
    final face = widget.resolve(id)!;
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ReviewText.t('내 힌트를 적어 둘까요?', 'Add your own hint?')),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${face.target}  ·  ${face.prompt}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: c, autofocus: true, maxLength: 120,
              decoration: InputDecoration(hintText: ReviewText.t('떠올리기 쉬운 연상 한 줄', 'One line that helps you remember'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ReviewText.t('나중에', 'Later'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(ReviewText.t('저장', 'Save'))),
        ],
      ),
    );
    if (r != null) svc.setHint(id, r);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final done = pos >= queue.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title.isEmpty ? ReviewText.t('복습', 'Review') : widget.title),
        actions: [
          IconButton(
            tooltip: ReviewText.t('방향 바꾸기', 'Switch direction'),
            icon: const Icon(Icons.swap_horiz),
            onPressed: () async {
              await svc.setDirection(flipped ? ReviewDirection.learnerToTarget : ReviewDirection.targetToLearner);
              setState(() {});
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: queue.isEmpty ? 1 : pos / queue.length, minHeight: 4),
        ),
      ),
      body: SafeArea(child: done ? _summary(cs) : _card(cs)),
    );
  }

  Widget _summary(ColorScheme cs) {
    final tomorrow = svc.engine.addDays(1);
    final dueTomorrow = svc.items.values.where((i) => !i.isNew && i.due.compareTo(tomorrow) <= 0).length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 56, color: cs.primary),
          const SizedBox(height: 12),
          Text(ReviewText.t('오늘 카드 끝!', 'All done for today!'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(ReviewText.t('맞음 $okCount · 틀림 $wrongCount · 내일 복습 $dueTomorrow', 'right $okCount · wrong $wrongCount · tomorrow $dueTomorrow'),
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(ReviewText.t('닫기', 'Close'))),
        ]),
      ),
    );
  }

  Widget _card(ColorScheme cs) {
    final (id, retry) = queue[pos];
    final face = widget.resolve(id)!;
    final item = svc.peek(id);
    final front = flipped ? face.target : face.prompt;
    final isNew = widget.freshIds.contains(id) && !retry;
    Widget? image;
    if (item?.image != null && File(item!.image!).existsSync()) {
      image = Image.file(File(item.image!), fit: BoxFit.contain);
    } else if (face.asset != null) {
      // http(s) 주소면 네트워크 그림(auth.talkverse.uk/art/… 등), 아니면 번들 에셋.
      final src = face.asset!;
      image = src.startsWith('http://') || src.startsWith('https://')
          ? Image(image: artProvider(src), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink())
          : Image.asset(assetPath(src), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(children: [
        Row(children: [
          if (isNew) _chip(ReviewText.t('새 카드', 'New'), cs.primary),
          if (retry) _chip(ReviewText.t('다시', 'Again'), cs.error),
          if (!isNew && !retry && item != null) _chip('Lv ${item.level}', cs.secondary),
          const Spacer(),
          Text('${pos + 1} / ${queue.length}', style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // 그림은 앞면에도 보인다(그림 덱은 그림 → 단어 떠올리기)
                if (image != null) ConstrainedBox(constraints: const BoxConstraints(maxHeight: 220), child: image),
                const SizedBox(height: 16),
                Text(front, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
                if (revealed) ...[
                  const Divider(height: 40),
                  Text(flipped ? face.prompt : face.target, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: cs.primary)),
                  if (face.reading != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(face.reading!, style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant))),
                  if (face.note != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(face.note!, textAlign: TextAlign.center)),
                  if (item?.hint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text('💡 ${item!.hint}', textAlign: TextAlign.center, style: TextStyle(color: cs.tertiary)),
                    ),
                  if (widget.speak != null)
                    IconButton(icon: const Icon(Icons.volume_up), onPressed: () => widget.speak!(id, face)),
                ],
              ]),
            ),
          ),
        ),
        if (!revealed)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.tonal(
              onPressed: () {
                setState(() => revealed = true);
                if (widget.speak != null) widget.speak!(id, face);
              },
              child: Text(ReviewText.t('정답 보기', 'Show answer'), style: const TextStyle(fontSize: 17)),
            ),
          )
        else
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: cs.error, side: BorderSide(color: cs.error)),
                  onPressed: () => _answer(false),
                  child: Text(ReviewText.t('틀림', 'Wrong'), style: const TextStyle(fontSize: 17)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton(onPressed: () => _answer(true), child: Text(ReviewText.t('맞음', 'Right'), style: const TextStyle(fontSize: 17))),
              ),
            ),
          ]),
      ]),
    );
  }

  Widget _chip(String s, Color c) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
        child: Text(s, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

/// 덱 첫 진입 '빠른 분류' — 이미 아는 카드를 골라 레벨 5 로.
class ReviewQuickSortScreen extends StatefulWidget {
  final List<String> ids;
  final ReviewFaceResolver resolve;
  final String title;
  const ReviewQuickSortScreen({super.key, required this.ids, required this.resolve, this.title = ''});
  @override
  State<ReviewQuickSortScreen> createState() => _ReviewQuickSortScreenState();
}

class _ReviewQuickSortScreenState extends State<ReviewQuickSortScreen> {
  final known = <String>{};
  @override
  Widget build(BuildContext context) {
    final ids = widget.ids.where((id) => (ReviewService.instance.peek(id)?.isNew ?? true) && widget.resolve(id) != null).toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title.isEmpty ? ReviewText.t('빠른 분류', 'Quick sort') : widget.title)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(ReviewText.t('이미 아는 카드를 누르세요. 아는 카드는 16일 뒤에 한 번 확인합니다.', 'Tap the cards you already know. They come back once in about 16 days.')),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: ids.length,
            itemBuilder: (_, i) {
              final f = widget.resolve(ids[i])!;
              final on = known.contains(ids[i]);
              return CheckboxListTile(
                value: on,
                title: Text(f.target, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text([f.reading, f.prompt].whereType<String>().join(' · ')),
                onChanged: (_) => setState(() => on ? known.remove(ids[i]) : known.add(ids[i])),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  ReviewService.instance.markKnown(known);
                  Navigator.pop(context, known.length);
                },
                child: Text(ReviewText.t('아는 카드 ${known.length}개 저장', 'Save ${known.length} known')),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// 설정 칸: 하루 새 카드 수 · 카드 방향 · 알림 시각(알림 예약은 앱이 onReminderChanged 로 처리).
class ReviewSettingsSection extends StatelessWidget {
  final void Function(int? minutes)? onReminderChanged;
  const ReviewSettingsSection({super.key, this.onReminderChanged});

  @override
  Widget build(BuildContext context) {
    final svc = ReviewService.instance;
    return ValueListenableBuilder<int>(
      valueListenable: svc.changes,
      builder: (context, _, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(
          title: Text(ReviewText.t('하루 새 카드', 'New cards per day')),
          trailing: SegmentedButton<int>(
            segments: const [ButtonSegment(value: 10, label: Text('10')), ButtonSegment(value: 20, label: Text('20')), ButtonSegment(value: 30, label: Text('30'))],
            selected: {svc.newPerDay},
            showSelectedIcon: false,
            onSelectionChanged: (s) => svc.setNewPerDay(s.first),
          ),
        ),
        SwitchListTile(
          title: Text(ReviewText.t('목표어 보고 뜻 떠올리기', 'Show target language first')),
          subtitle: Text(ReviewText.t('끄면 한국어를 보고 목표어를 떠올립니다(기본)', 'Off = recall the target from your language (default)')),
          value: svc.direction == ReviewDirection.targetToLearner,
          onChanged: (v) => svc.setDirection(v ? ReviewDirection.targetToLearner : ReviewDirection.learnerToTarget),
        ),
        ListTile(
          title: Text(ReviewText.t('복습 알림', 'Review reminder')),
          subtitle: Text(svc.reminderMinutes == null
              ? ReviewText.t('끔', 'Off')
              : '${(svc.reminderMinutes! ~/ 60).toString().padLeft(2, '0')}:${(svc.reminderMinutes! % 60).toString().padLeft(2, '0')}'),
          trailing: svc.reminderMinutes == null ? null : IconButton(icon: const Icon(Icons.close), onPressed: () async {
            await svc.setReminder(null);
            onReminderChanged?.call(null);
          }),
          onTap: () async {
            final m = svc.reminderMinutes ?? 20 * 60;
            final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
            if (t == null) return;
            final v = t.hour * 60 + t.minute;
            await svc.setReminder(v);
            onReminderChanged?.call(v);
          },
        ),
      ]),
    );
  }
}
