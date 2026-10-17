import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_essays.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/app_language.dart';
import '../services/permission_service.dart';
import '../services/speech_service.dart';
import '../state/settings_state.dart';
import 'l10n_extensions.dart';

/// The hearing test: read a sentence, see what the device actually heard.
///
/// This screen exists because the single most common support problem is "it
/// does not work", which can mean four very different things — no microphone
/// permission, no speech recogniser, no language pack, or a genuinely quiet
/// child. Showing all four states at once turns an unanswerable bug report into
/// a five-second diagnosis.
///
/// Nothing here is saved, scored, or added to the wallet.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  ReadingLanguage _language = ReadingLanguage.english;

  String _transcript = '';
  bool _listening = false;
  bool _checking = true;

  MicrophoneAccess? _microphone;
  bool _recogniserAvailable = false;
  String? _resolvedLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDeviceState());
  }

  @override
  void dispose() {
    // Never leave the microphone open behind us.
    context.read<SpeechRecogniser>().cancel();
    super.dispose();
  }

  Future<void> _refreshDeviceState() async {
    if (!mounted) return;
    setState(() => _checking = true);

    final permissions = context.read<MicrophonePermissions>();
    final speech = context.read<SpeechRecogniser>();

    final microphone = await permissions.microphoneStatus();
    final available = await speech.initialise();
    final locale = await speech.resolveLocale(_language);

    if (!mounted) return;
    setState(() {
      _microphone = microphone;
      _recogniserAvailable = available;
      _resolvedLocale = locale;
      _checking = false;
    });
  }

  Future<void> _changeLanguage(ReadingLanguage language) async {
    setState(() {
      _language = language;
      _transcript = '';
      _resolvedLocale = null;
    });
    final speech = context.read<SpeechRecogniser>();
    final locale = await speech.resolveLocale(language);
    if (!mounted) return;
    setState(() => _resolvedLocale = locale);
  }

  Future<void> _toggleListening() async {
    final speech = context.read<SpeechRecogniser>();
    final permissions = context.read<MicrophonePermissions>();
    final settings = context.read<SettingsState>();

    if (_listening) {
      await speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    setState(() {
      _transcript = '';
      _checking = true;
    });

    var access = await permissions.microphoneStatus();
    if (access != MicrophoneAccess.granted) {
      access = await permissions.requestMicrophone();
    }

    if (!mounted) return;
    if (access != MicrophoneAccess.granted) {
      setState(() {
        _microphone = access;
        _checking = false;
      });
      return;
    }

    speech.preferOnDevice = settings.preferOnDevice;

    final failure = await speech.listen(
      language: _language,
      onTranscript: (transcript, confidence) {
        if (mounted) setState(() => _transcript = transcript);
      },
      onSessionEnd: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );

    if (!mounted) return;
    setState(() {
      _microphone = access;
      _checking = false;
      _listening = failure == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsState>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.diagnosticsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(l10n.diagnosticsIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),

          _StatusCard(
            checking: _checking,
            rows: [
              _StatusRow(
                label: l10n.diagnosticsMicPermission,
                value: _microphoneLabel(l10n, _microphone),
                ok: _microphone == MicrophoneAccess.granted,
              ),
              _StatusRow(
                label: l10n.diagnosticsRecogniser,
                value: _recogniserAvailable
                    ? l10n.diagnosticsAvailable
                    : l10n.diagnosticsUnavailable,
                ok: _recogniserAvailable,
              ),
              _StatusRow(
                label: l10n.diagnosticsRecogniserLanguage,
                value: _resolvedLocale ?? l10n.diagnosticsNoneInstalled,
                ok: _resolvedLocale != null,
              ),
              _StatusRow(
                label: l10n.diagnosticsOnDeviceMode,
                value: settings.preferOnDevice
                    ? l10n.diagnosticsOnDeviceModeValue
                    : l10n.diagnosticsNetworkModeValue,
                ok: true,
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            l10n.settingsAppLanguage,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final language in ReadingLanguage.values)
                ChoiceChip(
                  label: Text(l10n.readingLanguageName(language)),
                  selected: language == _language,
                  onSelected: (_) => _changeLanguage(language),
                ),
            ],
          ),

          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kHearingTestSentences[_language] ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.diagnosticsHeard,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _transcript.isEmpty ? l10n.diagnosticsNothingYet : _transcript,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _checking ? null : _toggleListening,
            icon: Icon(_listening ? Icons.stop : Icons.mic_none),
            label: Text(
              _listening ? l10n.actionStop : l10n.actionStartListening,
            ),
          ),

          const SizedBox(height: 16),
          Text(
            l10n.diagnosticsPrivacyNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _microphoneLabel(AppLocalizations l10n, MicrophoneAccess? access) {
    return switch (access) {
      MicrophoneAccess.granted => l10n.diagnosticsGranted,
      MicrophoneAccess.denied ||
      MicrophoneAccess.permanentlyDenied ||
      MicrophoneAccess.restricted =>
        l10n.diagnosticsDenied,
      null => l10n.diagnosticsUnknown,
    };
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.rows, required this.checking});

  final List<_StatusRow> rows;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          children: [
            if (checking)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            for (final row in rows) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      row.ok ? Icons.check_circle : Icons.error_outline,
                      size: 20,
                      color: row.ok
                          ? const Color(0xFF2E7D32)
                          : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(row.label)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        row.value,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusRow {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;
}
