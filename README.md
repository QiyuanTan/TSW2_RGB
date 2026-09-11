# TSW2 ROG Keyboard Integration

Windows-first application skeleton for mapping Train Sim World 2 (TSW2) semantic controls and live train state to individually addressable ASUS ROG keyboard LEDs. Game discovery, state acquisition, and RGB transport remain gated research work and are not implemented yet.

## Developer setup

Install the .NET 8 SDK selected by [`global.json`](global.json) (8.0.414 or a later 8.0.4xx patch). Visual Studio is optional. Building and testing do not require TSW2, an ASUS SDK, Aura services, or physical hardware.

From the repository root, run the same sequence used by CI:

```powershell
dotnet restore TSW2Rgb.sln --configfile NuGet.Config --locked-mode
dotnet format TSW2Rgb.sln --verify-no-changes --no-restore
dotnet build TSW2Rgb.sln --configuration Release --no-restore
dotnet test TSW2Rgb.sln --configuration Release --no-build --logger "trx;LogFileName=test-results.trx" --results-directory artifacts/test-results
```

Warnings and SDK analyzers fail the build. Generated build and test output is written beneath ignored `bin/`, `obj/`, and `artifacts/` directories.

## Repository layout

- `src/TSW2Rgb.Domain`: platform-neutral domain library; it must not reference application or platform adapters.
- `src/TSW2Rgb.App`: Windows composition host.
- `tests/TSW2Rgb.Domain.Tests`: hardware-free unit and architecture tests.
- `docs/decisions`: architectural decision records, beginning with [ADR-001](docs/decisions/ADR-001-runtime.md).
- Future binding, state, lighting, and RGB projects will be added by their corresponding backlog issues after their dependency gates are satisfied.

## Start here

- [Product requirements](docs/product-requirements.md)
- [System architecture and contracts](docs/architecture.md)
- [Technical discovery plan](docs/technical-discovery.md)
- [Quality and test strategy](docs/test-strategy.md)
- [Issue backlog and dependency graph](issues/README.md)

The backlog is deliberately split into agent-sized issues. Do not begin runtime-state feature work until the acquisition feasibility gate in issue 02 is resolved.
