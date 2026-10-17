# Architecture

The guiding constraint is that **a six-year-old's reading score must be
explainable and reproducible**. Everything else follows from that.

## Layers

```
        UI              home_screen · reader_screen · result_screen · wallet_screen
         │              settings_screen · diagnostics_screen · l10n_extensions
         │              (thin: no marking logic, no audio sequencing, no literals)
         ▼
      State             ReadingSessionController · WalletState · SettingsState
         │              (owns the phase machine and the audio ordering rules)
         ▼
     Ports              Speaker · SpeechRecogniser · MicrophonePermissions
         │              VoiceSeparationRegistry
         ▼
   Adapters             TtsService · SpeechService · PermissionService
         │              (one place each that talks to a platform plugin)
         ▼
   Scoring engine       ReadingScorer · ReadingAligner · text_utils
                        (pure Dart, zero Flutter, zero plugins)
```

Dependencies point strictly downwards. The scoring engine imports nothing from
the layers above it, which is what makes it exhaustively testable and instant.

## The audio engines sit behind interfaces

`Speaker`, `SpeechRecogniser` and `MicrophonePermissions` are narrow interfaces;
`TtsService`, `SpeechService` and `PermissionService` are the plugin-backed
implementations. `ReadingSessionController` depends only on the interfaces.

This was not decoration. The first version had the controller depend on the
concrete classes, so the test fakes had to `extends TtsService` — which meant
every test constructed a real `FlutterTts`, and immediately failed with
*"Cannot set the method call handler before the binary messenger has been
initialized"*. The fakes were paying for a platform dependency they never used.

Three things fall out of fixing it properly:

- The whole session state machine is tested against fakes: 20 tests covering
  permission denial, silence timeouts, double payment and every recogniser
  failure mode — with no microphone and no device.
- The controller cannot accidentally reach for plugin-specific behaviour,
  because the interface does not expose any.
- Swapping the recogniser — exactly what voice isolation needs, see
  [`VOICE_ISOLATION.md`](VOICE_ISOLATION.md) — becomes a one-line change in
  `app.dart`.

Providers are registered by interface, not by implementation:

```dart
Provider<Speaker>(create: (_) => TtsService()),
Provider<SpeechRecogniser>(create: (_) => SpeechService()),
Provider<MicrophonePermissions>(create: (_) => const PermissionService()),
```

## Localisation

The interface ships in Chinese (default), English and Bahasa Melayu, generated
from ARB files by `flutter gen-l10n`.

Two rules keep this from rotting:

**The domain layer never produces strings.** `ScoreResult.grade` returns a
`ScoreGrade` enum, not `'Outstanding'`; `ReadingSessionController.error` returns a
`ReadingError` enum, not a sentence. The models have no business knowing which
language the interface is in, and this keeps the grading engine testable with no
localisation at all.

**One place bridges the two.** `lib/ui/l10n_extensions.dart` is the only code
that maps a `ScoreGrade`, a `ReadingError`, a `TokenMode` or a voice strategy to
words on screen.

`test/l10n/localization_test.dart` asserts that a set of important keys actually
*differ* from their English originals in both other languages. `gen-l10n` will
happily copy the template over a missing translation, so without that test an
entirely untranslated screen can ship looking correct in review.

## Interface language vs passage language

`UiLanguage` (menus) and `ReadingLanguage` (the text being read) are separate
types and separate settings, on purpose. A Malay-speaking parent may want a
Chinese interface while their child practises English.

Malay is `ms`, not `bm`. `bm` is the ISO code for Bambara, and Flutter's
`GlobalMaterialLocalizations` would render its own widgets in Bambara rather than
Bahasa Malaysia. A test pins this.


## Data flow of one reading attempt

```
Essay.text ──► tokenize() ──► gradeable words + display tokens
                                      │
microphone ──► SpeechService ──► transcript ──► tokenize()
                                      │
                              ReadingAligner.align()
                                      │
                             ReadingScorer.score()
                                      │
                     ┌────────────────┼────────────────┐
                     ▼                ▼                ▼
              per-word status    points/JKD      WalletState.credit()
```

## Key decisions

### The scoring engine has no Flutter dependency

`lib/services/scoring/` is plain Dart. That means:

- 43 tests run in a couple of seconds with no device, no emulator, no plugins.
- `ReadingScorer` is pure: same inputs, same output. No I/O, no clock, no state.
- A teacher or parent can be shown exactly why a word lost marks.

This is the part of the app most likely to be disputed, so it is the part
tested hardest.

### Passage text is tokenised once, per language

`tokenize()` returns a list of `EssayToken`s that **reconstructs the original
string exactly** when concatenated. Gaps between words are emitted as
non-gradeable filler tokens.

This one decision buys three things:

- The reader screen paints real prose, not a grid of word chips.
- Punctuation is never graded and never tappable (the test suite asserts this).
- English, Malay and Chinese share one code path; only `TokenMode` differs.

`TokenMode.character` exists because Chinese has no spaces. Each Han character
becomes its own gradeable unit, so "我爱学校" is four marks, not one.

### Alignment uses Needleman–Wunsch, not a similarity score

The naive approach — transcribe everything, diff the strings, produce one
percentage — gives a number and nothing else. It cannot tell the child *which*
word they missed, and it punishes a skipped word and a mispronounced word
identically.

Sequence alignment models the four things that actually happen when a child
reads:

| What happened | Alignment op |
| --- | --- |
| Read as written | match |
| Skipped a word | deletion |
| Added a word | insertion |
| Garbled a word | substitution |

Substitution cost is `1 − similarity`, a smooth character-level measure. A
garbled word therefore costs less than a completely different word, so the
alignment keeps its place in the sequence instead of desynchronising and
corrupting every subsequent mark. That robustness is the whole point.

### Speech must stop before the microphone opens

The speaker and the microphone share one audio session. If text-to-speech is
still running when listening starts, the recogniser transcribes the app's own
voice and the child's score is nonsense.

This is enforced in one place, `ReadingSessionController.startListening()`,
rather than being the UI's responsibility to remember. It is the single easiest
bug to reintroduce, and the most confusing when it happens.

### The recogniser can end the session, and the app must notice

The platform closes the listening session by itself once the child stops talking
for a few seconds. The first version only left the `listening` phase when the
child tapped "All done" — so a child who simply stopped reading left the app
sitting on a frozen "Listening…" screen forever, with the microphone open and no
way forward that a six-year-old would find.

`SpeechService` now reports the platform's `done` status back through an
`onSessionEnd` callback, distinguishing an ending *it* caused from one the app
asked for (`_stopRequested`), and `ReadingSessionController` marks whatever it
heard. Navigation to the results screen is driven by the phase change rather than
by the button handler, so the automatic path and the manual path are the same
code.

A test asserts that a second finish call cannot pay the reward twice, because
those two paths can now race.

### Money is an integer, not a double

`Jkd` stores hundredths as an `int`. Repeatedly adding `0.01` to a `double`
accumulates error; a child who has earned 137 rewards should still see the
balance they earned. `Jkd` also implements `operator ==` — an early test caught
that `Jkd(55) == Jkd(55)` was `false`, which would have silently broken both the
tests and any future spending logic.

### Errors surface as messages, not crashes

Audio plugins throw for mundane, recoverable reasons: a missing voice, a busy
audio session, an uninstalled language pack. `ReadingSessionController`
converts these into a sentence a parent can act on. A corrupt wallet ledger is
discarded and rebuilt rather than blocking the child from reading.

## Extension points

| Want to… | Change |
| --- | --- |
| Adjust marking | `ScoringConfig` in `lib/core/app_config.dart` |
| Add a passage | `kSampleEssays` in `lib/data/sample_essays.dart` |
| Add a passage language | A new `ReadingLanguage` enum value |
| Add an interface language | A new `.arb` file plus a `UiLanguage` value |
| Add an interface string | `app_en.arb` first, then the translations, then `flutter gen-l10n` |
| Replace the marking algorithm | `ReadingAligner` / `ReadingScorer` |
| Swap the speech engine | A new `SpeechRecogniser` implementation, registered in `app.dart` |
| Filter other voices | Implement `VoiceSeparator`, register it — see `docs/VOICE_ISOLATION.md` |
| Move essays to a server | Replace `kSampleEssays`; nothing else reads them directly |

## Known constraints

- **Not phoneme-aware.** A text-based grader can flag "fink" for "think" but
  cannot say which sound was wrong. Fixing this means a pronunciation-assessment
  API; see the roadmap.
- **Accommodating speech-to-text.** Modern recognisers auto-correct, so a child's
  mispronunciation is sometimes transcribed as the correct word and scores full
  marks. This is the ceiling of the current approach and the main argument for
  moving to phoneme scoring.
- **Local-only wallet.** Tied to one device until there is a backend.
- **`ms-MY` recognition is scarce.** Fallback candidates are tried, and a clear
  message is shown when none is installed.
