# Runtime state trace fixtures

These fixtures are sanitized JSON Lines (`.jsonl`). They contain observations actually made during issue #3 research; synthetic train-state transitions are not included.

## Provenance

| File | Date | Environment | Purpose |
|---|---|---|---|
| `process-absent.jsonl` | 2026-09-11 | Windows host; no running TSW2 process | Records genuine source-unavailable behavior only |
| `game-exited.jsonl` | 2026-09-12 | Windows host; user exited the observed TSW2 session | Records a point-in-time absence check after exit, not exit latency or production reader behavior |

This evidence does not validate any train-state field or locomotive.

Live BR442 observations are documented in [the session ledger](../../../docs/research/br442-live-session.md). They are manual screenshot interpretations, not replayable state-reader captures. No synthetic train state is promoted to authoritative or validated-derived quality.

## Schema

Each nonblank line is one JSON object with exactly these required fields:

- `schema_version`: integer `1`.
- `sequence`: integer, starting at `1` and increasing by one within a file.
- `observed_at_utc`: RFC 3339 UTC timestamp ending in `Z`, nondecreasing within a file.
- `source_id`: stable lowercase identifier containing letters, digits, dots, underscores, or hyphens.
- `event`: `observation`, `source_attached`, `source_unavailable`, `session_changed`, or `source_detached`.
- `field`: canonical field: `session`, `reverser`, `doors.left`, `doors.right`, `headlights`, `wipers`, or `locomotive_id`.
- `value`: a normalized enum value, a sanitized identifier, `unknown`, or `unavailable`.
- `quality`: `authoritative`, `validated-derived`, `optimistic`, `stale`, or `unavailable`.
- `context`: object containing only sanitized, non-personal qualifiers.

Future traces must document game build/store, locomotive, route or scenario where relevant, capture method/version, sanitization, and visible-state correlation. Do not commit personal paths, usernames, platform account IDs, save data, secrets, raw screenshots, video, memory dumps, or opaque binary captures.

## Validation

From the repository root:

```powershell
pwsh -NoProfile -File tests/fixtures/state/validate-traces.ps1
```

Pass `-TraceRoot <directory>` to validate a separate sanitized capture set before copying it into the repository.

The validator checks syntax, required fields, vocabulary, sequence/timestamp ordering, and common path/account redaction hazards. Semantic correlation with the game remains a manual review and must not be inferred from this check.
