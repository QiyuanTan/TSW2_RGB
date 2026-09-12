# Architecture and Contracts

## Components

```text
TSW2 config -> BindingReader -> BindingSnapshot --+
                                                  |
TSW2 process -> StateReader(s) -> TrainState ------+-> RuleEngine -> SemanticFrame
                                                  |                    |
Input events (optional) -> TemporaryEvent --------+                    v
                                                           BindingResolver -> KeyFrame
                                                                            |
                                                                            v
                                                                      RgbBackend
```

`AppCoordinator` owns lifecycle, health, scheduling, frame submission, and graceful shutdown. Domain packages must not import a concrete game reader or RGB SDK.

## Canonical domain contracts

Language-neutral shapes below are normative; issue 03 translates them into the chosen implementation language.

```text
SemanticAction = stable identifier (for example door.left, reverser.increase)
PhysicalKey = normalized keyboard usage/key identifier, not a display character

BindingSnapshot {
  revision, source_path, loaded_at,
  bindings: Map<SemanticAction, List<PhysicalKey>>,
  diagnostics: List<Diagnostic>
}

Observation<T> {
  value: T | Unknown,
  source_id, observed_at, confidence, quality
}

TrainState {
  reverser, doors.left, doors.right, headlights, wipers,
  safety_ack_required, warnings, locomotive_id, observed_at
}

LightIntent { action, color, effect, priority, expires_at?, source }
KeyFrame { sequence, generated_at, keys: Map<PhysicalKey, KeyLight>, reason }
```

Initial enums:

- `ReverserState`: reverse, neutral, forward, unknown.
- `DoorState`: closed, opening, open, closing, unavailable, unknown.
- `HeadlightState`: off, marker, dim, bright, unknown; readers may support a subset.
- `WiperState`: off, intermittent, slow, fast, unknown; readers may support a subset.
- `Effect`: steady, pulse, blink. Animation timing belongs to the renderer, not device backend.
- `Quality`: authoritative, validated-derived, optimistic, stale, unavailable.

## Required interfaces

```text
BindingReader.load() -> BindingSnapshot
BindingWatcher.start(on_change); stop()
StateReader.capabilities() -> Set<StateField>
StateReader.read(previous?) -> PartialTrainState
RuleEngine.evaluate(TrainState, BindingSnapshot, TemporaryEvents, time) -> List<LightIntent>
BindingResolver.resolve(List<LightIntent>, BindingSnapshot) -> KeyFrame
RgbBackend.discover(); open(device); submit(KeyFrame); clear(); close()
Clock.now(); Scheduler.start(); stop()
```

## Invariants

- Missing/unbound/unsupported controls emit diagnostics and no device command.
- Multiple bindings illuminate all supported bindings by default.
- If two actions resolve to one key, highest priority wins; equal priority uses a documented stable rule and emits a collision diagnostic.
- Stale observations become unknown after a configurable per-field timeout.
- A failed reader cannot overwrite fresher authoritative state with optimistic state.
- Identical frames may be coalesced; changed frames are ordered by sequence.
- Concrete readers/backends translate at boundaries; domain code remains device/game agnostic.
- External cleanup is idempotent.

## Suggested repository shape

```text
src/domain/          contracts, enums, state merge, rules
src/bindings/        config discovery/parser/watcher
src/state/           reader interfaces and adapters
src/lighting/        rules, animation, binding resolution
src/rgb/             backend interface and ASUS adapter
src/app/             coordinator, process monitor, configuration
tests/fixtures/      sanitized TSW2 configs and state traces
tests/unit/          pure domain tests
tests/contract/      adapter/backend contract suites
tests/integration/   replay and optional hardware/game tests
docs/decisions/      ADRs
docs/research/       reproducible discovery evidence
```

## Required decisions

- ADR-001 implementation language/runtime.
- ADR-002 RGB transport and SDK licensing/distribution.
- ADR-003 binding source and key normalization.
- ADR-004 runtime state acquisition method(s), risks, and fallback.
- ADR-005 update loop and threading model.

Any issue that changes a boundary above updates this document and adds or amends an ADR.

## RGB transport status

ADR-002 selects Windows HID LampArray after foreground and packaged ambient per-key smoke and ten-minute soak tests passed on the reference keyboard. Background ownership transfers took approximately 66 seconds, so temporary `IsAvailable=false` is a non-fatal waiting state. Normal and forced-exit restoration passed. The backend must use `DeviceWatcher` and `AvailabilityChanged`, keep discovery and ownership asynchronous, resume rendering after acquisition, and release on shutdown. Normalized physical keys are translated to Windows virtual keys and then lamp indices only inside the adapter; core, profile, and rule code never stores those representations. Production backend issue 09 remains gated until issue #5 records receiver reconnect and firmware/version evidence.
