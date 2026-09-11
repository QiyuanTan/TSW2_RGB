# 00 — Bootstrap solution and CI

**Labels:** `agent-ready`, `kind:feature`, `area:build`  
**Dependencies:** none

## Outcome

A minimal buildable Windows-first solution with deterministic local/CI commands, based on an explicit runtime decision.

## Scope

- Compare C#/.NET and other credible options against ASUS interop, process/file APIs, distribution, testing, and contributor ergonomics; record ADR-001.
- Create the repository layout from `docs/architecture.md`, application/library projects, test projects, formatting/lint config, and one smoke test.
- Add CI for clean build, format/lint check, and tests on Windows; cache dependencies safely.
- Add developer setup and exact build/test commands to README. Pin SDK/tool versions.

## Required artifacts

`docs/decisions/ADR-001-runtime.md`, solution/project files, CI workflow, source/test skeletons, updated README.

## Acceptance criteria

- A clean checkout builds/tests with documented commands and no TSW2, ASUS SDK, Aura service, or hardware.
- Domain projects do not reference platform adapters.
- CI executes the same commands as local development and uploads useful test output on failure.
- No placeholder production behavior pretends to discover game or hardware.

## Verification

Run format/lint, build with warnings treated per ADR, and all tests from a clean dependency restore. Record versions and commands.

## Out of scope

Real bindings, state acquisition, RGB SDK integration, packaging.
