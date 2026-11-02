import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/paywall_screen.dart';
import 'account.dart';
import 'purchase.dart';

/// 무료/유료 구분 — Talkverse ID 이용권(lang 'zh', auth.talkverse.uk) 또는 이 기기에서 산·복원한 평생 이용권(스토어).
/// 2026-11-02 한자앱과 같은 구성으로 붙였다. 아직 잠긴 화면은 없다(무료/유료 범위는 사용자 결정 대기).
class Entitlement {
  Entitlement._();
  static const lang = 'zh';
  static bool _local = false;
  static bool get premium => _local || Account.has(lang) || Purchase.owns(lang);

  /// 기기 제작용 스위치(시험용).
  static Future<void> load() async => _local = (await SharedPreferences.getInstance()).getBool('premium') ?? false;
  static Future<void> set(bool v) async {
    _local = v;
    (await SharedPreferences.getInstance()).setBool('premium', v);
  }

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
