import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/permission_service.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';
import 'services/voice_separator.dart';
import 'state/settings_state.dart';
import 'state/wallet_state.dart';
import 'ui/home_screen.dart';

/// Root of the app.
///
/// Shared services are created once here and injected downwards with
/// `provider`, so screens never construct their own audio engines — two TTS
/// engines fighting over the audio session is an easy bug to ship by accident.
class JkReadNLearnApp extends StatelessWidget {
  const JkReadNLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Registered by interface, not by implementation, so screens and the
        // session controller depend on the capability rather than on a
        // particular audio plugin.
        Provider<Speaker>(create: (_) => TtsService()),
        Provider<SpeechRecogniser>(create: (_) => SpeechService()),
        Provider<MicrophonePermissions>(create: (_) => const PermissionService()),
        Provider<VoiceSeparationRegistry>(
          create: (_) => VoiceSeparationRegistry(),
        ),
        ChangeNotifierProvider<WalletState>(
          create: (_) => WalletState()..load(),
        ),
        ChangeNotifierProvider<SettingsState>(
          create: (_) => SettingsState()..load(),
        ),
      ],
      // The interface language lives in SettingsState, so the whole MaterialApp
      // has to rebuild when it changes. The app renders in the default language
      // for the single frame before preferences load, which is invisible.
      child: Consumer<SettingsState>(
        builder: (context, settings, _) {
          return MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            locale: settings.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D6F),
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6FAF8),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        color: scheme.surface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
