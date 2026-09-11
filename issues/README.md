# Agent-ready Issue Backlog

Each numbered file is a canonical issue body suitable for GitHub. Issues are sized for one coding agent; research issues require the Windows game/hardware environment. Implement only the assigned issue plus the smallest contract-compatible changes.

| ID | Title | Kind | Depends on | Parallel notes |
|---|---|---|---|---|
| 00 | Bootstrap solution and CI | Build | none | Start immediately |
| 01 | Discover TSW2 binding source | Research | none | Parallel with 00, 02, 04 |
| 02 | Validate runtime state acquisition | Research gate | none | Parallel with 00, 01, 04 |
| 03 | Domain contracts and configuration | Core | 00 | Uses documented contracts |
| 04 | Select/prove ASUS RGB transport | Research spike | none | Parallel with 00-02 |
| 05 | Binding parser and key normalization | Feature | 01, 03 | Parallel with 06-08 |
| 06 | RGB abstraction and fake backend | Feature | 03 | Parallel with 05, 07, 08 |
| 07 | State aggregation and staleness | Feature | 02, 03 | Needs acquisition decision |
| 08 | Semantic lighting rule engine | Feature | 03 | Parallel with 05-07 |
| 09 | ASUS per-key backend | Feature | 04, 06 | Needs hardware |
| 10 | Binding hot reload | Feature | 05 | Parallel with 09, 11 |
| 11 | Runtime reader adapters | Feature | 02, 07 | Split only if ADR-004 requires it |
| 12 | Process lifecycle and coordinator | Integration | 05-11 | Avoid parallel edits here |
| 13 | Replay E2E and failure tests | Quality | 12 | Fixtures can start after 01/02 |
| 14 | Locomotive capability profiles | Feature | 07, 08, 11 | Generic state first |
| 15 | Package MVP and release validation | Release | 09, 10, 12-14 | Final gate |

Critical path: `00 -> 03 -> (05,06,07,08) -> (09,10,11) -> 12 -> 13 -> 15`.

Issue 02 is a product gate. If it cannot validate required state coverage, revise the PRD before downstream issues claim success.

Suggested labels: `kind:research`, `kind:feature`, `kind:quality`, `area:bindings`, `area:state`, `area:lighting`, `area:rgb`, `area:lifecycle`, `needs-hardware`, `needs-game`, `blocked`, `agent-ready`.

Shared references: [PRD](../docs/product-requirements.md), [architecture](../docs/architecture.md), [discovery](../docs/technical-discovery.md), [testing](../docs/test-strategy.md).
