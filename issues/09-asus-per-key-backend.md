# 09 — Implement the ASUS per-key RGB backend

**Labels:** `agent-ready`, `kind:feature`, `area:rgb`, `needs-hardware`  
**Dependencies:** 04, 06

## Outcome

The selected transport from ADR-002 implements the shared RGB contract on supported hardware.

## Scope

- Isolate native/SDK/HID interop behind one adapter and translate normalized keys via the researched table.
- Implement discovery, deterministic device selection, open, full-frame submit, clear, close, reconnect/error translation, and cancellation.
- Add required runtime/service detection and actionable diagnostics.
- Keep SDK binaries/license notices and architecture-specific loading compliant with ADR-002.

## Acceptance criteria

- Pass the shared backend contract suite; hardware-only tests are separately marked.
- Unsupported key/model/service/architecture fails safely without coordinator crash.
- No SDK type escapes the adapter package.
- Frame submission meets measured target or reports an evidence-backed limitation.
- Cleanup/release executes after normal stop and simulated handled failure.

## Required artifacts

Adapter code, setup/troubleshooting documentation, updated device matrix, dated hardware checklist.

## Verification

Automated contract tests plus issue 04 ten-key, animation, reconnect, and cleanup scenarios on the reference keyboard.
