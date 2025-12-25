import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;
    
    _flutterTts = FlutterTts();
    
    // Set Spanish language
    await _flutterTts!.setLanguage('es-ES');
    await _flutterTts!.setSpeechRate(0.5);
    await _flutterTts!.setVolume(1.0);
    await _flutterTts!.setPitch(1.0);
    
    _isInitialized = true;
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
