# 10 — Implement resilient binding hot reload

**Labels:** `agent-ready`, `kind:feature`, `area:bindings`  
**Dependencies:** 05

## Outcome

Valid TSW2 binding changes publish a new snapshot without application restart, and invalid intermediate writes cannot corrupt active lighting.

## Scope

- Implement ADR-003 watcher/poll strategy with debounce, cancellation, and retry for locked/atomic-replaced files.
- Parse into an isolated candidate; atomically publish only a complete valid snapshot with monotonically increasing revision.
- Retain last valid in-memory snapshot on transient invalid content and report health.
- Handle source/profile switch and watcher disposal.

## Acceptance criteria

- One logical save produces one published revision after stabilization.
- Rapid writes, truncate-then-write, rename replacement, lock, delete/recreate, and profile switch are tested.
- Invalid update preserves last valid snapshot and recovery publishes the new valid snapshot.
- Old binding keys are identified for clearing by downstream rendering.
- Shutdown leaves no watcher/tasks running.

## Verification

Temporary-directory integration tests with controlled timing/fake scheduler where possible; soak test repeated updates.
