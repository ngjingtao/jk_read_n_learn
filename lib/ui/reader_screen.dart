import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/essay.dart';
import '../services/permission_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/voice_separator.dart';
import '../state/reading_session_controller.dart';
import '../state/settings_state.dart';
import '../state/wallet_state.dart';
import 'l10n_extensions.dart';
import 'result_screen.dart';
import 'widgets/essay_text.dart';

/// The reading screen: the passage, a button to hear it, and a button to read
/// it aloud for marks.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.essay});

  final Essay essay;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final ReadingSessionController _controller;
  Timer? _ticker;

  /// Drives the on-screen reading clock only. The authoritative duration for
  /// marks lives inside the session controller.
  final Stopwatch _uiWatch = Stopwatch();

  /// Guards against pushing two result screens when the attempt finishes.
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _controller = ReadingSessionController(
      essay: widget.essay,
      tts: context.read<Speaker>(),
      speech: context.read<SpeechRecogniser>(),
      permissions: context.read<MicrophonePermissions>(),
      wallet: context.read<WalletState>(),
      settings: context.read<SettingsState>(),
      voiceSeparation: context.read<VoiceSeparationRegistry>(),
    )..addListener(_onControllerChanged);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_controller.phase == ReadingPhase.listening && mounted) {
        setState(() {});
      }
    });
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});

    // The attempt can finish two ways: the child taps "All done", or the
    // recogniser closes the session itself when they stop talking. Both end up
    // here rather than in the button handler, so the automatic path is not a
    // second-class citizen that forgets to show the marks.
    if (_controller.phase == ReadingPhase.finished && !_navigating) {
      _navigating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showResult());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.essay.title),
        actions: [
          IconButton(
            tooltip: l10n.howListeningWorks,
            icon: const Icon(Icons.hearing_outlined),
            onPressed: _showAudioInfoSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: EssayText(
                      text: widget.essay.text,
                      language: widget.essay.language,
                      onWordTap: _controller.speakWord,
                    ),
                  ),
                ),
              ),
            ),
            if (_controller.phase == ReadingPhase.listening) _buildLivePanel(theme),
            if (_controller.error != null) _buildErrorBanner(theme),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: _buildControls(theme),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- controls

  Widget _buildControls(ThemeData theme) {
    final l10n = AppLocalizations.of(context);

    switch (_controller.phase) {
      case ReadingPhase.ready:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _controller.isSpeaking ? null : _controller.speakPassage,
                icon: const Icon(Icons.volume_up_outlined),
                label: Text(l10n.actionListen),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.mic_none),
                label: Text(l10n.actionReadAloud),
              ),
            ),
          ],
        );

      case ReadingPhase.checkingPermission:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        );

      case ReadingPhase.listening:
        final seconds = _uiWatch.elapsed.inSeconds;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PulsingDot(color: theme.colorScheme.error),
                const SizedBox(width: 10),
                Text(
                  l10n.listeningStatus(_formatDuration(seconds)),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelListening,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(l10n.actionCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _finishReading,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.actionAllDone),
                  ),
                ),
              ],
            ),
          ],
        );

      case ReadingPhase.scoring:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 14),
            Text(
              l10n.markingInProgress,
              style: theme.textTheme.titleMedium,
            ),
          ],
        );

      case ReadingPhase.finished:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLivePanel(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final transcript = _controller.liveTranscript;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.iCanHear,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            transcript.isEmpty ? 'â€¦' : transcript,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final error = _controller.error!;
    final needsSettings = l10n.errorNeedsSystemSettings(error);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.readingError(error, widget.essay.language),
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
          if (needsSettings)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _openSystemSettings,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(l10n.actionOpenSettings),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- actions

  Future<void> _startListening() async {
    _uiWatch
      ..reset()
      ..start();
    await _controller.startListening();
    if (!mounted) return;
    if (_controller.phase != ReadingPhase.listening) _uiWatch.stop();
  }

  Future<void> _cancelListening() async {
    _uiWatch.stop();
    await _controller.cancelListening();
  }

  Future<void> _finishReading() async {
    _uiWatch.stop();
    await _controller.finishAndScore();
  }

  /// Pushes the marks screen and, on return, resets the passage for a re-read.
  Future<void> _showResult() async {
    final result = _controller.result;
    if (!mounted || result == null) {
      _navigating = false;
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(essay: widget.essay, result: result),
      ),
    );

    if (!mounted) return;
    _navigating = false;
    _controller.retry();
  }

  Future<void> _openSystemSettings() async {
    await context.read<MicrophonePermissions>().openSettings();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }

  void _showAudioInfoSheet() {
    final l10n = AppLocalizations.of(context);
    final registry = context.read<VoiceSeparationRegistry>();
    final settings = context.read<SettingsState>();
    final active = registry.active;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.micSheetTitle,
                style: sheetTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(l10n.micSheetBody, style: sheetTheme.textTheme.bodyMedium),
              const SizedBox(height: 18),
              Text(
                l10n.strategyLabel(l10n.voiceStrategyName(active)),
                style: sheetTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(l10n.voiceStrategyDescription(active)),
              const SizedBox(height: 16),
              Text(
                l10n.speechRecognitionStatus(
                  context.read<SpeechRecogniser>().isAvailable
                      ? l10n.statusAvailable
                      : l10n.statusUnavailable,
                ),
                style: sheetTheme.textTheme.bodySmall,
              ),
              Text(
                settings.preferOnDevice
                    ? l10n.diagnosticsOnDeviceModeValue
                    : l10n.diagnosticsNetworkModeValue,
                style: sheetTheme.textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A small blinking dot used as a "recording" indicator.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_animation),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
