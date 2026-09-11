# 05 — Implement binding discovery, parser, and key normalization

**Labels:** `agent-ready`, `kind:feature`, `area:bindings`  
**Dependencies:** 01, 03

## Outcome

The active TSW2 configuration becomes a `BindingSnapshot` without hard-coded physical bindings.

## Scope

- Implement source/profile discovery from ADR-003 with injectable paths.
- Parse captured format defensively and preserve diagnostics for unknown data.
- Map raw action IDs to canonical semantic actions and raw keys to normalized physical keys.
- Support primary/secondary, unbound, duplicates, unsupported keys, missing source, and safe fallback to the last valid snapshot only within one running session.

## Acceptance criteria

- All sanitized fixtures from issue 01 parse to documented golden snapshots.
- Unknown actions/keys do not abort known bindings.
- Malformed or partial files return diagnostics and never publish a partial snapshot as valid.
- User paths are not logged verbatim at normal levels.
- Search/test confirms core/profile data contains no semantic-action-to-physical-key defaults.

## Verification

Table-driven parser tests, discovery tests using temporary paths, fuzz/property tests if supported, and golden snapshot tests.

## Out of scope

Watching/reload (issue 10), RGB, game state.
