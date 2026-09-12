# TSW2 ROG Keyboard Integration

Planning package for a Windows application that maps Train Sim World 2 (TSW2) semantic controls and live train state to individually addressable ASUS ROG keyboard LEDs.

## Start here

- [Product requirements](docs/product-requirements.md)
- [System architecture and contracts](docs/architecture.md)
- [Technical discovery plan](docs/technical-discovery.md)
- [Quality and test strategy](docs/test-strategy.md)
- [ASUS RGB transport research](docs/research/rgb-backend.md)
- [Issue backlog and dependency graph](issues/README.md)

## Manual RGB diagnostic probe

The opt-in Windows LampArray probe is isolated from normal startup and automated tests. See the research record before using it. A pure, hardware-free check is available with:

```powershell
powershell.exe -NoProfile -File .\tests\rgb-probe\Run-Tests.ps1
powershell.exe -NoProfile -File .\tests\rgb-ambient-probe\Run-Tests.ps1
powershell.exe -NoProfile -File .\tests\rgb-aura-rest-probe\Run-Tests.ps1
```

The foreground probe proves direct device behavior only. Game-focused/background control requires the sparse-identity ambient probe and its explicit per-user registration; follow `docs/research/rgb-backend.md` before running it. The Aura REST probe records the rejected ASUS Game SDK alternative and must not be treated as a supported backend.

The backlog is deliberately split into agent-sized issues. Do not begin runtime-state feature work until the acquisition feasibility gate in issue 02 is resolved.
