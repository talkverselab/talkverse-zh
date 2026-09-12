import 'package:flutter/material.dart';

import 'core/platform_ui.dart';
import 'core/theme.dart';
import 'data/db/app_database.dart';
import 'data/db/seed_loader.dart';
import 'screens/main_screen.dart';
import 'services/ko_reading.dart';
import 'core/l10n.dart';

late final AppDatabase appDb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlatformUi.setup();
  appDb = AppDatabase();
  await SeedLoader(appDb).seedIfNeeded();
  await KoReadingPrefs.load();
  await AppLangPrefs.load();
  runApp(const ChineseUniverseApp());
}

class ChineseUniverseApp extends StatelessWidget {
  const ChineseUniverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 표시 언어가 바뀌면 key 가 바뀌어 앱 전체가 새로 그려진다 (홈으로 돌아감).
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLangPrefs.lang,
      builder: (context, lang, _) => MaterialApp(
        key: ValueKey(lang),
        title: tr('중국어유니버스'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        // 갤럭시·아이폰 글자 배율을 같은 범위로 (PlatformUi 참고)
        builder: PlatformUi.clampTextScale,
        home: const MainScreen(),
      ),
    );
  }
}
