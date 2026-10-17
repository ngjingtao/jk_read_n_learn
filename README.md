# JK Read n Learn

A tablet app (iPad and Android) that teaches children to read aloud in **English**,
**Chinese** and **Bahasa Malaysia**.

A child opens a passage, taps any word to hear it pronounced, then reads the
passage out loud. The app listens, compares what it heard against what was
written, marks every word, and pays the child in **JKD** (*Jiong Ke Dollar*) —
the in-app reward currency.

The interface itself is available in **中文 (default)**, English and Bahasa
Melayu.

---

## Current status

A working **vertical slice** with the full loop, plus the first round of
device-reliability work. `flutter analyze` is clean and **125 tests** pass.

| Feature | Status |
| --- | --- |
| Read a passage in en / zh / ms | ✅ Working |
| Tap any word to hear it pronounced | ✅ Working |
| Tap to hear the whole passage | ✅ Working |
| Listen to the child read aloud | ✅ Working |
| Word-level marking (correct / close / missed / added) | ✅ Working |
| Confidence-aware marking (flags words the microphone was unsure about) | ✅ Working |
| Points and JKD reward, saved on device | ✅ Working |
| Reward history / savings book | ✅ Working |
| Reward shop — spend JKD on a sticker collection | ✅ Working |
| Reading streaks (current and longest) | ✅ Working |
| Per-passage records (attempts, best accuracy, best speed) | ✅ Working |
| Reading comfort: text size, line spacing, reduce motion | ✅ Working |
| Interface in Chinese, English, Bahasa Melayu | ✅ Working |
| Microphone permission handling, with a route to system settings | ✅ Working |
| Auto-finish when the child stops talking | ✅ Working |
| Hearing test (diagnose the microphone and recogniser) | ✅ Working |
| On-device-only recognition as a parent setting | ✅ Working |
| Voice isolation (filter out a teacher or sibling) | 🔷 Designed, not implemented |

### What has **not** been built yet

- **Accounts and sync.** The wallet is local to one device. See
  [`docs/ROADMAP.md`](docs/ROADMAP.md).
- **Phoneme-level pronunciation scoring.** Marking is text-based, so it can tell
  that a word was said wrongly but not *which sound* was wrong.
- **Voice isolation.** A parent reading along will currently end up in the
  transcript. The seam for fixing this is already in the code — see
  [`docs/VOICE_ISOLATION.md`](docs/VOICE_ISOLATION.md).
- **Essays from a server.** Passages are bundled; adding more is a data change in
  `lib/data/sample_essays.dart`.
- **Nothing has run on real hardware yet.** See "Not yet verified" below.

---

## Running it

Requires Flutter 3.47 or newer.

```bash
flutter pub get
flutter run          # pick an iOS or Android device/tablet
```

Checks:

```bash
flutter analyze
flutter test
```

After editing any `.arb` file in `lib/l10n`, regenerate the strings:

```bash
flutter gen-l10n
```

### Building

```bash
flutter build apk --release      # Android — needs the Android SDK
flutter build ios --no-codesign  # iOS — needs macOS and Xcode
flutter build web --release      # Web — needs nothing but Chrome
```

The **web** build is the odd one out and earns its keep: it needs no mobile SDK,
so it can run anywhere, and it exercises the whole Dart codebase plus plugin
registration. It is how this project was verified before it ever had an Android
SDK. Microphone access on web uses the browser's own speech engine, so it is a
usable demo rather than a supported target. Web is also why `web/` exists in a
project whose real targets are iPad and Android.

### Continuous integration

`.github/workflows/ci.yml` builds all three targets on every push:

| Job | Runner | Proves |
| --- | --- | --- |
| `analyse-test` | ubuntu | Analyzer is clean, 125 tests pass, localisations are up to date |
| `android` | ubuntu | Manifest, Gradle config and every plugin link; uploads an APK |
| `ios` | macos | Info.plist usage strings and CocoaPods link |
| `web` | ubuntu | Full Dart compile; uploads a browsable build |

`analyse-test` gates the rest, so a broken build costs one fast job instead of
three slow ones. The APK is signed with the debug key — fine for handing a
tablet to a teacher, not for the Play Store.

## Deploying it to a tablet

The web build is the fastest way onto an iPad or an Android tablet: open a URL
in the browser, no app store, no signing.

### Option A — GitHub Pages (recommended)

Free, no account to create, HTTPS by default, and no cold start.

1. Repository → **Settings** → **Pages** → **Build and deployment** →
   **Source: GitHub Actions**.
2. Push to `main`. The `deploy-pages` job builds and publishes automatically.
3. The URL is `https://<user>.github.io/<repo>/`.

The build passes `--base-href /<repo>/`, because Pages serves from a subpath.
Without it the page loads and then shows a blank screen.

### Option B — Render

`Dockerfile` and `render.yaml` are in the repository, so Render can create the
service from **New +** → **Blueprint** with no form-filling.

If you configure it by hand instead, choose **Docker** as the runtime — Render
looks for `Dockerfile` at the repository root, and a missing one is the cause of
`failed to read dockerfile: open Dockerfile: no such file or directory`.

> ⚠️ **Render's free tier sleeps after 15 minutes of inactivity.** Waking takes
> 30–60 seconds. For a child who wants to read *right now*, that is a bad first
> impression — which is why Pages is the recommendation.

### Read this before relying on the web version

The web build is a **demo, not the product**. Three things differ from the
native apps, and all three matter:

| | Native app | Web build |
| --- | --- | --- |
| Where audio goes | On-device where the model exists | **To Google's or Apple's servers** — browsers do not do offline speech recognition |
| Malay (`ms-MY`) | Recogniser may be installed | **Very likely unsupported** by the browser |
| Reliability | Native speech APIs | Varies by browser and version; iOS Safari is the weakest |

So: the web build is excellent for **checking the interface, the marking logic,
the wallet and the shop** on a real device. It is not a fair test of the
microphone behaviour, and it is not the privacy story the app is designed
around. See `docs/VOICE_ISOLATION.md` and `docs/ROADMAP.md` Phase 2.

### Device setup that matters

Speech recognition **will not work** until the relevant language pack is
installed on the device. This is the single most common reason the app appears
broken, which is exactly why the app now has a **hearing test** (Settings →
Hearing test) that shows the microphone status, recogniser availability, and
whether a matching language pack was found.

- **Android:** Settings → System → Languages & input → On-device speech
  recognition (varies by manufacturer). Also needs Google's speech services.
- **iOS:** Settings → General → Keyboard → Keyboards → Add New Keyboard, and
  enable Dictation.

`ms-MY` (Bahasa Malaysia) recognisers are uncommon. The app falls back through a
list of locale candidates and reports precisely which of the four possible
problems it hit, rather than failing silently.

---

## How marking works

1. The passage is split into gradeable units — **words** for English and Malay,
   **individual characters** for Chinese. Punctuation is kept for display and is
   never graded.
2. The recogniser streams back a transcript of what the child said.
3. The transcript is aligned against the passage with a
   **Needleman–Wunsch sequence alignment** — the standard bioinformatics
   technique, which happens to fit reading assessment almost perfectly:
   - a word read as written → **match**
   - a word skipped → **deletion**
   - a word added → **insertion**
   - a word garbled → **substitution**, with a cost proportional to how garbled

   Because the cost is a smooth character-level similarity rather than a
   correct/incorrect flag, the alignment still finds the sensible pairing when a
   child mangles a word.
4. Each word becomes:

   | Colour | Meaning | Points |
   | --- | --- | --- |
   | 🟩 Green | Read correctly | 10 |
   | 🟧 Amber | Nearly right, partial credit | 3 |
   | 🟥 Red | Missed, or a different word entirely | 0 |
   | ⬜ Grey | Word added that is not in the passage | 0 |

5. A **completion bonus** of 25 points is paid once lenient accuracy reaches
   60%. This is deliberate: a struggling six-year-old must still earn something
   for trying, or the reward stops motivating them.
6. Points convert to JKD at **100 points = 1 JKD**.

Every one of those numbers lives in `ScoringConfig`
(`lib/core/app_config.dart`) and is covered by tests. Grading rules are the part
parents and teachers will argue about, so they are deliberately not buried in
the UI.

---

## The JKD economy

A reward currency that can only ever grow stops working after about a week, so
earning and spending are both real.

**Earning.** Marks convert to JKD and land in a savings book with a full ledger.
Entries are signed, so earnings and purchases share one history.

**Spending.** The reward shop sells a ladder of stickers, from `0.50 JKD` to
`20.00 JKD`. Prices are calibrated against the reward rate — the cheapest is
about one clean 60-word passage, so a child sees the loop close the first time
they read well. Each reward is owned once, and the collection sits at the top of
the shop.

**Streaks.** Consecutive days with at least one reading session. A streak is not
broken at midnight: if a child has not read *yet* today but read yesterday, it
still counts, because resetting it while they are asleep would be absurd. The
best-ever streak is kept separately.

**Records.** Every passage remembers how many times it has been read, the best
accuracy, and the best speed. Beating your own best shows a banner — but only
beating it, never a first attempt, because celebrating an improvement on nothing
is how a reward stops meaning anything.

The catalogue prices are considered guesses, not measurements. Expect to retune
them against real children; see `docs/ROADMAP.md` Phase 6.

---

## When the recogniser is not sure

The worst failure of text-based marking is that modern recognisers
**auto-correct**. A child says "fink", the recogniser returns "think", and the
app awards full marks for a word they mispronounced. The transcript cannot show
this — but the recogniser's own confidence can.

`speech_to_text` rates its output per *utterance*, not per word. So
`ConfidenceTracker` does the only thing available: it watches the transcript grow
and records the confidence reported each time a new word appears. A word's score
is therefore "how sure was the recogniser when this word showed up" — a proxy,
and documented as one.

Words that matched but scored below the threshold become **unclear** rather than
correct. That is a genuine third state, not a euphemism for wrong:

| Colour | Meaning |
| --- | --- |
| 🟩 Green | Read correctly |
| 🟦 **Blue** | **Heard, but the microphone was not sure** |
| 🟧 Amber | Nearly right |
| 🟥 Red | Missed or wrong |

**By default, unclear words cost the child nothing.** They still earn full marks
and still count toward accuracy, because a quiet reader with a distant tablet
must never be punished for the microphone. The result screen shows them in blue,
lists the words, and points the parent at the microphone rather than at the
child.

A setting turns on **strict marking**, which is the opposite trade: unclear words
then lose some marks, which is what catches a mispronunciation the recogniser
quietly corrected. That is a deliberate opt-in, not the default.

Two properties matter more than the accuracy of the threshold:

- **It fails safe.** When the platform reports no confidence — common on Android
  — every entry stays unknown and no word is ever downgraded. A device without
  confidence ratings behaves exactly as it did before this existed.
- **The threshold is uncalibrated.** It uses the same `0.8` that `speech_to_text`
  itself suggests, which is a reasonable starting point and nothing more. It is a
  single constant precisely so that calibration means changing one value. This
  needs real-device data — see `docs/ROADMAP.md` Phase 3.

---

## Interface language vs passage language

These are two independent choices, and confusing them would be a real bug:

- **Interface language** (`UiLanguage`) — the language of menus and buttons.
  Defaults to **Chinese**. Changed in Settings, and remembered.
- **Passage language** (`ReadingLanguage`) — the language of the text the child
  reads. Chosen on the home screen with the chips.

A Malay-speaking parent can have a Chinese interface while their child practises
English. Passage titles are never translated.

Malay is tagged **`ms`**, not `bm`: `bm` is the ISO code for Bambara, and using
it would make Flutter's own Material widgets render in the wrong language.

---

## Project layout

```
lib/
  core/app_config.dart              Scoring constants, all in one place
  models/
    app_language.dart               Passage languages: en / zh / ms
    essay.dart                      A passage
    money.dart                      JKD, stored as integer hundredths
    reward.dart                     The sticker catalogue you spend JKD on
    scoring_models.dart             EssayToken, WordStatus, ScoreGrade, ScoreResult
  data/sample_essays.dart           Bundled passages + hearing-test sentences
  l10n/
    app_en.arb · app_zh.arb · app_ms.arb
    generated/                      Produced by `flutter gen-l10n`
  services/
    tts_service.dart                Speaker interface + text-to-speech engine
    speech_service.dart             SpeechRecogniser interface + recogniser
    permission_service.dart         MicrophonePermissions interface + permissions
    voice_separator.dart            Voice-isolation seam (see docs/VOICE_ISOLATION.md)
    scoring/
      text_utils.dart               Tokenising, normalisation, similarity
      phonetic.dart                 Spelling-to-sound skeleton for English
      token_comparator.dart         Chooses how two words are compared
      aligner.dart                  Needleman–Wunsch alignment
      reading_scorer.dart           Words in, marks and JKD out
  state/
    wallet_state.dart               JKD balance and ledger, persisted
    progress_state.dart             Streaks, per-passage records, collection
    settings_state.dart             Language, speech, reading comfort
    reading_session_controller.dart One reading attempt, start to finish
  ui/
    l10n_extensions.dart            Domain enums → translated text
    home_screen.dart                Language picker, streak, passage list
    reader_screen.dart              The passage, listening, "All done"
    result_screen.dart              Marks, records, streak, reward
    wallet_screen.dart              Savings book
    shop_screen.dart                Spend JKD on stickers
    settings_screen.dart            Language, speech, reading comfort, about
    diagnostics_screen.dart         Hearing test
    widgets/essay_text.dart         Tappable, colour-codable passage text
test/                               Unit, widget and localisation tests
docs/                               Architecture, roadmap, voice isolation
```

The grading engine (`services/scoring/`) is pure Dart with no Flutter or plugin
dependencies, which is why it can be tested exhaustively and runs instantly.

The audio engines are hidden behind three small interfaces — `Speaker`,
`SpeechRecogniser` and `MicrophonePermissions`. That is what lets the whole
session controller be tested against fakes, with no microphone and no platform
channel.

---

## Not yet verified

The Dart code is proven: `flutter analyze` is clean, 125 tests pass, and
`flutter build web --release` completes with exit code 0.

What is **not** verified is anything native:

- No Android SDK on the machine this was written on, so `flutter build apk` has
  never run.
- No macOS, so `flutter build ios` has never run.
- No tablet has ever run the app, so the two audio plugins, the permission
  dialogs, and whether `ms-MY` resolves on the tablets families actually own are
  all still unproven.

The CI workflow above is how those get closed — it builds Android and iOS on
every push. The exceptions in the project are declared in the manifest and
`Info.plist`, but only a real build proves they are correct.

Phase 2 in the roadmap exists for the device work that no amount of CI can
replace: watching a real six-year-old use it.

---

## Adding a passage

Append an `Essay` to `kSampleEssays` in `lib/data/sample_essays.dart`:

```dart
const Essay(
  id: 'en-my-new-story',
  title: 'My New Story',
  language: ReadingLanguage.english,
  gradeLevel: 2,
  text: 'The text the child will read...',
),
```

Nothing else needs to change — the tokeniser, marker and reader screen all adapt
to the language.

## Adding an interface string

1. Add the key to `lib/l10n/app_en.arb` (the template).
2. Add the same key with a translation to `app_zh.arb` and `app_ms.arb`.
3. Run `flutter gen-l10n`.
4. Use it as `AppLocalizations.of(context).yourKey`.

`test/l10n/localization_test.dart` fails if a key is left copy-pasted in English,
so missing translations are caught rather than shipped.

---

## Further reading

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — how the pieces fit, and why
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — what to build next, in order
- [`docs/VOICE_ISOLATION.md`](docs/VOICE_ISOLATION.md) — filtering out other voices
