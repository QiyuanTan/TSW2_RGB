[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'Build-AmbientProbe.ps1')
$manifestPath = Join-Path $PSScriptRoot 'AppxManifest.xml'
$externalLocation = Join-Path $PSScriptRoot 'bin'
Add-AppxPackage -Register $manifestPath -ExternalLocation $externalLocation -ForceApplicationShutdown

$package = Get-AppxPackage -Name 'QiyuanTan.TSW2RGB.AmbientProbe'
if ($null -eq $package) { throw 'Ambient probe package registration did not appear for the current user.' }

Write-Output 'Registered TSW2 RGB Ambient Probe for the current user.'
Write-Output 'Open Settings > Personalization > Dynamic Lighting and move TSW2 RGB Ambient Probe to the top of Background light control.'
Write-Output "Run: $externalLocation\AmbientRgbProbe.exe --mode smoke --duration-seconds 15 --start-delay-seconds 10 --accept-lighting-control"
