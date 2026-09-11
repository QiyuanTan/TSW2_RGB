# 07 — Implement state aggregation, source precedence, and staleness

**Labels:** `agent-ready`, `kind:feature`, `area:state`  
**Dependencies:** 02, 03

## Outcome

Partial observations from selected readers produce a deterministic normalized `TrainState` without presenting stale/inferred values as confirmed.

## Scope

- Implement per-field capability registration, merge, timestamps, quality precedence, and configurable stale transitions.
- Define conflict resolution from ADR-004; freshest does not automatically beat more authoritative data unless policy says so.
- Isolate reader failure and expose health/diagnostics.
- Reset appropriate fields on game session or locomotive identity change.

## Acceptance criteria

- Deterministic tests cover authoritative vs derived vs optimistic data, out-of-order observations, equal timestamp, stale timeouts, recovery, reader loss, and session change.
- One failed reader cannot erase fresh unrelated fields.
- Unsupported and unknown remain distinguishable where the contract requires it.
- Uses injected monotonic clock for durations; wall-clock changes cannot break staleness.

## Verification

Fixture-driven tests using issue 02 traces and generated conflict matrices.
