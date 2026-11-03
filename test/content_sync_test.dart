import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:chinese_universe/data/db/seed_loader.dart';
import 'package:chinese_universe/services/content_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('version.json: DB 업데이트 번호(db)가 번들에 있고 1 이상', () async {
    expect(await rootBundle.loadString('assets/data/version.json'), contains('"db"'));
    expect(await SeedLoader.bundledVersion(), greaterThanOrEqualTo(8));
  });

  test('ContentSync.keyOf: base 를 떼고 ?v= 를 나눈다(기기 파일 키)', () {
    final s = ContentSync.instance;
    expect(s.keyOf('${s.base}/scene/zh/r1_x/cut1_584.webp?v=a323fe27'), ('scene/zh/r1_x/cut1_584.webp', 'a323fe27'));
    expect(s.keyOf('ja/512/18_watashi.webp'), ('ja/512/18_watashi.webp', '0'));
    // 아직 init 전(폴더 없음)이면 기기 파일은 없고 네트워크로
    expect(s.localFile('${s.base}/scene/zh/r1_x/cut1_584.webp?v=1'), isNull);
  });
}
