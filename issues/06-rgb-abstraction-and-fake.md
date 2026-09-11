# 06 — Implement RGB backend contract, fake, and frame submission

**Labels:** `agent-ready`, `kind:feature`, `area:rgb`  
**Dependencies:** 03

## Outcome

Application code can discover/open/submit/clear/close a keyboard through a transport-neutral interface and deterministic fake.

## Scope

- Implement `RgbBackend` lifecycle and capability/error types.
- Implement recording fake with configurable failures/disconnects.
- Add frame validation, sequence enforcement, identical-frame coalescing, and a bounded submission strategy so slow hardware cannot create unbounded backlog.
- Make cleanup idempotent and observable.

## Acceptance criteria

- Shared contract tests cover no-device, open, submit, changed/identical frames, invalid key/color, disconnect, clear, repeated close, and reopen.
- Backpressure has a documented deterministic policy (prefer newest complete frame).
- Backend errors carry stable category and actionable context without SDK leakage into domain types.
- No ASUS dependency appears in this issue.

## Verification

Contract suite using fake clock/backend plus concurrency/backpressure tests; optional benchmark for frame throughput.
