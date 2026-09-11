# 13 — Add replay end-to-end, resilience, and performance tests

**Labels:** `agent-ready`, `kind:quality`, `area:testing`  
**Dependencies:** 12

## Outcome

Captured bindings and state traces deterministically prove semantic-to-physical lighting behavior without game or hardware.

## Scope

- Build a replay harness using fixture binding snapshots, timestamped observations, fake clock/process/backend, and golden key frames.
- Cover all MVP system scenarios in `docs/test-strategy.md`, including hot reload and recovery.
- Add 30-minute accelerated/real-time soak modes and metrics for latency, CPU proxy/benchmark, memory growth, coalescing, errors, and backlog.
- Add fault injection for parser, reader, scheduler, and backend boundaries.

## Acceptance criteria

- Golden scenarios prove custom binding -> action/state -> expected physical key and color/effect.
- Same seed/fixtures generate identical results and actionable diffs on failure.
- No unbounded frame queue or material memory growth during soak; thresholds are explicit.
- CI runs a bounded replay suite without TSW2/Aura/hardware; long soak is separately invokable.
- Coverage gaps against PRD release gates are listed, not hidden.

## Required artifacts

Harness, golden scenarios, CI step, performance report template, updated fixture provenance.

## Verification

Run the bounded replay suite twice and compare outputs, execute every fault-injection case, and attach the long-soak metrics report with thresholds and environment details.
