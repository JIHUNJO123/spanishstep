import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'providers/progress_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/favorite_provider.dart';
import 'screens/home_screen.dart';
import 'config/theme.dart';
import 'services/tts_service.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Skip AdMob initialization on web
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('AdMob init error: $e');
    }
    try {
      await TtsService().init();
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
    try {
      await PurchaseService.instance.initialize();
    } catch (e) {
      debugPrint('IAP init error: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: const SpanishStepApp(),
    ),
  );
}

class SpanishStepApp extends StatelessWidget {
  const SpanishStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        // Apply TTS settings when they change
        if (!kIsWeb) {
          TtsService().setVolume(settings.ttsVolume);
          TtsService().setSpeechRate(settings.ttsSpeed);
        }
        return MaterialApp(
          title: 'Spanish Step',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      },
    );
  }
}
