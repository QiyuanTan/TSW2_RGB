[CmdletBinding()]
param(
    [ValidateSet('Discover', 'Smoke', 'Soak', 'SelfTest')]
    [string] $Mode = 'Discover',

    [ValidateRange(0, 64)]
    [int] $DeviceIndex = 0,

    [ValidateRange(1, 3600)]
    [int] $DurationSeconds = 600,

    [ValidateRange(1, 60)]
    [int] $FramesPerSecond = 20,

    [switch] $AcceptLightingControl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Diagnostic {
    param(
        [Parameter(Mandatory)] [string] $Code,
        [Parameter(Mandatory)] [string] $Message,
        [ValidateSet('info', 'error')] [string] $Level = 'info'
    )

    [pscustomobject]@{ level = $Level; code = $Code; message = $Message } |
        ConvertTo-Json -Compress |
        Write-Output
}

function Get-ProbeKeys {
    @(
        @{ Name = 'Escape'; Red = 255; Green = 0; Blue = 0 },
        @{ Name = 'A'; Red = 255; Green = 96; Blue = 0 },
        @{ Name = 'D'; Red = 255; Green = 255; Blue = 0 },
        @{ Name = 'G'; Red = 0; Green = 255; Blue = 0 },
        @{ Name = 'J'; Red = 0; Green = 255; Blue = 255 },
        @{ Name = 'L'; Red = 0; Green = 96; Blue = 255 },
        @{ Name = 'Space'; Red = 96; Green = 0; Blue = 255 },
        @{ Name = 'Left'; Red = 255; Green = 0; Blue = 255 },
        @{ Name = 'Down'; Red = 255; Green = 64; Blue = 128 },
        @{ Name = 'Right'; Red = 255; Green = 255; Blue = 255 }
    )
}

function Convert-HsvToRgb {
    param([ValidateRange(0.0, 1.0)] [double] $Hue)

    $scaled = $Hue * 6.0
    $sector = [math]::Floor($scaled)
    $fraction = $scaled - $sector
    $a = [byte][math]::Round(255 * (1 - $fraction))
    $b = [byte][math]::Round(255 * $fraction)

    switch ([int]$sector % 6) {
        0 { return [byte[]]@(255, $b, 0) }
        1 { return [byte[]]@($a, 255, 0) }
        2 { return [byte[]]@(0, 255, $b) }
        3 { return [byte[]]@(0, $a, 255) }
        4 { return [byte[]]@($b, 0, 255) }
        default { return [byte[]]@(255, 0, $a) }
    }
}

function ConvertTo-TaskResult {
    param(
        [Parameter(Mandatory)] [object] $Operation,
        [Parameter(Mandatory)] [type] $ResultType
    )

    $method = [System.WindowsRuntimeSystemExtensions].GetMethods() |
        Where-Object {
            $_.Name -eq 'AsTask' -and
            $_.IsGenericMethod -and
            $_.GetParameters().Count -eq 1 -and
            $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
        } |
        Select-Object -First 1

    if ($null -eq $method) {
        throw 'Windows Runtime task bridge is unavailable.'
    }

    $task = $method.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    $task.GetAwaiter().GetResult()
}

function Initialize-LampArrayTypes {
    if ($PSVersionTable.PSEdition -ne 'Desktop') {
        throw 'Run this probe with Windows PowerShell 5.1 (powershell.exe), not PowerShell Core.'
    }

    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    [Windows.Devices.Enumeration.DeviceInformation, Windows.Devices.Enumeration, ContentType = WindowsRuntime] > $null
    [Windows.Devices.Enumeration.DeviceInformationCollection, Windows.Devices.Enumeration, ContentType = WindowsRuntime] > $null
    [Windows.Devices.Lights.LampArray, Windows.Devices.Lights, ContentType = WindowsRuntime] > $null
    [Windows.System.VirtualKey, Windows.System, ContentType = WindowsRuntime] > $null
    # Color projection metadata is not directly resolvable by name on every
    # Windows build. Obtain the exact projected parameter type from LampArray.
    $script:ColorType = [Windows.Devices.Lights.LampArray].GetMethod('SetColor').GetParameters()[0].ParameterType
}

function Get-LampArrayDevices {
    $selector = [Windows.Devices.Lights.LampArray]::GetDeviceSelector()
    $operation = [Windows.Devices.Enumeration.DeviceInformation]::FindAllAsync($selector)
    ConvertTo-TaskResult $operation ([Windows.Devices.Enumeration.DeviceInformationCollection])
}

function Open-LampArray {
    param([Parameter(Mandatory)] [object] $DeviceInformation)

    $operation = [Windows.Devices.Lights.LampArray]::FromIdAsync($DeviceInformation.Id)
    ConvertTo-TaskResult $operation ([Windows.Devices.Lights.LampArray])
}

function Get-KeyIndices {
    param(
        [Parameter(Mandatory)] [object] $LampArray,
        [Parameter(Mandatory)] [string] $Name
    )

    $virtualKey = [System.Enum]::Parse([Windows.System.VirtualKey], $Name, $true)
    [int[]]$LampArray.GetIndicesForKey($virtualKey)
}

function Set-KeyColor {
    param(
        [Parameter(Mandatory)] [object] $LampArray,
        [Parameter(Mandatory)] [int[]] $Indices,
        [Parameter(Mandatory)] [byte] $Red,
        [Parameter(Mandatory)] [byte] $Green,
        [Parameter(Mandatory)] [byte] $Blue
    )

    $color = [System.Activator]::CreateInstance($script:ColorType)
    $color.A = [byte]255
    $color.R = $Red
    $color.G = $Green
    $color.B = $Blue
    $LampArray.SetSingleColorForIndices($color, $Indices)
}

function Invoke-SelfTest {
    $keys = @(Get-ProbeKeys)
    if ($keys.Count -ne 10) { throw 'The smoke palette must contain exactly ten keys.' }
    if (@($keys.Name | Sort-Object -Unique).Count -ne 10) { throw 'The smoke keys must be unique.' }

    foreach ($sample in @(0.0, 0.25, 0.5, 0.75, 0.999)) {
        $rgb = Convert-HsvToRgb $sample
        if ($rgb.Count -ne 3) { throw "HSV conversion failed for $sample." }
    }

    Write-Diagnostic 'self_test_passed' 'Pure probe validation passed; no device APIs were invoked.'
}

if ($Mode -eq 'SelfTest') {
    Invoke-SelfTest
    exit 0
}

if ($Mode -in @('Smoke', 'Soak') -and -not $AcceptLightingControl) {
    Write-Diagnostic 'consent_required' 'Smoke and soak modes change device lighting. Re-run with -AcceptLightingControl.' 'error'
    exit 2
}

$lampArray = $null
$probeExitCode = 0
$cleanupFailed = $false
try {
    Initialize-LampArrayTypes
    $devices = @(Get-LampArrayDevices)
    if ($devices.Count -eq 0) {
        Write-Diagnostic 'no_lamp_array' 'No HID LampArray device is available. Enable Windows Dynamic Lighting and reconnect a supported keyboard.' 'error'
        exit 3
    }

    for ($i = 0; $i -lt $devices.Count; $i++) {
        Write-Diagnostic 'device_found' ("index={0}; name={1}" -f $i, $devices[$i].Name)
    }

    if ($Mode -eq 'Discover') { exit 0 }
    if ($DeviceIndex -ge $devices.Count) {
        Write-Diagnostic 'invalid_device_index' ("Device index {0} is outside 0..{1}." -f $DeviceIndex, ($devices.Count - 1)) 'error'
        exit 4
    }

    $lampArray = Open-LampArray $devices[$DeviceIndex]
    if ($null -eq $lampArray) {
        Write-Diagnostic 'device_unavailable' 'Windows found the device, but it is not currently available to this process.' 'error'
        exit 5
    }

    $resolved = @()
    foreach ($key in Get-ProbeKeys) {
        $indices = @(Get-KeyIndices $lampArray $key.Name)
        if ($indices.Count -eq 0) {
            Write-Diagnostic 'key_unsupported' ("The device did not map normalized key '{0}'." -f $key.Name) 'error'
            exit 6
        }
        $resolved += [pscustomobject]@{ Key = $key; Indices = [int[]]$indices }
    }

    $latencies = [System.Collections.Generic.List[double]]::new()
    $errors = 0
    $process = [System.Diagnostics.Process]::GetCurrentProcess()
    $initialPrivateBytes = $process.PrivateMemorySize64
    $started = [System.Diagnostics.Stopwatch]::StartNew()

    if ($Mode -eq 'Smoke') {
        foreach ($item in $resolved) {
            Set-KeyColor $lampArray $item.Indices $item.Key.Red $item.Key.Green $item.Key.Blue
        }
        Start-Sleep -Seconds ([math]::Min($DurationSeconds, 15))
    }
    else {
        $frameIntervalMs = 1000.0 / $FramesPerSecond
        $frame = 0
        while ($started.Elapsed.TotalSeconds -lt $DurationSeconds) {
            $frameWatch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                for ($i = 0; $i -lt $resolved.Count; $i++) {
                    $rgb = Convert-HsvToRgb ((($frame + ($i * 7)) % 120) / 120.0)
                    Set-KeyColor $lampArray $resolved[$i].Indices $rgb[0] $rgb[1] $rgb[2]
                }
            }
            catch {
                $errors++
                Write-Diagnostic 'frame_failed' $_.Exception.Message 'error'
            }
            finally {
                $frameWatch.Stop()
                $latencies.Add($frameWatch.Elapsed.TotalMilliseconds)
            }

            $frame++
            $remaining = [math]::Floor($frameIntervalMs - $frameWatch.Elapsed.TotalMilliseconds)
            if ($remaining -gt 0) { Start-Sleep -Milliseconds $remaining }
        }
    }

    $process.Refresh()
    $sorted = @($latencies | Sort-Object)
    $p95 = if ($sorted.Count -eq 0) { 0 } else {
        $p95Index = [int]([math]::Max(0, [math]::Ceiling($sorted.Count * 0.95) - 1))
        $sorted[$p95Index]
    }
    Write-Diagnostic 'run_complete' ("mode={0}; seconds={1:N2}; frames={2}; errors={3}; p95_ms={4:N3}; private_bytes_delta={5}" -f $Mode, $started.Elapsed.TotalSeconds, $latencies.Count, $errors, $p95, ($process.PrivateMemorySize64 - $initialPrivateBytes))
    if ($errors -ne 0) {
        throw "The animation completed with $errors failed frame(s)."
    }
}
catch {
    $diagnosticCode = if ($_.Exception.ToString() -match '0x80070002') {
        'provider_unavailable'
    }
    elseif ($_.Exception.ToString() -match '0x80070005') {
        'access_denied'
    }
    else {
        'probe_failed'
    }
    Write-Diagnostic $diagnosticCode $_.Exception.Message 'error'
    $probeExitCode = 10
}
finally {
    if ($null -ne $lampArray) {
        try {
            $black = [System.Activator]::CreateInstance($script:ColorType)
            $black.A = [byte]255
            $lampArray.SetColor($black)
            Write-Diagnostic 'cleared' 'All lamps were set to black before control was released.'
        }
        catch {
            Write-Diagnostic 'clear_failed' $_.Exception.Message 'error'
            $cleanupFailed = $true
        }
        finally {
            $lampArray = $null
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
            Write-Diagnostic 'released' 'The LampArray reference was released; Windows may restore the next eligible lighting controller.'
        }
    }
}

if ($cleanupFailed -and $probeExitCode -eq 0) {
    $probeExitCode = 11
}

if ($probeExitCode -ne 0) {
    exit $probeExitCode
}
