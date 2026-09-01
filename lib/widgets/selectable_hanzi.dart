import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/cedict_service.dart';
import '../services/hanzi_info_service.dart';
import '../services/pinyin_util.dart';
import '../services/tts_service.dart';
import '../screens/phonetic_roots_screen.dart';
import '../screens/topic_vocab_screen.dart';

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
    await CedictService.instance.ensureLoaded();
    await HanziInfoService.instance.ensureLoaded();
    await VocabCatalog.instance.ensureGloss();
    if (!mounted) return;
    final cedict = CedictService.instance.lookup(text);
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
      builder: (_) => _ChunkInfoSheet(chunk: text, cedict: cedict, chunkData: chunkData),
    );
    if (mounted) setState(() => _focused = null);
  }

  Future<void> _openChar(String char) async {
    await HanziInfoService.instance.ensureLoaded();
    await CedictService.instance.ensureLoaded();
    if (!mounted) return;
    final info = HanziInfoService.instance.lookup(char);
    final cedict = CedictService.instance.lookup(char);
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.xuanZhi,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
      builder: (_) => HanziInfoSheet(char: char, info: info, cedict: cedict),
    );
    if (mounted) setState(() => _focused = null);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.mo,
          height: 1.3,
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

class _ChunkInfoSheet extends StatefulWidget {
  final String chunk;
  final CedictEntry? cedict;
  final Map<String, dynamic>? chunkData;

  const _ChunkInfoSheet({required this.chunk, this.cedict, this.chunkData});

  @override
  State<_ChunkInfoSheet> createState() => _ChunkInfoSheetState();
}

class _ChunkInfoSheetState extends State<_ChunkInfoSheet> {
  Future<void> _openChar(String char) async {
    await HanziInfoService.instance.ensureLoaded();
    await CedictService.instance.ensureLoaded();
    if (!mounted) return;
    final info = HanziInfoService.instance.lookup(char);
    final cedict = CedictService.instance.lookup(char);
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.xuanZhi,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
      builder: (_) => HanziInfoSheet(char: char, info: info, cedict: cedict),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chunk = widget.chunk;
    final cedict = widget.cedict;
    final chunkData = widget.chunkData;
    final pinyin = cedict?.pinyin ?? (chunkData?['pinyin'] as String?);
    final meanings = cedict?.meanings ??
        (chunkData?['meanings'] as List?)?.map((e) => e.toString()).toList() ??
        const [];
    final ko = (chunkData?['ko'] as String?) ??
        VocabCatalog.instance.koFor(chunk);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
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
                        child: const Text(
                          '청크 (词组)',
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
                  const Text(
                    '뜻',
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
                      'CC-CEDICT',
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
                  const Text(
                    '구성 한자 (탭하면 개별 설명)',
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

class HanziInfoSheet extends StatelessWidget {
  final String char;
  final HanziInfo? info;
  final CedictEntry? cedict;

  const HanziInfoSheet({super.key, required this.char, this.info, this.cedict});

  Future<void> _openFamily(BuildContext ctx, String phon, String phonPy, String exclude) async {
    // 발음부 메뉴로 이동 — 해당 발음부 가족 자동 오픈, from 한자 하이라이트.
    // 뒤로가기로 원래 화면 복귀.
    await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => PhoneticRootsScreen(focusRoot: phon, fromChar: exclude),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinyin = cedict?.pinyin;
    final meanings = cedict?.meanings ?? const [];
    final meaning = info?.meaning;
    final phon = info?.phonetic;
    final phonPy = info?.phoneticPinyin;
    final hasPhon = info?.isPhonosemantic ?? false;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.zhuHong,
                    border: Border.all(color: AppColors.jin, width: 1.5),
                  ),
                  child: Text(
                    char,
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      color: AppColors.xuanZhi,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pinyin != null)
                        Text(
                          pinyin,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mo,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.volume_up, size: 16),
                        label: const Text('읽기'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.zhuHong,
                          side: const BorderSide(color: AppColors.zhuHong),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(0, 32),
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: () => TtsService.instance.speak(char),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.mo),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.xuanZhiDeep,
                        border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '뜻',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.zhuHong,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (info?.koHun != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                info!.koHun!,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.zhuHong,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          if (meaning != null)
                            Text(
                              meaning,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mo,
                                height: 1.5,
                              ),
                            )
                          else if (info?.koHun == null)
                            const Text('—',
                                style: TextStyle(fontSize: 14, color: AppColors.moLight)),
                          if (meanings.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'CC-CEDICT',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.moLight,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...meanings.take(3).map((m) => Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    '· ${m.trim()}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.moLight,
                                      height: 1.4,
                                    ),
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.xuanZhiDeep,
                        border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '음·한자 (형성자)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.zhuHong,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (hasPhon) ...[
                            Builder(builder: (ctx) {
                              final phonStr = phon!;
                              final phonPyStr = phonPy!;
                              final family =
                                  HanziInfoService.instance.charsSharing(phonStr).where((c) => c != char).toList();
                              return InkWell(
                                onTap: () => _openFamily(ctx, phonStr, phonPyStr, char),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.zhuHong.withValues(alpha: 0.4),
                                      width: 0.8,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.jin.withValues(alpha: 0.25),
                                          border: Border.all(color: AppColors.jin),
                                        ),
                                        child: Text(
                                          phonStr,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.mo,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              phonPyStr,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.mo,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            const Text(
                                              '발음부 (聲旁)',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: AppColors.moLight,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                            if (family.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  '같은 음 +${family.length}자 →',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    color: AppColors.zhuHong,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            if (info?.semantic != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.feiCui.withValues(alpha: 0.2),
                                      border: Border.all(color: AppColors.feiCui),
                                    ),
                                    child: Text(
                                      info!.semantic!,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.mo,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '형부 (形旁)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.moLight,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ] else
                            const SizedBox(height: 8),
                        ],
                      ),
                    ),
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
    await CedictService.instance.ensureLoaded();
    final info = HanziInfoService.instance.lookup(char);
    final cedict = CedictService.instance.lookup(char);
    if (!ctx.mounted) return;
    Navigator.pop(ctx);
    await showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.xuanZhi,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
      builder: (_) => HanziInfoSheet(char: char, info: info, cedict: cedict),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
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
                      const Text(
                        '발음부 (聲旁) family',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.moLight,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${members.length}자',
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
            const Text(
              '💡 같은 발음부 = 발음 비슷한 경향. 단 한자가 진화하며 일부 음이 변형됨.',
              style: TextStyle(fontSize: 11, color: AppColors.moLight, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedFamily(BuildContext context) {
    // 각 멤버 의 cedict pinyin lookup, phoneticPinyin 과 compare
    final full = <_FamilyMember>[]; // 완전공유
    final partial = <_FamilyMember>[]; // 부분공유 (성조만 다름)
    final shifted = <_FamilyMember>[]; // 일부음차차이

    for (final c in members) {
      final cedict = CedictService.instance.lookup(c);
      final memberPy = cedict?.pinyin ?? '';
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
            title: '완전공유',
            subtitle: '발음·성조 모두 같음',
            color: AppColors.feiCui,
            members: full,
            onTap: (c) => _openChar(context, c),
          ),
        if (partial.isNotEmpty) ...[
          if (full.isNotEmpty) const SizedBox(height: 10),
          _FamilyGroup(
            title: '부분공유',
            subtitle: '음절 같음, 성조만 다름',
            color: AppColors.jin,
            members: partial,
            onTap: (c) => _openChar(context, c),
          ),
        ],
        if (shifted.isNotEmpty) ...[
          if (full.isNotEmpty || partial.isNotEmpty) const SizedBox(height: 10),
          _FamilyGroup(
            title: '일부음차차이',
            subtitle: '음이 변형됨',
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
                '${members.length}자',
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
