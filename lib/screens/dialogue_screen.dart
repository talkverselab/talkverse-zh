import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../services/achievement_service.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';
import '../widgets/episode_play_pane.dart';
import 'custom_script_screen.dart';
import 'dialogue_card_screen.dart';

/// 새 회화(R0~R4) 주제 목록 → 편 목록 → 편 화면 — 시안 zh05 「확 트인 배치」(2026-11-03).
/// 홈: 「이어서 읽기」 카드 하나가 주인공, 레벨 스위치·주제는 상자 없이 조용히. 편 화면 = 회화 리더([EpisodePlayPane]) 하나(폰·아이패드 공통).
/// 편이 없는 레벨(지금 R0·R1)은 빈 화면 대신 「준비 중」 한 줄을 보인다.
class DialogueHomeScreen extends StatefulWidget {
  final bool embedded; // 「배우기」 탭 안(앱바 없이)
  const DialogueHomeScreen({super.key, this.embedded = false});
  @override
  State<DialogueHomeScreen> createState() => _DialogueHomeScreenState();
}

class _DialogueHomeScreenState extends State<DialogueHomeScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DialogueService.instance.ensureLoaded().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = DialogueService.instance;
    final level = svc.level; // R0 왕초보 / R1 초보
    final toggle = LevelSwitch(
      level: level == 'R0' ? 'R0' : 'R1',
      onChanged: (lv) async {
        await svc.setLevel(lv);
        if (mounted) setState(() {});
      },
    );
    final items = _loading
        ? <Widget>[
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: AppColors.copper)),
            ),
          ]
        : DialogueHomeList.items(context, level: level, toggle: widget.embedded ? toggle : null, continueCard: !widget.embedded);
    // 「배우기」 탭 안(앱바·스크롤 없이 바깥 ListView 에 들어감) — 「이어서 읽기」는 탭이 맨 위에 따로 둔다
    if (widget.embedded) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items);
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Text(tr('회화')),
        actions: [Padding(padding: const EdgeInsets.only(right: 8), child: toggle)],
      ),
      body: SafeArea(
        top: false,
        child: ListView(padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context)), children: items),
      ),
    );
  }
}

/// 왕초보 · 초보 — 상자 없는 글자 스위치(고른 쪽만 진하게).
class LevelSwitch extends StatelessWidget {
  final String level;
  final ValueChanged<String> onChanged;
  const LevelSwitch({super.key, required this.level, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget opt(String lv, String label) {
      final on = lv == level;
      return InkWell(
        onTap: on ? null : () => onChanged(lv),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Text(label, style: AppFonts.captionText(size: 12, weight: on ? FontWeight.w600 : FontWeight.w400, color: on ? AppColors.mo : AppColors.muted)),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      opt('R0', tr('왕초보')),
      Text('·', style: AppFonts.captionText()),
      opt('R1', tr('초보')),
    ]);
  }
}

/// 회화 홈 목록(이어서 읽기 → 맞춤 회화 → 레벨 스위치·안내 → 레벨별 주제). 회화 화면과 「배우기」 탭이 같이 쓴다.
class DialogueHomeList {
  DialogueHomeList._();

  static List<Widget> items(BuildContext context, {required String level, Widget? toggle, bool continueCard = true}) {
    final svc = DialogueService.instance;
    return [
      if (continueCard) ...[ContinueReadingCard(level: svc.startLevel), const SizedBox(height: 18)],
      const CustomScriptEntryCard(),
      const SizedBox(height: 6),
      if (toggle != null) Align(alignment: Alignment.centerLeft, child: toggle),
      Padding(
        padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
        child: Text(
          level == 'R0' ? tr('왕초보: 문장이 짧은 편만 모았어요. 익숙해지면 초보로 올라오세요.') : tr('초보가 기본입니다. 너무 힘들면 「왕초보」로 바꾸세요 — 문장이 짧은 편들만 모아 보여 줍니다.'),
          style: AppFonts.captionText(size: 11.5),
        ),
      ),
      for (final lv in DialogueService.levels)
        if (lv != 'R0' && lv != 'R1' || lv == level) ...[
          _LevelHeader(lv: lv, count: svc.count(lv)),
          if (svc.count(lv) == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              child: Text(tr('준비 중 — 새 회화가 곧 들어와요. 지금은 아래 레벨부터 읽어 보세요.'), style: AppFonts.captionText(size: 12)),
            )
          else
            for (final isl in svc.islandsOf(lv))
              _IslandRow(
                lv: lv,
                island: isl,
                count: svc.list(region: lv, island: isl).length,
                onTap: () => openPane(context, (_) => DialogueListScreen(region: lv, island: isl)),
              ),
          const SizedBox(height: 6),
        ],
    ];
  }
}

/// 「이어서 읽기」 — 홈의 주인공 카드 하나(시안 zh05 ③). 마지막으로 연 편(없으면 시작 레벨 첫 편)의 장면 컷 + 제목 + 진행.
/// 진행 = 그 주제에서 끝까지 들은 편 수(한 줄짜리 가는 선 하나).
class ContinueReadingCard extends StatefulWidget {
  final String level;
  const ContinueReadingCard({super.key, required this.level});

  @override
  State<ContinueReadingCard> createState() => _ContinueReadingCardState();
}

class _ContinueReadingCardState extends State<ContinueReadingCard> {
  bool _ready = DialogueService.instance.count('R2') + DialogueService.instance.count('R3') + DialogueService.instance.count('R4') > 0;

  @override
  void initState() {
    super.initState();
    if (!_ready) {
      DialogueService.instance.ensureLoaded().then((_) {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final svc = DialogueService.instance;
    final last = svc.lastOpenedId != null ? svc.byId(svc.lastOpenedId!) : null;
    final level = last == null ? svc.startLevel : widget.level;
    final d = last ?? (svc.list(region: level).isNotEmpty ? svc.list(region: level).first : null);
    if (d == null) return const SizedBox.shrink();
    final same = svc.list(region: d.region, island: d.island);
    final done = same.where((e) => AchievementService.instance.isDone(e.id)).length;
    final pos = same.indexWhere((e) => e.id == d.id);
    void open() => openPane(context, (_) => DialogueScreen(dialogue: d));
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: kCardShadow),
      child: Material(
        color: AppColors.xuanZhi,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: open,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // 폭의 16:10, 넓은 칸에서도 260 까지만(홈이 그림 한 장으로 꽉 차지 않게)
            LayoutBuilder(builder: (context, c) => SizedBox(height: (c.maxWidth / 1.6).clamp(140.0, 260.0), child: SceneCut(dialogue: d, turn: d.turns.first))),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr(last == null ? '오늘의 컷' : '이어서 읽기'), style: AppFonts.captionText(weight: FontWeight.w600, color: AppColors.copper)),
                    const SizedBox(height: 4),
                    Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.titleText(size: 20)),
                    const SizedBox(height: 3),
                    Text(d.scene, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.uiText(size: 13)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(value: same.isEmpty ? 0 : done / same.length, minHeight: 2, color: AppColors.copper, backgroundColor: AppColors.line),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${tr(DialogueService.islandKo[d.island] ?? d.island)} ${pos < 0 ? '' : '${pos + 1}/${same.length}'}',
                        style: AppFonts.captionText(size: 11),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.xuanZhiDeep),
                  child: const Icon(Icons.chevron_right_rounded, color: AppColors.moLight),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  final String lv;
  final int count;
  const _LevelHeader({required this.lv, required this.count});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 14, 6, 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(lv, style: AppFonts.captionText(size: 12, weight: FontWeight.w600, color: AppColors.copper)),
        const SizedBox(width: 8),
        Text(tr(DialogueService.levelKo[lv] ?? lv), style: AppFonts.uiText(size: 14, weight: FontWeight.w600, color: AppColors.mo)),
        const SizedBox(width: 8),
        Text(trf('{0}편', [count]), style: AppFonts.captionText(size: 11)),
      ],
    ),
  );
}

/// 주제 한 줄 — 상자 없이(이모지 · 이름 · 편 수).
class _IslandRow extends StatelessWidget {
  final String lv;
  final String island;
  final int count;
  final VoidCallback onTap;
  const _IslandRow({required this.lv, required this.island, required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      child: Row(children: [
        Text(DialogueService.islandEmoji[island] ?? '💬', style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(child: Text(tr(DialogueService.islandKo[island] ?? island), style: AppFonts.uiText(size: 14.5, color: AppColors.mo))),
        Text(trf('{0}편', [count]), style: AppFonts.captionText(size: 11)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: AppColors.line, size: 18),
      ]),
    ),
  );
}

/// 주제의 편 목록 — 상자 없이 줄과 여백으로.
class DialogueListScreen extends StatelessWidget {
  final String region;
  final String island;
  const DialogueListScreen({super.key, required this.region, required this.island});

  @override
  Widget build(BuildContext context) {
    final list = DialogueService.instance.list(region: region, island: island);
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Text('${DialogueService.islandEmoji[island] ?? ''} ${tr(DialogueService.islandKo[island] ?? island)} · $region'),
      ),
      body: SafeArea(
        top: false,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 24 + bottomInset(context)),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final d = list[i];
            final done = AchievementService.instance.isDone(d.id);
            return InkWell(
              onTap: () => openPane(context, (_) => DialogueScreen(dialogue: d)),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.title, style: AppFonts.uiText(size: 15, weight: FontWeight.w600, color: AppColors.mo)),
                      const SizedBox(height: 2),
                      Text('${d.isChat ? '💬 ' : ''}${d.scene}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.captionText(size: 12)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  done
                      ? const Icon(Icons.check_rounded, size: 16, color: AppColors.copper)
                      : Text(trf('{0}턴', [d.turns.length]), style: AppFonts.captionText(size: 11)),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 편 화면 — 회화 리더 하나(장면 컷 크게 · 지금 대사 크게 · 나머지 접힘, ▶ 로 순차 재생).
class DialogueScreen extends StatefulWidget {
  final Dialogue dialogue;
  const DialogueScreen({super.key, required this.dialogue});
  @override
  State<DialogueScreen> createState() => _DialogueScreenState();
}

class _DialogueScreenState extends State<DialogueScreen> {
  Dialogue get d => widget.dialogue;

  @override
  void initState() {
    super.initState();
    DialogueService.instance.setLastOpened(d.id);
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${d.emoji} ${d.title}', style: AppFonts.titleText(size: 18)),
            const SizedBox(height: 1),
            Text('${d.region} · ${tr(DialogueService.islandKo[d.island] ?? d.island)} · ${d.turns.length}${tr('턴')}', style: AppFonts.captionText(size: 10.5)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr('그림 카드(글자 없이)'),
            icon: const Icon(Icons.style_outlined, color: AppColors.muted),
            onPressed: () => openFull(context, (_) => DialogueCardScreen(dialogue: d)),
          ),
        ],
      ),
      // 폰·아이패드 모두 같은 리더(장면 컷 위 · 지금 대사 크게 · 나머지 접힘). ▶ 를 누르면 순차 재생.
      body: SafeArea(
        top: false,
        child: EpisodePlayPane(key: ValueKey(d.id), dialogue: d, autoPlay: false),
      ),
    );
  }
}

