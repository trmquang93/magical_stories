import 'package:flutter/material.dart';
import 'package:magical_stories/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTab),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.darkMode),
            value: settings.isDarkMode,
            onChanged: (bool value) {
              settings.toggleDarkMode();
            },
          ),
          ListTile(
            title: Text(l10n.fontSize),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (settings.fontSize > 12) {
                      settings.setFontSize(settings.fontSize - 2);
                    }
                  },
                ),
                Text('${settings.fontSize.toInt()}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (settings.fontSize < 32) {
                      settings.setFontSize(settings.fontSize + 2);
                    }
                  },
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: settings.locale.languageCode,
              items: const [
                DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: 'es',
                  child: Text('Español'),
                ),
                DropdownMenuItem(
                  value: 'fr',
                  child: Text('Français'),
                ),
                DropdownMenuItem(
                  value: 'vi',
                  child: Text('Tiếng Việt'),
                ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  settings.setLanguage(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
