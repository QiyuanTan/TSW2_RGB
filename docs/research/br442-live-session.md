# BR442 live discovery session

Date: 2026-09-12 (UTC). Issue #3, manual observation session; acquisition validation remains incomplete.

The user loaded a BR442 and operated its controls. Observation uses read-only window capture. No game input was injected and no game files were modified.

## Environment and interface inspection

- Running process: `TS2Prototype-Win64-Shipping.exe`.
- Windows version reported by the local runtime: `10.0.28120.0`.
- Game manifest lists the shipping executable with timestamp `2022-06-20T21:48:41.897Z`. This is a packaging timestamp, not a verified game version.
- User configuration directory is named `TrainSimWorld2EGS`; distribution/build identity has not been independently verified.
- The installation contains `TS2Prototype/Binaries/ThirdParty/PieHid/Binaries/PieHid64.dll` (72,704 bytes; SHA-256 `3E0169D5722F4B35BDB6D40716F49AC6DDDD1F3412125B5382E77F5DB0EEF9E0`). The library was not loaded or modified by the probe.
- [RailDriver's product documentation](https://raildriver.com/products/raildriver.php) confirms native TSW2 controller support. This does not establish an external API for confirmed train state.
- Accessibility inspection returned only the game window, with no semantic control values.
- The inspected user Logs directory contained four crash-report logs, the newest dated 2026-08-26. No current gameplay log was present there. Other paths and IPC mechanisms remain unvalidated.

## Manual observation ledger

Capture intervals bracket screenshot requests; they are not source-event timestamps or latency measurements. Images remain in the task's observation history, not committed to the repository. These notes are human-interpreted observations, not an automated reader replay fixture.

| Capture start UTC | Capture finish UTC | User-reported control state | Visible evidence | Interpretation limit |
|---|---|---|---|---|
| 2026-09-12T10:50:03.056Z | 2026-09-12T10:50:04.148Z | Reverser Neutral | Horizontal bar in the HUD direction indicator beside the speed reading; speed 0.0 km/h | One stationary sample correlated to the user's report. Earlier screenshot showed an upward arrow. No automated classification, transition timing, or repeatability established. |
| 2026-09-12T10:52:31.825Z | 2026-09-12T10:52:32.914Z | Reverser Reverse | Downward arrow in the HUD direction indicator beside the speed reading; speed 0.0 km/h | Distinct from the preceding Neutral sample despite changed cab camera position. Event time and intermediate transitions were not captured; acquisition latency remains unmeasured. |
| 2026-09-12T10:53:36.055Z | 2026-09-12T10:53:37.093Z | Reverser Forward | Upward arrow in the HUD direction indicator beside the speed reading; speed 0.0 km/h | The three reported positions have distinct visible indicators in these samples. This establishes a candidate visual mapping only, not automated-reader accuracy or latency. |

## Door observations

Capture interval `2026-09-12T10:54:45.695Z` to `2026-09-12T10:54:46.719Z`: the user reported "left open". The left flank of the HUD train/door pictogram was white while the right flank remained gray. The passenger-loading objective also showed progress. Speed remained 0.0 km/h. The subsequent message "released" was corrected by the user to "both closed" and is not a retrospective relabeling of this sample. The cab screenshot does not independently show the physical passenger-door leaves or distinguish unlocked, opening, and fully open states. These meanings require further correlation and must not be conflated. No independently validated canonical `DoorState.open` observation is justified by this sample.

Capture interval `2026-09-12T10:56:41.039Z` to `2026-09-12T10:56:42.178Z`: following the user's corrected report "both closed", both flanks of the HUD train/door pictogram were gray. The objective had changed to prepare for departure. Speed remained 0.0 km/h. The left indication therefore changed from white to gray between the two samples. Door motion and lock status were not independently observed.

Capture interval `2026-09-12T10:57:48.844Z` to `2026-09-12T10:57:49.877Z`: following the user's report "right open", the right flank of the HUD train/door pictogram was white and the left flank gray. Speed remained 0.0 km/h. This complements the left-side and both-closed samples and suggests independent side indications. Physical door opening versus release remains unverified from this cab view; there is no captured opening/closing transition or measured latency.

## Restart and wipers

The user reported restarting the game and setting wipers Off. Process enumeration confirmed a different shipping-process ID, and window enumeration returned a different game-window handle. The observer selected the new returned window before capture; previous session observations must not be carried forward as current state. This demonstrates manual observer reattachment only. Exit timing, an unavailable interval, and automatic reader recovery were not captured.

Capture interval `2026-09-12T21:46:51.390Z` to `2026-09-12T21:46:52.101Z`: the new session showed a stationary cab (0.0 km/h), upward HUD direction arrow, both door pictogram flanks gray, passenger-loading objective, and 0 AP. The prior right-open sample had a white right flank and departure objective. These are post-restart observations, not evidence that every game restart resets these fields identically.

No explicit wiper-setting indicator was visible in the HUD. A wiper blade was visible on the windscreen, but its position in one frame cannot distinguish Off from an intermittent dwell or a paused animation. `WiperState.off` is therefore user-reported only and has not been independently acquired. A view of the labeled cab selector or its game-rendered tooltip is needed for the next visual comparison. Accessibility still exposed only a window; the inspected Logs directory remained unchanged, containing crash-report logs and no current gameplay log.

Capture interval `2026-09-12T21:48:29.370Z` to `2026-09-12T21:48:30.480Z`: with the user hovering over the cab wiper selector, the game-rendered tooltip read `雨刷 雨刷速度设定：关` (Wipers — wiper speed setting: Off). This explicitly corroborates Off for this sample, unlike the earlier windscreen view. This is a manual reading of a transient, localized tooltip, not an automated or continuously available source. It depends on camera position and pointer hover; loss of the tooltip must make such a visual reader unknown rather than retain Off indefinitely.

Capture interval `2026-09-12T21:49:38.340Z` to `2026-09-12T21:49:39.493Z`: after the user advanced the wiper selector, its tooltip read `雨刷 雨刷速度设置：1` (Wipers — wiper speed setting: 1). This is a visibly distinct setting from Off. The numeric notch is preserved as `1`; it has not been mapped to intermittent, slow, or fast because sweep behavior has not been measured. The observation remains a manual tooltip reading with no measured source-event latency.

Capture interval `2026-09-12T21:50:52.200Z` to `2026-09-12T21:50:53.397Z`: the next selector setting displayed `雨刷 雨刷速度设置：2` (Wipers — wiper speed setting: 2). Off, 1, and 2 are now distinct manually observed tooltip values. No sweep-rate interpretation or claim that 2 is the maximum setting is made.

Capture interval `2026-09-12T21:52:09.283Z` to `2026-09-12T21:52:10.439Z`: the selector tooltip displayed `雨刷 雨刷速度设置：3` (Wipers — wiper speed setting: 3). The observed sequence is Off, 1, 2, 3. These are raw visual labels; sweep-rate semantics, maximum notch, automatic recognition, and continuous visibility remain unvalidated.

Capture interval `2026-09-12T21:53:37.979Z` to `2026-09-12T21:53:39.216Z`: after the user looked through the windscreen without intentionally changing the setting, the wiper tooltip was absent. The wiper blade and a cleared area of glass were visible, but there was no numeric wiper setting in the HUD. A tooltip-based observation must become unknown when the tooltip disappears; retaining the last observed notch as current would be unsupported. This is observed loss of the candidate visual field, not a game-process disconnect. No sweep-rate measurement was taken.

The user reports that the selector reaches speed **5**. Off, 1, 2, and 3 have been visually captured; 4 and 5 and the maximum-stop behavior have not. The six reported settings (Off plus 1–5) do not have a validated mapping to the architecture's off/intermittent/slow/fast enum. A future adapter must document a justified mapping or propose a contract revision rather than arbitrarily collapse numeric notches.

## Pause/menu visibility

Capture interval `2026-09-12T21:54:46.368Z` to `2026-09-12T21:54:47.601Z`: following the user's report "paused", the Overview pause screen replaced the cab and driving HUD. It explicitly identified `BR 442` and vehicle `442 260-5`. Reverser, left/right door indicators, and the wiper tooltip were absent. A visual reader restricted to the previously inspected HUD/tooltip sources must report no current observation for those fields in this view; cached values cannot be advertised as freshly confirmed. The menu demonstrates field-visibility loss while the game remains present, distinct from process exit. Locomotive identity is visible here, but continuous identity acquisition and change detection are not validated.

Capture interval `2026-09-12T21:56:12.989Z` to `2026-09-12T21:56:14.152Z`: after the user resumed, the driving HUD returned with an upward reverser arrow, both door pictogram flanks gray, and speed 0.0 km/h. The wiper blade was at a different position than in the pre-pause windscreen sample, but the numeric setting tooltip remained absent. This demonstrates manual observation of HUD visibility recovery while exact wiper-setting visibility remains lost. It does not validate an automatic pause detector, continuous sweep rate, or source-to-observation latency.

## Locomotive change

Capture interval `2026-09-12T21:58:28.744Z` to `2026-09-12T21:58:30.026Z`: after the user loaded another locomotive, the Overview screen identified **1972 Stock**, vehicle **3250**, instead of BR 442. The same selected game-window object remained usable for this capture. Thus a window remaining valid is insufficient to assume locomotive identity is unchanged. No BR442-specific wiper interpretation or cached train state may transfer to this context without new evidence. Only the identity label was observed for 1972 Stock; its reverser, doors, headlights, and wipers are untested. Transition timing and automatic identity-change detection remain unvalidated.

## Game exit

After the user reported normal exit, window enumeration from `2026-09-12T21:59:41.532Z` to `2026-09-12T21:59:41.935Z` returned no TSW2 shipping-process window. Independent process enumeration at `2026-09-12T21:59:43.6406109Z` returned no `TS2Prototype` or shipping process. This corroborates process/window absence after exit. The actual exit instant and detection latency were not measured, and no production reader was running to exercise cleanup.

## Status

The live observation session is complete and the user has exited the game. Acquisition research remains incomplete: candidate visual indications have been recorded for reverser, both door sides, and wiper settings, with pause/resume, restart, locomotive-change, and exit observations. No automated reader, continuous capture, latency measurement, or reliability trial was performed. Physical door transitions, numeric wiper semantics, build identification, and independent replay validation remain outstanding. The absence-based rationale from the initial assessment is superseded; no claim of impossibility follows from these observations.
