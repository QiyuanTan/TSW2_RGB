# ADR-003: TSW2 binding source and key normalization

- Status: blocked
- Date: 2026-09-11
- Decision owners: binding discovery / issue #2

## Context

TSW2 lighting must follow the in-game keyboard bindings for the supported configuration. A controlled manual UI run proved that three required swaps persist to a UE4 GVAS player-profile save while `Input.ini` remains empty. Door action overrides appear as old/new pairs in `CustomActionMappings`; the reverser vehicle-control override appears in `CustomVehicle`. `VehicleMappings` alone is contradictory and insufficient. The MVP support envelope is one resolved player profile, one UI binding per action/direction, and US-layout keyboards. Unbound, duplicate, and restart experiments remain outstanding.

See `docs/research/bindings.md` and its sanitized fixtures for the evidence and exact remaining experiment.

## Decision

For the tested profile/build, `PP_aps.sav` is the authoritative persistence source. Resolve exactly one matching self-consistent `PP_*.sav`, or require an explicitly configured profile path; never guess among multiple profiles. Readers must apply `CustomActionMappings.NewBinding` action overrides and `CustomVehicle` vehicle-control overrides; they must not treat `VehicleMappings` alone as authoritative. Issue 05 remains blocked on the approval gate below.

The following boundary decisions are safe regardless of the eventual source and are accepted:

- Domain semantic actions do not contain default physical keys.
- Serialized raw action identifiers are translated through an explicit catalog; unknown identifiers remain unknown.
- Physical keys are normalized to keyboard HID usages plus modifiers, independently of localized display characters.
- Multiple supported chords are preserved; empty/unsupported chords produce no binding and diagnostics.
- Key normalization targets the US physical keyboard layout. Non-US translation and multi-profile selection are unsupported for MVP.
- No secondary-binding UI behavior is required; multiple serialized chords are tolerated in stable order for forward compatibility.
- Readers are read-only and publish only complete snapshots. Parse/write races retain the last known-good snapshot.

## Consequences

- Binding parser and hot-reload implementation remain gated on unresolved unbound, duplicate, and restart behavior; restart validation includes confirming the documented reload strategy against any resulting write.
- No hard-coded semantic-to-key defaults enter core/profile code.
- A later accepted revision must finalize the unbound encoding, duplicate behavior, and restart persistence; restart validation includes the documented reload check.
- The proposed polling/debounce behavior in the research report is test input, not a measured guarantee.

## Alternatives considered

- `Input.ini`: rejected for the observed capture because it is empty.
- Treat `VehicleMappings` as the effective source: rejected because the controlled reverser swap left a contradictory record there while `CustomVehicle` matched the UI change.
- Hard-code documented/default keys: rejected because it violates product requirements and would not follow user rebindings.
- Ask users to maintain a second mapping: rejected as a product non-goal.

## Approval gate

Change status to Accepted only after the remaining bounded experiment in `docs/research/bindings.md` proves unbound form, duplicate behavior, and restart persistence. The three required binding changes, single-profile resolution policy, US-layout scope, and in-place write behavior are already captured.
