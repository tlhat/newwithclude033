# Developmental support layer (phase 2)

All data is stored on the phone (SharedPreferences key `dev_state_<childId>`). No network. The app is for practice and play: no diagnosis, no IQ, no comparison with other children. Sources and strength of evidence: `docs/EVIDENCE.md`. Items marked UNVERIFIED there are design choices and are labeled that way in the app.

| # | Requirement | Where |
|---|---|---|
| 1-7 | Cognition, language, social, executive, motor, independence, creative areas | `SkillArea` and `areaOf()` in `lib/features/development/dev_core.dart`; new games `stop_go`, `rule_switch`, `draw_imagine` in `brain_games/screens/dev_games.dart` |
| 8 | Four age bands | `AgeBand`, `bandsOf()`; parent picks the band (default guessed from the profile age) |
| 9 | Skill map with levels | levels 1-3 in `ExerciseProgress`, stages new, learning, confident, solid in `computeState()` |
| 10 | Activity bank metadata | `ActivityMeta` (goal, skill, level, assessment, hints, evidence badge) |
| 11 | Performance log | per day right/total/extra tries after a hint, trend over days |
| 12 | Independent checks | `TransferCheckScreen`: 3 questions never answered before; passing is part of "solid" |
| 13 | Gentle adaptivity | level drops only after 2 misses in a row, rises after 3 right, hints never cost anything |
| 14 | Spaced review | wrong answers return after 1, 3 and 7 days (`ExerciseProgress`) |
| 15 | Confidence | low, medium, high from answers and separate good days |
| 16 | Parent activities and notes | `DevelopmentCard`: weekly real-world activity per area plus notes |
| 17 | Parent report | `DevelopmentCard`: strengths, improving, needs practice, trend, disclaimer |
| 18 | Evidence per activity | `kAreaEvidence` (sources, strength, limit); UNVERIFIED shown as play |
| 19 | Offline | everything local |

Screen time: 18-36 months is off until a parent switches on co-use; default cap 20 min (18-36 m) and 60 min (3-5), parent-set for older ages (no source gives a number, UNVERIFIED). `DevGate` wraps the games area.
