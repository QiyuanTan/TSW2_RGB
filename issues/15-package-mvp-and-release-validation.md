# 15 — Package MVP and execute release validation

**Labels:** `agent-ready`, `kind:quality`, `area:release`, `needs-game`, `needs-hardware`  
**Dependencies:** 09, 10, 12, 13, 14

## Outcome

A reproducible Windows MVP build with complete setup, support boundaries, safety notes, and evidence against every PRD release gate.

## Scope

- Create repeatable publish/package workflow with pinned runtime/architecture and required license notices; do not add an installer unless separately approved.
- Write user setup, supported TSW2/device/locomotive matrix, troubleshooting, logs/privacy, clean shutdown, and uninstall/manual removal guidance.
- Add config example and validation command; default to safe logging and no invasive optional reader unless ADR-004 permits/enables it.
- Execute automated, live-game, hardware, reconnect, exit/restore, 30-minute soak, latency, CPU, and memory checks.

## Acceptance criteria

- Fresh-machine or clean-VM walkthrough reaches working lighting using only documented prerequisites/steps.
- Every PRD release gate has `PASS`, `FAIL`, or `DEFERRED` plus evidence and owner; MVP ships only with required gates passing.
- Package excludes fixtures containing personal data, research probes, unlicensed SDK files, debug symbols/secrets unless intentionally documented.
- Startup failure and unsupported hardware/build produce actionable messages and safe cleanup.
- Version/changelog and known limitations accurately match the support matrix.

## Required artifacts

Publish scripts/config, `docs/user-guide.md`, `docs/support-matrix.md`, `docs/release-checklist.md`, license notices, release notes.

## Verification

Attach checksums and exact build command; repeat install/run/exit/removal from the produced artifact, not a developer build.
