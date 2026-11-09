import 'dart:async';

import 'package:flutter/material.dart';

import 'core/embed_env.dart';
import 'core/l10n.dart';
import 'core/platform_ui.dart';
import 'core/theme.dart';
import 'data/account.dart';
import 'data/db/app_database.dart';
import 'data/db/seed_loader.dart';
import 'data/entitlement.dart';
import 'data/purchase.dart';
import 'review/review_service.dart';
import 'review/review_ui.dart' show ReviewText;
import 'screens/main_screen.dart';
import 'screens/sync_screen.dart';
import 'services/achievement_service.dart';
import 'services/content_sync.dart';
import 'services/hanzi_info_service.dart';
import 'services/ko_reading.dart';
import 'services/learner_prefs.dart';
import 'services/shared_hanja_service.dart';

export 'core/embed_env.dart' show embedded;
export 'data/purchase.dart' show Purchase;

/// 통합 앱(Talkverse) 연결점 — 2026-11-09, ~/talkverse/talkverse-app/EMBED_GUIDE.md.
/// 단독 앱 `main()`: `await embedInit(standalone: true)` → `runApp(embedApp())`.
/// 통합 앱: `await embedInit()` → 이 언어 화면을 열 때 `embedApp(onSwitchLanguage: …)`.
/// 통합 앱 결제: 공용 결제가 lang_zh_*·all_* 상품을 `Purchase.onPurchaseUpdates(list)` 로 넘기고 completePurchase 는 통합 앱이 한다.

late final AppDatabase appDb;
bool _inited = false;
bool _syncFirst = false;

/// 「다른 언어 배우기」 — 통합 앱이 넘긴 콜백(없으면 메뉴를 안 보인다).
VoidCallback? switchLanguage;

/// 초기화 전부(화면 방향·runApp 제외). 여러 번 불러도 한 번만 한다.
Future<void> embedInit({bool standalone = false}) async {
  if (_inited) return;
  _inited = true;
  embedded = !standalone;
  WidgetsFlutterBinding.ensureInitialized();
  appDb = AppDatabase();
  await SeedLoader(appDb).seedIfNeeded();
  await KoReadingPrefs.load();
  await AppLangPrefs.load();
  await ReviewService.instance.load(); // 라이트너 복습 기록
  await LearnerPrefs.load(); // 학습자 이름·성별 → 회화 「나」
  await AchievementService.instance.load();
  await Entitlement.load();
  Account.load(); // Talkverse ID(선택) — 저장된 로그인 표시 + 뒤에서 토큰 갱신(기다리지 않음)
  Purchase.ownStream = standalone;
  // 가격·상품 ID = Talkverse 공통(2026-11-09 사용자 최종 확정, ~/talkverse/PRICING.md — 앱 정가/할인가 30%). 스토어 등록은 사용자(docs/STORE_PRODUCTS.md).
  unawaited(Purchase.configure(Entitlement.lang, const [
    Plan('lang_zh_1m', 1, 3900, listKrw: 5500),
    Plan('lang_zh_3m', 3, 9000, listKrw: 12900),
    Plan('lang_zh_1y', 12, 19900, listKrw: 28500),
    Plan('lang_zh_life', 0, 49000, listKrw: 69900),
    Plan('all_1y', 12, 79000, listKrw: 112900, bundle: true),
    Plan('all_life', 0, 329000, listKrw: 469000, bundle: true),
  ]));
  // 그림(장면 컷·단어 그림)·회화 음성 기기 내려받기: 버전이 다르면 로딩 화면에서 받고 시작(2026-11-04). 태블릿(짧은 변 600 이상)은 큰 컷.
  _syncFirst = await ContentSync.instance.init(large: _isLargeScreen(), female: LearnerPrefs.isFemale);
  // 한자 공용 DB(발음부·외우는 방법·GIF·쓰기 범위) — 화면을 막지 않고 뒤에서 받는다.
  unawaited(
    SharedHanjaService.instance.syncIfStale().then((changed) {
      if (changed) HanziInfoService.instance.refreshShared();
    }),
  );
}

bool _isLargeScreen() {
  try {
    final v = WidgetsBinding.instance.platformDispatcher.views.first;
    return v.physicalSize.shortestSide / v.devicePixelRatio >= 600;
  } catch (_) {
    return false;
  }
}

/// runApp 에 넘기는 위젯(통합 앱은 이 언어 화면으로). [onSwitchLanguage] 가 있으면 프로필 설정 맨 위에 「다른 언어 배우기」.
Widget embedApp({VoidCallback? onSwitchLanguage}) {
  switchLanguage = onSwitchLanguage;
  return ChineseUniverseApp(syncFirst: _syncFirst);
}

class ChineseUniverseApp extends StatelessWidget {
  final bool syncFirst;
  const ChineseUniverseApp({super.key, this.syncFirst = false});

  @override
  Widget build(BuildContext context) {
    // 표시 언어가 바뀌면 key 가 바뀌어 앱 전체가 새로 그려진다 (홈으로 돌아감).
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLangPrefs.lang,
      builder: (context, lang, _) {
        ReviewText.en = lang != AppLang.ko; // 공용 복습 화면 문구: 한국어 외에는 영어
        return MaterialApp(
          key: ValueKey(lang),
          title: tr('중국어유니버스'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          // 갤럭시·아이폰 글자 배율을 같은 범위로 (PlatformUi 참고)
          builder: PlatformUi.clampTextScale,
          home: syncFirst ? const SyncScreen(next: MainScreen()) : const MainScreen(),
        );
      },
    );
  }
}
