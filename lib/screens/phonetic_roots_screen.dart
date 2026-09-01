import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/cedict_service.dart';
import '../services/hanzi_info_service.dart';
import '../services/pinyin_util.dart';
import '../widgets/chinese_decor.dart';
import '../widgets/selectable_hanzi.dart';

/// 발음부(声旁) 탐색 — HSK1-5 실데이터.
/// 카드를 탭하면 그 발음부를 공유하는 한자 가족 시트가 열린다.
class PhoneticRootsScreen extends StatefulWidget {
  /// [focusRoot]가 있으면 진입 시 해당 발음부 가족 시트를 자동으로 연다.
  /// [fromChar]는 어떤 한자에서 이동해 왔는지 표시(가족에서 하이라이트).
  final String? focusRoot;
  final String? fromChar;
  const PhoneticRootsScreen({super.key, this.focusRoot, this.fromChar});

  @override
  State<PhoneticRootsScreen> createState() => _PhoneticRootsScreenState();
}

class _PhoneticRootsScreenState extends State<PhoneticRootsScreen> {
  bool _loading = true;
  List<PhoneticRootInfo> _roots = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await HanziInfoService.instance.ensureLoaded();
    await CedictService.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _roots = HanziInfoService.instance.allRoots;
      _loading = false;
    });
    // focusRoot 자동 오픈 (from 한자 하이라이트)
    final focus = widget.focusRoot;
    if (focus != null) {
      final root = _roots.where((r) => r.root == focus).firstOrNull ??
          PhoneticRootInfo(
              root: focus,
              pinyin: CedictService.instance.lookup(focus)?.pinyin ?? '',
              count: HanziInfoService.instance.charsSharing(focus).length);
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openFamily(root, highlight: widget.fromChar ?? ''));
    }
  }

  List<PhoneticRootInfo> get _filtered {
    if (_query.isEmpty) return _roots;
    final q = _query.trim().toLowerCase();
    return _roots.where((r) {
      if (r.root.contains(q)) return true;
      if (r.ko != null && r.ko!.contains(q)) return true;
      final basePy = PinyinUtil.stripTones(
          PinyinUtil.toTonedPinyin(r.pinyin));
      return basePy.contains(q);
    }).toList();
  }

  Future<void> _openFamily(PhoneticRootInfo root, {String highlight = ''}) async {
    final members = <String>[
      root.root,
      ...HanziInfoService.instance.charsSharing(root.root)
        ..sort(),
    ];
    final toned = PinyinUtil.toTonedPinyin(root.pinyin);
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.xuanZhi,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          child: PhoneticFamilySheet(
            phonetic: root.root,
            phoneticPinyin: toned,
            members: members,
            highlight: highlight,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _roots.fold(0, (s, r) => s + r.count);
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        backgroundColor: AppColors.xuanZhi,
        foregroundColor: AppColors.mo,
        elevation: 0,
        centerTitle: true,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('발음부 + 한국 한자음',
                style: TextStyle(
                    color: AppColors.mo, fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('声旁 · HSK 1-5',
                style: TextStyle(
                    color: AppColors.moLight, fontSize: 10, letterSpacing: 2)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.zhuHong))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.mo),
                    decoration: InputDecoration(
                      hintText: '马 · ma · 마',
                      hintStyle:
                          const TextStyle(color: AppColors.moLight, fontSize: 14),
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.zhuHong),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.xuanZhiDeep,
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppColors.jin),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide:
                            BorderSide(color: AppColors.zhuHong, width: 1.5),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const SealStamp(text: '声旁', size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '발음부 ${_roots.length}개 · 한자 $total자 커버',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mo,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '탭 → 한자 가족',
                        style: TextStyle(fontSize: 10, color: AppColors.moLight),
                      ),
                    ],
                  ),
                ),
                const GreekKeyDivider(height: 8),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.9,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final r = _filtered[i];
                      return _RootCard(
                        root: r,
                        onTap: () => _openFamily(r),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _RootCard extends StatelessWidget {
  final PhoneticRootInfo root;
  final VoidCallback onTap;
  const _RootCard({required this.root, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final toned = PinyinUtil.toTonedPinyin(root.pinyin);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.xuanZhi,
        border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SealStamp(text: root.root, size: 48, color: AppColors.zhuHong),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      toned,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.mo,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (root.ko != null)
                      Text(
                        '${root.ko}(${root.root})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.moLight,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.jin.withValues(alpha: 0.2),
                        border: Border.all(color: AppColors.jin),
                      ),
                      child: Text(
                        '가족 ${root.count}자',
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.mo,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.moLight, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
