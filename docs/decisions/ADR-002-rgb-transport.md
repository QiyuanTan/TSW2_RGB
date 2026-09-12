# ADR-002: RGB transport

- Status: Accepted
- Date: 2026-09-12
- Decision owners: project maintainers

## Context

The MVP needs per-key RGB on a target ASUS ROG keyboard, safe ownership release, reconnect handling, low update latency, and a distributable transport. Domain and lighting code must remain vendor-neutral. The transport decision must not rely on guessed HID packets or unlicensed binaries.

## Decision

Select Windows `Windows.Devices.Lights.LampArray` as the ASUS RGB transport. It is standards-based, requires no redistributed ASUS binary, exposes per-key virtual-key lookup, and has now passed foreground and game-focused ambient smoke and ten-minute soak tests on the reference device. Translate normalized keys through Windows `VirtualKey` and `GetIndicesForKey` only inside the adapter.

The required smoke, soak, normal/forced exit, and disconnect/reconnect lifecycle checks passed. The keyboard firmware and relevant ASUS software stack are recorded, so issue #5 may close and production backend issue 09 may proceed against this decision.

Foreground control is insufficient because TSW2 must retain focus. The packaged ambient controller initially appeared unavailable, but a longer observation proved that Windows transferred control after 65.643 seconds. Ten spatially distinct keys then displayed their expected colors while TSW2 retained focus, with zero submission errors. Delayed arbitration is therefore a required lifecycle state rather than an unsupported-provider result. The diagnostic probe waits a bounded interval; a production adapter must remain event-driven and recover when `IsAvailable` changes instead of failing startup after a short timeout.

## Consequences

- No ASUS SDK binary or COM interop assembly is distributed.
- Windows owns device arbitration and restoration; ownership transfer may take over a minute on the tested Windows/ASUS combination.
- Supported hardware is limited to devices that expose HID LampArray and map required virtual keys.
- Dynamic Lighting must be enabled and user/app priority may affect availability.
- The LampArray backend must use `DeviceWatcher` plus `LampArray.AvailabilityChanged`, expose a non-fatal waiting-for-control state, and resume after availability changes.
- The adapter must submit complete key colors without persisting a hard-coded lamp-index table.

## Rejected alternatives

### ASUS Aura SDK 3.07.05

Rejected on the reference machine because enumeration hung or crashed in isolated workers, restoration was not proven, and redistribution terms were not established. The probe released control separately after the failed experiment; no SDK binary is committed.

### ASUS Aura Ready Game SDK REST API

Rejected on the reference machine. The documented loopback service accepted SDK initialization and release with result `0`, but `GET /AuraSDK/AuraDevice` returned HTTP 500 in both standalone-device-lighting and Aura Sync + Windows Dynamic Lighting modes. The service therefore exposed no keyboard inventory to address. This API would avoid foreground arbitration if it worked, but a successful lease alone is not device proof. The isolated probe sends no frame unless discovery returns an external `Keyboard` device, and always attempts documented release after acquisition.

### Direct HID / OpenRGB-derived transport

Rejected because the exact target PID was not found in inspected OpenRGB support and no authoritative protocol evidence was available. Reverse-engineering or copying packets before that evidence exists would create device-safety, vendor-service conflict, maintenance, and licensing risk.

## Links

- [Research record](../research/rgb-backend.md)
- [Architecture](../architecture.md)
- [Technical discovery protocol](../technical-discovery.md)
