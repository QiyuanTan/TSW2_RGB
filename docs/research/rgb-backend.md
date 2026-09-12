# ASUS RGB transport research

**Status:** LampArray selected; final ambient lifecycle validation pending

**Research dates:** 2026-09-11 through 2026-09-12

**Issue:** #5 (`04 — Select and prove ASUS RGB transport`)

## Recommendation

Select Windows `Windows.Devices.Lights.LampArray` for the production ASUS transport. It is an OS API over the open HID Lighting and Illumination standard, exposes per-lamp positions and virtual-key lookup, and requires no redistributed ASUS SDK binary. Foreground and packaged ambient smoke tests now prove per-key control on the reference keyboard while TSW2 retains focus.

The critical discovery is that WDL ownership transfer is asynchronous and unusually slow on the reference preview Windows build. The ambient probe initially observed `IsAvailable=false`, then acquired control after 65.643 seconds when allowed to wait. This selects the transport but does not finish issue #5: ambient soak, visible restoration, forced termination, and reconnect remain manual gates. No unrun result is inferred from foreground evidence.

## Reference environment

| Item | Observed value | Evidence method |
|---|---|---|
| Date | 2026-09-11 through 2026-09-12 | Local test sessions |
| OS | Windows 10 Home China label, display version 26H1, builds 28120.2912 and 28120.3002, x64 | Read-only Windows version registry query |
| Computer | ASUS ROG Strix G512LV | Read-only PnP inventory |
| Keyboard | ROG Strix Scope II 96 Wireless through ROG Omni Receiver | Installed ASUS package plus connected ASUS VID `0B05`, PID `1ACE` |
| Connection | 2.4 GHz receiver | Installed ASUS device package; receiver present in PnP |
| Keyboard firmware | Unknown | Must be copied from Armoury Crate during manual run |
| Armoury Crate | Installed; exact UI version not recorded | Installed-package inventory |
| Lighting service | `LightingService` running | Windows service query |
| ASUS Aura SDK | 3.07.05, x64/x86, ASUS-signed | Installed-package and Authenticode inspection |
| Dynamic Lighting | Enabled for manual tests; foreground override disabled; ambient probe stored in priority slot 1 | Sanitized `HKCU\Software\Microsoft\Lighting` read-only query and Settings observation |
| LampArray provider | Windows and ASUS providers registered for PID `1ACE` | Sanitized read-only registry query |

Device instance IDs, serial-like values, user paths, and diagnostic archives are intentionally omitted.

## Reproducible observations

### Windows Dynamic Lighting / LampArray

1. Loaded the documented WinRT `LampArray` type with Windows PowerShell 5.1.
2. Obtained the HID LampArray device selector (usage page 89, usage ID 1).
3. `DeviceInformation.FindAllAsync(selector)` returned the structured `provider_unavailable` diagnostic for HRESULT `0x80070002` in the non-interactive test environment.
4. A read-only registry check found historical/current provider registrations for the target PID, but Dynamic Lighting was disabled.

Conclusion: the initial non-interactive attempt established provider presence but could not prove control. The later interactive validation below proved operation after Dynamic Lighting was enabled; the probe never changes that setting automatically.

### Interactive LampArray validation

After Dynamic Lighting was enabled for the interactive user, the revised probe opened its own foreground control window and successfully acquired the ROG Omni Receiver LampArray. The receiver reported 101 lamps, virtual-key support, and a 33 ms minimum update interval.

The foreground ten-key smoke test displayed the ten expected distinct colors on the spatially separated keys. The foreground 600-second soak completed with the following sanitized result:

```text
mode=Soak; seconds=600.11; frames=9757; errors=0; p95_ms=2.602; private_bytes_delta=1925120
```

No visible stutter was observed. Normal completion emitted `cleared` and `released`; the test keys went black and normal Windows/Armoury lighting resumed. The 1,925,120-byte private-memory increase (approximately 1.84 MiB) is not a material leak signal for this bounded run. These results prove the device path but do not satisfy the product lifecycle because TSW2 could not retain focus.

The first smoke attempt exposed an important arbitration constraint: an unpackaged console child hosted by Windows Terminal does not itself own a foreground window, so accepted writes were not applied. Smoke and soak modes now create and maintain a focused window, verify `IsAvailable`, and report loss of control. Settings priority applies to registered ambient/background controllers and is not a substitute for foreground ownership.

### Background/game-focus diagnostic

`tools/rgb-ambient-probe` is a minimal x64 .NET Framework console program compiled with the Windows-provided compiler and WinRT metadata. It has no third-party runtime or SDK dependency. A sparse manifest gives only this executable package identity and declares Microsoft's `com.microsoft.windows.lighting` app extension; generated executables and placeholder package assets stay under the ignored `bin` directory.

Build and validate without registering or touching hardware:

```powershell
powershell.exe -NoProfile -File .\tests\rgb-ambient-probe\Run-Tests.ps1
```

Registration changes package state for the current user and must be explicitly invoked from a normal, non-administrator PowerShell session:

```powershell
powershell.exe -NoProfile -File .\tools\rgb-ambient-probe\Register-AmbientProbe.ps1
```

After registration, open **Settings > Personalization > Dynamic Lighting** and move **TSW2 RGB Ambient Probe** to the top of **Background light control**. Then run the executable and switch focus to TSW2 during the ten-second start delay:

```powershell
.\tools\rgb-ambient-probe\bin\AmbientRgbProbe.exe --mode smoke --duration-seconds 15 --start-delay-seconds 10 --accept-lighting-control
.\tools\rgb-ambient-probe\bin\AmbientRgbProbe.exe --mode soak --duration-seconds 600 --frames-per-second 20 --start-delay-seconds 10 --accept-lighting-control
```

Windows may apply a Background light control priority change asynchronously. Smoke and soak therefore wait up to 120 seconds for `IsAvailable` by default, emit a pending diagnostic every ten seconds, and report the measured handoff time. Use `--availability-timeout-seconds 1..600` to change this bounded wait; Ctrl+C cancels it without submitting a frame. The start delay begins only after control is actually granted.

The ambient probe refuses to run without its exact package identity and fails if background availability is absent or lost. Remove the development registration after testing with:

```powershell
powershell.exe -NoProfile -File .\tools\rgb-ambient-probe\Unregister-AmbientProbe.ps1
```

When Windows denies ambient availability, capture a sanitized diagnostic bundle containing package/extension state, Dynamic Lighting registry value metadata, relevant services/processes, device summaries, a timed `IsAvailable` observation, and matching Application/System events:

```powershell
powershell.exe -NoProfile -File .\tools\rgb-ambient-probe\Get-AmbientDiagnostics.ps1 -ObservationSeconds 30
```

The generated NDJSON file is written under the ignored `tools/rgb-ambient-probe/diagnostics` directory. User-profile paths, device instance identifiers, and user SIDs are redacted; the collector is read-only except for writing that local report.

The 2026-09-12 capture on build `28120.3002` established all of the following simultaneously:

- Package `QiyuanTan.TSW2RGB.AmbientProbe` was registered with status `Ok` and exactly one lighting app extension.
- The running executable had the matching package family identity.
- `AmbientLightingEnabled=1`, `ControlledByForegroundApp=0`, and the probe package family occupied priority slot 1 across all 20 recorded lighting entries.
- ASUS `LightingService` and `AsHidCtrlService` were running; the ASUS `AacAmbientLighting` controller was also present.
- LampArray VID `0B05`, PID `1ACE` was connected, enabled, at brightness 1.0, typed as a keyboard, and exposed 101 lamps with a 33 ms minimum update interval.
- `IsAvailable` stayed false from the initial observation through the end of the 30.09-second sample, with no availability transition and no relevant Application or System event emitted.

The original ambient smoke test waited five seconds, submitted no frame, and emitted `clear_skipped`. Armoury Crate independently failed to obtain background control immediately when placed first with foreground override disabled, but later gained it after a delay. The revised probe then measured the same behavior directly: `IsAvailable` became true after 65.643 seconds. While TSW2 retained focus, the ten spatially distinct smoke keys displayed their expected colors for 15 seconds. The run submitted 264 frames with zero errors, p95 submission latency of 0.087 ms, and a private-byte delta of 864,256 bytes; it emitted `cleared` and `released` afterward.

This result confirms delayed arbitration, not its undocumented internal cause. Short unavailability is not a terminal transport failure. A production adapter must discover devices continuously, retain a waiting state while unavailable, react to `AvailabilityChanged`, and begin or resume rendering only after ownership is granted. The diagnostic probe keeps a timeout so manual tests terminate predictably; the production coordinator should instead wait until cancellation, device removal, or application shutdown.

### ASUS Aura SDK 3.07.05

1. Confirmed ASUS-signed `AuraSdk_x64.dll` and `AuraSdk_x86.dll` are installed under the ASUS product directory.
2. Confirmed the `aura.sdk` COM class exposes device enumeration, mode switching, release control, per-key lookup, and apply operations.
3. A read-only `Enumerate(0)` call failed to return within 30 seconds.
4. After `SwitchMode`, keyboard enumeration terminated the worker before a device collection was returned; a separate process successfully called `ReleaseControl(Keyboard)`.
5. The development enumeration entry point raised an `AccessViolationException` in its isolated Windows PowerShell process.

Conclusion: this installed SDK build is not stable enough on the reference environment. Its redistributable license terms were not available in the installed product, so neither SDK binaries nor generated interop assemblies may be committed. Aura SDK is rejected for the MVP unless ASUS supplies current written licensing and the crash is independently resolved.

### ASUS Aura Ready Game SDK REST API

The separately documented local Game SDK service was tested as a bounded alternative that would not depend on Windows foreground/background arbitration. Its endpoint was reachable at the documented loopback address. A pre-initialization GET returned result `5` (`RESULT_NOT_INIT`), and the required SDK initialization POST then returned result `0`.

After successful initialization, `GET /AuraSDK/AuraDevice` returned HTTP 500 rather than a device inventory. The result was identical with Dynamic Lighting off and Armoury Crate in standalone device-lighting mode, and with the keyboard set to **Aura Sync & Windows Dynamic Lighting**. In both attempts the documented DELETE returned result `0`; no color frame was submitted. This shows that the installed REST broker runs, but does not expose the reference keyboard as an addressable Game SDK device. It is rejected for this environment rather than inferred to work from successful initialization.

The manual-only probe preserves this exact boundary:

```powershell
powershell.exe -NoProfile -File .\tests\rgb-aura-rest-probe\Run-Tests.ps1
powershell.exe -NoProfile -File .\tools\rgb-aura-rest-probe\Invoke-AuraRestProbe.ps1 -Mode Discover -AcceptLightingControl
```

`Discover`, `Smoke`, and `Soak` all require explicit lighting-control consent because even inventory requires an SDK lease. The probe binds only to `127.0.0.1`, refuses to write unless discovery includes the documented external `Keyboard` device, emits structured diagnostics, and attempts release in `finally`. Its ten keys use ASUS's published key codes at the transport boundary; normalized core keys remain vendor-neutral.

### Direct HID / compatible libraries

OpenRGB was inspected as the most credible compatible implementation. Its current source has ASUS Aura USB controllers, but no exact PID `1ACE` or Scope II 96 Wireless match was found. Adding a guessed packet protocol would violate the discovery evidence rules and risks conflict with Armoury Crate. Direct HID is rejected for the MVP.

## Comparison

| Criterion | Windows LampArray | ASUS Aura SDK 3.07.05 | ASUS Game SDK REST | Direct HID/OpenRGB |
|---|---|---|---|---|
| Supported API | Microsoft-documented OS API | Vendor API, legacy COM | Vendor-documented localhost API | Community/reverse engineered |
| Per-key model | Virtual-key-to-lamp indices | Per-key COM interfaces | Published ASUS key codes or coordinates | Device-specific |
| Distribution | No vendor binary bundled | License not established | No client binary required; product terms still require review | GPL-2.0 OpenRGB; integration choice matters |
| Required service | Windows Dynamic Lighting/device provider | ASUS Lighting Service | ASUS local Aura REST service | Usually direct device access |
| x64 | Yes | Installed x64 binary | Process-independent HTTP | Yes, implementation dependent |
| Packaging/signing | Foreground probe is unpackaged; background control requires package identity/app extension and normal application-signing review | Vendor DLL is signed; redistribution rights remain unknown | No client SDK binary; service availability is an installer prerequisite | Shipping or deriving code requires GPL and driver/signing review |
| Arbitration | Windows foreground/background priority | Exclusive `SwitchMode`/`ReleaseControl` | Explicit POST acquire and DELETE release | Likely conflicts with vendor software |
| Cleanup/restore | Release reference; Windows selects next controller/autonomous mode | Explicit release, behavior unproven | Release passed; no device/frame was exposed | Device-specific and unproven |
| Reference result | Foreground passed; ambient smoke passed after delayed handoff; ambient soak/lifecycle pending | Hang/native crash; restoration unproven | Initialization passed; inventory failed with HTTP 500 in both ASUS lighting modes | Exact device support not found |
| Decision | **Selected; final lifecycle proof pending** | Rejected | Rejected | Rejected |

## Supported-device matrix

This matrix records evidence, not marketing compatibility. A device is supported only after the complete hardware checklist passes on the listed connection and firmware.

| Device | Connection | Provider/API evidence | Per-key proof | Cleanup/reconnect proof | Status |
|---|---|---|---|---|---|
| ROG Strix Scope II 96 Wireless (PID `1ACE`) | ROG Omni Receiver, 2.4 GHz | LampArray foreground and packaged ambient control passed after a 65.643-second handoff; Aura REST inventory returned HTTP 500 | Foreground ten-key/600-second tests and game-focused ambient ten-key smoke passed | Foreground clear/release passed; final ambient restoration, forced-exit, and reconnect checks pending | **Transport selected; final lifecycle validation pending** |
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

The explicit switch prevents accidental lighting control. Smoke and soak modes open a small topmost window because Windows applies foreground `LampArray` writes only while the calling application has focus; keep that window focused for the run. The probe checks `IsConnected`, `IsAvailable`, virtual-key support, and the device minimum update interval instead of treating accepted-but-inactive writes as success. Output is newline-delimited JSON with stable diagnostic codes and no raw device IDs. The probe clears lamps in `finally` and releases its LampArray reference. A hard process termination cannot run `finally`; Windows should reassign control according to its priority policy, which remains a required manual observation.

## Hardware acceptance checklist

All unchecked items block acceptance and ADR promotion:

- [ ] Record Armoury Crate and keyboard firmware versions.
- [x] Enable Dynamic Lighting manually and confirm `Discover` reports the ROG Omni Receiver serving the Scope II 96.
- [x] Run the foreground `Smoke`; visually confirm all ten named, spatially distinct keys show their distinct expected colors.
- [x] Run the foreground 600-second soak; record zero errors, acceptable p95 submission time, no obvious stutter, and no material private-byte growth.
- [x] Register and prioritize the ambient probe with foreground override disabled; record the delayed 65.643-second ownership transfer.
- [x] Run ambient smoke while TSW2 retains focus; confirm ten spatially distinct keys display their expected colors.
- [ ] Run the ambient 600-second soak while TSW2 retains focus.
- [ ] Confirm ambient `cleared` makes the test keys black before release.
- [ ] Confirm ambient normal exit returns control to the expected Windows/Armoury lighting.
- [ ] Terminate the probe process during a run and record restoration behavior.
- [ ] Disconnect and reconnect the keyboard/receiver, rerun `Discover`, and repeat a short smoke test.
- [x] Confirm an unavailable provider returns the structured `provider_unavailable` diagnostic plus exit code 10 without changing lighting.

## Sources

- [Microsoft: Dynamic lighting for Windows apps](https://learn.microsoft.com/en-us/windows/apps/develop/devices-sensors/lighting-dynamic-lamparray)
- [Microsoft: `LampArray` API](https://learn.microsoft.com/en-us/uwp/api/windows.devices.lights.lamparray)
- [Microsoft: control Dynamic Lighting devices](https://support.microsoft.com/en-us/windows/hardware/input-devices/control-dynamic-lighting-devices-in-windows)
- [USB-IF HID Lighting and Illumination usage page](https://usb.org/sites/default/files/hutrr84_-_lighting_and_illumination_page.pdf)
- [Microsoft LampArray sample](https://github.com/microsoft/Windows-universal-samples/tree/main/Samples/LampArray)
- [OpenRGB source](https://github.com/CalcProgrammer1/OpenRGB)
- [ASUS Aura Ready Game SDK REST API](https://www.asus.com/microsite/aurareadygamesdk/game_sdk_restful.html)
- [ASUS Aura Ready Game SDK result codes](https://www.asus.com/microsite/aurareadygamesdk/appendix_c.html)
- [ASUS Aura Ready Game SDK key codes](https://www.asus.com/microsite/aurareadygamesdk/appendix_a.html)
