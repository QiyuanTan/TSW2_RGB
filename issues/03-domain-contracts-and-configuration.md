# 03 — Implement domain contracts and configuration

**Labels:** `agent-ready`, `kind:feature`, `area:core`  
**Dependencies:** 00

## Outcome

The canonical types/interfaces in `docs/architecture.md` exist as a platform-neutral, tested package with validated application configuration.

## Scope

- Implement semantic actions, normalized physical keys, observations/quality, train state/enums, capabilities, intents, effects, frames, and diagnostics.
- Implement interfaces for readers, watcher, RGB backend, clock, and scheduler/coordinator boundaries.
- Define versioned configuration for colors, effects, intervals, stale thresholds, log level, and optional adapters; provide safe defaults and validation.
- Add serialization round-trip tests where configuration/data crosses boundaries.

## Acceptance criteria

- Domain package imports no ASUS/game/process/filesystem adapter.
- Unknown/unavailable/stale are first-class; nullable/default enum values cannot silently mean a valid state.
- Configuration rejects invalid RGB, negative timing, duplicate identifiers, and unsupported schema versions with actionable messages.
- Public types have concise contract documentation and equality/immutability behavior suitable for deterministic tests.

## Verification

Unit tests for every enum boundary and invalid configuration class; architecture dependency test if supported.

## Out of scope

Parsing real game files, merging observations, lighting rules, SDK calls.
