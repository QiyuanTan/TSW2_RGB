# ASUS RGB transport research

**Status:** hardware proof blocked; do not use this document to claim support

**Research date:** 2026-09-11

**Issue:** #5 (`04 — Select and prove ASUS RGB transport`)

## Recommendation

Use the Windows `Windows.Devices.Lights.LampArray` API as the preferred transport, conditional on completing the hardware checklist below. It is an OS API over the open USB HID Lighting and Illumination/LampArray standard, supports Win32 applications, exposes per-lamp positions and virtual-key lookup, and does not require committing or redistributing an ASUS SDK binary.

The decision remains **proposed**, not accepted. The reference keyboard exposes a Windows LampArray provider in the local Dynamic Lighting registry, but the current non-interactive environment could not open the provider. No visual assertion, ten-minute soak, or reconnect assertion was fabricated.

## Reference environment

| Item | Observed value | Evidence method |
|---|---|---|
| Date | 2026-09-11 | Local test session |
| OS | Windows 10 Home China, display version 26H1, build 28120.2912, x64 | Read-only Windows version registry query |
| Computer | ASUS ROG Strix G512LV | Read-only PnP inventory |
| Keyboard | ROG Strix Scope II 96 Wireless through ROG Omni Receiver | Installed ASUS package plus connected ASUS VID `0B05`, PID `1ACE` |
| Connection | 2.4 GHz receiver | Installed ASUS device package; receiver present in PnP |
| Keyboard firmware | Unknown | Must be copied from Armoury Crate during manual run |
| Armoury Crate | Installed; exact UI version not recorded | Installed-package inventory |
| Lighting service | `LightingService` running | Windows service query |
| ASUS Aura SDK | 3.07.05, x64/x86, ASUS-signed | Installed-package and Authenticode inspection |
| Dynamic Lighting | Globally disabled during automation | `HKCU\Software\Microsoft\Lighting` read-only query |
| LampArray provider | Windows and ASUS providers registered for PID `1ACE` | Sanitized read-only registry query |

Device instance IDs, serial-like values, user paths, and diagnostic archives are intentionally omitted.

## Reproducible observations

### Windows Dynamic Lighting / LampArray

1. Loaded the documented WinRT `LampArray` type with Windows PowerShell 5.1.
2. Obtained the HID LampArray device selector (usage page 89, usage ID 1).
3. `DeviceInformation.FindAllAsync(selector)` returned the structured `provider_unavailable` diagnostic for HRESULT `0x80070002` in the non-interactive test environment.
4. A read-only registry check found historical/current provider registrations for the target PID, but Dynamic Lighting was disabled.

Conclusion: the standards-based path is credible and present, but not proven operational. Run the probe interactively after enabling Dynamic Lighting; do not change the setting automatically.

### ASUS Aura SDK 3.07.05

1. Confirmed ASUS-signed `AuraSdk_x64.dll` and `AuraSdk_x86.dll` are installed under the ASUS product directory.
2. Confirmed the `aura.sdk` COM class exposes device enumeration, mode switching, release control, per-key lookup, and apply operations.
3. A read-only `Enumerate(0)` call failed to return within 30 seconds.
4. After `SwitchMode`, keyboard enumeration terminated the worker before a device collection was returned; a separate process successfully called `ReleaseControl(Keyboard)`.
5. The development enumeration entry point raised an `AccessViolationException` in its isolated Windows PowerShell process.

Conclusion: this installed SDK build is not stable enough on the reference environment. Its redistributable license terms were not available in the installed product, so neither SDK binaries nor generated interop assemblies may be committed. Aura SDK is rejected for the MVP unless ASUS supplies current written licensing and the crash is independently resolved.

### Direct HID / compatible libraries

OpenRGB was inspected as the most credible compatible implementation. Its current source has ASUS Aura USB controllers, but no exact PID `1ACE` or Scope II 96 Wireless match was found. Adding a guessed packet protocol would violate the discovery evidence rules and risks conflict with Armoury Crate. Direct HID is rejected for the MVP.

## Comparison

| Criterion | Windows LampArray | ASUS Aura SDK 3.07.05 | Direct HID/OpenRGB |
|---|---|---|---|
| Supported API | Microsoft-documented OS API | Vendor API, legacy COM | Community/reverse engineered |
| Per-key model | Virtual-key-to-lamp indices | Per-key COM interfaces | Device-specific |
| Distribution | No vendor binary bundled | License not established | GPL-2.0 OpenRGB; integration choice matters |
| Required service | Windows Dynamic Lighting/device provider | ASUS Lighting Service | Usually direct device access |
| x64 | Yes | Installed x64 binary | Yes, implementation dependent |
| Packaging/signing | Foreground probe is unpackaged; background control requires package identity/app extension and normal application-signing review | Vendor DLL is signed; redistribution rights remain unknown | Shipping or deriving code requires GPL and driver/signing review |
| Arbitration | Windows foreground/background priority | Exclusive `SwitchMode`/`ReleaseControl` | Likely conflicts with vendor software |
| Cleanup/restore | Release reference; Windows selects next controller/autonomous mode | Explicit release, behavior unproven | Device-specific and unproven |
| Reference result | Provider present; API open blocked | Hang/native crash | Exact device support not found |
| Decision | **Proposed, proof pending** | Rejected | Rejected |

## Supported-device matrix

This matrix records evidence, not marketing compatibility. A device is supported only after the complete hardware checklist passes on the listed connection and firmware.

| Device | Connection | Provider/API evidence | Per-key proof | Cleanup/reconnect proof | Status |
|---|---|---|---|---|---|
| ROG Strix Scope II 96 Wireless (PID `1ACE`) | ROG Omni Receiver, 2.4 GHz | LampArray providers registered; API discovery blocked in the non-interactive session | Not run | Not run | **Candidate only — unsupported pending manual proof** |
| Any other ASUS keyboard | Any | Not evaluated | Not run | Not run | **Unsupported / unknown** |

Firmware is deliberately `unknown` until it is copied from Armoury Crate during the manual run. No compatibility should be inferred for USB or Bluetooth from the receiver observation.

## Key translation

Core code must store normalized physical keys, never SDK LED numbers. The LampArray boundary translates normalized keys to Windows `VirtualKey` values, then calls `GetIndicesForKey`; one key may map to multiple lamp indices.

| Normalized key | Windows `VirtualKey` | Probe role |
|---|---|---|
| `keyboard.escape` | `Escape` | upper-left |
| `keyboard.a` | `A` | left alpha |
| `keyboard.d` | `D` | left-center alpha |
| `keyboard.g` | `G` | center alpha |
| `keyboard.j` | `J` | right-center alpha |
| `keyboard.l` | `L` | right alpha |
| `keyboard.space` | `Space` | lower-center |
| `keyboard.arrow-left` | `Left` | navigation left |
| `keyboard.arrow-down` | `Down` | navigation down |
| `keyboard.arrow-right` | `Right` | navigation right |

An empty result is `key_unsupported`; the adapter must not fall back to a hard-coded LED index. Full production mapping belongs in issue #10 (backlog item 09) after normalized key contracts exist.

## Isolated probe

The probe is manual-only and has no startup or test-suite hook. Run from a normal interactive desktop, not an elevated console:

```powershell
powershell.exe -NoProfile -File .\tools\rgb-probe\Invoke-RgbProbe.ps1 -Mode Discover
powershell.exe -NoProfile -File .\tools\rgb-probe\Invoke-RgbProbe.ps1 -Mode Smoke -DurationSeconds 15 -AcceptLightingControl
powershell.exe -NoProfile -File .\tools\rgb-probe\Invoke-RgbProbe.ps1 -Mode Soak -DurationSeconds 600 -FramesPerSecond 20 -AcceptLightingControl
```

The explicit switch prevents accidental lighting control. Output is newline-delimited JSON with stable diagnostic codes and no raw device IDs. The probe clears lamps in `finally` and releases its LampArray reference. A hard process termination cannot run `finally`; Windows should reassign control according to its priority policy, which remains a required manual observation.

## Hardware acceptance checklist

All unchecked items block acceptance and ADR promotion:

- [ ] Record Armoury Crate and keyboard firmware versions.
- [ ] Enable Dynamic Lighting manually and confirm `Discover` reports the Scope II 96.
- [ ] Run `Smoke`; visually confirm all ten named, spatially distinct keys show their distinct expected colors.
- [ ] Run the 600-second soak; attach the final `run_complete` line and confirm zero errors, acceptable p95 submission time, no obvious stutter, and no material private-byte growth.
- [ ] Confirm `cleared` makes the test keys black before release.
- [ ] Confirm normal exit returns control to the expected Windows/Armoury lighting.
- [ ] Terminate the probe process during a run and record restoration behavior.
- [ ] Disconnect and reconnect the keyboard/receiver, rerun `Discover`, and repeat a short smoke test.
- [ ] Disable the service/provider or use an unsupported device and confirm a clear diagnostic plus safe exit.

## Sources

- [Microsoft: Dynamic lighting for Windows apps](https://learn.microsoft.com/en-us/windows/apps/develop/devices-sensors/lighting-dynamic-lamparray)
- [Microsoft: `LampArray` API](https://learn.microsoft.com/en-us/uwp/api/windows.devices.lights.lamparray)
- [Microsoft: control Dynamic Lighting devices](https://support.microsoft.com/en-us/windows/hardware/input-devices/control-dynamic-lighting-devices-in-windows)
- [USB-IF HID Lighting and Illumination usage page](https://usb.org/sites/default/files/hutrr84_-_lighting_and_illumination_page.pdf)
- [Microsoft LampArray sample](https://github.com/microsoft/Windows-universal-samples/tree/main/Samples/LampArray)
- [OpenRGB source](https://github.com/CalcProgrammer1/OpenRGB)
