import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/progress_provider.dart';
import '../config/theme.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, ProgressProvider>(
      builder: (context, settings, progress, _) {
        final lang = settings.language;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.get('settings', lang)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                title: AppStrings.get('appearance', lang),
                children: [
                  SwitchListTile(
                    title: Text(AppStrings.get('dark_mode', lang)),
                    subtitle: Text(AppStrings.get('enable_dark_theme', lang)),
                    value: settings.isDarkMode,
                    onChanged: (value) => settings.setDarkMode(value),
                    secondary: Icon(
                      settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: AppStrings.get('translation_language', lang),
                children: [
                  ...SettingsProvider.languages.entries.map((entry) {
                    return RadioListTile<String>(
                      title: Text(entry.value),
                      value: entry.key,
                      groupValue: settings.language,
                      onChanged: (value) {
                        if (value != null) settings.setLanguage(value);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: AppStrings.get('premium', lang),
                children: [
                  ListTile(
                    leading: Icon(
                      progress.isPremium ? Icons.check_circle : Icons.lock,
                      color: progress.isPremium ? Colors.green : null,
                    ),
                    title: Text(AppStrings.get('remove_ads', lang)),
                    subtitle: Text(
                      progress.isPremium
                          ? AppStrings.get('purchased_unlimited', lang)
                          : AppStrings.get('unlock_unlimited', lang),
                    ),
                    trailing: progress.isPremium
                        ? null
                        : ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        AppStrings.get('coming_soon', lang))),
                              );
                            },
                            child: const Text('\$1.99'),
                          ),
                  ),
                  if (progress.isPremium)
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: Text(AppStrings.get('restore_purchase', lang)),
                      onTap: () {
                        // TODO: Implement restore
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: AppStrings.get('about', lang),
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(AppStrings.get('privacy_policy', lang)),
                    onTap: () {
                      // TODO: Open privacy policy URL
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  '🇪🇸 Spanish Step\n© 2025 All rights reserved',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
