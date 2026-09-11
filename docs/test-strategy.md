# Quality and Test Strategy

## Test layers

- Unit: parsing, key normalization, state merge/staleness, rule priority, animation phases, collision handling, config validation.
- Contract: every `StateReader` and `RgbBackend` runs a shared behavioral suite using fakes or captured traces.
- Replay integration: binding fixtures plus timestamped state traces produce deterministic expected frames using a fake clock.
- System: real TSW2 plus real keyboard, manually initiated and never required in ordinary CI.
- Soak/performance: 30-minute replay and optional live run; track CPU, memory, frames, errors, reconnects, and latency percentiles.

## Required fixtures

- Default/custom bindings, secondary binding, unbound action, duplicate collision, malformed/truncated file, unsupported key, and a non-US-layout case if available.
- State traces for every transition, stale/unavailable source, contradictory readers, pause/menu, locomotive change, and reader disconnect.
- Golden frames for static lighting, state changes, temporary feedback expiry, warning override, and binding reload.

Fixtures must be sanitized and include provenance plus tested game version. Retain unknown fields where safe to test forward compatibility.

## MVP system scenarios

1. Start before game; wait safely and attach when TSW2 starts.
2. Load custom bindings; rebind/reload moves lighting and clears the old key.
3. Cycle reverser and each door; keys follow confirmed state.
4. Exercise headlights or wipers; key follows confirmed state.
5. Trigger warning/event; priority overrides then returns to confirmed state.
6. Unbind/collide actions; deterministic safe result plus diagnostic.
7. Disconnect reader/device; unaffected services stay alive and reconnect recovers.
8. Exit game/application; cleanup runs and keyboard ownership is restored/released.

## CI policy

CI runs build, formatting/linting, unit tests, fake contract tests, replay tests, and dependency/license checks. Hardware/game tests are opt-in and publish a dated checklist. Ordinary tests must not require TSW2, Aura services, or physical hardware.

## Definition of done for coding issues

- Acceptance criteria have automated coverage where feasible.
- Failure paths log actionable structured diagnostics without personal data.
- Public contracts and user-facing behavior are documented.
- No unrelated refactor or hard-coded binding is introduced.
- Verification commands and evidence are recorded in the completion note.
