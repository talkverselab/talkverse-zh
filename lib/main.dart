import 'package:flutter/material.dart';

import 'core/platform_ui.dart';
import 'core/theme.dart';
import 'data/db/app_database.dart';
import 'data/db/seed_loader.dart';
import 'screens/main_screen.dart';
import 'services/ko_reading.dart';

late final AppDatabase appDb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlatformUi.setup();
  appDb = AppDatabase();
  await SeedLoader(appDb).seedIfNeeded();
  await KoReadingPrefs.load();
  runApp(const ChineseUniverseApp());
}

class ChineseUniverseApp extends StatelessWidget {
  const ChineseUniverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '중국어유니버스',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      // 갤럭시·아이폰 글자 배율을 같은 범위로 (PlatformUi 참고)
      builder: PlatformUi.clampTextScale,
      home: const MainScreen(),
    );
  }
}
