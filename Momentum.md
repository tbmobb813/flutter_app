# Quick Smoke-Check (September 7, 2025)

**Build & Run:**  

- 5 modes appear
- Time-of-day “Suggested mode” visible
- JSON presets load correctly
- Start/stop works
- Intensity slider updates audio
- App plays with screen off

## Quick Smoke-Check Checklist

- [ ] App builds and launches on Android simulator/device
- [ ] App builds and launches on iOS simulator/device
- [ ] 5 modes appear in the UI
- [ ] Time-of-day “Suggested mode” is visible
- [ ] JSON presets load correctly
- [ ] Start/stop session works
- [ ] Intensity slider updates audio
- [ ] App continues playing audio with screen off

## 1. Small, High-Impact Wins (Next)

## A. Randomize & Layer for Variety

- Add multiple JSON variants per mode:  
  `assets/presets/focus_1.json` … `focus_5.json` (same for relax/sleep/study/recovery)
- On session start: pick one at random; every N minutes cross-fade to a sibling preset
- If using a single FFI entrypoint, emulate “layering” by switching presets and cross-fading gain over ~2–3s

## B. Cross-Fade on Mode/Preset Changes

- Fade out current preset while fading in the next (linear or equal-power)
- If Rust lib doesn’t expose per-layer gain, do two consecutive `update()` calls with a timer to step intensity (e.g., 10–12 steps over 2s)

## C. Persist Basics

- Use `shared_preferences` to remember last mode, last intensity, and whether “suggested mode” auto-selects on launch

---

## 2. Context Awareness (Incremental)

## A. Time-of-Day (Very Easy)

- Map Day/Evening/Night to different preset families
- Focus: brighter in AM, mellower in late evening
- Relax/Sleep: soften/reduce HF at night (choose different JSON)
- Done entirely in Dart—no new permissions

## B. Weather (Easy)

- Add `geolocator` + `http`, hit OpenWeather (or similar)
- On session start (and hourly), pick a weather-matched variant (e.g., add rain layer JSON)
- Make it opt-in (privacy toggle in Settings)

## C. Motion/Activity (Medium)

- Use `sensor_plus` or activity-recognition plugin to detect walking vs. still
- While walking: select “Active” preset variant for Focus/Recovery; when still: revert
- Keep all context rules in a single `ContextOrchestrator` class that emits a small set of intent flags (e.g., `{dayPhase: 'night', weather: 'rain', motion: 'walking'}`), and a pure function maps flags → preset name

---

## 3. Scheduling & “Autopilot”

- Add a Schedule screen: simple rows like “Weekdays 9:00–12:00 → Focus”, “22:30 → Sleep”
- Use `flutter_local_notifications` and, on Android, `android_alarm_manager_plus`
- When a schedule fires: start session (or prompt if you prefer) and set the matching preset
- Guard rails: do nothing if audio is already playing; respect “Do Not Disturb”

---

## 4. UX Polish

- Onboarding: one-time screens explaining the modes, optional permissions (Location for weather, Motion)
- Visual feedback: subtle pulsing/flowing animation tied to intensity
- Lock-screen controls: show current mode + pause/stop
- Info tips: “Study is softer Focus tuned for reading”, etc.

---

## 5. Reliability & Edge Cases

- Handle audio interruptions (calls/other media); auto-resume when appropriate
- Keep audio running with screen off (Android battery optimizations/foreground service note)
- Ensure crash-safe: null-checks if a preset JSON is missing/malformed → fallback to built-in Dart preset

---

## 6. Observability (Optional but Helpful)

- Add minimal usage stats (local only or Firebase): total minutes per mode/day
- Weekly summary card: “3h Focus (+42% vs last week)”
- This feeds future personalization (e.g., smarter “suggested mode”)

---

## 7. Issue Backlog (Copy-Paste into GitHub)

**Preset randomization & cross-fade**  
AC: Each mode loads one of ≥3 presets randomly; cross-fade between presets and on mode switch (2–3s).

**Persist last session settings**  
AC: Last mode/intensity re-applied on app launch; toggle to auto-start suggested mode.

**Time-of-day adaptation**  
AC: Morning/Evening/Night select different preset families; visible in debug logs.

**Weather-aware variants (opt-in)**  
AC: With Location enabled, rainy conditions add rain variant; fallback when offline.

**Motion-aware boost (opt-in)**  
AC: While walking, Focus/Recovery use “active” variants; idle → standard variants.

**Scheduling (Autopilot v1)**  
AC: User can add at least two rules; notifications fire on time; starting audio respects existing playback.

**Lock-screen controls & interruption handling**  
AC: Media controls appear; playback pauses on call; resumes sensibly.

**Onboarding & permissions**  
AC: First-run flow explains features; granular toggles in Settings.

**Error handling for presets**  
AC: Corrupt/missing JSON triggers fallback preset; user sees a gentle toast (no crash).

**Weekly usage summary**  
AC: Local stats; simple chart or text summary on Home.

---

## Tiny Code Pointers

- `lib/services/context_orchestrator.dart`  
  Holds time/weather/motion logic and exposes a `Stream<ContextFlags>`

- `lib/services/scheduler.dart`  
  Wraps notifications/alarms and emits “start mode X” intents

- `lib/services/preset_loader.dart`  
  Resolves the final preset name based on mode + context; loads JSON; falls back to defaults

- `lib/state/app_state.dart` (Provider/Riverpod/BLoC—your pick)  
  Central place to subscribe to orchestrator + scheduler and call `AudioService.update()` or restart with a new preset as needed

---
