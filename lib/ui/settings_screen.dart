import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../state/settings_state.dart';
import '../state/wallet_state.dart';
import 'diagnostics_screen.dart';
import 'l10n_extensions.dart';

/// Parent-facing settings: interface language, speech privacy, and the
/// microphone hearing test.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsState>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionHeader(title: l10n.settingsAppLanguage),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: RadioGroup<UiLanguage>(
                groupValue: settings.language,
                onChanged: (value) {
                  if (value != null) settings.setLanguage(value);
                },
                child: Column(
                  children: [
                    for (final language in UiLanguage.values)
                      RadioListTile<UiLanguage>(
                        value: language,
                        title: Text(l10n.uiLanguageName(language)),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          _SectionHeader(title: l10n.settingsSoundAndSpeech),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.preferOnDevice,
                  onChanged: settings.setPreferOnDevice,
                  title: Text(l10n.settingsOnDeviceOnly),
                  subtitle: Text(
                    l10n.settingsOnDeviceOnlySubtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                  isThreeLine: true,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.hearing_outlined),
                  title: Text(l10n.settingsHearingTest),
                  subtitle: Text(l10n.settingsHearingTestSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DiagnosticsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _SectionHeader(title: l10n.settingsAbout),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aboutBody,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.aboutVersion(_appVersion(context)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${l10n.walletTitle}: '
                    '${context.watch<WalletState>().balance.label}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Reads the version from the bundle without pulling in `package_info_plus`
  /// for a single string. Replace with a package if it ever needs to be exact.
  String _appVersion(BuildContext context) => '1.0.0';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
