# 02 — Validate runtime state acquisition

**Labels:** `agent-ready`, `kind:research`, `area:state`, `needs-game`, `product-gate`  
**Dependencies:** none

## Outcome

A go/no-go recommendation backed by traces for authoritative or validated reverser, both door sides, and headlights or wipers.

## Work

Execute the runtime section of `docs/technical-discovery.md`. Compare candidate sources using the scoring dimensions there. Measure observation rate and source-to-observation latency where possible. Test pause/menu, locomotive change, loss, and game exit. Use read-only techniques only.

## Required artifacts

- `docs/research/state-acquisition.md` and capability matrix per tested locomotive/build.
- `docs/decisions/ADR-004-state-acquisition.md` including threat/stability/distribution assessment.
- Sanitized timestamped traces under `tests/fixtures/state/`, plus schema/provenance README.
- Proposed `StateReader` adapter boundaries and supported-field declaration.

## Acceptance criteria

- Required transitions are correlated to visible game state, including unknown/unavailable cases.
- Reliability limitations and false-positive/negative observations are explicit.
- Selected source has a recovery strategy and does not write/inject into TSW2.
- Gate ends as: `GO`, `GO with revised scope`, or `NO-GO`, with required PRD changes for the latter two.
- Input tracking alone cannot yield `GO`.

## Verification

Replay traces independently and validate timestamps, transition order, and redaction. No full production reader in this issue.
