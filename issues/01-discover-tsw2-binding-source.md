# 01 — Discover and specify the TSW2 binding source

**Labels:** `agent-ready`, `kind:research`, `area:bindings`, `needs-game`  
**Dependencies:** none

## Outcome

Reproducible evidence identifies the authoritative active binding source and a schema sufficient to implement issue 05.

## Work

Execute the binding section of `docs/technical-discovery.md`. Capture default/custom/secondary/unbound/duplicate examples, identify active profile selection and write behavior, and define semantic action plus physical-key normalization. Investigate reload detection. Sanitize all fixtures.

## Required artifacts

- `docs/research/bindings.md` with environment, paths expressed generically, experiments, schema, edge cases, and redaction notes.
- `docs/decisions/ADR-003-bindings.md`.
- Versioned fixtures under `tests/fixtures/bindings/` with provenance README.
- Candidate action catalog for MVP, mapping raw identifiers only to semantic actions—not physical defaults.

## Acceptance criteria

- Changing three required bindings produces explained fixture differences.
- Primary, secondary, unbound, duplicate, malformed/truncated, and unknown-action behavior is specified.
- Keyboard representation is defined independently from localized display characters.
- A reload mechanism and debounce/atomic-write behavior are documented.
- If the authority cannot be proven, report the precise blocker and next bounded experiment; do not invent a format.

## Verification

Have a second person/agent reproduce fixture interpretation solely from the document. No production parser in this issue.
