import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'providers/progress_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/favorite_provider.dart';
import 'screens/home_screen.dart';
import 'config/theme.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Skip AdMob initialization on web
  if (!kIsWeb) {
    // Request App Tracking Transparency permission on iOS
    if (Platform.isIOS) {
      try {
        // Wait for the widget to be ready before showing ATT dialog
        await Future.delayed(const Duration(milliseconds: 500));
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      } catch (e) {
        debugPrint('ATT request error: $e');
      }
    }
    
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('AdMob init error: $e');
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
