import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/progress_provider.dart';
import '../config/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer2<SettingsProvider, ProgressProvider>(
        builder: (context, settings, progress, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                title: 'Appearance',
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Enable dark theme'),
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
                title: 'Translation Language',
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
                title: 'Premium',
                children: [
                  ListTile(
                    leading: Icon(
                      progress.isPremium ? Icons.check_circle : Icons.lock,
                      color: progress.isPremium ? Colors.green : null,
                    ),
                    title: const Text('Remove Ads'),
                    subtitle: Text(
                      progress.isPremium
                          ? 'Purchased - Unlimited access'
                          : 'Unlock unlimited access for \$1.99',
                    ),
                    trailing: progress.isPremium
                        ? null
                        : ElevatedButton(
                            onPressed: () {
                              // TODO: Implement purchase
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Coming soon!')),
                              );
                            },
                            child: const Text('\$1.99'),
                          ),
                  ),
                  if (progress.isPremium)
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: const Text('Restore Purchase'),
                      onChanged: (value) {
                        // TODO: Implement restore
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'About',
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      // TODO: Open privacy policy URL
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Support'),
                    subtitle: const Text('jihun.jo@yahoo.com'),
                    onTap: () {
                      // TODO: Open support URL or email
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
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
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
