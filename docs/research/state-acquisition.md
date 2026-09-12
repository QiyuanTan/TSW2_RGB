# Runtime state acquisition research

**Issue:** #3 (backlog item 02)

**Decision:** provisional `NO-GO` for downstream implementation; research incomplete

**Research dates:** 2026-09-11–12

## Executive result

Live BR442 observations now establish candidate reverser HUD indications, separate left/right door indications, and hover-dependent wiper-setting tooltips. The [dated session ledger](br442-live-session.md) records exact capture intervals and interpretations, including restart, pause/resume, locomotive change, and exit. No automated source has yet demonstrated required coverage, reliability, and latency. Consequently, this work selects no production source and does not unblock backlog items 07 or 11 (GitHub #8 and #12). Issue #3 acceptance is incomplete.

Input observation is explicitly rejected as a substitute: a key press cannot prove that the game accepted the command or reveal changes caused by the cab, AI, scenarios, safety systems, pause state, or a different binding.

The initial process-absence probe was insufficient for a feasibility verdict. The live observations supersede that rationale. A provisional `NO-GO` here means insufficient evidence to implement downstream readers, not proof that no usable source exists.

## Environment and evidence limits

| Item | Recorded value |
|---|---|
| Host OS | Runtime reports Windows 10.0.28120.0 |
| TSW2 build/store | Unverified; manifest executable timestamp 2022-06-20 is not a build identifier; user configuration directory is TrainSimWorld2EGS |
| Observed locomotives | BR442 controls; 1972 Stock identity only; exact scenario not recorded |
| Game lifecycle | Present, restarted, changed locomotive, then exited normally |
| Capture timestamps | See the dated session ledger; initial absence probe retained separately |
| Technique | Read-only process/file metadata and window observation; user operated game controls |

No usernames, installation paths, account identifiers, Steam IDs, save data, memory contents, or secrets were captured.

## Candidate assessment

The initial numerical ratings were unsupported and are withdrawn. The qualitative assessment below distinguishes observed facts from untested possibilities. No candidate is selected for production.

| Candidate | Evidence and coverage/authority | Rate, latency, stability | Setup, security, distribution, recovery |
|---|---|---|---|
| Documented game / RailDriver interface | PieHid64.dll present; vendor confirms native controller support, not required state export | Unmeasured; no state protocol validated | Hardware interface found; telemetry access, license and reconnect behavior unvalidated |
| Files / IPC | Inspected Logs directory has only old crash logs; no current gameplay log there | Unmeasured; no field schema validated | Metadata read-only; other paths and IPC not exhaustively investigated |
| Telemetry / plugins | No tested state-export plugin | All unmeasured | Supported installation, licensing, security and recovery unvalidated |
| HUD / tooltip observation | Manually corroborated reverser and wiper labels; side-specific door symbols have unresolved physical semantics | No automated rate/latency/error measurements; pause hides fields and hover loss hides wiper setting | Read-only capture; locale/camera dependence demonstrated; screenshot redistribution not assessed; manual reattachment and visibility recovery observed |
| Input estimates | Cannot prove command acceptance or externally caused changes | Not tested; insufficient authority regardless of rate | Not selected; confirmed-state use prohibited |
| Read-only memory | Not attempted; no validated offsets or values | Build/locomotive stability unknown | Separate risk assessment remains necessary; no memory access or redistribution undertaken |

Desk research about generic Unreal Engine facilities does not establish that TSW2 exposes them in its shipping build. Epic documents that Studio Telemetry does not function in shipping builds, while runtime plugins must be packaged by the game project. These facts rule out assuming generic engine facilities are externally available, but do not prove anything about a TSW2-specific interface.

Sources:

- [Epic Games: FStudioTelemetry](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/StudioTelemetry/FStudioTelemetry)
- [Epic Games: Plugins in Unreal Engine](https://dev.epicgames.com/documentation/en-us/unreal-engine/plugins-in-unreal-engine)

## Capability matrix

These are manual observations, not advertised production capabilities. Build identity remains unverified for both locomotives. Missing visual information must not be interpreted as a closed/off state.

| Build / locomotive | Reverser | Left door | Right door | Headlights | Wipers | Pause/menu | Loco change | Loss/exit |
|---|---|---|---|---|---|---|---|---|
| BR442 / build unverified | Neutral, reverse, forward HUD samples | White/gray symbols; physical semantics unresolved | White/gray symbols; physical semantics unresolved | Not tested | Off, 1–3 tooltips; 4–5 user-reported only | HUD hidden then restored; tooltip absent in forward view | Changed to 1972 Stock | Manual restart reattachment; eventual process/window absence |
| 1972 Stock / build unverified | Not tested | Not tested | Not tested | Not tested | Not tested | Overview identity observed | Identity differs from BR442 in same window | Exit observed |

There are no measured observation rates, transition latencies, false positives, or false negatives. Reporting numerical values would fabricate results.

## Trace inventory and replay

`tests/fixtures/state/process-absent.jsonl` contains the initial absence observation; `game-exited.jsonl` records the final live-session process check. The live visual observations are timestamped prose in the session ledger, with screenshots retained in task history only. They are not independently replayable image fixtures, and this remains an acceptance gap. Validate the JSONL lifecycle fixtures from the repository root:

```powershell
pwsh -NoProfile -File tests/fixtures/state/validate-traces.ps1
```

This trace is deliberately insufficient for a `GO` decision.

## Required bounded experiment

Run the following on an explicitly identified TSW2 build and locomotive. Prefer documented interfaces, stable files/IPC, and supported telemetry in that order. Do not proceed to memory inspection without a separate threat and account-safety approval.

1. Record the Windows build, TSW2 build/store, route, locomotive, and candidate-source version. Keep personal paths and account identifiers out of the trace.
2. Start the candidate source before TSW2; record absence, attach, source loss, reattach, and game exit.
3. With synchronized UTC timestamps and a screen recording or observer log, exercise reverse → neutral → forward; left and right doors through every distinguishable transition; and headlights or wipers through every supported state.
4. Repeat while paused/in menus, after a locomotive change, and after deliberate source interruption.
5. Run at least 30 transitions per required field. Report sample rate, source-to-observation latency distribution, missed transitions, false transitions, and unavailable/unknown behavior.
6. Sanitize the trace, replay it with the checked-in validator, and have an independent reviewer correlate transition order and timestamps to the visible-state evidence.
7. Update the capability matrix per build/locomotive and revise ADR-004. A `GO` requires all mandatory fields from authoritative or validated-derived sources; input tracking alone cannot qualify.

## Adapter boundary proposed for later implementation

The selected mechanism must remain behind a replaceable reader boundary:

```text
StateReader
  source_id() -> stable non-secret identifier
  capabilities(context) -> field declarations with support status
  start(session, cancellation)
  read(previous?) -> timestamped partial observations
  health() -> ready | degraded | unavailable plus diagnostic code
  stop() -> idempotent cleanup
```

Each observation must carry the canonical field, normalized value or `unknown`/`unavailable`, source ID, capture timestamp, monotonic sequence, quality, and session/build context. Source-specific offsets, selectors, or protocols must stay inside the adapter. Loss, unsupported builds, and locomotive changes must emit unavailable observations; they must never retain or guess valid state.

## Gate consequence

The result remains provisional `NO-GO` for downstream implementation. Live observation narrows the research gaps but does not satisfy issue #3 in full. The PRD retains the synchronization release gates. Next work must establish an automated read-only source, physically correlate door semantics, resolve numeric wiper mapping or validate headlights, identify the build, and collect independently replayable captures with measured rate/latency and errors. No production capability is declared until those checks pass.
