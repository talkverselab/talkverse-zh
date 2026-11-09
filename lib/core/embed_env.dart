import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 통합 앱(Talkverse, com.talkverse.app) 안에 패키지로 들어갔는지 — `embedInit()` 이 정한다(2026-11-09, ~/talkverse/talkverse-app/EMBED_GUIDE.md).
/// 단독 앱(중국어유니버스)에서는 false 이고 모든 동작이 예전과 같다.
bool embedded = false;

/// 패키지 이름(pubspec name) · 이 언어의 저장 이름 접두(설정 키·기기 폴더).
const packageName = 'chinese_universe';
const storePrefix = 'zh_';

/// 에셋 경로 — 패키지로 들어가면 Flutter 가 `packages/<패키지>/` 아래에 둔다.
String assetPath(String p) => embedded && !p.startsWith('packages/') ? 'packages/$packageName/$p' : p;

/// AssetManifest 의 키 → 앱 안 상대 경로(`assets/...`). 패키지 접두가 있으면 뗀다.
String stripAssetPrefix(String p) => p.startsWith('packages/$packageName/') ? p.substring('packages/$packageName/'.length) : p;

/// 글꼴 이름 — 패키지에 든 글꼴은 `packages/<패키지>/<이름>` 으로 불러야 한다.
String fontName(String f) => embedded ? 'packages/$packageName/$f' : f;

String? _dir;

/// 이 언어 전용 기기 저장 폴더(Application Support/zh). 단독 앱의 옛 위치(art·shared_hanja_v1.json)는 처음 한 번 옮긴다.
Future<String> dataDir() async {
  if (_dir != null) return _dir!;
  final base = (await getApplicationSupportDirectory()).path;
  final d = Directory('$base/zh');
  if (!d.existsSync()) d.createSync(recursive: true);
  if (!embedded) {
    for (final name in const ['art', 'shared_hanja_v1.json']) {
      final old = '$base/$name', now = '${d.path}/$name';
      try {
        if (FileSystemEntity.typeSync(old) != FileSystemEntityType.notFound && FileSystemEntity.typeSync(now) == FileSystemEntityType.notFound) {
          await (FileSystemEntity.isDirectorySync(old) ? Directory(old).rename(now) : File(old).rename(now));
        }
      } catch (_) {}
    }
  }
  return _dir = d.path;
}
