# TSW2 binding-source discovery

Status: **blocked pending the controlled in-game rebind experiment described below**. This document records verified observations, not a completed authority decision.

## Scope and evidence boundary

The issue requires proof that a source is authoritative by changing `KeyboardToggleDoorsLeft`, `KeyboardToggleDoorsRight`, and one reverser binding in TSW2 and correlating the writes. The available installation could be inspected read-only, but this execution environment could not operate the native game UI. Two existing profile files were compared; their three required records are byte-for-byte equivalent, so they are not a substitute for the required experiment.

No production parser should be implemented from this report yet. Issue 05 remains gated.

## Environment

Observation date: 2026-09-11 (America/Los_Angeles).

- OS: Windows 11 Home Insider Preview, build 28120, UI/input culture `zh-CN`.
- Game: installed TSW2 Windows build with an executable timestamp of 2022-07-01; the executable exposes no file/product version. Its SHA-256 was recorded locally for reproducibility but is omitted because the installed package provenance is not independently established.
- Store-shaped user directory: `TrainSimWorld2EGS`.
- Game/keyboard UI validation: not performed.
- Keyboard model, firmware, Armoury Crate/Aura versions: not relevant to this binding-only observation and not collected.

## Candidate locations and observations

Paths below deliberately use environment variables and contain no username or account identifier.

| Candidate | Observation | Confidence |
|---|---|---|
| `%USERPROFILE%\Documents\My Games\TrainSimWorld2EGS\Saved\SaveGames\PP_aps.sav` | Standard-looking unencrypted GVAS; save class `/Script/TS2Prototype.PlayerProfile`; contains action/chord records. | Strong candidate, authority unproven |
| `%USERPROFILE%\Documents\My Games\TrainSimWorld2EGS\Saved\SaveGames\BAK_aps.sav` | Older backup with the same required binding records. | Backup candidate only |
| `%USERPROFILE%\Documents\My Games\TrainSimWorld2EGS\Saved\Config\WindowsNoEditor\Input.ini` | Two-byte empty file (CRLF) at observation time. | Rejected for this capture |

The current profile file contains the slot strings `PP_aps` and a profile name. Profile names are personal data and are not retained in fixtures. The existence of `PP_aps.sav` does **not** prove how TSW2 chooses the active profile, whether the slot name is stable, or whether another store/build uses the same filename.

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

Observed mapping arrays include `CustomVehicle` and `VehicleMappings`. Their precedence and active-profile semantics are unproven. A parser must preserve array order and all unknown properties, but must not infer that the first array or first chord is active until the controlled experiment proves it.

The sanitized transcriptions in `tests/fixtures/bindings/` contain only the three required action records. In both captures:

- `Reverser`: one increase chord (`W`) and one decrease chord (`S`).
- `KeyboardToggleDoorsLeft`: one increase chord (`Y`) and an empty decrease array.
- `KeyboardToggleDoorsRight`: one increase chord (`U`) and an empty decrease array.
- All modifiers on populated chords are false.

These values are evidence, not application defaults.

## Normalization contract candidate

This contract is sufficient to describe the next experiment, but remains provisional until that experiment succeeds.

1. Treat `Identifier` plus direction (`increase` or `decrease`) as the raw action identity. Map only catalogued pairs to stable semantic actions. Retain unknown identifiers as diagnostics and ignore them for lighting.
2. Treat every array element as a binding candidate. Do not label array positions “primary” or “secondary” until the UI-to-array ordering is observed. Preserve multiple chords and duplicates.
3. Represent a chord as `{ key_name, modifiers }`. `key_name` is the serialized Unreal `FKey` name, not a localized label or display character.
4. Normalize supported keyboard keys at the adapter boundary to USB HID usage identifiers plus modifiers. For example, serialized letter names describe physical key identities; layout-specific characters must come from the OS layout only for display. Core semantic mappings never contain a physical default.
5. An empty chord array is the observed candidate representation for “no binding in that direction”; a UI unbind must still prove this. A serialized `KeyName=None` must be treated as unsupported/unbound, not as a key.

`tests/fixtures/bindings/action-catalog.json` is the candidate MVP raw-to-semantic catalog. It intentionally contains no physical keys.

## Required edge-case behavior for issue 05

These are safety requirements, not claims about unobserved TSW2 writes.

- Primary/secondary: emit every supported chord in stable serialized order; deduplicate identical normalized chords while reporting a diagnostic.
- Unbound: emit no physical key and an informational diagnostic.
- Duplicate physical key across actions: retain both semantic bindings; collision resolution belongs to `BindingResolver`, not the reader.
- Unknown action: retain enough raw identity for a diagnostic, but do not invent a semantic action.
- Unsupported key or modifier combination: skip only that chord and report its serialized `FKey` name.
- Malformed/truncated GVAS: reject the entire candidate snapshot, keep the last known-good snapshot, and report source path generically plus parse offset/reason. Never publish a partial snapshot.
- Unknown properties: skip by declared property length where safe; otherwise fail closed. Never edit or rewrite the game save.

## Reload and write behavior

Actual TSW2 write/rename behavior is **not yet observed**. Until measured, use debounced polling as the proposed cross-build fallback rather than relying solely on `FileSystemWatcher`:

1. Poll the resolved candidate identity `(last-write time, length)` every 500 ms.
2. On a change, debounce for 250 ms.
3. Require two samples 100 ms apart with identical identity, then read a fresh handle.
4. On sharing violations, disappearance, parse failure, or a second identity change, retain the last known-good snapshot and retry with bounded backoff (50 ms to 1 s, maximum 5 s).
5. Publish only a completely parsed snapshot with a content-derived revision; coalesce identical content.
6. Watch the parent directory as an optimization so replace-by-rename is noticed, but keep polling as recovery for missed/coalesced events.

The timing values are starting parameters for the bounded experiment, not measured facts. The experiment must record whether TSW2 writes in place, truncates then writes, or replaces atomically, and whether changes occur on key assignment, menu apply/back, profile switch, or shutdown.

## Bounded experiment required to unblock ADR-003

Use a supported, legitimately installed TSW2 build whose exact game version/store can be recorded.

1. Close TSW2. Inventory candidate files with relative path, size, SHA-256, and nanosecond-capable timestamp. Copy candidates to an external scratch directory; never commit whole saves.
2. Start a filesystem trace on the `Saved` directory that records create/write/rename/delete events and periodically records candidate metadata.
3. Launch TSW2, select a named test profile, and record which file changes. Capture `default-before`.
4. In the keyboard settings UI, bind left doors to a previously unused key, add a secondary binding if the UI supports it, then apply/back. Capture the UI and changed files.
5. Repeat for right doors and reverser increase. Then unbind one secondary, deliberately duplicate one key on two actions if allowed, and capture after each apply.
6. Switch profiles and repeat one change to establish active-profile selection.
7. With a non-US layout active, bind the physical key whose legend/produced character differs and compare serialized `KeyName` with the UI label.
8. Diff parsed property trees and raw byte ranges. Confirm unrelated profile data is excluded from fixtures. Repeat once after game restart to prove persistence and selection.
9. Record event timing and test the proposed debounce algorithm against every write trace.

Success requires a one-to-one correlation between each UI operation and the selected source/schema, including primary/secondary ordering, unbound form, duplicates, layout behavior, profile selection, and write completion. If any point is ambiguous, keep ADR-003 blocked and narrow the next experiment to that ambiguity.

## Redaction and distribution notes

- Fixtures are hand-transcribed subsets, not distributable save files.
- Removed: username, profile name, account/store identifiers, avatar choices, progress, entitlements, rolling stock, routes, and timestamps precise enough to identify personal play sessions.
- No game binaries, SDKs, memory dumps, secrets, or personal paths are committed.
- GVAS parsing can be implemented independently; a third-party parser would require a separate dependency/license review. No such dependency is selected here.

## Recommendation

Keep `PP_aps.sav` as the leading candidate and keep issue 05 blocked. Do not approve ADR-003 or claim hot reload support until the bounded in-game experiment succeeds. The empty `Input.ini` and matching records in `PP_aps.sav`/`BAK_aps.sav` are useful discovery evidence but do not establish authority.

## Independent reproduction

On 2026-09-11, a second agent was limited to this document and `tests/fixtures/bindings/` (no original saves). It independently recovered the three chord interpretations listed above, identified `PP_aps.sav` only as a leading candidate, and reported every unproven behavior called out in this document. It found no contradiction, hard-coded semantic-to-key default, or privacy leak. This verifies that the sanitized evidence is interpretable; it does not satisfy the missing in-game authority experiment.
