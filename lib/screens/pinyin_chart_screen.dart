import 'dart:async';

import 'package:flutter/material.dart';
import '../core/embed_env.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/pinyin_phonetics.dart';
import '../services/tts_service.dart';

/// 「병음과 발음」 — 일본어앱 「50음도와 발음」(kana_chart_screen) 과 같은 짜임(2026-11-08, 공통 프롬프터 §5-3).
/// 탭 성모 21 · 운모 36 · 성조 → 묶음 칩(소리 나는 곳별) → 네모 격자. 보조 표기(한글 근사·예시 한자)는 앱바 「拼」 전역 토글.
/// 글자 탭 = 발음 시트(1초 뒤 자동 재생 · 다시 듣기 · IPA · 소리 나는 곳 · 조음 위치 그림 · 한국어와 비교).
class PinyinChartScreen extends StatefulWidget {
  const PinyinChartScreen({super.key});

  @override
  State<PinyinChartScreen> createState() => _PinyinChartScreenState();
}

class _PinyinChartScreenState extends State<PinyinChartScreen> {
  int _tab = 0; // 0 성모 · 1 운모 · 2 성조
  int _group = -1; // -1 = 전체

  static const _colors = [AppColors.zhuHong, AppColors.copper, AppColors.feiCui, AppColors.tone2, AppColors.hanyu, AppColors.jinDeep];
  static const _toneColors = [AppColors.tone1, AppColors.tone2, AppColors.tone3, AppColors.tone4, AppColors.muted];

  List<PyGroup> get _groups => [pyInitials, pyFinals, pyTones][_tab];

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    final shown = _group < 0 || _group >= groups.length ? List.generate(groups.length, (i) => i) : [_group];
    final cols = (MediaQuery.sizeOf(context).width ~/ 96).clamp(3, 8);
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: Text(tr('병음과 발음')),
        actions: const [KoReadingToggleAction(), SizedBox(width: 4)],
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(value: 0, label: Text(tr('성모 21'))),
                ButtonSegment(value: 1, label: Text(tr('운모 36'))),
                ButtonSegment(value: 2, label: Text(tr('성조'))),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() {
                _tab = s.first;
                _group = -1;
              }),
            ),
          ),
          if (groups.length > 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                children: [
                  for (var i = -1; i < groups.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        selected: _group == i,
                        showCheckmark: false,
                        label: Text(i < 0 ? tr('전체') : tr(groups[i].name),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _group == i ? AppColors.xuanZhi : AppColors.mo)),
                        selectedColor: i < 0 ? AppColors.mo : _colors[i % _colors.length],
                        backgroundColor: AppColors.xuanZhiDeep,
                        side: BorderSide(color: AppColors.line),
                        onSelected: (_) => setState(() => _group = i),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 24 + bottomInset(context)),
              children: [
                for (final gi in shown) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 12, 2, 6),
                    child: Row(children: [
                      Text(tr(groups[gi].name), style: AppFonts.uiText(size: 13.5, weight: FontWeight.w600, color: AppColors.mo)),
                      const SizedBox(width: 8),
                      Text(groups[gi].hint, style: AppFonts.pinyinText(size: 12)),
                    ]),
                  ),
                  GridView.count(
                    crossAxisCount: _tab == 2 ? 5.clamp(3, cols) : cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.9,
                    children: [
                      for (var k = 0; k < groups[gi].items.length; k++)
                        _Tile(
                          s: groups[gi].items[k],
                          color: _tab == 2 ? _toneColors[k] : _colors[gi % _colors.length],
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  _tab == 2
                      ? tr('같은 ma 도 성조가 바뀌면 다른 낱말이에요: 妈 엄마 · 麻 삼베 · 马 말 · 骂 꾸짖다 · 吗 의문 조사.')
                      : tr('무기음(b d g j zh z)은 바람 없이 ㄲ·ㄸ·ㅃ에 가깝고, 유기음(p t k q ch c)은 바람을 세게 냅니다.'),
                  style: AppFonts.captionText(size: 12),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final PySound s;
  final Color color;
  const _Tile({required this.s, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showPinyinSoundSheet(context, s, color),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.45))),
          padding: const EdgeInsets.all(4),
          child: ValueListenableBuilder<bool>(
            valueListenable: KoReadingPrefs.show,
            builder: (_, aid, _) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s.py, style: AppFonts.pinyinText(size: s.py.length > 3 ? 18 : 22, weight: FontWeight.w600, color: color)),
              const SizedBox(height: 2),
              if (aid) ...[
                Text(s.hangul, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.captionText(size: 11, color: AppColors.moLight)),
                Text('${s.ex} ${s.exPy}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.zhText(size: 11, color: AppColors.muted)),
              ] else
                Text(s.ex, style: AppFonts.zhText(size: 14, color: AppColors.muted)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 병음 하나의 발음 시트 — 열리면 1초 뒤 예시 한자를 읽는다.
Future<void> showPinyinSoundSheet(BuildContext context, PySound s, Color color) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.xuanZhi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _SoundSheet(s: s, color: color),
    );

class _SoundSheet extends StatefulWidget {
  final PySound s;
  final Color color;
  const _SoundSheet({required this.s, required this.color});

  @override
  State<_SoundSheet> createState() => _SoundSheetState();
}

class _SoundSheetState extends State<_SoundSheet> {
  Timer? _auto;
  bool _chart = false;

  void _play() => TtsService.instance.speak(widget.s.ex);

  @override
  void initState() {
    super.initState();
    _auto = Timer(const Duration(seconds: 1), _play);
  }

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s, c = widget.color;
    final tone = RegExp(r'^\d+$').hasMatch(s.ipa) || s.ipa == '경성';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => SafeArea(
        top: false,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset(context)),
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
                child: Text(s.py, style: AppFonts.pinyinText(size: s.py.length > 3 ? 26 : 34, weight: FontWeight.w600, color: AppColors.xuanZhi)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s.ex}  ${s.exPy}', style: AppFonts.zhText(size: 22, weight: FontWeight.w600, color: c)),
                  const SizedBox(height: 4),
                  Text(tone ? trf('성조값 {0}', [s.ipa]) : 'IPA [${s.ipa}]', style: AppFonts.uiText(size: 15, weight: FontWeight.w600, color: AppColors.mo)),
                  Text(trf('한글 근사: {0}', [s.hangul]), style: AppFonts.captionText(size: 12)),
                ]),
              ),
              IconButton(iconSize: 44, color: c, tooltip: tr('다시 듣기'), icon: const Icon(Icons.play_circle_fill), onPressed: _play),
            ]),
            const SizedBox(height: 20),
            _box(tr('👄 소리 나는 곳 · 입모양'), s.place, c),
            if (s.consonant) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _chart = !_chart),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Icon(_chart ? Icons.expand_less : Icons.expand_more, size: 18, color: c),
                    Text(tr('자음 조음 위치 그림 보기'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
                  ]),
                ),
              ),
              if (_chart) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(color: Colors.white, padding: const EdgeInsets.all(8), child: Image.asset(assetPath('assets/images/ipa/places_of_articulation.png'), fit: BoxFit.contain)),
                ),
              ],
            ],
            const SizedBox(height: 14),
            _box(tr('🇰🇷 한국어와 비교'), s.diff.isEmpty ? trf('비슷한 소리: {0}', [s.ko]) : trf('비슷한 소리: {0}\n\n{1}', [s.ko, s.diff]), c),
          ],
        ),
      ),
    );
  }

  Widget _box(String title, String body, Color c) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.xuanZhiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.35))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 8),
          Text(body, style: AppFonts.uiText(size: 13.5, color: AppColors.mo, height: 1.55)),
        ]),
      );
}
