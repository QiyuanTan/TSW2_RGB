# Technical Discovery Protocol

The project has two feasibility risks that must be measured on the target PC before the implementation backlog is fully unblocked.

## Evidence rules

Research must record environment (Windows build, TSW2 build/store, keyboard model, firmware, Armoury Crate/Aura versions), exact reproduction steps, sanitized samples or traces, failure modes, licensing/distribution notes, and a recommendation with rejected alternatives. Do not commit personal paths, usernames, Steam IDs, save data, secrets, SDK binaries, or memory dumps.

## Binding discovery (issue 01)

1. Identify the TSW2 process and candidate user configuration locations using read-only observation.
2. Save a sanitized default binding fixture.
3. Rebind `DoorLeft`, `DoorRight`, and one reverser action in-game; diff before/after data.
4. Determine active profile selection, action identifiers, primary/secondary bindings, unbound representation, duplicate keys, locale/layout behavior, format, and atomic-write behavior.
5. Prove a reliable change signal or specify debounced polling.
6. Produce `docs/research/bindings.md`, sanitized fixtures, and ADR-003.

Exit: a parser can be implemented without guessing the source/schema, or issue 01 documents the bounded experiment still required.

## Runtime state discovery (issue 02)

Evaluate, least invasive first: documented game or RailDriver interfaces; stable files/IPC; accessible telemetry/plugins; HUD observation; input-derived estimates; read-only memory inspection. Input-only data is insufficient for the three required synchronized systems.

For each candidate score coverage, authority, latency, update rate, stability across locomotives/builds, setup burden, security risk, licensing/distribution, and recovery behavior.

Record traces for reverse/neutral/forward; both door sides and transitions if distinguishable; headlights or wipers; pause/menu; locomotive change; game exit. Compare observations with visible in-game state.

Produce `docs/research/state-acquisition.md`, sanitized replay traces, a capability matrix by field/tested locomotive, and ADR-004.

Exit: reverser, both doors, and headlights or wipers each have a validated source and measurable latency. Otherwise explicitly recommend reduced scope; never mask unknown with inference.

## RGB discovery (issue 04)

Compare supported ASUS SDK and direct HID/compatible libraries. Check discovery, per-key addressing, services, exclusive control, frame rate, latency, reconnect, cleanup, restore behavior, architecture support, license, redistributables, and code-signing implications.

Prove ten spatially distinct keys can be set independently, animated for ten minutes, cleared, disconnected/reconnected, and released to normal lighting. Produce `docs/research/rgb-backend.md`, a key-translation table, ADR-002, and a small hardware probe excluded from normal startup.

## Safety

Discovery is read-only toward TSW2. No input injection, config modification by the integration, packet tampering, or writable memory access. Stop and document if a technique threatens game stability or account/security controls.
