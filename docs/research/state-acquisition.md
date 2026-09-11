# Runtime state acquisition research

**Issue:** #3 (backlog item 02)

**Decision:** `NO-GO`

**Research date:** 2026-09-11

## Executive result

No source has been validated against a running Train Sim World 2 (TSW2) session for reverser, both door sides, and either headlights or wipers. The required game, locomotive, and visible-state correlation session was not available in the execution environment. Consequently, this work does **not** select a runtime source and does not unblock issues 07 or 11.

Input observation is explicitly rejected as a substitute: a key press cannot prove that the game accepted the command or reveal changes caused by the cab, AI, scenarios, safety systems, pause state, or a different binding.

The only captured observation is a sanitized lifecycle probe showing that the expected game process was absent. It proves the unavailable representation and validator path, not train-state feasibility.

## Environment and evidence limits

| Item | Recorded value |
|---|---|
| Host OS | Windows; build intentionally not asserted because it was not captured by the probe |
| TSW2 build/store | Not available |
| Tested locomotive/route | None |
| Game process during probe | Absent |
| Capture timestamp | 2026-09-11T20:09:02.9947155Z |
| Technique | Read-only process enumeration |

No usernames, installation paths, account identifiers, Steam IDs, save data, memory contents, or secrets were captured.

## Candidate assessment

Scores use `0` (no evidence/unacceptable), `1` (plausible but unvalidated), and `2` (validated). A score is not evidence of availability. All candidates remain unselected.

| Candidate | Coverage | Authority | Latency/rate | Stability | Setup | Security | Distribution | Recovery | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Documented game API / RailDriver interface | 1 | 1 | 0 | 0 | 1 | 2 | 0 | 0 | No public, captured state contract was demonstrated |
| Stable files or IPC | 0 | 1 | 0 | 0 | 2 | 2 | 2 | 0 | No changing runtime source was observed |
| Supported telemetry or game plugin | 1 | 2 | 1 | 1 | 0 | 1 | 0 | 1 | Requires vendor-supported access and a live validation build |
| HUD observation / OCR | 1 | 1 | 0 | 0 | 1 | 2 | 2 | 1 | Some fields may not be visible; false positives remain unmeasured |
| Input-derived estimates | 0 | 0 | 1 | 0 | 2 | 2 | 2 | 1 | Rejected as non-authoritative and incomplete |
| Read-only memory inspection | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | Not attempted; requires explicit risk review and versioned evidence |

Desk research about generic Unreal Engine facilities does not establish that TSW2 exposes them in its shipping build. Epic documents that Studio Telemetry does not function in shipping builds, while runtime plugins must be packaged by the game project. These facts rule out assuming generic engine facilities are externally available, but do not prove anything about a TSW2-specific interface.

Sources:

- [Epic Games: FStudioTelemetry](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/StudioTelemetry/FStudioTelemetry)
- [Epic Games: Plugins in Unreal Engine](https://dev.epicgames.com/documentation/en-us/unreal-engine/plugins-in-unreal-engine)

## Capability matrix

`Not tested` means no claim can be made. `Unavailable` is reserved for a source that was present but explicitly reported a field unavailable; no such source was present.

| Build / locomotive | Reverser | Left door | Right door | Headlights | Wipers | Pause/menu | Loco change | Loss/exit |
|---|---|---|---|---|---|---|---|---|
| No running TSW2 session | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | Process absence captured |

There are no measured observation rates, transition latencies, false positives, or false negatives. Reporting numerical values would fabricate results.

## Trace inventory and replay

`tests/fixtures/state/process-absent.jsonl` contains the one real observation. Each line conforms to the schema in `tests/fixtures/state/README.md`. Validate ordering, vocabulary, and redaction from the repository root:

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

The result is `NO-GO`. The PRD is revised so the current demonstrable milestone excludes live synchronized train state. Reverser, both doors, and a third system remain product-release gates for any future MVP that claims runtime synchronization. Issues 07 and 11 remain blocked until this experiment produces validated evidence and ADR-004 is superseded.
