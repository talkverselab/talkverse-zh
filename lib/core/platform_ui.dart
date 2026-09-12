import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 갤럭시(Android)·아이폰(iOS) 두 기기에서 화면이 같게 보이도록 맞추는 공통 규칙.
///
/// - 세로 고정: 두 폰 모두 세로로만 쓴다 (가로 회전 시 레이아웃 깨짐 방지).
/// - 글자 크기 고정 범위: 기기 설정의 큰 글씨(아이폰 Dynamic Type, 갤럭시 글꼴 크기)가
///   0.85~1.15배를 넘지 않게 눌러 두 폰의 카드·버튼 높이가 비슷하게 유지된다.
/// - 상태 표시줄: 앱바 없는 화면(홈·학습 목록)은 밝은 배경이라 아이콘을 어둡게.
///   앱바(빨강)가 있는 화면은 AppBar 가 스스로 밝은 아이콘으로 바꾼다.
class PlatformUi {
  PlatformUi._();

  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;

  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.15;

  /// 앱 시작 시 한 번.
  static Future<void> setup() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(lightBackgroundOverlay);
  }

  /// 밝은 배경 위 상태 표시줄 (어두운 아이콘). 안드로이드는 내비게이션 바도 투명.
  static const SystemUiOverlayStyle lightBackgroundOverlay =
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Android
        statusBarBrightness: Brightness.light, // iOS (배경 밝기 기준)
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      );

  /// MaterialApp.builder 에 끼워 두 폰의 글자 배율을 같은 범위로 맞춘다.
  static Widget clampTextScale(BuildContext context, Widget? child) {
    final mq = MediaQuery.of(context);
    final scaled = mq.textScaler.scale(1.0);
    final clamped = scaled.clamp(minTextScale, maxTextScale);
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(clamped)),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
