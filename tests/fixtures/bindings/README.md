# Binding discovery fixtures

Schema version: 1.

These JSON files are sanitized, manually checked transcriptions of read-only local GVAS observations. They are research evidence, not parser input promises and not game defaults.

- `observed-backup.json`: required-action subset from `BAK_aps.sav`.
- `observed-current.json`: required-action subset from `PP_aps.sav`.
- `observed-custom.json`: sanitized section-aware transcription after the controlled three swaps.
- `action-catalog.json`: candidate raw action/direction to semantic-action mapping; intentionally contains no keys.

All captures came from the same Windows `zh-CN` environment and an installed TSW2 executable dated 2022-07-01. The source save class reported UE4 4.26 and `/Script/TS2Prototype.PlayerProfile`. Personal path segments, profile identity, progress, account/store identifiers, timestamps, and unrelated bindings were excluded.

The first two captures have identical records for the required actions and establish the before state. `observed-custom.json` records the correlated after state. Remaining unbound, duplicate, and restart fixtures are deliberately not fabricated; follow the bounded experiment in `docs/research/bindings.md` to supplement them. Secondary-binding UI behavior, multi-profile selection, and non-US layouts are outside the MVP support envelope.

Fixture invariants:

- `source_path` is generic.
- Chord order matches observed array order.
- `key_name` is the serialized Unreal `FKey` name, not a localized display character or a project default.
- An empty array records only what was observed; it is not proof of the UI's unbound encoding.
