import 'package:flutter_tts/flutter_tts.dart';

/// flutter_tts 기반 — Android 시스템 zh-CN voice 사용.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String? _speaking;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() => _speaking = null);
    _tts.setCancelHandler(() => _speaking = null);
    _tts.setErrorHandler((msg) => _speaking = null);
    _initialized = true;
  }

  bool isSpeaking(String text) => _speaking == text;

  Future<void> speak(String text) async {
    await _ensureInit();
    await _tts.stop();
    _speaking = text;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = null;
  }
}
