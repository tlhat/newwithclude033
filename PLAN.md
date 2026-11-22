# Rive Mascot Upgrade — Implementation Plan

> Stage 2 deliverable. Stage 3 approval gate follows this document.
> Status: **NOT YET IMPLEMENTED.** Nothing in this plan has touched production code yet.

---

## 1. Asset Status (audited 2026-11-22)

| Item | Finding |
|---|---|
| Character assets | 4 flat PNGs in `assets/avatars/`: `boy_front.png`, `girl_front.png`, `boy_3d_angle.png`, `girl_3d_angle.png` (plus `assets/images/characters_turnaround.png` sheet) |
| Rigged assets | **NONE.** No `.riv` files exist anywhere in `assets/`. Glob for `*.riv` returned zero results. |
| Rive dependency | **Not present** in `pubspec.yaml` (current deps: video_player, http, shared_preferences, speech_to_text, crypto, flutter_secure_storage). Must be added at Stage 4. |
| Accessories | Not asset files at all — wings/glasses/crown are **Flutter-painted overlay widgets** in `HaneenCompanionAvatarWidget._buildSprite` / stage builder; outfit tint is a colored `Container` overlay. Nothing to preserve as separate files; overlays are unaffected by Rive path. |
| Implication | Flat PNGs cannot be animated by Rive. Real, natural Rive animation requires **external rigging work in the Rive editor** (bone/state-machine rigging of new character art). This code phase can only deliver: the Rive rendering harness, input-mapping state machine, graceful PNG fallback, and the naturalness input drivers. **We state plainly: no claim of "fully animated" or "production-ready" until a real rigged `.riv` is verified on screen.** |

**Safeguard:** existing PNGs, overlays, and accessory logic are never deleted or replaced. PNG rendering remains the default path; Rive activates only when a `.riv` exists and loads successfully.

## 2. Speech-Signal Reality (audited — no assumptions)

`SpeechCoordinator` is a `ChangeNotifier` exposing an immutable `CompanionSpeechSnapshot`:

- `phase`: `idle` | `speaking` | `textFallback`
- `playbackProgress`: `0.0–1.0`, **estimated** from a word-count duration heuristic (no real audio timestamps)
- `mouthOpen`: `0.0–1.0`, approximate only, derived from playback progress (explicitly documented in-source as "not viseme/lip-sync")

**There are NO phoneme callbacks, NO viseme events, NO RMS/amplitude stream, NO real audio timestamps.** `CalmVoiceService` is accessed only via `speakCalmly`/`stopSpeaking` (sequential stop semantics, no signal callbacks). 

**Lip-sync decision (honest):** Layer 3 Rhubarb viseme mapping is **impossible with current signals**. Documented limitation. Fallback per spec: when speaking, drive `SMITrigger`-based amplitude-gated mouth via `mouthOpen` (already amplitude-shaped by the coordinator's estimator) — clearly labeled approximate mouth activity, never marketed as lip-sync. If phoneme data is ever added upstream, `SMINumber visemeId` input slot exists in the plan (§3) but will stay unwired.

## 3. Architecture & Lifecycle (minimal diffs, existing state pattern)

- **No new state-management library.** Follow the existing `ChangeNotifier` + listener pattern (as `SpeechCoordinator` and `AppStateManager` do).
- New file: `lib/features/companion/widgets/haneen_rive_avatar_widget.dart` — `HaneenRiveAvatarWidget` wraps `HaneenCompanionAvatarWidget`:
  1. Attempt `RiveFile.asset('assets/avatars/<gender>_<angle>.riv')` (pre-cached once via a static `Future` so flat `build` never awaits network/disk).
  2. On success: render `Rive(...)` + `StateMachineController` with the input taxonomy below.
  3. On failure (missing file, load error, unrigged): render the existing `HaneenCompanionAvatarWidget` **verbatim** — identical props, zero behavior change.
- **Dispose discipline:** every `StateMachineController` is `dispose()`d in `State.dispose()`; `rive` controllers are never leaked. Controllers are created once per successful load, not per build.
- `RepaintBoundary` added only around the Rive canvas (justified: full-canvas repaint isolation), not around the PNG fallback.
- Diff surface: `pubspec.yaml` (+`rive`), 1 new widget file, ~1–3 call sites switch from `HaneenCompanionAvatarWidget` to the wrapper (fallback keeps them safe). No edits to `SpeechCoordinator`, `CalmVoiceService`, memory engine, or Phase 5 wiring.

### State-machine input taxonomy (contract with the future rig)

| Input | Type | Driven by | Purpose |
|---|---|---|---|
| `isSpeaking` | `SMIBool` | coordinator `phase == speaking` | Layer 4 gating |
| `lookX` / `lookY` | `SMINumber` (-1..1) | pointer/Idle drift timer | Layer 1 gaze + parallax |
| `blinkTrigger` | `SMITrigger` | randomized timer 2–6 s (non-robotic) | Layer 2 natural blinks |
| `mouthOpen` | `SMINumber` (0..1) | `snapshot.mouthOpen` | Approximate mouth (fallback viseme) |
| `visemeId` | `SMINumber` (0..12, 0.03–0.05 s mix) | **UNWIRED** — no phoneme source exists | Layer 3 slot, documented as blocked |
| `emotionId` | `SMINumber` | `CompanionFaceExpression` map | Layer 4 emotional overrides |
| `waveTrigger` / `celebrateTrigger` | `SMITrigger` | existing `isWaving`/`isCelebrating` | backward compat with Phase 3 |

Breathing (Layer 0) and posture live inside the rig's idle state machine, not in Flutter timers.

## 4. Safeguards & Baselines

- PNG fallback path is the **default and must pass** with `.riv` absent (which is today's reality).
- Analyzer must stay at exactly **235 issues / 0 errors** — no new info-level issues.
- Full test suite must stay green (106/106, including Phase 5 `phase5_wiring_integration_test.dart` 10/10).
- No device audio/visual verification claim; no "production-ready" claim absent a verified rigged `.riv`.
- Boy/girl selection, customization (outfit tint, accessory overlays), animation triggers, Companion Engine, and `companion_memory_v1_<childId>` memory state are untouched.

## 5. Verification Plan (Stage 4–6)

1. `flutter pub get` resolves `rive` within a Windows-compatible version.
2. New widget test: `test/rive_avatar_fallback_test.dart` — no `.riv` present → widget tree is byte-for-byte the existing avatar widget; fallback works when `.riv` missing/unrigged; controllers disposed (no leaks via `debugDisposed`/manual assertions).
3. Analyzer: `flutter analyze` → exactly 235 / 0 new.
4. `flutter test` → all suites green.
5. Report states: external Rive-editor rigging of real `.riv` files is **required** before any animated-mascot claim; current state is harness + fallback only.
