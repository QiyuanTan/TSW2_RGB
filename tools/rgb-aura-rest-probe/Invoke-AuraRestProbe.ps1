[CmdletBinding()]
param(
    [ValidateSet('Discover', 'Smoke', 'Soak', 'SelfTest')]
    [string] $Mode = 'Discover',

    [ValidateRange(1, 3600)]
    [int] $DurationSeconds = 600,

    [ValidateRange(1, 60)]
    [int] $FramesPerSecond = 20,

    [switch] $AcceptLightingControl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:BaseUri = 'http://127.0.0.1:27339/AuraSDK'

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

function Get-ResultName {
    param([Parameter(Mandatory)] [int] $Result)

    $names = @{
        -1 = 'RESULT_INVALID'
        0 = 'RESULT_SUCCESS'
        1 = 'RESULT_NOT_READY'
        2 = 'RESULT_INSTANCE_FAIL'
        3 = 'RESULT_INVALID_PARAMETER'
        4 = 'RESULT_EXCEPTION'
        5 = 'RESULT_NOT_INIT'
        6 = 'RESULT_NO_DEVICE'
        7 = 'RESULT_NO_EVENT'
        8 = 'RESULT_NO_EVENTTYPE'
        9 = 'RESULT_NO_GIF'
        10 = 'RESULT_INVALID_TYPE'
        11 = 'RESULT_NO_CORRESPOND_KEY'
        12 = 'RESULT_REPEAT_EVENT'
        13 = 'RESULT_CATEGORY_REDEFINED'
        14 = 'RESULT_NOT_GAME_EVENT_CATEGORY'
        15 = 'RESULT_NOT_SDK_CATEGORY'
    }

    if ($names.ContainsKey($Result)) { return $names[$Result] }
    "RESULT_UNKNOWN_$Result"
}

function Assert-SuccessResult {
    param(
        [Parameter(Mandatory)] [object] $Response,
        [Parameter(Mandatory)] [string] $Operation
    )

    if ($null -eq $Response.result) {
        throw "$Operation returned no result code."
    }

    $result = [int]$Response.result
    if ($result -ne 0) {
        throw ("{0} returned {1} ({2})." -f $Operation, $result, (Get-ResultName $result))
    }
}

function Invoke-AuraRequest {
    param(
        [Parameter(Mandatory)] [ValidateSet('Get', 'Post', 'Put', 'Delete')] [string] $Method,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Path,
        [object] $Body
    )

    $parameters = @{
        Uri = "$script:BaseUri$Path"
        Method = $Method
        TimeoutSec = 10
    }
    if ($null -ne $Body) {
        $parameters.ContentType = 'application/json'
        $parameters.Body = $Body | ConvertTo-Json -Compress -Depth 8
    }

    try {
        Invoke-RestMethod @parameters
    }
    catch {
        $status = $null
        if ($null -ne $_.Exception.Response) {
            try { $status = [int]$_.Exception.Response.StatusCode } catch { }
        }
        if ($null -ne $status) {
            throw "Aura REST $Method $Path returned HTTP $status. The ASUS service is reachable but could not complete this operation."
        }
        throw "Aura REST $Method $Path failed: $($_.Exception.Message)"
    }
}

function Get-ProbeKeys {
    @(
        @{ Name = 'Escape'; KeyCode = '1'; Red = 255; Green = 0; Blue = 0 },
        @{ Name = 'A'; KeyCode = '30'; Red = 255; Green = 96; Blue = 0 },
        @{ Name = 'D'; KeyCode = '32'; Red = 255; Green = 255; Blue = 0 },
        @{ Name = 'G'; KeyCode = '34'; Red = 0; Green = 255; Blue = 0 },
        @{ Name = 'J'; KeyCode = '36'; Red = 0; Green = 255; Blue = 255 },
        @{ Name = 'L'; KeyCode = '38'; Red = 0; Green = 96; Blue = 255 },
        @{ Name = 'Space'; KeyCode = '57'; Red = 96; Green = 0; Blue = 255 },
        @{ Name = 'Left'; KeyCode = '203'; Red = 255; Green = 0; Blue = 255 },
        @{ Name = 'Down'; KeyCode = '208'; Red = 255; Green = 64; Blue = 128 },
        @{ Name = 'Right'; KeyCode = '205'; Red = 255; Green = 255; Blue = 255 }
    )
}

function ConvertTo-AuraBgr {
    param(
        [Parameter(Mandatory)] [ValidateRange(0, 255)] [int] $Red,
        [Parameter(Mandatory)] [ValidateRange(0, 255)] [int] $Green,
        [Parameter(Mandatory)] [ValidateRange(0, 255)] [int] $Blue
    )

    [string]($Red -bor ($Green -shl 8) -bor ($Blue -shl 16))
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

function New-KeyFrame {
    param(
        [Parameter(Mandatory)] [array] $Keys,
        [int] $Frame = -1
    )

    $data = [System.Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $Keys.Count; $index++) {
        $key = $Keys[$index]
        if ($Frame -ge 0) {
            $rgb = Convert-HsvToRgb ((($Frame + ($index * 7)) % 120) / 120.0)
            $red = $rgb[0]
            $green = $rgb[1]
            $blue = $rgb[2]
        }
        else {
            $red = $key.Red
            $green = $key.Green
            $blue = $key.Blue
        }

        $data.Add([ordered]@{
            device = 'Keyboard'
            range = 'custom'
            keycode = @([string]$key.KeyCode)
            color = ConvertTo-AuraBgr $red $green $blue
            apply = 'false'
        })
    }
    $data.Add([ordered]@{ device = 'Keyboard'; apply = 'true' })
    [ordered]@{ data = @($data) }
}

function Invoke-SelfTest {
    $keys = @(Get-ProbeKeys)
    if ($keys.Count -ne 10) { throw 'The smoke palette must contain exactly ten keys.' }
    if (@($keys.Name | Sort-Object -Unique).Count -ne 10) { throw 'The smoke keys must be unique.' }
    if (@($keys.KeyCode | Sort-Object -Unique).Count -ne 10) { throw 'The Aura key codes must be unique.' }
    if ((ConvertTo-AuraBgr 255 0 0) -ne '255') { throw 'Red BGR conversion failed.' }
    if ((ConvertTo-AuraBgr 0 255 0) -ne '65280') { throw 'Green BGR conversion failed.' }
    if ((ConvertTo-AuraBgr 0 0 255) -ne '16711680') { throw 'Blue BGR conversion failed.' }

    $frame = New-KeyFrame $keys
    if ($frame.data.Count -ne 11 -or $frame.data[-1].apply -ne 'true') {
        throw 'The key frame must buffer ten colors and finish with one apply command.'
    }
    Write-Diagnostic 'self_test_passed' 'Pure Aura REST probe validation passed; no HTTP or device APIs were invoked.'
}

if ($Mode -eq 'SelfTest') {
    Invoke-SelfTest
    exit 0
}

if (-not $AcceptLightingControl) {
    Write-Diagnostic 'consent_required' 'All Aura REST modes acquire lighting control. Re-run with -AcceptLightingControl.' 'error'
    exit 2
}

$acquired = $false
$probeExitCode = 0
$keys = @(Get-ProbeKeys)
try {
    $initialization = Invoke-AuraRequest -Method Post -Path '' -Body @{ category = 'SDK' }
    Assert-SuccessResult $initialization 'Initialization'
    $acquired = $true
    Write-Diagnostic 'control_acquired' 'The Aura REST service granted SDK lighting control.'

    $inventory = Invoke-AuraRequest -Method Get -Path '/AuraDevice'
    Assert-SuccessResult $inventory 'Device discovery'
    $deviceNames = @($inventory.PSObject.Properties.Name | Where-Object { $_ -ne 'result' })
    if ($deviceNames.Count -eq 0) {
        throw 'Aura REST discovery succeeded but returned no devices.'
    }
    foreach ($deviceName in $deviceNames) {
        $device = $inventory.$deviceName
        Write-Diagnostic 'device_found' ("name={0}; lamps={1}; width={2}; height={3}" -f $deviceName, $device.count, $device.width, $device.height)
    }
    if ('Keyboard' -notin $deviceNames) {
        throw "Aura REST did not expose the required external Keyboard device. Discovered: $($deviceNames -join ', ')."
    }
    if ($Mode -eq 'Discover') { return }

    $latencies = [System.Collections.Generic.List[double]]::new()
    $errors = 0
    $process = [System.Diagnostics.Process]::GetCurrentProcess()
    $initialPrivateBytes = $process.PrivateMemorySize64
    $started = [System.Diagnostics.Stopwatch]::StartNew()

    if ($Mode -eq 'Smoke') {
        $response = Invoke-AuraRequest -Method Put -Path '/AuraDevice' -Body (New-KeyFrame $keys)
        Assert-SuccessResult $response 'Smoke frame'
        while ($started.Elapsed.TotalSeconds -lt [math]::Min($DurationSeconds, 15)) {
            Start-Sleep -Milliseconds 50
        }
    }
    else {
        $frameIntervalMs = 1000.0 / $FramesPerSecond
        $frame = 0
        while ($started.Elapsed.TotalSeconds -lt $DurationSeconds) {
            $frameWatch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $response = Invoke-AuraRequest -Method Put -Path '/AuraDevice' -Body (New-KeyFrame $keys $frame)
                Assert-SuccessResult $response "Frame $frame"
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
    if ($errors -ne 0) { throw "The animation completed with $errors failed frame(s)." }
}
catch {
    $diagnosticCode = if ($_.Exception.Message -match 'Get /AuraDevice returned HTTP') {
        'device_discovery_failed'
    }
    elseif ($_.Exception.Message -match 'failed:.*(connect|refused|timed out)') {
        'service_unavailable'
    }
    elseif ($_.Exception.Message -match 'no devices|did not expose the required') {
        'device_unsupported'
    }
    else {
        'aura_rest_failed'
    }
    Write-Diagnostic $diagnosticCode $_.Exception.Message 'error'
    $probeExitCode = 10
}
finally {
    if ($acquired) {
        try {
            $release = Invoke-AuraRequest -Method Delete -Path ''
            Assert-SuccessResult $release 'Release'
            Write-Diagnostic 'released' 'Aura REST control was released; ASUS should restore the configured effect.'
        }
        catch {
            Write-Diagnostic 'release_failed' $_.Exception.Message 'error'
            if ($probeExitCode -eq 0) { $probeExitCode = 11 }
        }
    }
}

if ($probeExitCode -ne 0) { exit $probeExitCode }
