# ADR-003: TSW2 binding source and key normalization

- Status: blocked
- Date: 2026-09-11
- Decision owners: binding discovery / issue #2

## Context

TSW2 lighting must follow the active in-game keyboard bindings. A local TSW2 profile provides strong evidence that binding-like `VirtualHIDInputConfig` records live in a UE4 GVAS player-profile save, while `Input.ini` is empty. The required controlled rebind, active-profile, secondary/unbound, locale, and write-behavior experiments could not be executed in the available environment.

See `docs/research/bindings.md` and its sanitized fixtures for the evidence and exact remaining experiment.

## Decision

No binding source is accepted yet. `PP_aps.sav` is the leading candidate, not an authoritative contract. Issue 05 remains blocked and must not ship a production parser based on this ADR.

The following boundary decisions are safe regardless of the eventual source and are accepted:

- Domain semantic actions do not contain default physical keys.
- Serialized raw action identifiers are translated through an explicit catalog; unknown identifiers remain unknown.
- Physical keys are normalized to keyboard HID usages plus modifiers, independently of localized display characters.
- Multiple supported chords are preserved; empty/unsupported chords produce no binding and diagnostics.
- Readers are read-only and publish only complete snapshots. Parse/write races retain the last known-good snapshot.

## Consequences

- Binding parser and hot-reload implementation remain gated.
- No hard-coded semantic-to-key defaults enter core/profile code.
- A later accepted revision must name the active-profile resolution rule, exact property schema, primary/secondary and unbound encodings, layout behavior, and validated reload strategy.
- The proposed polling/debounce behavior in the research report is test input, not a measured guarantee.

## Alternatives considered

- `Input.ini`: rejected for the observed capture because it is empty.
- Treat `PP_aps.sav` as authoritative from string inspection alone: rejected because correlation and selection are unproven.
- Hard-code documented/default keys: rejected because it violates product requirements and would not follow user rebindings.
- Ask users to maintain a second mapping: rejected as a product non-goal.

## Approval gate

Change status to Accepted only after the bounded experiment in `docs/research/bindings.md` is reproduced and its sanitized before/after fixtures explain all three required binding changes and edge cases.
