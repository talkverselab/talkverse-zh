import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/achievement_service.dart';
import '../services/art_service.dart';
import '../services/content_sync.dart';
import '../services/lexicon_service.dart';
import '../services/hanzi_family.dart';
import '../services/hanzi_info_service.dart';
import '../services/pinyin_util.dart';
import '../services/shared_hanja_service.dart';
import '../services/tts_service.dart';
import '../screens/family_hanzi_screen.dart';
import '../screens/phonetic_roots_screen.dart';
import '../screens/topic_vocab_screen.dart';
import '../core/platform.dart';
import '../core/l10n.dart';
import 'tone_pinyin.dart';

/// 문장 내 청크·한자를 탭하면 정보 모달 띄움. tokens 기반 (서버 토크나이즈).
class SelectableHanziText extends StatefulWidget {
  final String text;
  final List<dynamic>? tokens; // [{text, compound}]
  final Map<String, dynamic>? chunks; // chunk dict
  final TextStyle? style;
  final String? highlightText; // 이 텍스트와 같은 토큰을 강조 (검색 결과용)

  const SelectableHanziText({
    super.key,
    required this.text,
    this.tokens,
    this.chunks,
    this.style,
    this.highlightText,
  });

  @override
  State<SelectableHanziText> createState() => _SelectableHanziTextState();
}

class _SelectableHanziTextState extends State<SelectableHanziText> {
  int? _focused;

  bool _isCjk(String c) {
    if (c.isEmpty) return false;
    final code = c.codeUnitAt(0);
    return code >= 0x4E00 && code <= 0x9FFF;
  }

  Future<void> _openChunk(String text) async {
    await LexiconService.instance.ensureLoaded();
    await HanziInfoService.instance.ensureLoaded();
    await VocabCatalog.instance.ensureGloss();
    if (!mounted) return;
    final lex = LexiconService.instance.lookup(text);
    Map<String, dynamic>? chunkData;
    if (widget.chunks != null) {
      final raw = widget.chunks![text];
      if (raw is Map<String, dynamic>) chunkData = raw;
    }
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.xuanZhi,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
      builder: (_) => _ChunkInfoSheet(chunk: text, lex: lex, chunkData: chunkData),
    );
    if (mounted) setState(() => _focused = null);
  }

  Future<void> _openChar(String char) async {
    await showHanziSheet(context, char);
    if (mounted) setState(() => _focused = null);
  }

  @override
  Widget build(BuildContext context) {
    // 중국어 본문은 NotoSansSC — 글꼴을 따로 주지 않았으면 여기서 입힌다(가변 글꼴 굵기 포함).
    final given = widget.style ?? AppFonts.zhText(size: 20, weight: FontWeight.w600, height: 1.3);
    final style = given.fontFamily != null
        ? given
        : given.copyWith(
            fontFamily: AppFonts.zh,
            fontFamilyFallback: const [AppFonts.ui],
            fontVariations: [FontVariation.weight((given.fontWeight ?? FontWeight.w400).value.toDouble())],
          );

    // tokens 우선, 없으면 각 char 로 fallback
    final tokens = widget.tokens ??
        widget.text.characters.map((c) => {'text': c, 'compound': false}).toList();

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(tokens.length, (i) {
        final t = tokens[i] as Map;
        final txt = t['text'] as String? ?? '';
        final compound = (t['compound'] as bool?) ?? false;
        if (txt.isEmpty || (!compound && !_isCjk(txt))) {
          return Text(txt, style: style);
        }
        final focused = _focused == i;
        final highlighted = widget.highlightText != null && txt == widget.highlightText;
        return Material(
          color: focused
              ? (compound ? AppColors.jin.withValues(alpha: 0.25) : AppColors.zhuHong.withValues(alpha: 0.18))
              : (highlighted ? AppColors.jin.withValues(alpha: 0.3) : Colors.transparent),
          child: InkWell(
            onTap: () {
              setState(() => _focused = i);
              if (compound) {
                _openChunk(txt);
              } else {
                _openChar(txt);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
              decoration: compound
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.jin.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                    )
                  : null,
              child: Text(
                txt,
                style: style.copyWith(
                  color: focused ? AppColors.zhuHong : style.color,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// 단어(청크) 정보 시트를 바깥(레마 칩 등)에서 연다 — 앱 사전에 없으면 넘겨 준 병음만 보인다(2026-11-04).
Future<void> showChunkSheet(BuildContext context, String word, {String? pinyin}) async {
  await LexiconService.instance.ensureLoaded();
  await HanziInfoService.instance.ensureLoaded();
  await VocabCatalog.instance.ensureGloss();
  if (!context.mounted) return;
  final lex = LexiconService.instance.lookup(word);
  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.xuanZhi,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(2))),
    builder: (_) => _ChunkInfoSheet(chunk: word, lex: lex, chunkData: lex == null && pinyin != null && pinyin.isNotEmpty ? {'pinyin': pinyin} : null),
  );
}

class _ChunkInfoSheet extends StatefulWidget {
  final String chunk;
  final LexEntry? lex;
  final Map<String, dynamic>? chunkData;

  const _ChunkInfoSheet({required this.chunk, this.lex, this.chunkData});

  @override
  State<_ChunkInfoSheet> createState() => _ChunkInfoSheetState();
}

class _ChunkInfoSheetState extends State<_ChunkInfoSheet> {
  Future<void> _openChar(String char) => showHanziSheet(context, char);

  @override
  Widget build(BuildContext context) {
    final chunk = widget.chunk;
    final lex = widget.lex;
    final chunkData = widget.chunkData;
    final rawPy = lex?.pinyin ?? (chunkData?['pinyin'] as String?);
    final pinyin = rawPy == null ? null : PinyinUtil.toTonedPinyin(rawPy);
    final meanings = lex?.meanings ??
        (chunkData?['meanings'] as List?)?.map((e) => e.toString()).toList() ??
        const [];
    final ko = (chunkData?['ko'] as String?) ??
        VocabCatalog.instance.koFor(chunk);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.jin,
                    border: Border.all(color: AppColors.jinDeep, width: 1.5),
                  ),
                  child: Text(
                    chunk,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mo,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.jin.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.jin),
                        ),
                        child: Text(
                          tr('청크 (词组)'),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.mo,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      if (pinyin != null && pinyin.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          pinyin,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mo,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: AppColors.zhuHong),
                  onPressed: () => TtsService.instance.speak(chunk),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.mo),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.xuanZhiDeep,
                border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('뜻'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.zhuHong,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (ko != null)
                    Text(
                      ko,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mo,
                        height: 1.5,
                      ),
                    ),
                  if (meanings.isNotEmpty) ...[
                    if (ko != null) const SizedBox(height: 10),
                    const Text(
                      '앱 사전',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.moLight,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...meanings.take(4).map((m) => Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '· ${m.trim()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mo,
                              height: 1.4,
                            ),
                          ),
                        )),
                  ],
                  if (ko == null && meanings.isEmpty)
                    const Text('—', style: TextStyle(color: AppColors.moLight)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 구성 한자 (각각 탭 가능)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.xuanZhi,
                border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('구성 한자 (탭하면 개별 설명)'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.zhuHong,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chunk.characters.map((c) {
                      final info = HanziInfoService.instance.lookup(c);
                      final hun = info?.koHun;
                      final phon = info?.phonetic;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _openChar(c),
                            child: Container(
                              width: 56,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.zhuHong.withValues(alpha: 0.1),
                                border:
                                    Border.all(color: AppColors.zhuHong, width: 1),
                              ),
                              child: Text(
                                c,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.zhuHong,
                                ),
                              ),
                            ),
                          ),
                          if (hun != null)
                            SizedBox(
                              width: 62,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  hun,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 9, color: AppColors.mo),
                                ),
                              ),
                            ),
                          if (phon != null)
                            InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PhoneticRootsScreen(
                                      focusRoot: phon, fromChar: c),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.jin.withValues(alpha: 0.2),
                                  border: Border.all(color: AppColors.jin),
                                ),
                                child: Text(
                                  '声旁 $phon →',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.jinDeep,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 한자 한 글자 정보 — 시안 zh05 「넓은 시트 한 장」(2026-11-03).
/// 첫 화면 = 큰 자형 + 성조 색 병음 + 뜻 + 발음부 가족 한 줄(같은 소리 = 구리 테두리, 다른 소리 = 테두리 없음; 누르면 「패밀리 한자」).
/// 「자세히」를 펼치면 형부·앱 사전·공용 DB 그림·외우는 방법·쓰기 범위·발음부 메뉴. 팝업([HanziInfoSheet])과 「한자 배우기」 화면이 같이 쓴다.
class HanziInfoBody extends StatefulWidget {
  final String char;
  final HanziInfo? info;
  final LexEntry? lex;
  final bool showClose; // 팝업이면 닫기 단추
  final bool initiallyExpanded; // 「자세히」를 펼친 채로 시작(한자 배우기)

  const HanziInfoBody({super.key, required this.char, this.info, this.lex, this.showClose = true, this.initiallyExpanded = false});

  @override
  State<HanziInfoBody> createState() => _HanziInfoBodyState();
}

class _HanziInfoBodyState extends State<HanziInfoBody> {
  late bool _more = widget.initiallyExpanded;

  void _openFamily(String phon) => Navigator.push(context, MaterialPageRoute(builder: (_) => FamilyHanziScreen(focus: phon)));

  @override
  Widget build(BuildContext context) {
    final char = widget.char;
    final info = widget.info;
    final lex = widget.lex;
    final pinyin = (lex?.pinyin.isNotEmpty ?? false) ? lex!.pinyin : pinyinOf(char);
    final meanings = lex?.meanings ?? const [];
    final hun = info?.koHun;
    final meaning = info?.meaning;
    final family = familyFor(char);
    final phonPy = family == null ? '' : pinyinOf(family.phonetic);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Spacer(),
          IconButton(
            tooltip: tr('읽기'),
            icon: const Icon(Icons.volume_up_outlined, color: AppColors.muted, size: 22),
            onPressed: () => TtsService.instance.speak(char),
          ),
          if (widget.showClose)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.muted, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
        ]),
        Center(child: Text(char, style: AppFonts.glyphText(size: AppFonts.glyphBig))),
        if (pinyin.isNotEmpty) ...[
          const SizedBox(height: 6),
          Center(child: TonePinyinText(pinyin, size: 16, textAlign: TextAlign.center)),
        ],
        const SizedBox(height: 8),
        if (hun != null) Center(child: Text(hun, textAlign: TextAlign.center, style: AppFonts.uiText(size: 15, weight: FontWeight.w600, color: AppColors.mo))),
        if (meaning != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(meaning, textAlign: TextAlign.center, style: AppFonts.uiText()),
          )
        else if (hun == null && meanings.isNotEmpty)
          Text(meanings.first.trim(), textAlign: TextAlign.center, style: AppFonts.uiText()),
        if (family != null) ...[
          const SizedBox(height: 22),
          HanziFamilyStrip(
            phonetic: family.phonetic,
            phoneticPinyin: phonPy,
            chars: family.row(char),
            current: char,
            total: family.members.length + 1,
            pinyinOf: pinyinOf,
            onOpen: () => _openFamily(family.phonetic),
          ),
        ],
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _more = !_more),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted, textStyle: AppFonts.captionText()),
            icon: Icon(_more ? Icons.expand_less : Icons.expand_more, size: 18),
            label: Text(_more ? tr('접기') : tr('자세히')),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: !_more
              ? const SizedBox(width: double.infinity)
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (info?.semantic != null || info?.phonetic != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Wrap(spacing: 18, runSpacing: 6, children: [
                        if (info?.semantic != null) _part(info!.semantic!, tr('형부 (形旁)')),
                        if (info?.phonetic != null)
                          _part(info!.phonetic!, info.estimated == true ? '${tr('발음부 (聲旁)')} · ${tr('추정')}' : tr('발음부 (聲旁)'),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PhoneticRootsScreen(focusRoot: info.phonetic!, fromChar: char)))),
                      ]),
                    ),
                  if (meanings.isNotEmpty) ...[
                    Text(tr('앱 사전'), style: AppFonts.captionText()),
                    const SizedBox(height: 2),
                    for (final m in meanings.take(3)) Text('· ${m.trim()}', style: AppFonts.uiText(size: 13)),
                  ],
                  _SharedHanjaCard(char: char),
                ]),
        ),
      ],
    );
  }

  Widget _part(String ch, String label, {VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(ch, style: AppFonts.glyphText(size: 22)),
            const SizedBox(width: 6),
            Text(label, style: AppFonts.captionText()),
            if (onTap != null) const Icon(Icons.chevron_right, size: 14, color: AppColors.muted),
          ]),
        ),
      );
}

/// 발음부 가족 한 줄 — 발음부 + 구성원. 같은 소리(음절 같음) = 구리 테두리, 다른 소리 = 테두리 없음.
/// 줄 어디를 눌러도 [onOpen](「패밀리 한자」 그 가족).
class HanziFamilyStrip extends StatelessWidget {
  final String phonetic;
  final String phoneticPinyin;
  final List<String> chars; // 발음부 포함, 한 줄
  final String current;
  final int total;
  final String Function(String) pinyinOf;
  final VoidCallback onOpen;
  const HanziFamilyStrip({
    super.key,
    required this.phonetic,
    required this.phoneticPinyin,
    required this.chars,
    required this.current,
    required this.total,
    required this.pinyinOf,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(trf('발음부 {0} 가족', [phonetic]), style: AppFonts.captionText(weight: FontWeight.w600, color: AppColors.moLight)),
            const SizedBox(width: 6),
            Text(trf('{0}자', [total]), style: AppFonts.captionText()),
            const Spacer(),
            Text(tr('패밀리 한자'), style: AppFonts.captionText(color: AppColors.copper)),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.copper),
          ]),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final c in chars)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FamilyGlyphTile(
                    key: ValueKey('fam-$c'),
                    ch: c,
                    pinyin: pinyinOf(c),
                    sameSound: c != phonetic && sameSound(pinyinOf(c), phoneticPinyin),
                    current: c == current,
                    root: c == phonetic,
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// 가족 한 글자 타일 — 큰 자형 + 성조 색 병음. 같은 소리면 구리 테두리.
class FamilyGlyphTile extends StatelessWidget {
  final String ch;
  final String pinyin;
  final bool sameSound;
  final bool current;
  final bool root;
  final VoidCallback? onTap;
  const FamilyGlyphTile({super.key, required this.ch, required this.pinyin, required this.sameSound, this.current = false, this.root = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: 54,
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 5),
      decoration: BoxDecoration(
        color: current ? AppColors.copper.withValues(alpha: 0.08) : null,
        border: sameSound ? Border.all(color: AppColors.copper, width: 1.4) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(ch, style: AppFonts.glyphText(size: AppFonts.glyphTile, color: root ? AppColors.copperDeep : AppColors.mo)),
        const SizedBox(height: 2),
        TonePinyinText(pinyin.isEmpty ? '·' : pinyin, size: 10.5, maxLines: 1),
      ]),
    );
    if (onTap == null) return tile;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: tile);
  }
}

/// 한자 팝업(바닥 시트). 내용은 [HanziInfoBody]. 넓은 화면에서도 가운데 한 장(최대 640).
class HanziInfoSheet extends StatelessWidget {
  final String char;
  final HanziInfo? info;
  final LexEntry? lex;

  const HanziInfoSheet({super.key, required this.char, this.info, this.lex});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.sizeOf(context).height * 0.85),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset(context)),
              child: HanziInfoBody(char: char, info: info, lex: lex),
            ),
          ),
        ),
      );
}

/// 한자 팝업 열기 — 사전·글자 정보를 읽고, 성과(팝업으로 본 한자)를 남긴다. 앱의 한자 팝업은 이것 하나.
Future<void> showHanziSheet(BuildContext context, String char) async {
  await HanziInfoService.instance.ensureLoaded();
  await LexiconService.instance.ensureLoaded();
  if (!context.mounted) return;
  AchievementService.instance.markHanziSeen(char);
  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.xuanZhi,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => HanziInfoSheet(
      char: char,
      info: HanziInfoService.instance.lookup(char),
      lex: LexiconService.instance.lookup(char),
    ),
  );
}

/// 한자 공용 DB 에서 받은 그림(모핑 GIF 또는 楷書 글자)·외우는 방법·쓰기 범위.
/// 받은 것이 없으면 그 한자를 품은 단어 그림(공용 그림 DB)으로 대신하고, 그것도 없으면 아무것도 그리지 않는다.
class _SharedHanjaCard extends StatelessWidget {
  final String char;
  const _SharedHanjaCard({required this.char});

  @override
  Widget build(BuildContext context) {
    final idx = SharedHanjaService.instance.index;
    final h = idx.lookup(char);
    if (h == null) return const SizedBox.shrink();
    final image = h.gifUrl ?? h.bCutUrl;
    final mn = idx.mnemonicFor(h, AppLangPrefs.isEn ? 'en' : 'ko');
    final write = switch (h.hskW) {
      1 => tr('쓰기 · HSK 초등'),
      2 => tr('쓰기 · HSK 중등'),
      3 => tr('쓰기 · HSK 고등'),
      _ => null,
    };
    if (image == null && mn == null && write == null) return _HanziWordArt(ch: char);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.xuanZhiDeep,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null) ...[
              SizedBox(
                width: 88,
                height: 88,
                child: Image(
                  image: artProvider(image),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(tr('외우는 방법'), style: AppFonts.captionText(weight: FontWeight.w600, color: AppColors.copper)),
                      const Spacer(),
                      if (write != null)
                        Text(write, style: AppFonts.captionText(size: 11, color: AppColors.feiCui)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (mn?.tip != null && mn!.tip!.isNotEmpty)
                    Text(mn.tip!, style: AppFonts.uiText(size: 14, weight: FontWeight.w600, color: AppColors.mo, height: 1.5)),
                  if (mn?.origin != null && mn!.origin!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(mn.origin!, style: AppFonts.uiText(size: 12.5, height: 1.5)),
                    ),
                  if (mn == null)
                    Text(
                      tr('준비 중'),
                      style: const TextStyle(fontSize: 12, color: AppColors.moLight),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneticFamilySheet extends StatelessWidget {
  final String phonetic;
  final String phoneticPinyin;
  final List<String> members;
  final String highlight;

  const PhoneticFamilySheet({
    super.key,
    required this.phonetic,
    required this.phoneticPinyin,
    required this.members,
    required this.highlight,
  });

  Future<void> _openChar(BuildContext ctx, String char) async {
    await HanziInfoService.instance.ensureLoaded();
    await LexiconService.instance.ensureLoaded();
    final info = HanziInfoService.instance.lookup(char);
    final lex = LexiconService.instance.lookup(char);
    if (!ctx.mounted) return;
    Navigator.pop(ctx);
    await showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.xuanZhi,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
      builder: (_) => HanziInfoSheet(char: char, info: info, lex: lex),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.jin,
                    border: Border.all(color: AppColors.jinDeep, width: 2),
                  ),
                  child: Text(
                    phonetic,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mo,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phoneticPinyin,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.mo,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('발음부 (聲旁) family'),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.moLight,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trf('{0}자', [members.length]),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.zhuHong,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: AppColors.zhuHong),
                  onPressed: () => TtsService.instance.speak(phonetic),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.mo),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildGroupedFamily(context),
            const SizedBox(height: 10),
            Text(
              tr('💡 같은 발음부 = 발음 비슷한 경향. 단 한자가 진화하며 일부 음이 변형됨.'),
              style: TextStyle(fontSize: 11, color: AppColors.moLight, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedFamily(BuildContext context) {
    // 각 멤버 의 lex pinyin lookup, phoneticPinyin 과 compare
    final full = <_FamilyMember>[]; // 완전공유
    final partial = <_FamilyMember>[]; // 부분공유 (성조만 다름)
    final shifted = <_FamilyMember>[]; // 일부음차차이

    for (final c in members) {
      final lex = LexiconService.instance.lookup(c);
      final memberPy = lex?.pinyin ?? '';
      final mem = _FamilyMember(
        char: c,
        pinyin: memberPy,
        info: HanziInfoService.instance.lookup(c),
        isPhoneticRoot: c == phonetic,
        isCurrent: c == highlight,
      );
      if (memberPy.isEmpty) {
        shifted.add(mem);
        continue;
      }
      final lv = PinyinUtil.compareLevel(memberPy, phoneticPinyin);
      if (lv == 0) {
        full.add(mem);
      } else if (lv == 1) {
        partial.add(mem);
      } else {
        shifted.add(mem);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (full.isNotEmpty)
          _FamilyGroup(
            title: tr('완전공유'),
            subtitle: tr('발음·성조 모두 같음'),
            color: AppColors.feiCui,
            members: full,
            onTap: (c) => _openChar(context, c),
          ),
        if (partial.isNotEmpty) ...[
          if (full.isNotEmpty) const SizedBox(height: 10),
          _FamilyGroup(
            title: tr('부분공유'),
            subtitle: tr('음절 같음, 성조만 다름'),
            color: AppColors.jin,
            members: partial,
            onTap: (c) => _openChar(context, c),
          ),
        ],
        if (shifted.isNotEmpty) ...[
          if (full.isNotEmpty || partial.isNotEmpty) const SizedBox(height: 10),
          _FamilyGroup(
            title: tr('일부음차차이'),
            subtitle: tr('음이 변형됨'),
            color: AppColors.zhuHong,
            members: shifted,
            onTap: (c) => _openChar(context, c),
          ),
        ],
      ],
    );
  }
}

class _FamilyMember {
  final String char;
  final String pinyin;
  final HanziInfo? info;
  final bool isPhoneticRoot;
  final bool isCurrent;
  _FamilyMember({
    required this.char,
    required this.pinyin,
    required this.info,
    required this.isPhoneticRoot,
    required this.isCurrent,
  });
}

class _FamilyGroup extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final List<_FamilyMember> members;
  final void Function(String) onTap;

  const _FamilyGroup({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.members,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.xuanZhiDeep,
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: color,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.xuanZhi,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.moLight,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                trf('{0}자', [members.length]),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: members.map((m) => _FamilyTile(member: m, color: color, onTap: () => onTap(m.char))).toList(),
          ),
        ],
      ),
    );
  }
}

class _FamilyTile extends StatelessWidget {
  final _FamilyMember member;
  final Color color;
  final VoidCallback onTap;
  const _FamilyTile({required this.member, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meaning = member.info?.meaning ?? member.info?.koHun;
    final shortMeaning = (meaning ?? '').split(RegExp(r'[·,()(]')).first.trim();
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: member.isCurrent
              ? AppColors.zhuHong
              : (member.isPhoneticRoot ? color.withValues(alpha: 0.18) : AppColors.xuanZhi),
          border: Border.all(
            color: member.isCurrent ? AppColors.zhuHongDeep : color.withValues(alpha: 0.5),
            width: member.isCurrent ? 1.5 : 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  member.char,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: member.isCurrent ? AppColors.xuanZhi : AppColors.mo,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 3),
                InkWell(
                  onTap: () => TtsService.instance.speak(member.char),
                  child: Icon(
                    Icons.volume_up,
                    size: 15,
                    color: member.isCurrent
                        ? AppColors.jinBright
                        : AppColors.zhuHong.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              member.pinyin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: member.isCurrent ? AppColors.jinBright : color,
              ),
            ),
            const SizedBox(height: 1),
            SizedBox(
              height: 12,
              child: Text(
                shortMeaning,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: member.isCurrent
                      ? AppColors.xuanZhi.withValues(alpha: 0.85)
                      : AppColors.moLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 한자 그림이 없을 때: 그 한자를 품은 가장 흔한 단어의 그림(talkverse.uk 공용 단어 그림, 일본어앱과 같은 방식).
class _HanziWordArt extends StatelessWidget {
  final String ch;
  const _HanziWordArt({required this.ch});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MapEntry<String, String>?>(
      future: ArtService.instance.wordArtForHanzi(ch),
      builder: (context, snap) {
        final e = snap.data;
        if (e == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260, maxHeight: 200),
                  child: Image(image: artProvider(e.value), fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                ),
              ),
              const SizedBox(height: 4),
              Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.mo)),
            ]),
          ),
        );
      },
    );
  }
}
