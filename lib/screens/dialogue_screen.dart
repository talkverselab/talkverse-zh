import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../services/ko_reading.dart';
import '../services/learner_prefs.dart';
import '../services/tts_service.dart';
import '../widgets/episode_play_pane.dart';
import '../widgets/chinese_decor.dart';
import '../widgets/selectable_hanzi.dart';
import 'custom_script_screen.dart';
import 'dialogue_card_screen.dart';

/// 새 회화(R0~R4) 주제 목록 → 편 목록 → 편 화면 — 일본어앱 시안 02 「만화책 읽기형」을 옮김(2026-11-02).
/// 아이패드: 홈 맨 위 「오늘의 컷」, 편 화면 = 왼쪽 대화 스크립트 + 오른쪽 큰 장면 컷(말풍선) + 하단 재생 컨트롤.
/// 폰: 각 단계가 push, 재생은 전체 화면(컷 위·스크립트 아래).
/// 편이 없는 레벨(지금 R0·R1)은 빈 화면 대신 「준비 중」 카드를 보인다.
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
    final toggle = SegmentedButton<String>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
      segments: [
        ButtonSegment(value: 'R0', label: Text(tr('왕초보'))),
        ButtonSegment(value: 'R1', label: Text(tr('초보'))),
      ],
      selected: {level == 'R0' ? 'R0' : 'R1'},
      onSelectionChanged: (s) async {
        await svc.setLevel(s.first);
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
        : DialogueHomeList.items(context, level: level, toggle: widget.embedded ? toggle : null);
    // 「배우기」 탭 안(앱바·스크롤 없이 바깥 ListView 에 들어감)
    if (widget.embedded) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items);
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Text(
          tr('회화'),
          style: const TextStyle(color: AppColors.mo, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [Padding(padding: const EdgeInsets.only(right: 8), child: toggle)],
      ),
      body: SafeArea(
        top: false,
        child: ListView(padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context)), children: items),
      ),
    );
  }
}

/// 회화 홈 목록(오늘의 컷 → 맞춤 회화 → 안내 → 레벨별 주제). 회화 화면과 「배우기」 탭이 같이 쓴다.
class DialogueHomeList {
  DialogueHomeList._();

  static List<Widget> items(BuildContext context, {required String level, Widget? toggle}) {
    final svc = DialogueService.instance;
    return [
      _TodayCut(level: svc.startLevel),
      const SizedBox(height: 10),
      const CustomScriptEntryCard(),
      const SizedBox(height: 10),
      if (toggle != null) Align(alignment: Alignment.centerLeft, child: toggle),
      if (toggle != null) const SizedBox(height: 8),
      _hint(level),
      const SizedBox(height: 8),
      for (final lv in DialogueService.levels)
        if (lv != 'R0' && lv != 'R1' || lv == level) ...[
          _LevelHeader(lv: lv, count: svc.count(lv)),
          if (svc.count(lv) == 0)
            const _ComingSoon()
          else
            for (final isl in svc.islandsOf(lv))
              _IslandRow(
                lv: lv,
                island: isl,
                count: svc.list(region: lv, island: isl).length,
                onTap: () => openPane(context, (_) => DialogueListScreen(region: lv, island: isl)),
              ),
          const SizedBox(height: 10),
        ],
    ];
  }

  static Widget _hint(String level) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    decoration: BoxDecoration(
      color: AppColors.xuanZhiDeep,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.line),
    ),
    child: Text(
      level == 'R0' ? tr('왕초보: 문장이 짧은 편만 모았어요. 익숙해지면 초보로 올라오세요.') : tr('초보가 기본입니다. 너무 힘들면 「왕초보」로 바꾸세요 — 문장이 짧은 편들만 모아 보여 줍니다.'),
      style: const TextStyle(fontSize: 12, color: AppColors.moLight, height: 1.4),
    ),
  );
}

/// 편이 아직 없는 레벨 — 빈 화면 대신.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
    decoration: BoxDecoration(
      color: AppColors.xuanZhiDeep,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.hourglass_empty_rounded, color: AppColors.muted, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(tr('준비 중 — 새 회화가 곧 들어와요. 지금은 아래 레벨부터 읽어 보세요.'), style: const TextStyle(fontSize: 12.5, color: AppColors.moLight, height: 1.4)),
        ),
      ],
    ),
  );
}

/// 「오늘의 컷」 — 마지막으로 열었던 편(없으면 현재 레벨 첫 편)의 장면 컷 + 읽기 시작(시안 02 홈).
class _TodayCut extends StatelessWidget {
  final String level;
  const _TodayCut({required this.level});

  @override
  Widget build(BuildContext context) {
    final svc = DialogueService.instance;
    final last = svc.lastOpenedId != null ? svc.byId(svc.lastOpenedId!) : null;
    final d = last ?? (svc.list(region: level).isNotEmpty ? svc.list(region: level).first : null);
    if (d == null) return const SizedBox.shrink();
    final wide = isWide(context);
    final t = d.turns.first;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tr(last == null ? '오늘의 컷' : '이어서 읽기'),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.copper, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          '${d.emoji} ${d.title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.mo),
        ),
        const SizedBox(height: 2),
        Text('${d.region} · ${tr(DialogueService.islandKo[d.island] ?? d.island)} · ${trf('{0}턴', [d.turns.length])}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 6),
        Text(
          d.scene,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.moLight, height: 1.4),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => openPane(context, (_) => DialogueScreen(dialogue: d)),
          style: FilledButton.styleFrom(backgroundColor: AppColors.copper, foregroundColor: Colors.white, shape: const StadiumBorder(), visualDensity: VisualDensity.compact),
          icon: const Icon(Icons.menu_book_rounded, size: 18),
          label: Text(tr('읽기 시작'), style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
    final cut = SizedBox(
      height: wide ? 180 : 150,
      child: SceneCut(dialogue: d, turn: t, bubble: true),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.xuanZhi,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardShadow,
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: cut),
                const SizedBox(width: 14),
                Expanded(flex: 6, child: info),
              ],
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [cut, const SizedBox(height: 10), info]),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  final String lv;
  final int count;
  const _LevelHeader({required this.lv, required this.count});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
    child: Row(
      children: [
        GradText(lv, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        Text(
          tr(DialogueService.levelKo[lv] ?? lv),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.mo),
        ),
        const SizedBox(width: 8),
        Text(trf('{0}편', [count]), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    ),
  );
}

class _IslandRow extends StatelessWidget {
  final String lv;
  final String island;
  final int count;
  final VoidCallback onTap;
  const _IslandRow({required this.lv, required this.island, required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: AppColors.xuanZhi,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(14),
      boxShadow: kCardShadow,
    ),
    child: Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Text(DialogueService.islandEmoji[island] ?? '💬', style: const TextStyle(fontSize: 26)),
        title: Text(
          tr(DialogueService.islandKo[island] ?? island),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.mo),
        ),
        subtitle: Text(trf('{0}편', [count]), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      ),
    ),
  );
}

/// 주제의 편 목록.
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
        title: Text(
          '${DialogueService.islandEmoji[island] ?? ''} ${tr(DialogueService.islandKo[island] ?? island)} · $region',
          style: const TextStyle(color: AppColors.mo, fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = list[i];
            return Container(
              decoration: BoxDecoration(
                color: AppColors.xuanZhi,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
                boxShadow: kCardShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  onTap: () => openPane(context, (_) => DialogueScreen(dialogue: d)),
                  leading: Text(d.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    d.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.mo),
                  ),
                  subtitle: Text(
                    '${d.isChat ? '💬 ' : ''}${d.scene}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
                  ),
                  trailing: Text(trf('{0}턴', [d.turns.length]), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 편 화면 — 시안 02 만화책 읽기형. 아이패드: 왼쪽 대화 스크립트 + 오른쪽 큰 장면 컷(같은 패널, ▶ 로 순차 재생).
/// 폰: 버블 목록 + 맨 위 「▶ 모든 문장 듣기」(전체 화면 재생).
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

  void _openPlay({int at = 0}) => openFull(context, (_) => _PlayFull(dialogue: d, at: at));

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${d.emoji} ${d.title}',
              style: const TextStyle(color: AppColors.mo, fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text('${d.region} · ${tr(DialogueService.islandKo[d.island] ?? d.island)} · ${d.turns.length}${tr('턴')}', style: const TextStyle(color: AppColors.muted, fontSize: 10, letterSpacing: 1)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr('그림 카드(글자 없이)'),
            icon: const Icon(Icons.style_outlined, color: AppColors.zhuHong),
            onPressed: () => openFull(context, (_) => DialogueCardScreen(dialogue: d)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: wide
            ? EpisodePlayPane(key: ValueKey(d.id), dialogue: d, autoPlay: false)
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _openPlay(),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.copper,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(tr('모든 문장 듣기'), style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                    child: Text(d.scene, style: const TextStyle(fontSize: 12, color: AppColors.moLight, height: 1.4)),
                  ),
                  const WordmarkDivider(height: 2),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context)),
                      itemCount: d.turns.length,
                      itemBuilder: (context, i) => _Bubble(
                        d: d,
                        t: d.turns[i],
                        onPlayFrom: () => _openPlay(at: i),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PlayFull extends StatelessWidget {
  final Dialogue dialogue;
  final int at;
  const _PlayFull({required this.dialogue, required this.at});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.xuanZhi,
    appBar: AppBar(
      title: Text(
        '${dialogue.emoji} ${dialogue.title}',
        style: const TextStyle(color: AppColors.mo, fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    body: SafeArea(
      top: false,
      child: EpisodePlayPane(dialogue: dialogue, initialIndex: at),
    ),
  );
}

class _Bubble extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn t;
  final VoidCallback onPlayFrom;
  const _Bubble({required this.d, required this.t, required this.onPlayFrom});

  @override
  Widget build(BuildContext context) {
    final me = t.speaker == 'A';
    final name = d.speakerName(t.speaker);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!me) _avatar(name),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: me ? AppColors.copper.withValues(alpha: 0.08) : AppColors.xuanZhi,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(me ? 16 : 4),
                  bottomRight: Radius.circular(me ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$name${t.at != null ? ' · ${t.at}' : ''}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => TtsService.instance.speakAs(ttsTextOf(t), gender: LearnerPrefs.voiceGender(t.speaker)),
                        child: const Icon(Icons.volume_up, size: 16, color: AppColors.copper),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onPlayFrom,
                        child: const Icon(Icons.play_circle_outline, size: 16, color: AppColors.zhuHong),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 한자를 누르면 한자 팝업(글자 형성·그림) — 사용자가 좋아한 그 창 그대로
                  SelectableHanziText(
                    text: LearnerPrefs.fill(t.zh),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.mo, height: 1.4),
                  ),
                  if (t.pinyin.isNotEmpty)
                    KoReadingText(
                      LearnerPrefs.fill(t.pinyin),
                      style: const TextStyle(fontSize: 12, color: AppColors.zhuHong, fontWeight: FontWeight.w700),
                    ),
                  if (AppLangPrefs.isKo && t.rd.isNotEmpty) Text(LearnerPrefs.fill(t.rd, ko: true), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 3),
                  Text(LearnerPrefs.fill(t.ko, ko: true), style: const TextStyle(fontSize: 13, color: AppColors.moLight, height: 1.35)),
                  if (t.note.isNotEmpty) ...[const SizedBox(height: 4), Text('💡 ${t.note}', style: const TextStyle(fontSize: 11, color: AppColors.copperDeep, height: 1.35))],
                  if (t.stamp != null) Text(t.stamp!, style: const TextStyle(fontSize: 28)),
                ],
              ),
            ),
          ),
          if (me) _avatar(name),
        ],
      ),
    );
  }

  Widget _avatar(String name) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.xuanZhiDeep,
      child: Text(
        name.isEmpty ? '?' : name.characters.first,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.mo),
      ),
    ),
  );
}
