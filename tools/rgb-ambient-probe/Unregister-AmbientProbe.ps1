[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$packages = @(Get-AppxPackage -Name 'QiyuanTan.TSW2RGB.AmbientProbe')
foreach ($package in $packages) {
    Remove-AppxPackage -Package $package.PackageFullName
}
Write-Output "Removed $($packages.Count) ambient probe package registration(s) for the current user."
