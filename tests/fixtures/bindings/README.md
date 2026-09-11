# Binding discovery fixtures

Schema version: 1.

These JSON files are sanitized, manually checked transcriptions of read-only local GVAS observations. They are research evidence, not parser input promises and not game defaults.

- `observed-backup.json`: required-action subset from `BAK_aps.sav`.
- `observed-current.json`: required-action subset from `PP_aps.sav`.
- `action-catalog.json`: candidate raw action/direction to semantic-action mapping; intentionally contains no keys.

Both captures came from the same Windows `zh-CN` environment and an installed TSW2 executable dated 2022-07-01. The source save class reported UE4 4.26 and `/Script/TS2Prototype.PlayerProfile`. Personal path segments, profile identity, progress, account/store identifiers, timestamps, and unrelated bindings were excluded.

The two captures have identical records for the required actions. They therefore do not prove a UI rebind or authority. Do not rename them to “default” or “custom”. The missing controlled fixtures are deliberately not fabricated; follow the bounded experiment in `docs/research/bindings.md` to replace/supplement them.

Fixture invariants:

- `source_path` is generic.
- Chord order matches observed array order.
- `key_name` is the serialized Unreal `FKey` name, not a localized display character or a project default.
- An empty array records only what was observed; it is not proof of the UI's unbound encoding.
