[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$probeDirectory = Join-Path $repositoryRoot 'tools\rgb-ambient-probe'
foreach ($script in Get-ChildItem -LiteralPath $probeDirectory -Filter '*.ps1') {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors) > $null
    if ($errors.Count -ne 0) { throw "$($script.Name) syntax check failed: $($errors.Message -join '; ')" }
}

$diagnosticScript = Get-Content -Raw -LiteralPath (Join-Path $probeDirectory 'Get-AmbientDiagnostics.ps1')
if ($diagnosticScript -match '(?i)\b(Set-ItemProperty|New-ItemProperty|Remove-ItemProperty|Start-Service|Stop-Service|Restart-Service|Disable-PnpDevice|Enable-PnpDevice)\b') {
    throw 'Ambient diagnostics must remain read-only.'
}

[xml]$packageManifest = Get-Content -Raw -LiteralPath (Join-Path $probeDirectory 'AppxManifest.xml')
[xml]$applicationManifest = Get-Content -Raw -LiteralPath (Join-Path $probeDirectory 'app.manifest')
$namespace = [System.Xml.XmlNamespaceManager]::new($packageManifest.NameTable)
$namespace.AddNamespace('f', 'http://schemas.microsoft.com/appx/manifest/foundation/windows10')
$namespace.AddNamespace('uap3', 'http://schemas.microsoft.com/appx/manifest/uap/windows10/3')
$identity = $packageManifest.SelectSingleNode('/f:Package/f:Identity', $namespace)
$extension = $packageManifest.SelectSingleNode('//uap3:AppExtension[@Name="com.microsoft.windows.lighting"]', $namespace)
$msix = $applicationManifest.assembly.msix
if ($null -eq $extension) { throw 'Ambient lighting app extension is missing.' }
if ($identity.Name -ne $msix.packageName -or $identity.Publisher -ne $msix.publisher) {
    throw 'Package and executable identity declarations do not match.'
}

& (Join-Path $probeDirectory 'Build-AmbientProbe.ps1')
$probePath = Join-Path $probeDirectory 'bin\AmbientRgbProbe.SelfTest.exe'
$output = & $probePath --self-test
if ($LASTEXITCODE -ne 0) { throw "Ambient probe self-test failed: $output" }
$diagnostic = $output | ConvertFrom-Json
if ($diagnostic.code -ne 'self_test_passed') { throw "Unexpected self-test diagnostic: $output" }

$guardOutput = & $probePath --mode smoke 2>&1
if ($LASTEXITCODE -ne 2) { throw "Ambient lighting guard failed: $guardOutput" }
$guardDiagnostic = $guardOutput | ConvertFrom-Json
if ($guardDiagnostic.code -ne 'consent_required') { throw "Unexpected guard diagnostic: $guardOutput" }

Write-Output 'PASS: scripts, identity manifests, compilation, and hardware-free self-test'
