import 'package:flutter/material.dart';
import '../core/prefs.dart';

import '../screens/paywall_screen.dart';
import '../services/curriculum_service.dart';
import 'account.dart';
import 'purchase.dart';

/// 무료/유료 구분 — Talkverse ID 이용권(lang 'zh', auth.talkverse.uk) 또는 이 기기에서 산·복원한 이용권(스토어 lang_zh_*·all_*).
/// 범위 = `~/talkverse/PAYWALL_SPEC.md`(11/23 사용자 「1 2 모두 진행」, 범위는 uk 의 정함):
/// 무료 = 커리큘럼 1단계·회화 R0·R1·글자/발음/단어 기본·문법 1~2스텝·언어감각 1급. 유료 = 그 밖(2단계~·HSK 준비·문법 3스텝~·언어감각 2급~).
/// 단계·급수의 free 와 freeSteps·freeSenseLevels 는 서버 커리큘럼 판(rev 2~)이 준다 — 없으면 위 기본값.
class Entitlement {
  Entitlement._();
  static const lang = 'zh';
  static bool _local = false;
  static bool get premium => _local || Account.has(lang) || Purchase.owns(lang);

  /// 기기 제작용 스위치(시험용).
  static Future<void> load() async => _local = (await Prefs.getInstance()).getBool('premium') ?? false;
  static Future<void> set(bool v) async {
    _local = v;
    (await Prefs.getInstance()).setBool('premium', v);
  }

  /// 시험 내용(HSK 4·5급, 사용자 확정 2026-11-28 · ~/talkverse/PRICING.md「프로+시험」) — 프로+HSK(`lang_zh_exam_*`)·언어 평생·종합 1년·종합 평생이 연다.
  /// 서버: 이용권 응답의 중국어 항목 `exam === true`(uk 규격 11-28). 기기: 이 기기에서 산·복원한 시험 상품([Purchase.ownsExam]).
  static bool get exam => _local || Account.hasExam(lang) || Purchase.ownsExam(lang);

  /// HSK 4·5급(커리큘럼 「HSK 준비」 HSK4·HSK5, 단어장 hsk4·hsk5)인가.
  static bool examLevel(String key) => const {'HSK4', 'HSK5', 'hsk4', 'hsk5'}.contains(key);

  /// 열려 있는가 — 시험 칸은 [exam], 나머지는 무료이거나 [premium].
  static bool open(bool free, {bool exam = false}) => exam ? Entitlement.exam : (free || premium);

  static Future<void> showPaywall(BuildContext context, {bool exam = false}) => PaywallScreen.show(context, exam: exam);

  static CurriculumPlan? get _plan => CurriculumService.instance.plan;

  /// 회화 목록의 편 — 1단계(R0·R1)만 무료.
  static bool dialogueFree(String region) => region == 'R0' || region == 'R1';

  /// 문법 스텝 n(1부터) — freeSteps(기본 2)까지 무료.
  static bool stepFree(int n) => n <= (_plan?.freeSteps ?? 2);

  /// 언어감각 급 순번(1부터) — freeSenseLevels(기본 1)까지 무료.
  static bool senseLevelFree(int n) => n <= (_plan?.freeSenseLevels ?? 1);

  /// 잠겨 있으면 결제 화면을 띄우고, 닫힌 뒤 열렸는지(true = 지나가도 됨)를 돌려준다.
  /// [exam] = 시험 칸(HSK 4·5급) — 결제 화면이 「프로+HSK」 줄을 위에 보인다.
  static Future<bool> gate(BuildContext context, bool free, {bool exam = false}) async {
    if (open(free, exam: exam)) return true;
    await PaywallScreen.show(context, exam: exam);
    return open(free, exam: exam);
  }
}

/// 잠긴 칸의 작은 자물쇠(무엇을 사는지 보이게 숨기지 않는다 — 애플 3.1.1).
class LockBadge extends StatelessWidget {
  final double size;
  const LockBadge({super.key, this.size = 16});
  @override
  Widget build(BuildContext context) => Icon(Icons.lock_outline, size: size, color: const Color(0xFF9A5F38));
}
