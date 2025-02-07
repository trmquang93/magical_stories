import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

class ParentalControlsScreen extends StatelessWidget {
  const ParentalControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parental Controls'),
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSecuritySection(context, settings),
              const Divider(),
              _buildContentFiltersSection(context, settings),
              const Divider(),
              _buildTimeControlsSection(context, settings),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSecuritySection(
      BuildContext context, SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable PIN Protection'),
          subtitle: const Text('Require PIN to access settings'),
          value: settings.isPinEnabled,
          onChanged: (bool value) => settings.setPinEnabled(value),
        ),
        if (settings.isPinEnabled)
          ListTile(
            title: const Text('Change PIN'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showPinChangeDialog(context),
          ),
      ],
    );
  }

  Widget _buildContentFiltersSection(
      BuildContext context, SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Content Filters',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Age-Appropriate Content Only'),
          subtitle: const Text('Filter stories based on age settings'),
          value: settings.isAgeFilterEnabled,
          onChanged: (bool value) => settings.setAgeFilterEnabled(value),
        ),
        ListTile(
          title: const Text('Set Age Range'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showAgeRangeDialog(context),
        ),
      ],
    );
  }

  Widget _buildTimeControlsSection(
      BuildContext context, SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Controls',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Daily Time Limit'),
          subtitle: const Text('Set maximum daily usage time'),
          value: settings.isTimeLimitEnabled,
          onChanged: (bool value) => settings.setTimeLimitEnabled(value),
        ),
        if (settings.isTimeLimitEnabled)
          ListTile(
            title: const Text('Set Daily Time Limit'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showTimeLimitDialog(context),
          ),
      ],
    );
  }

  void _showPinChangeDialog(BuildContext context) {
    // Implement PIN change dialog
  }

  void _showAgeRangeDialog(BuildContext context) {
    // Implement age range selection dialog
  }

  void _showTimeLimitDialog(BuildContext context) {
    // Implement time limit selection dialog
  }
}
