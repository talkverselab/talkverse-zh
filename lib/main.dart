import 'package:flutter/material.dart';

import 'core/platform_ui.dart';
import 'embed.dart';

export 'embed.dart' show appDb, ChineseUniverseApp;

/// 단독 앱(중국어유니버스). 초기화·화면은 embed.dart — 통합 앱(Talkverse)도 같은 두 함수를 쓴다(2026-11-09).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlatformUi.setup(); // 화면 방향·상태 표시줄(단독 앱만)
  await embedInit(standalone: true);
  runApp(embedApp());
}
