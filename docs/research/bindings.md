# TSW2 binding-source discovery

Status: **validated for the defined MVP support envelope**.

## Scope and evidence boundary

The issue requires proof that a source is authoritative by changing `KeyboardToggleDoorsLeft`, `KeyboardToggleDoorsRight`, and one reverser binding in TSW2 and correlating the writes. The initial two profile files had equivalent required records. On 2026-09-11 a person operating the native game UI swapped left/right doors and reverser increase/decrease while a read-only watcher observed the save directory. The resulting `PP_aps.sav` changes encode all three UI changes exactly, proving that file is an authoritative persistence source for this tested profile/build.

The experiment also proved that a reader cannot use `VehicleMappings` alone: TSW2 stores action overrides and vehicle-control overrides in different properties, and retains a materialized/base mapping array. Follow-up experiments established unbound encoding, duplicate-key behavior, and restart persistence. The MVP is explicitly limited to one configured/discovered profile, one UI binding per action/direction, and US-layout keyboards.

## Environment

Observation date: 2026-09-11 (America/Los_Angeles).

- OS: Windows 11 Home Insider Preview, build 28120, UI/input culture `zh-CN`.
- Game: installed TSW2 Windows build with an executable timestamp of 2022-07-01; the executable exposes no file/product version. Its SHA-256 was recorded locally for reproducibility but is omitted because the installed package provenance is not independently established.
- Store-shaped user directory: `TrainSimWorld2EGS`.
- Game UI validation: performed manually for the three required swaps; exact UI screenshots were not captured.
- Keyboard model, firmware, Armoury Crate/Aura versions: not relevant to this binding-only observation and not collected.

## Candidate locations and observations

Paths below deliberately use environment variables and contain no username or account identifier.

| Candidate | Observation | Confidence |
|---|---|---|
| `%USERPROFILE%\Documents\My Games\TrainSimWorld2EGS\Saved\SaveGames\PP_aps.sav` | Standard-looking unencrypted GVAS; save class `/Script/TS2Prototype.PlayerProfile`; the three controlled UI swaps were persisted here. | Authoritative for tested profile/build |
| `%USERPROFILE%\Documents\My Games\TrainSimWorld2EGS\Saved\SaveGames\BAK_aps.sav` | Older backup with the same required binding records. | Backup candidate only |
| `%USERPROFILE%\Documents\My Games\TrainSimWorld2EGS\Saved\Config\WindowsNoEditor\Input.ini` | Two-byte empty file (CRLF) at observation time. | Rejected for this capture |

The current profile file contains a `SlotName` equal to its filename stem and a `PlayerProfileName`; the latter is personal data and is not retained in fixtures. For the single-profile MVP, discover exactly one matching `PP_*.sav` whose embedded `SlotName` matches its filename stem, or accept an explicitly configured path. Zero or multiple matches are an actionable configuration error; the reader must not guess which profile is active. Multi-profile selection and other store/build naming conventions are out of scope.

## Observed binary shape

The candidate begins with GVAS metadata identifying Unreal Engine `++UE4+Release-4.26` and save class `/Script/TS2Prototype.PlayerProfile`. Binding-like values occur in arrays of `VirtualHIDInputConfig` structs. The observed nesting is:

```text
<mapping array entry>: VirtualHIDInputConfig
  Identifier: NameProperty                 # raw action identifier
  VirtualHIDName: NameProperty             # observed as None
  IncreaseInputs: ArrayProperty<StructProperty>
    VirtualHIDInputChord
      Key: StructProperty<Key>
        KeyName: NameProperty              # Unreal FKey name
      bShift/bCtrl/bAlt/bCmd: BoolProperty
  DecreaseInputs: ArrayProperty<StructProperty>
    VirtualHIDInputChord ...
```

Observed mapping properties are:

- `CustomActionMappings: Array<CustomKeyboardActionBinding>`. Each entry has `KeyType`, `OldBinding`, and `NewBinding`; each binding is an `InputActionKeyMapping` containing `ActionName`, a key, and modifiers.
- `CustomVehicle: Array<VirtualHIDInputConfig>`. Controlled vehicle-input changes appear here as full directional overrides.
- `VehicleMappings: Array<VirtualHIDInputConfig>`. This retains/materializes base/effective-looking vehicle data, but the controlled experiment produced a contradictory duplicate reverser value here; it is not independently authoritative.

Use `VehicleMappings` as the base catalog of bindings, then replay every `CustomActionMappings` entry in serialized order: remove the exact `OldBinding` chord when it is not `None`, and add the exact `NewBinding` chord when it is not `None`. Apply matching `CustomVehicle` directional arrays as vehicle-control overrides. Do not read `VehicleMappings` as the sole effective source. The single-profile resolution rule above deliberately avoids unproven active-profile inference.

The sanitized transcriptions in `tests/fixtures/bindings/` contain only the three required action records. In both captures:

- `Reverser`: one increase chord (`W`) and one decrease chord (`S`).
- `KeyboardToggleDoorsLeft`: one increase chord (`Y`) and an empty decrease array.
- `KeyboardToggleDoorsRight`: one increase chord (`U`) and an empty decrease array.
- All modifiers on populated chords are false.

After the controlled swaps, `observed-custom.json` records:

- Door right: `OldBinding` `U`, `NewBinding` `Y`.
- Door left: `OldBinding` `Y`, `NewBinding` `U`.
- Reverser custom vehicle override: increase `S`, decrease `W`.
- The retained `VehicleMappings` reverser record became increase `S`, decrease `S`; this contradicts the UI swap and proves it cannot be treated as the only authoritative property.

These values are evidence, not application defaults.

### Unbound and duplicate experiments

After restart, the UI operator cleared Left Doors. `PP_aps.sav` emitted a paired `Changed` notification, grew by three bytes, and changed hash. The existing left-door delta remained, but its `NewBinding.Key.KeyName` became the Unreal name `None`. This proves UI unbound is represented by a retained delta whose new key is `None`; it is not an empty array for action mappings.

The operator then assigned Left Doors the same `Y` key already used by Right Doors. TSW2 accepted the duplicate without a conflict prompt. The delta array became, in order:

1. Right Doors `U` -> `Y`.
2. Left Doors `Y` -> `Y`.
3. Left Doors `None` -> `Y`.

This proves `CustomActionMappings` must be replayed as ordered remove/add operations rather than collapsed to one last entry per action. Replaying over the base yields both door actions bound to `Y`. The file grew again and changed hash. `observed-unbound.json` and `observed-duplicate-restart.json` are sanitized transcriptions.

After a normal exit and full relaunch, the operator confirmed in the UI that Left Doors=`Y`, Right Doors=`Y`, Reverser Increase=`S`, and Reverser Decrease=`W`. The duplicate and vehicle override therefore persist across restart.

## Normalization contract candidate

This contract is sufficient to implement issue 05 within the defined MVP envelope.

1. Treat `Identifier` plus direction (`increase` or `decrease`) as the raw action identity. Map only catalogued pairs to stable semantic actions. Retain unknown identifiers as diagnostics and ignore them for lighting.
2. Start from `VehicleMappings`. Replay `CustomActionMappings` in serialized order, removing the exact old action chord unless its key is `None`, then adding the exact new chord unless its key is `None`. Do not collapse entries by action identifier. Apply `CustomVehicle` directional arrays as vehicle-control overrides. The supported UI contract is one binding per action/direction. If a directional array nevertheless contains multiple chords, preserve all supported entries in serialized order as forward-compatible input; no primary/secondary UI semantics are claimed.
3. Represent a chord as `{ key_name, modifiers }`. `key_name` is the serialized Unreal `FKey` name, not a localized label or display character.
4. Normalize supported keyboard keys at the adapter boundary to USB HID keyboard usages plus modifiers using the US physical layout. Serialized Unreal `FKey` names are identities, not localized characters. Non-US layout display/translation is out of MVP scope. Core semantic mappings never contain a physical default.
5. For action deltas, `NewBinding.Key.KeyName=None` means remove the old chord and add nothing. For `VirtualHIDInputConfig`, an empty directional chord array means no binding in that direction. `None` is never a physical key.

`tests/fixtures/bindings/action-catalog.json` is the candidate MVP raw-to-semantic catalog. It intentionally contains no physical keys.

## Required edge-case behavior for issue 05

These are safety requirements, not claims about unobserved TSW2 writes.

- Multiple serialized chords: tolerate and emit every supported chord in stable order, deduplicating identical normalized chords with a diagnostic; the MVP exposes no secondary-binding UI semantics.
- Unbound: emit no physical key and an informational diagnostic.
- Duplicate physical key across actions: retain both semantic bindings; collision resolution belongs to `BindingResolver`, not the reader.
- Unknown action: retain enough raw identity for a diagnostic, but do not invent a semantic action.
- Unsupported key or modifier combination: skip only that chord and report its serialized `FKey` name.
- Malformed/truncated GVAS: reject the entire candidate snapshot, keep the last known-good snapshot, and report source path generically plus parse offset/reason. Never publish a partial snapshot.
- Unknown properties: skip by declared property length where safe; otherwise fail closed. Never edit or rewrite the game save.

## Reload and write behavior

For the controlled run, Windows `FileSystemWatcher` reported paired `Changed` notifications for `PP_aps.sav` at relative times T+0 s, T+3 s, and T+11 s, correlating with the three UI edits, plus another pair at T+108 s. It reported no create, delete, or rename. File length changed from 253,750 to 256,762 bytes and SHA-256 changed. Alt+F4 shutdown produced no additional profile-save event.

A separate isolated run launched to the main menu and exited through the normal menu without changing bindings. `firsttimeexperience.sav` emitted multiple `Changed` events, confirming the watcher was active, but `PP_aps.sav` emitted none and remained byte-identical: same 256,762-byte length, last-write timestamp, and SHA-256. Therefore binding changes are persisted during the edit/apply flow rather than deferred to normal shutdown. An earlier launch/exit updated the profile timestamp while preserving length and content hash, proving metadata-only false positives can also occur.

This is evidence of in-place writes for the tested build, but filesystem events may be coalesced or missed. Use debounced polling as the cross-build fallback rather than relying solely on `FileSystemWatcher`:

1. Poll the resolved candidate identity `(last-write time, length)` every 500 ms.
2. On a change, debounce for 250 ms.
3. Require two samples 100 ms apart with identical identity, then read a fresh handle.
4. On sharing violations, disappearance, parse failure, or a second identity change, retain the last known-good snapshot and retry with bounded backoff (50 ms to 1 s, maximum 5 s).
5. Publish only a completely parsed snapshot with a content-derived revision; coalesce identical content.
6. Watch the parent directory as an optimization so replace-by-rename is noticed, but keep polling as recovery for missed/coalesced events.

The timing values remain conservative starting parameters rather than performance-tuned guarantees. Content-derived revisions are mandatory because timestamp-only writes were observed.

## Completed bounded experiment

The following experiment was completed on the same installed build, identified by its UE version header, executable timestamp, and locally retained executable hash. The store-shaped user directory was recorded without claiming independently unavailable package provenance.

1. Close TSW2. Inventory candidate files with relative path, size, SHA-256, and nanosecond-capable timestamp. Copy candidates to an external scratch directory; never commit whole saves.
2. Start a filesystem trace on the `Saved` directory that records create/write/rename/delete events and periodically records candidate metadata.
3. TSW2 was launched with the same single test profile.
4. Left Doors was unbound through the UI and the changed file captured.
5. Left Doors was assigned the same key as Right Doors; TSW2 accepted and persisted the collision.
6. Parsed property trees and relevant byte ranges were compared and sanitized. The game was restarted and the effective bindings were confirmed in the UI.
7. The watcher observed each content write; content-derived revisions correctly distinguish writes from metadata-only changes and repeated/coalesced events.

The required three-change correlation, unbound form, duplicate behavior, restart persistence, and write completion are demonstrated. Secondary-binding UI behavior, multi-profile selection, and non-US layouts are explicitly outside the supported MVP envelope.

## Redaction and distribution notes

- Fixtures are hand-transcribed subsets, not distributable save files.
- Removed: username, profile name, account/store identifiers, avatar choices, progress, entitlements, rolling stock, routes, and timestamps precise enough to identify personal play sessions.
- No game binaries, SDKs, memory dumps, secrets, or personal paths are committed.
- GVAS parsing can be implemented independently; a third-party parser would require a separate dependency/license review. No such dependency is selected here.

## Recommendation

Use `PP_aps.sav` as the authoritative persistence source for the tested single profile/build. Resolve the effective bindings by replaying ordered `CustomActionMappings` deltas over `VehicleMappings`, then applying `CustomVehicle` overrides. Issue 05 is unblocked within the single-profile, single-UI-binding, US-layout MVP envelope.

## Independent reproduction

On 2026-09-11, a second agent was limited to this document, ADR-003, and `tests/fixtures/bindings/` (no original saves). It independently recovered both door old/new pairs and the reverser before/after swap and reproduced the property-precedence conclusion for the tested profile/build. A final reproduction includes the unbound, ordered-duplicate, and restart fixtures. It found no hard-coded semantic-to-key default or privacy leak after review findings were addressed.
