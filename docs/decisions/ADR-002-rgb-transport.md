# ADR-002: RGB transport

- Status: Blocked — no production transport accepted
- Date: 2026-09-12
- Decision owners: project maintainers

## Context

The MVP needs per-key RGB on a target ASUS ROG keyboard, safe ownership release, reconnect handling, low update latency, and a distributable transport. Domain and lighting code must remain vendor-neutral. The transport decision must not rely on guessed HID packets or unlicensed binaries.

## Decision

Do not implement a production ASUS backend yet. Windows `Windows.Devices.Lights.LampArray` remains the preferred standards-based candidate, but it failed the required game-focus lifecycle on the reference environment: foreground control passed, while a correctly registered and prioritized ambient controller remained unavailable. Translate normalized keys through Windows `VirtualKey` and `GetIndicesForKey` only if a later environment passes the ambient gate.

Do not merge a production adapter or claim Scope II 96 support while this ADR is Blocked. Reconsider LampArray only after a Windows/ASUS update makes the packaged ambient controller available and the dated ten-key, ten-minute soak, clear, normal/forced exit, and reconnect evidence is recorded.

Foreground control is insufficient for the product because TSW2 must retain focus. The minimal ambient diagnostic had valid sparse package identity, one `com.microsoft.windows.lighting` extension, priority slot 1, Dynamic Lighting enabled, and foreground override disabled. Windows nevertheless reported the connected and enabled LampArray as unavailable for the complete observation. Armoury Crate also failed to obtain background control under the same settings. This is a platform/provider gate, not authorization to bypass Windows arbitration or guess a direct-HID protocol.

## Consequences

- No ASUS SDK binary or COM interop assembly is distributed.
- Windows owns device arbitration and restoration, but the tested Windows/ASUS combination did not grant an ambient lease.
- Supported hardware is limited to devices that expose HID LampArray and map required virtual keys.
- Dynamic Lighting must be enabled and user/app priority may affect availability.
- A future LampArray backend would use `DeviceWatcher` plus `LampArray.AvailabilityChanged`, but production work is blocked.
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
