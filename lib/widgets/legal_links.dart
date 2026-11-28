import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../data/usage_pages.dart';

/// 이용약관·개인정보처리방침 주소(출시 점검 2026-11-09, uk 공통). 결제 화면·로그인·설정에서 같은 링크를 쓴다.
class Legal {
  Legal._();
  static const terms = 'https://talkverse.uk/terms/';
  static const privacy = 'https://talkverse.uk/talkverse/zh/privacy/';
  static Future<void> open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// 「이용약관 · 개인정보처리방침」 한 줄 링크.
class LegalLinks extends StatelessWidget {
  final String? lead; // 앞에 붙는 안내(예: 로그인 동의 문구)
  const LegalLinks({super.key, this.lead});
  @override
  Widget build(BuildContext context) {
    const link = TextStyle(fontSize: 12, color: AppColors.zhuHongDeep, fontWeight: FontWeight.w700, decoration: TextDecoration.underline);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (lead != null) Text(lead!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.45)),
      Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
        TextButton(onPressed: () => Legal.open(Legal.terms), child: Text(tr('이용약관'), style: link)),
        const Text('·', style: TextStyle(color: AppColors.muted)),
        TextButton(onPressed: () => Legal.open(Legal.privacy), child: Text(tr('개인정보처리방침'), style: link)),
      ]),
    ]);
  }
}

/// 「유료 화면의 30% 이상을 열람하면 환불되지 않습니다」 + 환불 규정 링크(결제 화면, uk 규격 11-28). 숫자는 [UsagePages.refundNoPercent].
class RefundNote extends StatelessWidget {
  const RefundNote({super.key});
  @override
  Widget build(BuildContext context) {
    return Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text(trf(UsagePages.refundLineKo, [UsagePages.refundNoPercent]), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.45)),
      TextButton(
        onPressed: () => Legal.open(UsagePages.refundUrl),
        child: Text(tr('환불 규정'), style: const TextStyle(fontSize: 12, color: AppColors.zhuHongDeep, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
      ),
    ]);
  }
}
