[CmdletBinding()]
param(
    [Parameter()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$TraceRoot = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$traceFiles = @(Get-ChildItem -LiteralPath $TraceRoot -Filter '*.jsonl' -File)

if ($traceFiles.Count -eq 0) {
    throw 'No state trace fixtures were found.'
}

$allowedEvents = @('observation', 'source_attached', 'source_unavailable', 'session_changed', 'source_detached')
$allowedFields = @('session', 'reverser', 'doors.left', 'doors.right', 'headlights', 'wipers', 'locomotive_id')
$allowedQualities = @('authoritative', 'validated-derived', 'optimistic', 'stale', 'unavailable')
$sourceIdPattern = '^[a-z0-9][a-z0-9._-]*$'
$sensitivePattern = '(?i)([A-Z]:\\|/Users/|\\Users\\|steamid|account[_-]?id|access[_-]?token|password|secret)'
$requiredProperties = @('schema_version', 'sequence', 'observed_at_utc', 'source_id', 'event', 'field', 'value', 'quality', 'context')

foreach ($traceFile in $traceFiles) {
    $expectedSequence = 1
    $previousTimestamp = [DateTimeOffset]::MinValue
    $lineNumber = 0

    foreach ($line in Get-Content -LiteralPath $traceFile.FullName) {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        try { $record = $line | ConvertFrom-Json }
        catch { throw "$($traceFile.Name):$lineNumber is not valid JSON: $($_.Exception.Message)" }

        foreach ($property in $requiredProperties) {
            if ($record.PSObject.Properties.Name -notcontains $property) {
                throw "$($traceFile.Name):$lineNumber is missing '$property'."
            }
        }

        $unexpectedProperties = @($record.PSObject.Properties.Name | Where-Object { $requiredProperties -notcontains $_ })
        if ($unexpectedProperties.Count -gt 0) {
            throw "$($traceFile.Name):$lineNumber has unexpected properties: $($unexpectedProperties -join ', ')."
        }

        if ($record.schema_version -ne 1) { throw "$($traceFile.Name):$lineNumber has an unsupported schema_version." }
        if ($record.sequence -ne $expectedSequence) { throw "$($traceFile.Name):$lineNumber expected sequence $expectedSequence." }
        if ($allowedEvents -notcontains $record.event) { throw "$($traceFile.Name):$lineNumber has an unknown event." }
        if ($allowedFields -notcontains $record.field) { throw "$($traceFile.Name):$lineNumber has an unknown field." }
        if ($allowedQualities -notcontains $record.quality) { throw "$($traceFile.Name):$lineNumber has an unknown quality." }
        if ($record.source_id -notmatch $sourceIdPattern) { throw "$($traceFile.Name):$lineNumber has an invalid source_id." }
        if ($null -eq $record.context -or $record.context -isnot [PSCustomObject]) { throw "$($traceFile.Name):$lineNumber context must be an object." }
        if ($line -match $sensitivePattern) { throw "$($traceFile.Name):$lineNumber may contain sensitive or personal data." }

        $timestampMatch = [regex]::Match($line, '"observed_at_utc"\s*:\s*"(?<timestamp>[^"]+)"')
        $timestampText = $timestampMatch.Groups['timestamp'].Value
        $timestamp = [DateTimeOffset]::MinValue
        if (-not $timestampMatch.Success -or $timestampText -notmatch 'Z$' -or
            -not [DateTimeOffset]::TryParse($timestampText, [Globalization.CultureInfo]::InvariantCulture, ([Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal), [ref]$timestamp) -or
            $timestamp.Offset -ne [TimeSpan]::Zero) {
            throw "$($traceFile.Name):$lineNumber observed_at_utc must be an RFC 3339 UTC timestamp."
        }

        if ($timestamp -lt $previousTimestamp) { throw "$($traceFile.Name):$lineNumber timestamp moved backwards." }
        if ($record.quality -eq 'unavailable' -and $record.value -ne 'unavailable') { throw "$($traceFile.Name):$lineNumber unavailable quality requires unavailable value." }

        $previousTimestamp = $timestamp
        $expectedSequence++
    }

    if ($expectedSequence -eq 1) { throw "$($traceFile.Name) contains no records." }
    Write-Output "Validated $($expectedSequence - 1) record(s): $($traceFile.Name)"
}
