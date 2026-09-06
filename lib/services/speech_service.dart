import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// speech_to_text (BSD-3) 래퍼 — Android SpeechRecognizer zh-CN 스트리밍.
///
/// - [listen] 은 마이크가 실제로 열린 뒤 완료되므로, 완료 직후 타이머를 시작하면
///   "TEST 누르자마자 녹음" 이 보장된다.
/// - 부분 결과(partial)가 계속 올라오므로 호출 측은 매 결과마다 즉시 판정한다.
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final SpeechToText _stt = SpeechToText();
  bool? _available;
  String _localeId = 'zh_CN';
  String _status = '';
  String? _lastError;

  void Function(String status)? onStatus;

  bool get isListening => _stt.isListening;
  String get status => _status;
  String? get lastError => _lastError;
  String get localeId => _localeId;

  /// 1회 초기화 (마이크 권한 요청 포함). 실패 시 false.
  Future<bool> init() async {
    if (_available != null) return _available!;
    try {
      final ok = await _stt.initialize(
        onError: (SpeechRecognitionError e) => _lastError = e.errorMsg,
        onStatus: (s) {
          _status = s;
          onStatus?.call(s);
        },
        finalTimeout: const Duration(milliseconds: 800),
      );
      _available = ok;
      if (ok) await _pickLocale();
    } catch (_) {
      _available = false;
    }
    return _available!;
  }

  Future<void> _pickLocale() async {
    try {
      final locales = await _stt.locales();
      const prefer = ['zh_CN', 'cmn_CN', 'zh-CN', 'cmn-Hans-CN', 'zh_Hans_CN'];
      for (final p in prefer) {
        if (locales.any((l) => l.localeId == p)) {
          _localeId = p;
          return;
        }
      }
      final any = locales.where(
          (l) => l.localeId.toLowerCase().startsWith('zh') ||
              l.localeId.toLowerCase().startsWith('cmn'));
      if (any.isNotEmpty) _localeId = any.first.localeId;
    } catch (_) {
      // 목록 실패 → 기본 zh_CN
    }
  }

  /// 녹음 시작. [maxFor] 동안 듣고, 부분 결과마다 [onResult] 호출.
  /// 반환 Future 는 플랫폼이 실제 listening 상태가 된 뒤 완료.
  Future<bool> listen({
    required void Function(String words, bool isFinal) onResult,
    required Duration maxFor,
  }) async {
    if (!(await init())) return false;
    _lastError = null;
    if (_stt.isListening) await _stt.cancel();
    try {
      await _stt.listen(
        onResult: (SpeechRecognitionResult r) =>
            onResult(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          listenFor: maxFor,
          pauseFor: maxFor,
          autoPunctuation: false,
          enableHapticFeedback: false,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 듣기 종료 → 지금까지 들은 것을 최종 결과로 확정.
  Future<void> stop() async {
    if (_stt.isListening) await _stt.stop();
  }

  /// 결과 없이 즉시 취소.
  Future<void> cancel() async {
    if (_stt.isListening) await _stt.cancel();
  }
}
