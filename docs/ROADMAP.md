# Roadmap

Ordered by what unblocks the most. Nothing below is started unless marked.

---

## ✅ Phase 1 — Vertical slice (done)

The whole loop, end to end, for one passage in one language at a time.

- [x] Read a passage in en / zh / bm
- [x] Tap any word to hear it pronounced
- [x] Listen to the child and stream a live transcript
- [x] Word-level marking via Needleman–Wunsch alignment
- [x] Points → JKD reward, persisted on device
- [x] Reward history
- [x] Grading engine unit-tested and widget-tested (43 tests)

---

## Phase 2 — Make it trustworthy on a real device

The slice works on a developer machine. Some of this round is done; the rest
genuinely needs hardware.

- [x] Handle permission denial gracefully, with distinct messages for
      "ask again" and "only system settings can fix this", plus a button that
      opens them.
- [x] Add a **hearing test** screen showing microphone permission, recogniser
      availability, the resolved locale, and a live transcript. This turns "it
      does not work" into a four-second diagnosis.
- [x] Auto-stop on prolonged silence, and mark what was heard instead of leaving
      the child staring at a frozen "listening" screen.
- [ ] Run on a physical iPad and a physical Android tablet with Standard 1
      students; watch a real session happen.
- [ ] Verify the `ms-MY` fallback chain on real devices and record which
      candidates actually resolve.
- [ ] Confirm the audio session recovers after a phone call or another app
      grabbing the microphone.
- [ ] Test with a genuinely quiet child, and tune `pauseFor` (currently 6s) so a
      hesitant reader is not cut off mid-sentence.

**Exit criteria:** a teacher can hand the tablet to a child and get a correct
score without helping.

---

## Phase 3 — Real pronunciation accuracy

The current grader is text-based, so it cannot hear *which sound* was wrong, and
a modern recogniser will sometimes auto-correct a child's error into the right
word and award full marks.

Two options, and the choice matters:

- [ ] **Phoneme/pronunciation assessment API** (Azure Speech pronunciation
      assessment, or Google's equivalent). Gives per-phoneme scores, detects
      omissions and substitutions, and is genuinely accurate.
      *Cost:* needs a network round trip per attempt, costs money per request,
      and ships a child's voice to a server. Needs a clear privacy decision.
- [ ] **On-device phoneme comparison.** Align the transcript *phonemically*
      rather than as text, using eSpeak-style grapheme-to-phoneme conversion
      plus forced alignment. No network, no cost, no data leaves the device.
      *Cost:* significantly more work, and weaker on tones (which matters for
      Chinese).

Recommendation: build the phonemic aligner as the local default and offer the
API as a "best accuracy" mode the parent opts into. The `ReadingAligner`
interface already allows swapping the comparison strategy without touching the
scorer or the UI.

- [ ] Tone accuracy for Chinese, which text comparison cannot see at all.

---

## Phase 4 — Voice isolation

Currently a parent reading along, a sibling, or a television ends up in the
transcript and corrupts the marks. The seam exists; the DSP does not. See
[`VOICE_ISOLATION.md`](VOICE_ISOLATION.md) for the full analysis.

- [ ] Voice activity detection: do not open the recogniser until the child
      actually starts speaking.
- [ ] Enrolment: record ~15 seconds of the child, keep a voice embedding on
      device, gate the audio on similarity to it.
- [ ] Source separation: run target-speaker extraction before recognition.
- [ ] Teach the flow: ask the parent to read *with* the child deliberately, so
      the filter has a real target to separate.

---

## Phase 5 — Content and curriculum

- [ ] Move passages out of the binary. Start with bundled JSON, then a backend.
- [ ] Passage metadata: topic, difficulty, vocabulary list, estimated duration.
- [ ] Authoring tool for teachers — paste text, set language and standard.
- [ ] A graded library: Standard 1 through 6, per language, with
      school-syllabus alignment.
- [ ] Sentence-level scoring, so a long passage gives feedback per sentence
      rather than only at the end.

---

## Phase 6 — Motivation and progression

- [x] Something to **spend** JKD on: a reward shop with a ladder of stickers,
      and a collection. Prices calibrated so the cheapest reward is about one
      good reading.
- [x] Streaks, with the current and best-ever runs. Deliberately not reset at
      midnight.
- [x] Per-passage progress: attempts, best accuracy, best speed, and a banner
      for beating your own record.
- [x] Reading comfort: text size, line spacing, and a reduce-motion switch.
- [ ] Tune the reward curve against real data. The current numbers (10 points
      per correct word, 25 bonus, 100 points = 1 JKD, cheapest sticker 0.50 JKD)
      are a considered guess and nothing more.
- [ ] A dyslexia-friendly font option. Needs a licensed font file to bundle —
      the text size and line spacing controls cover part of the need, but not
      the typeface itself.
- [ ] Daily goal, e.g. "read one passage today", with a gentle nudge rather than
      a hard streak break.
- [ ] Weekly chart of accuracy and words per minute, once there is enough
      history to make a chart meaningful.

---

## Phase 7 — Accounts and multi-device

- [ ] Backend: accounts, wallet sync, progress sync.
- [ ] Parent app or web view: see how the child is doing.
- [ ] Class view for teachers: which students need help, on what.
- [ ] Offline-first sync, because school wifi is unreliable.
- [ ] Privacy and compliance work — this is children's voice data. Under PDPA
      (Malaysia) and GDPR-K, voice recordings of minors are sensitive. Decide
      retention, get parental consent, and document it. **This should be
      designed before any of it is built, not bolted on.**

---

## Known technical debt

| Item | Notes |
| --- | --- |
| Reward values are guesses | No data behind them; expect to retune in Phase 6 |
| Recogniser output is auto-corrected | Ceiling of text-based grading — see Phase 3 |
| Wallet has no migration story | If the `Jkd` storage format changes, old balances need handling |
| No `ReaderScreen` widget test | It needs plugin fakes at the screens layer; the controller beneath it is covered |
| Version string is hard-coded | `SettingsScreen._appVersion` returns a literal; swap in `package_info_plus` when it needs to be real |
