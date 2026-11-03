import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/learner_prefs.dart';

bool _askedThisRun = false;

/// 회화에 `{name}` 자리가 있는데 학습자 이름이 비어 있으면 이름·성별을 묻는 작은 창(사용자 지시 2026-11-04
/// "○○ 로 나오는 건 고쳐 주든지 팝업 띄워서 설정하게"). 앱을 켠 뒤 한 번만 묻고, 「나중에」면 ○○ 그대로.
Future<void> ensureLearnerName(BuildContext context, {required bool needed}) async {
  if (!needed || _askedThisRun || LearnerPrefs.name.value.isNotEmpty) return;
  _askedThisRun = true;
  final c = TextEditingController();
  var gender = LearnerPrefs.gender.value;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: AppColors.xuanZhi,
        title: Text(tr('회화 속 「나」 이름'), style: AppFonts.titleText(size: 17)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('대사의 ○○ 자리에 들어갑니다. 「나」 탭에서 언제든 바꿀 수 있어요.'), style: AppFonts.uiText(size: 12.5, color: AppColors.moLight)),
          const SizedBox(height: 12),
          TextField(controller: c, maxLength: 20, autofocus: true, decoration: InputDecoration(hintText: tr('이름 (예: 민준, Mina)'), counterText: '')),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: [ButtonSegment(value: 'male', label: Text(tr('남'))), ButtonSegment(value: 'female', label: Text(tr('여')))],
            selected: {gender},
            onSelectionChanged: (s) => setS(() => gender = s.first),
            style: SegmentedButton.styleFrom(selectedBackgroundColor: AppColors.copper.withValues(alpha: 0.15), selectedForegroundColor: AppColors.copper),
          ),
          const SizedBox(height: 4),
          Text(tr('성별 = 「나」의 목소리와 그림'), style: AppFonts.captionText(size: 11)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('나중에'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.copper),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('저장')),
          ),
        ],
      ),
    ),
  );
  if (ok == true) {
    await LearnerPrefs.setGender(gender);
    if (c.text.trim().isNotEmpty) await LearnerPrefs.setName(c.text);
  }
}
