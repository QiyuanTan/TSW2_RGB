[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$probePath = Join-Path $repositoryRoot 'tools\rgb-probe\Invoke-RgbProbe.ps1'
$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile($probePath, [ref]$tokens, [ref]$parseErrors) > $null
if ($parseErrors.Count -ne 0) {
    throw "Probe syntax check failed: $($parseErrors.Message -join '; ')"
}

$windowsPowerShell = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$selfTestOutput = & $windowsPowerShell -NoProfile -NonInteractive -File $probePath -Mode SelfTest
$selfTestExitCode = $LASTEXITCODE
if ($selfTestExitCode -ne 0) {
    throw "Probe self-test failed: $selfTestOutput"
}
$selfTestDiagnostic = $selfTestOutput | ConvertFrom-Json
if ($selfTestDiagnostic.level -ne 'info' -or $selfTestDiagnostic.code -ne 'self_test_passed') {
    throw "Probe self-test returned an unstable diagnostic: $selfTestOutput"
}

$guardOutput = & $windowsPowerShell -NoProfile -NonInteractive -File $probePath -Mode Smoke 2>&1
$guardExitCode = $LASTEXITCODE
if ($guardExitCode -ne 2) {
    throw "Lighting-control guard test failed: $guardOutput"
}
$guardDiagnostic = $guardOutput | ConvertFrom-Json
if ($guardDiagnostic.level -ne 'error' -or $guardDiagnostic.code -ne 'consent_required') {
    throw "Lighting-control guard returned an unstable diagnostic: $guardOutput"
}

Write-Output 'PASS: syntax, pure functions, and explicit lighting-control guard'
