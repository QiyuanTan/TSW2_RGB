# 11 — Implement selected TSW2 runtime state reader adapter(s)

**Labels:** `agent-ready`, `kind:feature`, `area:state`, `needs-game`  
**Dependencies:** 02, 07

## Outcome

The source(s) selected by ADR-004 emit normalized observations for the validated MVP fields and recover from ordinary lifecycle changes.

## Scope

- Implement only the source adapters and fields marked `GO` by issue 02.
- Advertise capabilities, translate raw values at the boundary, timestamp observations, and map source loss/unsupported builds to unavailable diagnostics.
- Support cancellation, TSW2 attach/detach, locomotive/session changes, and reconnect.
- Keep source-specific offsets/selectors/protocol details versioned in the adapter, never in domain/rules.

If ADR-004 selects materially different mechanisms, create one child issue per adapter and keep this issue as their integration/contract gate.

## Acceptance criteria

- Each adapter passes the shared reader contract suite and reproduces expected normalized values from captured traces.
- Real-game checklist confirms reverser, both doors, and the selected third system on the declared support matrix.
- Unsupported build/locomotive never returns a guessed valid state.
- Read-only and distribution/security constraints from ADR-004 are preserved.
- Reader loss and game restart recover without restarting the application.

## Verification

Replay tests, failure injection, and dated opt-in live-game evidence with observed latency.
