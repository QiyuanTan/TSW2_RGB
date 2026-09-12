[CmdletBinding()]
param(
    [ValidateRange(1, 60)]
    [int] $ObservationSeconds = 15,

    [string] $OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $diagnosticDirectory = Join-Path $PSScriptRoot 'diagnostics'
    New-Item -ItemType Directory -Force -Path $diagnosticDirectory > $null
    $OutputPath = Join-Path $diagnosticDirectory ("ambient-{0}.ndjson" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
}
else {
    $parent = Split-Path -Parent $OutputPath
    if (-not [string]::IsNullOrWhiteSpace($parent)) { New-Item -ItemType Directory -Force -Path $parent > $null }
}
$script:DiagnosticOutputPath = $OutputPath
$captureStartedAt = Get-Date

function Write-Diagnostic {
    param(
        [Parameter(Mandatory)] [string] $Code,
        [Parameter(Mandatory)] [string] $Message,
        [ValidateSet('info', 'error')] [string] $Level = 'info'
    )

    $line = [pscustomobject]@{ level = $Level; code = $Code; message = $Message } | ConvertTo-Json -Compress
    Add-Content -LiteralPath $script:DiagnosticOutputPath -Value $line -Encoding UTF8
    Write-Output $line
}

function Remove-PrivateEventData {
    param([string] $Message)

    if ([string]::IsNullOrWhiteSpace($Message)) { return '' }
    $sanitized = $Message
    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        $sanitized = $sanitized -replace [regex]::Escape($env:USERPROFILE), '<USERPROFILE>'
    }
    $sanitized = $sanitized -replace '(?i)(HID|USB)\\[^\s,;]+', '<DEVICE_ID>'
    $sanitized = $sanitized -replace '(?i)S-1-5-21-(\d+-){3}\d+', '<USER_SID>'
    if ($sanitized.Length -gt 1200) { $sanitized = $sanitized.Substring(0, 1200) + '...' }
    $sanitized
}

function Get-ShortHash {
    param([Parameter(Mandatory)] [object] $Value)

    $bytes = if ($Value -is [byte[]]) { $Value } else { [Text.Encoding]::UTF8.GetBytes([string]$Value) }
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace('-', '').Substring(0, 12).ToLowerInvariant() }
    finally { $sha256.Dispose() }
}

function Format-RegistryValue {
    param([Parameter(Mandatory)] [object] $Value)

    if ($Value -is [int] -or $Value -is [long] -or $Value -is [bool]) { return [string]$Value }
    if ($Value -is [byte[]]) { return "bytes=$($Value.Length); sha256_12=$(Get-ShortHash $Value)" }
    $text = [string]$Value
    if ($text -match 'TSW2RGB|AmbientProbe|Armoury|Dynamic.?Lighting') { return $text }
    "redacted; length=$($text.Length); sha256_12=$(Get-ShortHash $text)"
}

$os = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
Write-Diagnostic 'environment' ("product={0}; display_version={1}; build={2}.{3}; architecture={4}; user_interactive={5}" -f
    $os.ProductName, $os.DisplayVersion, $os.CurrentBuildNumber, $os.UBR, $env:PROCESSOR_ARCHITECTURE, [Environment]::UserInteractive)

$package = Get-AppxPackage -Name 'QiyuanTan.TSW2RGB.AmbientProbe'
if ($null -eq $package) {
    Write-Diagnostic 'package_missing' 'The ambient probe package is not registered for the current user.' 'error'
}
else {
    $manifest = $package | Get-AppxPackageManifest
    $extensions = @($manifest.Package.Applications.Application.Extensions.Extension)
    $lightingExtension = @($extensions | Where-Object { $_.AppExtension.Name -eq 'com.microsoft.windows.lighting' })
    Write-Diagnostic 'package_registration' ("name={0}; version={1}; status={2}; lighting_extension_count={3}" -f
        $package.Name, $package.Version, $package.Status, $lightingExtension.Count)
}

$lightingRoot = 'HKCU:\Software\Microsoft\Lighting'
$registryKeys = @(
    Get-Item -LiteralPath $lightingRoot -ErrorAction SilentlyContinue
    Get-ChildItem -Recurse -LiteralPath $lightingRoot -ErrorAction SilentlyContinue
)
Write-Diagnostic 'lighting_registry' ("key_count={0}; root_exists={1}" -f $registryKeys.Count, (Test-Path -LiteralPath $lightingRoot))
$registrySummary = @{}
$prioritySummary = @{}
foreach ($key in $registryKeys) {
    $properties = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction SilentlyContinue
    foreach ($property in @($properties.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' })) {
        $formattedValue = Format-RegistryValue $property.Value
        if ($formattedValue -match 'TSW2RGB|AmbientProbe|Armoury|Dynamic.?Lighting') {
            $priorityKey = "slot=$($property.Name); value=$formattedValue"
            $prioritySummary[$priorityKey] = 1 + [int]$prioritySummary[$priorityKey]
        }
        elseif ($property.Value -is [int] -or $property.Value -is [long] -or $property.Value -is [bool]) {
            $summaryKey = "name=$($property.Name); value=$formattedValue"
            $registrySummary[$summaryKey] = 1 + [int]$registrySummary[$summaryKey]
        }
    }
}
foreach ($entry in $registrySummary.GetEnumerator() | Sort-Object Name) {
    Write-Diagnostic 'lighting_setting_summary' ("{0}; occurrences={1}" -f $entry.Name, $entry.Value)
}
foreach ($entry in $prioritySummary.GetEnumerator() | Sort-Object Name) {
    Write-Diagnostic 'lighting_priority_summary' ("{0}; occurrences={1}" -f $entry.Name, $entry.Value)
}

foreach ($serviceName in @('LightingService', 'AsHidCtrlService')) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($null -ne $service) {
        Write-Diagnostic 'service_state' ("name={0}; status={1}; start_type={2}" -f $service.Name, $service.Status, $service.StartType)
    }
}

$controllerProcesses = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -match 'Armoury|Aura|Lighting'
} | Select-Object -ExpandProperty ProcessName -Unique | Sort-Object)
Write-Diagnostic 'controller_processes' ("names={0}" -f ($controllerProcesses -join ','))

$devices = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object {
    $_.FriendlyName -match 'ROG|ASUS'
} | Select-Object Status, Class, FriendlyName)
foreach ($device in $devices) {
    Write-Diagnostic 'asus_device' ("status={0}; class={1}; name={2}" -f $device.Status, $device.Class, $device.FriendlyName)
}

$probePath = Join-Path $PSScriptRoot 'bin\AmbientRgbProbe.exe'
if (-not (Test-Path -LiteralPath $probePath -PathType Leaf)) {
    Write-Diagnostic 'probe_binary_missing' 'Run Build-AmbientProbe.ps1 before diagnostics.' 'error'
    exit 2
}

& $probePath --mode diagnose --duration-seconds $ObservationSeconds | ForEach-Object {
    Add-Content -LiteralPath $script:DiagnosticOutputPath -Value $_ -Encoding UTF8
    Write-Output $_
}
$probeExitCode = $LASTEXITCODE

foreach ($logName in @('Application', 'System')) {
    $events = @(Get-WinEvent -FilterHashtable @{ LogName = $logName; StartTime = $captureStartedAt } -ErrorAction SilentlyContinue |
        Where-Object { $_.ProviderName -match 'Light|Lamp|Aura|ASUS|AppModel' -or $_.Message -match 'Light|Lamp|Aura|Armoury' } |
        Select-Object -First 100)
    foreach ($event in $events) {
        Write-Diagnostic 'windows_event' ("log={0}; provider={1}; id={2}; level={3}; time={4:o}; message={5}" -f
            $logName, $event.ProviderName, $event.Id, $event.LevelDisplayName, $event.TimeCreated,
            (Remove-PrivateEventData $event.Message))
    }
}

Write-Diagnostic 'capture_complete' ("probe_exit_code={0}; windows_event_count_capped_at=200" -f $probeExitCode)
Write-Output "Diagnostic log saved to: $OutputPath"
exit $probeExitCode
