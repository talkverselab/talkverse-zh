import 'dart:convert';

import 'package:http/http.dart' as http;

import '../usage_log.dart';
import 'account.dart';

/// 화면 열람 기록(uk 규격 2026-11-28 `~/talkverse/_shared/talkverse_usage/USAGE_LOG.md`) — 화면 ID·환불 문구를 한 곳에.
/// 화면 ID 는 `tool/usage_catalog.py` 가 만드는 목록(`tool/usage_catalog.json`)의 page 와 **글자까지 같아야** 한다 — 여기를 바꾸면 그 도구도 같이.
///
/// | 단위 | ID | tier |
/// |---|---|---|
/// | 회화 한 편(회화 목록·커리큘럼 편 연습 어디서 열든) | `conv/<편 id>` | 그 편을 여는 가장 낮은 권한: 무료 경로(R0·R1, 무료 단계) free, 프로 pro, HSK4·5 경로뿐이면 exam |
/// | 문법 스텝 | `grammar/step<n>` | freeSteps(기본 2) 까지 free, 그 밖 pro |
/// | 언어감각 회차 | `sense/<회차 id>` | freeSenseLevels(기본 1) 급까지 free, 그 밖 pro |
/// | 단어장 묶음 | `vocab/<묶음 id>` | hsk4·hsk5 exam, 그 밖 free |
class UsagePages {
  UsagePages._();

  static String conv(String dialogueId) => 'conv/$dialogueId';
  static String grammar(int step) => 'grammar/step$step';
  static String sense(String lessonId) => 'sense/$lessonId';
  static String vocab(String themeId) => 'vocab/$themeId';

  /// 기록(실패해도 앱에 영향 없음).
  static void view(String page) => UsageLog.view(page);

  // 환불 기준 숫자 — uk 의 안(사용자가 바꿀 수 있음). 서버 `REFUND_RULE`·talkverse.uk/refund/ 와 함께 바꾼다.
  static const refundNoPercent = 30;
  static const refundUrl = 'https://talkverse.uk/refund/';

  /// 「내 정보」의 한 줄(한국어 원문 — 화면에서 trf 로 감싼다). 숫자는 서버 rule.none_from 이 있으면 그것.
  static const refundLineKo = '유료 화면의 {0}% 이상을 열람하면 환불되지 않습니다';

  /// 결제 화면(이용권 사는 화면)의 한 줄 — 앱 안 결제 환불은 스토어가 정한다(사용자 확정 11-28, uk 전달).
  static const storeNoticeKo = '환불 심사 때 이용 기록이 스토어에 제공될 수 있습니다.';

  /// 서버 열람률 — 유료 화면 중 연 수 / 전체. [exam] = 시험 권한이 있으면 exam 화면도 합친다(환불 규정: 프로+시험·평생·종합). 로그인 전·실패면 null.
  static Future<({int viewed, int total, int nonePercent})?> summary({bool exam = false}) async {
    try {
      final tok = await Account.accessToken();
      if (tok == null || tok.isEmpty) return null;
      final r = await http
          .get(Uri.parse('https://auth.talkverse.uk/v1/usage/summary?lang=zh'), headers: {'Authorization': 'Bearer $tok'})
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final j = json.decode(r.body) as Map;
      var viewed = 0, total = 0;
      for (final t in (j['tiers'] as List? ?? const []).whereType<Map>()) {
        final tier = '${t['tier']}';
        if (tier != 'pro' && !(exam && tier == 'exam')) continue;
        viewed += (t['viewed'] as num?)?.toInt() ?? 0;
        total += (t['total'] as num?)?.toInt() ?? 0;
      }
      final nf = ((j['rule'] as Map?)?['none_from'] as num?)?.toDouble();
      final pct = nf == null ? refundNoPercent : (nf <= 1 ? (nf * 100).round() : nf.round());
      return total == 0 ? null : (viewed: viewed, total: total, nonePercent: pct);
    } catch (_) {
      return null;
    }
  }
}
