# 04 — Select and prove ASUS RGB transport

**Labels:** `agent-ready`, `kind:research`, `area:rgb`, `needs-hardware`  
**Dependencies:** none

## Outcome

A legally distributable, stable approach is selected and shown to address the target ROG keyboard per key.

## Work

Execute the RGB section of `docs/technical-discovery.md`. Prefer supported APIs when they meet requirements. Measure frame/update behavior and resource cleanup; document services, architecture, SDK installation, licensing, device/firmware matrix, key translation, exclusive-control behavior, and restoration limits.

## Required artifacts

`docs/research/rgb-backend.md`, `docs/decisions/ADR-002-rgb-transport.md`, supported-device matrix, normalized-key translation table, and an isolated diagnostic probe with explicit manual invocation.

## Acceptance criteria

- Ten spatially distinct keys display distinct expected colors.
- Ten-minute animation reports errors/latency and no obvious leak or stutter.
- Clear, close, process termination, and device reconnect behavior are documented and tested where possible.
- SDK binaries are not committed unless license explicitly permits it.
- Unsupported device/service yields a clear diagnostic and safe exit.

## Verification

Record dated hardware test evidence and exact environment. The probe must never run in ordinary automated tests.
