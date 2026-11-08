import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';

/// 「글꼴 라이선스」 — 앱에 넣은 글꼴 네 벌의 SIL Open Font License 1.1 전문(OFL 이 배포물에 함께 두라고 요구).
/// 원문은 `assets/fonts/licenses/` 그대로 읽는다.
class FontLicensesScreen extends StatelessWidget {
  const FontLicensesScreen({super.key});

  /// (글꼴 이름, 쓰는 곳, 라이선스 파일)
  static List<(String, String, String)> get fonts => [
        ('Pretendard', tr('한글 UI·독음·번역'), 'assets/fonts/licenses/OFL-Pretendard.txt'),
        ('Noto Sans SC', tr('중국어 본문'), 'assets/fonts/licenses/OFL-NotoSansSC.txt'),
        ('LXGW WenKai GB', tr('큰 한자 자형'), 'assets/fonts/licenses/OFL-LXGWWenKaiGB.txt'),
        ('Noto Sans', tr('병음'), 'assets/fonts/licenses/OFL-NotoSans.txt'),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(tr('글꼴 라이선스'))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset(context)),
          children: [
            Text(tr('이 앱의 글꼴은 모두 SIL Open Font License 1.1 로 배포됩니다. 눌러서 전문을 펼치세요.'), style: AppFonts.uiText(size: 13)),
            const SizedBox(height: 8),
            // 그림 자료(2026-11-08) — 병음 발음 시트의 조음 위치 그림
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(tr('조음 위치 그림'), style: AppFonts.uiText(size: 14.5, weight: FontWeight.w600, color: AppColors.mo)),
              subtitle: Text(tr('Wikimedia Commons IPA 자료 · CC BY-SA — 병음과 발음 화면의 자음 조음 위치 그림'), style: AppFonts.captionText()),
            ),
            for (final (name, use, path) in fonts)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(name, style: AppFonts.uiText(size: 14.5, weight: FontWeight.w600, color: AppColors.mo)),
                  subtitle: Text('$use · SIL OFL 1.1', style: AppFonts.captionText()),
                  childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                  children: [
                    FutureBuilder<String>(
                      future: rootBundle.loadString(path),
                      builder: (context, snap) => SelectableText(
                        snap.data ?? (snap.hasError ? tr('라이선스 파일을 읽지 못했어요.') : '…'),
                        style: AppFonts.uiText(size: 11.5, height: 1.5),
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
