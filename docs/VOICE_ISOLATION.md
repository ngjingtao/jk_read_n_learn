# Voice isolation

> **Status: designed, not implemented.** This document is the plan. The code
> seam exists; the signal processing does not.

## The problem

A child practising at home is rarely alone. A parent or teacher reads along,
prompts them when they get stuck, or repeats a word. A sibling talks. A
television plays in the next room.

All of that reaches the recogniser. Because the recogniser does not know or care
who is speaking, the transcript fills up with words the child never said, and
the marks are wrong in the worst possible direction: **the child is credited for
words a helpful adult said for them.**

This is not a cosmetic problem. In the current build there is a dedicated
"words I heard that are not in the passage" panel on the result screen, and when
that list is long the likeliest explanation is a second voice — not a child
making mistakes.

## What v1 actually does

Nothing, and it says so.

`VoiceSeparationRegistry.active` returns a `PassthroughVoiceSeparator`, whose
description is displayed to the parent: *"No filtering. Every voice in the room
can be picked up by the recogniser."*

Doing nothing is defensible. Silently pretending to filter, or quietly
mis-scoring, is not.

## Where the seam is

`lib/services/voice_separator.dart`:

```dart
abstract class VoiceSeparator {
  String get id;                 // stable, safe to persist
  String get displayName;        // shown to a parent
  String get description;        // one honest line about what it does
  bool get isAvailable;          // can this device run it right now?

  Future<IsolatedAudio> isolate(
    CapturedAudio input, {
    List<String> expectedSpeakers = const [],
  });
}
```

`CapturedAudio` deliberately carries almost nothing yet — a source enum, sample
rate, channel count, and an optional file path. That is the one type a real
implementation has to extend, and it is intentionally the smallest surface
possible.

Registering an implementation makes it the default immediately:

```dart
final registry = VoiceSeparationRegistry();
registry.register(const OnDeviceTargetSpeakerExtraction());
// registry.active is now the new separator; no other code changes.
```

## The architectural finding that changes everything

**`speech_to_text` cannot transcribe a file.** It opens the microphone and
streams from it. It has no API for "here is a WAV, what was said".

So voice isolation is not a drop-in stage. The two possible shapes are:

### Shape A — streaming filter (keeps the current recogniser)

```
microphone ──► [ filter: pass only the child ] ──► speech_to_text
```

The filter runs as a live DSP stage inside the audio callback and forwards only
frames believed to be the child. `CapturedAudio.source` would be
`liveRecogniserStream`.

*Problem:* `speech_to_text` owns the audio session. There is no supported hook to
intercept and modify its frames. Making this work means a custom platform
channel with a native audio pipeline, on both iOS and Android. Real work, but it
keeps the recogniser.

### Shape B — batch separation (needs a different recogniser)

```
microphone ──► record to file ──► [ separate ] ──► recognise file ──► align
```

Record, isolate, then transcribe the cleaned audio. `CapturedAudio.source` would
be `file`.

*Problem:* needs a recogniser that takes a file. That means an on-device engine
such as `whisper.cpp`, `sherpa-onnx` or `Vosk`, each with its own model size and
accuracy tradeoffs, and each needing a model bundled or downloaded per language.

*Advantage:* it also unlocks Phase 3 of the roadmap. A file-based pipeline can
run phoneme-level forced alignment, which is a far more accurate grader than
text comparison. **Batch separation and better pronunciation scoring are the
same architectural move.**

**Recommendation: Shape B.** The extra recogniser work is not additional cost —
it is work that Phase 3 needs regardless. Shape A delivers voice isolation but
leaves the grader text-based forever.

## Candidate filtering techniques

Ranked from cheapest to most effective.

### 1. Voice activity detection (VAD)

Don't open the recogniser until the child actually speaks. Cheap, no model
needed, and it removes silence and room tone.

*Does not solve the problem:* a talking parent is still speech.

### 2. Turn-taking and prompting heuristics

A teacher's voice usually arrives as a short prompt *before* the child reads,
not simultaneously. Detect the pattern — prompt, then sustained child speech —
and score only the sustained stretches.

*Cheap, partial, fragile.* Warps the transcript whenever it guesses wrong.
Useful as a supporting signal, not a solution.

### 3. Speaker diarisation

Segment the audio by speaker ("speaker 1", "speaker 2"), then discard segments
that are not the target.

*Needs a way to decide which segment is the child.* Two options: ask the parent to
pick one after the fact (acceptable UX, and honest), or enrol the child's voice
up front with a ~15 second sample and match embeddings.

*Failure mode:* overlapping speech. When the parent and child talk at once —
which is exactly when prompting happens — diarisation cannot cleanly split them.

### 4. Target speaker extraction (the real fix)

Also called the "cocktail party problem". Given a reference embedding of the
child's voice, extract *only* that voice from a mixed signal, including during
overlap. Modern neural approaches do this well.

*Best quality. Heaviest.* Needs an enrolled voice profile and an on-device model
(a few MB, more with better accuracy). There are mobile-friendly open models;
none were evaluated during this build.

*Privacy upside:* enrolment and inference both stay on device. A child's voice
biometric never leaves the tablet — which is the right default, and worth
protecting explicitly in the design.

### 5. Hardware and physicality

Unglamorous and effective. A lapel or headset microphone close to the child's
mouth improves the signal-to-noise ratio more than any model, and gives a
separation algorithm far better material to work with.

Worth surfacing to parents: *"a headset gives noticeably better marks than the
tablet microphone."* Cheap to say, immediately true.

### 6. Flow design

The cheapest intervention of all.

- Ask the parent **not** to prompt during a scoring attempt.
- Separate *practice* (help allowed, not scored) from *testing* (no help,
  scored). Two obvious buttons, one honest contract.

This costs nothing, works on every device, and should ship **before** any DSP.

## Recommended sequence

1. **Flow** — split practice from scoring; ask the parent not to help.
2. **VAD** — stop listening to silence.
3. **Enrolment** — record the child once, keep the embedding on device.
4. **Batch pipeline** — record → separate → recognise, which also brings
   phoneme-level scoring.
5. **Target speaker extraction** — swap the separator implementation behind the
   existing `VoiceSeparator` interface.

Each step is independently useful and none requires throwing the previous one
away.

## What has to change in the code

| Concern | Change |
| --- | --- |
| `VoiceSeparator` | No change — the interface already fits |
| `CapturedAudio` | Add PCM frames or a file path plus format details |
| Recording | New service; needs `record` + `path_provider` |
| Recognition | Replace or supplement `SpeechService` with a file-capable engine |
| `ReadingSessionController` | Insert record → separate → recognise between "done" and "score" |
| UI | An extra "preparing audio" phase, and an enrolment flow |
| Storage | Keep voice embeddings; decide retention and deletion |

## Privacy, and why it is not negotiable here

This is **biometric data belonging to a minor**. Enrolling a child's voice
creates a template that identifies them, and voice recordings of children are
sensitive personal data under Malaysia's PDPA and are treated as special-category
data under GDPR.

Therefore, as a design constraint from the start:

- Enrolment and inference stay **on device**. No voice data to a server without a
  separately-consented, clearly-explained, opt-in path.
- Embeddings are deletable, from a visible setting, by the parent.
- Recorded audio is not retained beyond scoring unless the parent opts in.
- The parent can always see, plainly, what the app is currently doing — the
  existing "What the microphone hears" sheet is that surface, and it should keep
  telling the truth as the implementation improves.

## How to know it works

A filter is only worth shipping if it can be measured. A test protocol:

1. Record a scripted session: a child reading a known passage while an adult
   prompts, plus a television in the background.
2. Score it with and without isolation.
3. Compare against the ground-truth transcript of *only the child's* speech.

Metrics that matter:

- **Word error rate against the child-only ground truth** — did the extra voice
  disappear?
- **False deletions** — did the filter also eat words the child genuinely said?
  This is the dangerous direction: it loses the child marks they earned.
- **Overlap survival** — does it still work when the parent and child speak at
  the same time? This is where diarisation fails and extraction must cope.

Target: false deletions near zero, and a large drop in word error rate versus the
passthrough baseline. A filter that improves the average but occasionally deletes
a correctly-read word will be experienced by the child as the app being unfair,
which is worse than no filter at all.
