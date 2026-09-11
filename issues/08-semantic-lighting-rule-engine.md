# 08 — Implement semantic lighting and binding resolution

**Labels:** `agent-ready`, `kind:feature`, `area:lighting`  
**Dependencies:** 03

## Outcome

Pure deterministic logic turns state/events/configuration into key frames with the PRD's priority rules.

## Scope

- Implement static function colors and state rules for reverser, both doors, headlights, wipers, and safety acknowledgement.
- Implement warning and expiring temporary-event layers.
- Implement pulse/blink sampling with injected clock.
- Resolve actions to all bindings, collisions to one winner, and clear keys removed by a binding change.
- Validate configurable colors/effects while preserving safe defaults.

## Acceptance criteria

- Golden tests cover every documented state, unknown/unavailable/stale, all priority levels, expiry, animation boundaries, multiple bindings, unbound actions, collisions, and removed bindings.
- Equal-priority collision behavior is stable and diagnosed.
- Rule code contains semantic actions only; physical keys enter solely through `BindingSnapshot`.
- Same inputs/time produce byte-equivalent frames.

## Verification

Unit/golden tests with fake clock; property test verifies higher priority cannot be overridden by lower priority.

## Out of scope

Game readers and device SDK.
