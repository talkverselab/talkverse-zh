// 화면 열람 기록 — 사용자가 어느 학습 화면을 열었는지 서버(auth.talkverse.uk)에 남긴다.
// 환불 규정(talkverse.uk/refund/ 3항)의 「열람률」 계산에 쓰인다. 원본: M6 ~/talkverse/_shared/talkverse_usage (talkverse-uk 세션 보유).
// 이 파일 하나를 각 앱 lib/ 에 복사해 쓴다. 고칠 일이 있으면 원본을 고치고 다시 복사한다.
//
// 쓰는 법
//   앱 시작 때 한 번:  UsageLog.init(lang: 'ja', token: Account.accessToken, appBuild: 21);
//   학습 화면을 열 때:  UsageLog.view('conv/n5_012');      // 화면 ID = 화면 목록(usage_catalog.json)의 page 와 같은 글자
//   앱이 뒤로 갈 때:    UsageLog.flush();                    // AppLifecycleState.paused 에서
//
// 규칙
//   - 화면 ID 는 내용에 붙은 고정 이름이다(순서·제목이 바뀌어도 그대로). 글자: 영문·숫자·_ . / : # - , 120자 이하.
//   - 같은 화면은 하루에 한 번만 보낸다. 로그인하지 않았으면 기기에 모아 두었다가 로그인 뒤 보낸다(최대 2,000건).
//   - 실패해도 앱 동작에는 영향이 없다(예외를 밖으로 던지지 않는다).
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UsageLog {
  UsageLog._();

  static const _base = 'https://auth.talkverse.uk';
  // 통합 앱에서는 언어 패키지마다 이 파일의 복사본이 따로 돈다 — 저장 키에 언어를 붙여 서로의 대기열을 덮어쓰지 않게 한다(v2, 2026-11-28).
  static String get _kQueue => 'tv_usage_queue_${_lang ?? ''}';
  static String get _kSent => 'tv_usage_sent_${_lang ?? ''}';
  static String get _kDay => 'tv_usage_day_${_lang ?? ''}';
  static const _maxQueue = 2000, _batch = 200;
  static final _pageRe = RegExp(r'^[\w./:#-]{1,120}$');

  static String? _lang;
  static Future<String?> Function()? _token;
  static int? _appBuild;
  static http.Client _http = http.Client();
  static DateTime Function() _now = DateTime.now;

  static final List<Map<String, String>> _queue = [];
  static final Set<String> _sentToday = {};
  static String _day = '';
  static bool _loaded = false, _sending = false;
  static Timer? _timer;

  /// [lang] 이 패키지의 언어 코드, [token] 로그인 토큰을 주는 함수(로그아웃이면 null).
  static void init({required String lang, required Future<String?> Function() token, int? appBuild, http.Client? client, DateTime Function()? now}) {
    _lang = lang;
    _token = token;
    _appBuild = appBuild;
    if (client != null) _http = client;
    if (now != null) _now = now;
  }

  /// 학습 화면을 열었다. [lang] 을 주지 않으면 init 의 언어.
  static void view(String page, {String? lang}) {
    final l = lang ?? _lang;
    if (l == null || !_pageRe.hasMatch(page)) return;
    unawaited(_add(l, page).catchError((_) {}));
  }

  /// 모아 둔 기록을 지금 보낸다. 앱이 뒤로 갈 때 부른다.
  static Future<void> flush() async {
    try {
      await _load();
      await _send();
    } catch (_) {}
  }

  static Future<void> _add(String lang, String page) async {
    await _load();
    final now = _now().toUtc();
    final day = now.toIso8601String().substring(0, 10);
    if (day != _day) {
      _day = day;
      _sentToday.clear();
    }
    final key = '$lang\n$page';
    if (!_sentToday.add(key)) return; // 오늘 이미 기록함
    _queue.add({'lang': lang, 'page': page, 'at': now.toIso8601String()});
    if (_queue.length > _maxQueue) _queue.removeRange(0, _queue.length - _maxQueue);
    await _save();
    if (_queue.length >= 20) {
      await _send();
    } else {
      _timer ??= Timer(const Duration(seconds: 30), () {
        _timer = null;
        unawaited(flush());
      });
    }
  }

  static Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    _day = p.getString(_kDay) ?? '';
    final today = _now().toUtc().toIso8601String().substring(0, 10);
    if (_day == today) _sentToday.addAll(p.getStringList(_kSent) ?? const []);
    _day = today;
    try {
      for (final x in jsonDecode(p.getString(_kQueue) ?? '[]') as List) {
        _queue.add(Map<String, String>.from(x as Map));
      }
    } catch (_) {}
  }

  static Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kQueue, jsonEncode(_queue));
    await p.setStringList(_kSent, _sentToday.toList());
    await p.setString(_kDay, _day);
  }

  static Future<void> _send() async {
    if (_sending || _queue.isEmpty) return;
    _sending = true;
    try {
      while (_queue.isNotEmpty) {
        final tok = await _token?.call();
        if (tok == null || tok.isEmpty) return; // 로그인 전 — 기기에 둔다
        final n = _queue.length < _batch ? _queue.length : _batch;
        final r = await _http
            .post(Uri.parse('$_base/v1/usage/views'),
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $tok'},
                body: jsonEncode({'platform': _platform(), if (_appBuild != null) 'app_build': _appBuild, 'items': _queue.sublist(0, n)}))
            .timeout(const Duration(seconds: 15));
        // 200 = 저장됨. 4xx(401 제외) = 다시 보내도 같은 결과라 버린다. 그 밖(401·5xx·끊김)은 다음에 다시.
        if (r.statusCode == 200 || (r.statusCode >= 400 && r.statusCode < 500 && r.statusCode != 401 && r.statusCode != 429)) {
          _queue.removeRange(0, n);
          await _save();
        } else {
          return;
        }
      }
    } catch (_) {
      // 네트워크 실패 — 다음 view·flush 때 다시
    } finally {
      _sending = false;
    }
  }

  static String _platform() {
    try {
      return Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : Platform.operatingSystem;
    } catch (_) {
      return 'web';
    }
  }

  /// 시험용: 상태를 비운다.
  static void resetForTest() {
    _queue.clear();
    _sentToday.clear();
    _day = '';
    _loaded = false;
    _sending = false;
    _timer?.cancel();
    _timer = null;
  }
}
