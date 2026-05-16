import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  Map<String, String> _hanziMap = const {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/audio_manifest.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final hanzi = (data['hanzi'] as Map<String, dynamic>?) ?? {};
      _hanziMap = hanzi.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      _hanziMap = const {};
    }
    _loaded = true;
  }

  bool hasHanzi(String char) {
    return _hanziMap.containsKey(char);
  }

  Future<bool> playHanzi(String char) async {
    await ensureLoaded();
    final path = _hanziMap[char];
    if (path == null) return false;
    final assetPath = path.startsWith('assets/') ? path.substring('assets/'.length) : path;
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() async {
    await _player.dispose();
  }
}
