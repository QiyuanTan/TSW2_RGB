# 12 — Implement TSW2 lifecycle and application coordinator

**Labels:** `agent-ready`, `kind:feature`, `area:lifecycle`, `area:integration`  
**Dependencies:** 05, 06, 07, 08, 09, 10, 11

## Outcome

One cancellation-safe coordinator composes bindings, readers, rules, and RGB backend across game/device lifecycle.

## Scope

- Detect the process identity defined by discovery, wait when absent, attach once, and handle exit/restart without polling aggressively.
- Order startup: config/logging, bindings, backend, readers, scheduler; order shutdown in reverse with guaranteed RGB release.
- Run configurable state/render cadence, coalesce frames, expose component health, and isolate recoverable faults with bounded backoff/jitter.
- Handle Ctrl+C/service/application shutdown and unexpected component failures.
- Record ADR-005 for threading/update loop.

## Acceptance criteria

- Starting before/after TSW2, game exit/restart, missing binding, reader failure, device disconnect/reconnect, and cancellation are integration-tested with fakes.
- No duplicate loops/resources after reconnect; cleanup is idempotent.
- Supported features continue when one optional reader/field fails.
- Logs include session/revision/frame context but no sensitive paths or raw dumps.
- Coordinator never treats input feedback as confirmed state.

## Verification

Deterministic fake-clock lifecycle tests plus a manual live smoke test. Inspect for background task/thread leaks.
