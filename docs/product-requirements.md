# Product Requirements Document

## Product outcome

While TSW2 is running, the player's compatible ROG keyboard acts as a low-latency control/status panel. Lighting follows the player's actual TSW2 key bindings and confirmed simulator state. When the game exits or the integration fails, the prior keyboard lighting is restored where the selected backend permits it.

## Users and jobs

Primary user: a Windows TSW2 player with a per-key RGB ASUS ROG keyboard.

1. See which physical keys currently control important train functions.
2. Read useful train-system state without shifting attention from gameplay.
3. Rebind controls in TSW2 without maintaining a second mapping.
4. Run the integration without measurable gameplay disruption.

## MVP scope

Required:

- Detect TSW2 process lifecycle.
- Locate and parse the active user's TSW2 keyboard bindings.
- Resolve semantic actions to zero, one, or multiple supported physical keys.
- Reload bindings after a file change without restarting the application.
- Address individual keyboard LEDs through a replaceable RGB backend.
- Render static semantic colors.
- Synchronize authoritative reverser, left/right door, and at least one of headlight or wiper state.
- Show safety acknowledgement demand if a sufficiently reliable source is found.
- Prioritize warning/event/state/static layers deterministically.
- Degrade per feature when bindings, state sources, or hardware are unavailable.
- Restore or relinquish keyboard lighting on shutdown.

Deferred: GUI, installer polish, auto-update, multiple keyboard vendors, community profile marketplace, broad locomotive coverage, and traction/brake state without a reliable source.

Non-goals: speed, route, timetable, physics, or performance telemetry; virtual dashboard; RailDriver replacement; duplicate manually maintained keyboard layouts.

## Semantic behavior

Default categories are configurable: traction green, braking red/orange, doors blue, exterior lights white, safety amber, auxiliary/wipers cyan, critical warnings flashing red.

Default door states: closed = dim blue; opening/closing = pulsing blue; open = bright blue; unknown/unavailable = dim neutral or off.

Priority, highest first: critical warning, temporary input/event feedback, confirmed system state, static function color, background/off. A higher layer fully owns a key unless the rule explicitly defines blending.

Input observation can create short optimistic feedback, but it must expire and must never be persisted as confirmed simulator state.

## Product constraints

- Windows-first and TSW2-specific for MVP.
- MVP supports one explicitly resolved TSW2 player profile and a US-layout physical keyboard; multi-profile selection and non-US layout display/translation are out of scope.
- MVP does not require a secondary-binding UI workflow. Readers remain tolerant of multiple serialized chords if a build contains them.
- No hard-coded physical key for a semantic action in core or profile code.
- State readers, binding reader, rules, and RGB transport remain independently replaceable.
- Polling/rendering must not inject keyboard input or modify game files.
- Memory inspection, if selected, must be read-only, isolated, documented, and opt-in where appropriate.
- Unsupported data is represented as unknown, never guessed.

## MVP release gates

1. A captured custom binding fixture resolves correctly and a changed binding moves the LED after reload.
2. A hardware smoke test sets and clears at least ten distinct keys without visible stutter.
3. Reverser and both door sides are driven by an authoritative or validated state source; a third system is also synchronized.
4. End-to-end latency from observed state change to submitted frame is p95 <= 100 ms on the reference PC, excluding the game's own delay in exposing state.
5. Idle integration CPU average <= 2% of one logical processor and memory <= 150 MB during a 30-minute reference run. These initial budgets must be reported, not silently relaxed.
6. Reader/device failure does not crash the coordinator; unaffected controls continue.
7. Normal exit, TSW2 exit, and handled device disconnect run cleanup and restore/relinquish lighting.
8. Automated unit/contract tests pass; hardware and game-integration results are recorded in the release checklist.

## Open decisions

- Supported keyboard model/firmware matrix.
- Whether the RGB backend can restore prior lighting or only relinquish control.
- Runtime source meeting reliability and distribution constraints.
- Initial locomotive and route for acceptance testing.

Issues 01, 02, and 04 resolve these before broad support is claimed.
