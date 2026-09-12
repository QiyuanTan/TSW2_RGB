# ADR-003: TSW2 binding source and key normalization

- Status: accepted
- Date: 2026-09-11
- Decision owners: binding discovery / issue #2

## Context

TSW2 lighting must follow the in-game keyboard bindings for the supported configuration. Controlled manual UI runs proved three required swaps, unbinding, duplicate keys, and restart persistence in a UE4 GVAS player-profile save while `Input.ini` remains empty. Door action overrides are ordered old/new deltas in `CustomActionMappings`; vehicle-control overrides appear in `CustomVehicle`. `VehicleMappings` alone is insufficient. The MVP support envelope is one resolved player profile, one UI binding per action/direction, and US-layout keyboards.

See `docs/research/bindings.md` and its sanitized fixtures for the evidence and reproduction procedure.

## Decision

For the tested profile/build, `PP_aps.sav` is the authoritative persistence source. Resolve exactly one matching self-consistent `PP_*.sav`, or require an explicitly configured profile path; never guess among multiple profiles. Start with `VehicleMappings`, replay every `CustomActionMappings` entry in serialized order as remove-old/add-new (`None` means no chord), then apply matching `CustomVehicle` directional overrides. Issue 05 is unblocked within the defined MVP envelope.

The following boundary decisions are safe regardless of the eventual source and are accepted:

- Domain semantic actions do not contain default physical keys.
- Serialized raw action identifiers are translated through an explicit catalog; unknown identifiers remain unknown.
- Physical keys are normalized to keyboard HID usages plus modifiers, independently of localized display characters.
- Multiple supported chords are preserved; empty/unsupported chords produce no binding and diagnostics.
- Key normalization targets the US physical keyboard layout. Non-US translation and multi-profile selection are unsupported for MVP.
- No secondary-binding UI behavior is required; multiple serialized chords are tolerated in stable order for forward compatibility.
- Readers are read-only and publish only complete snapshots. Parse/write races retain the last known-good snapshot.

## Consequences

- Binding parser and hot-reload implementation may proceed within the defined support envelope.
- No hard-coded semantic-to-key defaults enter core/profile code.
- Unbound action deltas use `NewBinding.Key.KeyName=None`; duplicate deltas are replayed in order and preserved; effective bindings persist across restart.
- The proposed polling/debounce behavior in the research report is test input, not a measured guarantee.

## Alternatives considered

- `Input.ini`: rejected for the observed capture because it is empty.
- Treat `VehicleMappings` as the effective source: rejected because the controlled reverser swap left a contradictory record there while `CustomVehicle` matched the UI change.
- Hard-code documented/default keys: rejected because it violates product requirements and would not follow user rebindings.
- Ask users to maintain a second mapping: rejected as a product non-goal.

## Validation

Accepted after the bounded experiment in `docs/research/bindings.md` proved all three required changes, unbound form, duplicate behavior, restart persistence, and in-place write behavior. The decision also adopts the single-profile resolution policy and US-layout support boundary.
