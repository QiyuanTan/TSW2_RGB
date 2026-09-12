[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$outputDirectory = Join-Path $PSScriptRoot 'bin'
$assetDirectory = Join-Path $outputDirectory 'Assets'
$publicDirectory = Join-Path $outputDirectory 'public'
New-Item -ItemType Directory -Force -Path $outputDirectory, $assetDirectory, $publicDirectory > $null

$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$metadataDirectory = Join-Path $env:WINDIR 'System32\WinMetadata'
$references = @(
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\System.Runtime.dll'),
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\Microsoft.CSharp.dll'),
    (Join-Path $metadataDirectory 'Windows.ApplicationModel.winmd'),
    (Join-Path $metadataDirectory 'Windows.Devices.winmd'),
    (Join-Path $metadataDirectory 'Windows.Foundation.winmd'),
    (Join-Path $metadataDirectory 'Windows.System.winmd'),
    (Join-Path $metadataDirectory 'Windows.UI.winmd')
)

foreach ($path in @($compiler) + $references) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required build input is unavailable: $path" }
}

$outputPath = Join-Path $outputDirectory 'AmbientRgbProbe.exe'
$commonArguments = @('/nologo', '/target:exe', '/platform:x64', '/optimize+') +
    ($references | ForEach-Object { "/reference:$_" }) +
    @((Join-Path $PSScriptRoot 'AmbientRgbProbe.cs'))
$arguments = @(
    "/out:$outputPath",
    "/win32manifest:$(Join-Path $PSScriptRoot 'app.manifest')"
) + $commonArguments

& $compiler $arguments
if ($LASTEXITCODE -ne 0) { throw "C# compilation failed with exit code $LASTEXITCODE." }

$selfTestPath = Join-Path $outputDirectory 'AmbientRgbProbe.SelfTest.exe'
& $compiler @("/out:$selfTestPath") $commonArguments
if ($LASTEXITCODE -ne 0) { throw "C# self-test host compilation failed with exit code $LASTEXITCODE." }

Add-Type -AssemblyName System.Drawing
foreach ($asset in @(
    @{ Name = 'StoreLogo.png'; Width = 50; Height = 50 },
    @{ Name = 'Square44x44Logo.png'; Width = 44; Height = 44 },
    @{ Name = 'Square150x150Logo.png'; Width = 150; Height = 150 }
)) {
    $bitmap = [System.Drawing.Bitmap]::new($asset.Width, $asset.Height)
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try { $graphics.Clear([System.Drawing.Color]::FromArgb(255, 32, 32, 32)) }
        finally { $graphics.Dispose() }
        $bitmap.Save((Join-Path $assetDirectory $asset.Name), [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $bitmap.Dispose() }
}

Write-Output "Built $outputPath"
