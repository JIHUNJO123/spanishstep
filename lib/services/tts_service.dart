import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  double _volume = 1.0;
  double _speechRate = 0.45;

  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;

    _flutterTts = FlutterTts();

    // iOS specific settings
    if (!kIsWeb && Platform.isIOS) {
      await _flutterTts!.setSharedInstance(true);
      await _flutterTts!.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }

    // Android specific settings for better volume
    if (!kIsWeb && Platform.isAndroid) {
      await _flutterTts!.setSharedInstance(true);
    }

    // Set Spanish language
    await _flutterTts!.setLanguage('es-ES');
    await _flutterTts!.setSpeechRate(_speechRate);
    await _flutterTts!.setVolume(_volume);
    await _flutterTts!.setPitch(1.0);

    // Queue mode and completion
    await _flutterTts!.setQueueMode(1);
    await _flutterTts!.awaitSpeakCompletion(true);

    _isInitialized = true;
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    if (_flutterTts != null) {
      await _flutterTts!.setVolume(volume);
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    if (_flutterTts != null) {
      await _flutterTts!.setSpeechRate(rate);
    }
  }

  Future<void> speak(String text) async {
    if (kIsWeb || !_isInitialized || _flutterTts == null) return;

    await _flutterTts!.stop();
    await _flutterTts!.speak(text);
  }

  Future<void> stop() async {
    if (kIsWeb || !_isInitialized || _flutterTts == null) return;
    await _flutterTts!.stop();
  }

  Future<void> dispose() async {
    if (kIsWeb || !_isInitialized || _flutterTts == null) return;
    await _flutterTts!.stop();
  }
}
