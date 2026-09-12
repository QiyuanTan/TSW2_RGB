# ADR-002: RGB transport

- Status: Proposed — hardware gate open
- Date: 2026-09-11
- Decision owners: project maintainers

## Context

The MVP needs per-key RGB on a target ASUS ROG keyboard, safe ownership release, reconnect handling, low update latency, and a distributable transport. Domain and lighting code must remain vendor-neutral. The transport decision must not rely on guessed HID packets or unlicensed binaries.

## Decision

Implement the ASUS backend against Windows `Windows.Devices.Lights.LampArray`, provided the hardware checklist in `docs/research/rgb-backend.md` passes. Translate normalized keys at the adapter boundary through Windows `VirtualKey` and `GetIndicesForKey`. Treat an absent device, unavailable device, and unmapped key as explicit recoverable diagnostics.

Do not merge a production adapter or claim Scope II 96 support while this ADR is Proposed. Promote it to Accepted only after the dated ten-key, ten-minute soak, clear, normal/forced exit, and reconnect evidence is recorded.

Foreground control is sufficient for the diagnostic probe. A production background integration must use package identity and the `com.microsoft.windows.lighting` app extension, or document why foreground-only operation meets the product lifecycle. This packaging requirement is deferred to the backend/release issues.

## Consequences

- No ASUS SDK binary or COM interop assembly is distributed.
- Windows owns device arbitration and restoration to the next eligible controller or firmware autonomous mode.
- Supported hardware is limited to devices that expose HID LampArray and map required virtual keys.
- Dynamic Lighting must be enabled and user/app priority may affect availability.
- Reconnect should use `DeviceWatcher` plus `LampArray.AvailabilityChanged` in the production backend.
- The adapter must submit complete key colors without persisting a hard-coded lamp-index table.

## Rejected alternatives

### ASUS Aura SDK 3.07.05

Rejected on the reference machine because enumeration hung or crashed in isolated workers, restoration was not proven, and redistribution terms were not established. The probe released control separately after the failed experiment; no SDK binary is committed.

### Direct HID / OpenRGB-derived transport

Rejected because the exact target PID was not found in inspected OpenRGB support and no authoritative protocol evidence was available. Reverse-engineering or copying packets before that evidence exists would create device-safety, vendor-service conflict, maintenance, and licensing risk.

## Links

- [Research record](../research/rgb-backend.md)
- [Architecture](../architecture.md)
- [Technical discovery protocol](../technical-discovery.md)
