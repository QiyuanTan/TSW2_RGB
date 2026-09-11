# ADR-001: C# and .NET 8 for the Windows application

- Status: accepted
- Date: 2026-09-11

## Context

The application is Windows-first and must eventually combine process lifecycle and file observation with a replaceable ASUS per-key RGB adapter. It also needs deterministic unit, contract, and replay tests that run without the game, vendor services, or hardware.

Credible runtime choices were C#/.NET, Rust, and C++. Python was considered unsuitable for the primary runtime because packaging a dependable Windows background application and consuming native vendor SDKs would add deployment complexity without improving access to the required APIs.

## Decision

Use C# with the .NET 8 long-term-support SDK. Pin SDK feature band 8.0.4xx in `global.json`, permit only patch roll-forward within that band, target `net8.0` for platform-neutral libraries, and target `net8.0-windows` only at Windows composition boundaries.

The domain library must not reference the application host or concrete bindings, state-reader, or RGB adapters. CI treats compiler and analyzer warnings as errors. Formatting is enforced with the SDK-provided `dotnet format`; no separately installed formatter is required.

## Options considered

| Criterion | C# / .NET 8 | Rust | C++ |
| --- | --- | --- | --- |
| Windows process and file APIs | First-class managed APIs with P/Invoke escape hatch | Strong crates and Win32 bindings, with more unsafe boundary work | Direct Win32 access, with manual resource/error handling |
| ASUS/native interop | Straightforward P/Invoke/COM and vendor DLL loading behind an adapter | FFI is viable but requires a C ABI wrapper and unsafe code | Best raw SDK compatibility, but exposes native concerns broadly |
| Distribution | Self-contained or framework-dependent single-platform publishing | Small native executable | Native executable plus compiler/runtime and SDK dependency management |
| Testing | Mature xUnit ecosystem and simple fakes/clocks | Strong built-in test tooling | Framework choice and test discovery add setup |
| Contributor ergonomics | One pinned SDK for build, formatting, and tests | Good tooling, steeper Windows FFI learning curve | Highest build-system and memory-safety burden |

C# provides the best balance for a Windows integration while keeping native interop isolated. Rust remains a credible choice for a future low-level helper if discovery proves a native boundary demands it. C++ is not selected as the application runtime because its interop advantage does not outweigh testing, safety, and contributor costs here.

## Consequences

- Contributors need the pinned .NET 8 SDK; TSW2, Aura, an ASUS SDK, and physical hardware are not build dependencies.
- Platform-neutral projects remain testable on any .NET-supported host, while the executable is explicitly Windows-targeted.
- Any native SDK is loaded only by a future adapter selected through ADR-002; this decision does not select or claim compatibility with an ASUS transport.
- Binding and runtime-state schemas remain unresolved and are not represented by placeholder production implementations. Issues 01, 02, and 04 retain their research gates.
- Moving to a later .NET major version requires an ADR amendment and coordinated CI/tooling update.
