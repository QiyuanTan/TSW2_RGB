# ADR-004: Runtime state acquisition remains unselected

- Status: Rejected / `NO-GO`
- Date: 2026-09-11
- Issue: #3

## Context

The product requires confirmed reverser, left-door, right-door, and headlight or wiper state. The acquisition source must be read-only, recover from lifecycle changes, declare supported fields, and represent unsupported data as unknown or unavailable.

No live TSW2 session, tested locomotive, authoritative interface, or visible-state-correlated trace was available during this decision. Generic engine documentation and input events cannot establish a TSW2 runtime contract.

## Decision

Select no runtime state source. The gate is `NO-GO`.

Do not implement a production reader, offsets, selectors, OCR rules, or input-derived confirmed state from this ADR. Issues depending on acquisition feasibility remain blocked. The bounded validation experiment in `docs/research/state-acquisition.md` must be completed before this ADR can be superseded.

## Rejected alternatives

- **Treat input as state:** rejected because it cannot confirm acceptance or externally caused changes.
- **Assume generic Unreal telemetry/plugin access:** rejected because availability in a packaged TSW2 build was not demonstrated.
- **Infer a file or IPC schema:** rejected because no changing authoritative source was captured.
- **Ship OCR selectors without measurements:** rejected because field visibility, error rate, latency, resolution, and localization behavior are unknown.
- **Adopt memory inspection speculatively:** rejected due to build fragility, security/account risk, distribution burden, and lack of explicit validation approval.

## Threat, stability, and distribution assessment

| Area | Decision impact |
|---|---|
| Game integrity | Only read-only observation is permitted; injection, config writes, packet tampering, and writable memory are prohibited |
| Account/security | Memory inspection is not approved by this ADR and requires separate risk review |
| Stability | No build/locomotive compatibility claim exists; unsupported contexts must fail unavailable |
| Privacy | Captures must exclude usernames, paths, account IDs, save data, raw dumps, and secrets |
| Distribution | No SDK, plugin, offset database, or third-party binary is approved for redistribution |
| Recovery | A future reader must detach on loss, mark its fields unavailable, retry with bounded backoff, and treat a new process/locomotive as a new session |

## Consequences

- The PRD narrows the current demonstrable milestone to binding-driven/static lighting and explicitly defers confirmed runtime synchronization.
- No feature may present optimistic input feedback as confirmed simulator state.
- The trace schema and validation tooling can accept future sanitized captures without committing source-specific production behavior.
- A future `GO` or `GO with revised scope` must supersede this ADR with correlated traces, a per-build/locomotive capability matrix, measured reliability/latency, and licensing/distribution evidence.
