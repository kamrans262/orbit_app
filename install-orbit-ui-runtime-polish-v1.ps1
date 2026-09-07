param(
    [Parameter(Mandatory = $false)]
    [string]$FlutterProjectPath = "C:\laravel-projects\orbit_app"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step([string]$Message) {
    Write-Host "`n== $Message ==" -ForegroundColor Cyan
}

function Invoke-CheckedNative {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $false)][string[]]$Arguments = @(),
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage (exit code $LASTEXITCODE)."
    }
}

$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$OverlayRoot = Join-Path $PackageRoot "overlay"
$ManifestPath = Join-Path $PackageRoot "PACKAGE_MANIFEST.sha256"

if (-not (Test-Path $FlutterProjectPath)) {
    throw "Flutter project not found: $FlutterProjectPath"
}
if (-not (Test-Path (Join-Path $FlutterProjectPath "pubspec.yaml"))) {
    throw "pubspec.yaml was not found in $FlutterProjectPath"
}
if (-not (Test-Path $OverlayRoot)) {
    throw "Package overlay is missing: $OverlayRoot"
}

Write-Step "Validating package integrity"
if (Test-Path $ManifestPath) {
    Get-Content $ManifestPath | ForEach-Object {
        if ([string]::IsNullOrWhiteSpace($_)) { return }
        $parts = $_ -split '\s+', 2
        if ($parts.Count -ne 2) { throw "Invalid manifest line: $_" }
        $expected = $parts[0].Trim().ToLowerInvariant()
        $relative = $parts[1].Trim().Replace('/', [IO.Path]::DirectorySeparatorChar)
        $path = Join-Path $PackageRoot $relative
        if (-not (Test-Path $path)) { throw "Package file missing: $relative" }
        $actual = (Get-FileHash -Algorithm SHA256 -Path $path).Hash.ToLowerInvariant()
        if ($actual -ne $expected) { throw "Package hash mismatch: $relative" }
    }
}

Write-Step "Validating M10P Flutter baseline"
$requiredBaselineFiles = @(
    "lib\features\profile\presentation\pages\edit_profile_page.dart",
    "lib\features\notifications\presentation\pages\notification_preferences_page.dart",
    "lib\features\home\presentation\widgets\home_header.dart",
    "lib\features\home\presentation\widgets\quick_actions.dart",
    "lib\features\home\presentation\widgets\sos_floating_action.dart",
    "lib\features\camera\presentation\camera_page.dart",
    "lib\features\push\application\orbit_push_bootstrap.dart"
)
foreach ($relative in $requiredBaselineFiles) {
    $path = Join-Path $FlutterProjectPath $relative
    if (-not (Test-Path $path)) { throw "Required Orbit source is missing: $relative" }
}

Write-Step "Creating rollback checkpoint"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = Join-Path $FlutterProjectPath ".orbit-backups\ui-runtime-polish-$stamp"
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null

$overlayFiles = Get-ChildItem -Path $OverlayRoot -File -Recurse
$metadata = @()
foreach ($file in $overlayFiles) {
    $relative = $file.FullName.Substring($OverlayRoot.Length).TrimStart('\', '/')
    $target = Join-Path $FlutterProjectPath $relative
    $existed = Test-Path $target
    $metadata += [pscustomobject]@{ relative = $relative; existed = $existed }
    if ($existed) {
        $backup = Join-Path $BackupRoot $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
        Copy-Item $target $backup -Force
    }
}
$metadata | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $BackupRoot "backup-meta.json") -Encoding UTF8
Write-Host "Rollback checkpoint: $BackupRoot"

Write-Step "Installing UI runtime polish overlay"
foreach ($file in $overlayFiles) {
    $relative = $file.FullName.Substring($OverlayRoot.Length).TrimStart('\', '/')
    $target = Join-Path $FlutterProjectPath $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item $file.FullName $target -Force
}

# When the package was copied into the project root, remove the staging overlay
# before analyzer/test so duplicate Dart sources are never analyzed.
if ((Resolve-Path $PackageRoot).Path -eq (Resolve-Path $FlutterProjectPath).Path) {
    Remove-Item (Join-Path $FlutterProjectPath "overlay") -Recurse -Force -ErrorAction SilentlyContinue
}

Set-Location $FlutterProjectPath

$dartFiles = @(
    "lib\features\profile\presentation\pages\edit_profile_page.dart",
    "lib\features\notifications\presentation\pages\notification_preferences_page.dart",
    "lib\features\home\presentation\widgets\home_header.dart",
    "lib\features\home\presentation\widgets\quick_actions.dart",
    "lib\features\home\presentation\widgets\sos_floating_action.dart",
    "lib\features\camera\presentation\camera_page.dart",
    "test\features\ui_polish\ui_polish_source_contract_test.dart"
)

Write-Step "Formatting modified Dart sources"
Invoke-CheckedNative -FilePath "dart" -Arguments (@("format") + $dartFiles) -FailureMessage "Dart formatting failed"

Write-Step "Running Flutter analyzer early"
Invoke-CheckedNative -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Flutter analyzer failed"

Write-Step "Running focused UI polish contract test"
Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/ui_polish/ui_polish_source_contract_test.dart") -FailureMessage "UI polish contract test failed"

Write-Host "`nOrbit Flutter UI Runtime Polish v1 installed." -ForegroundColor Green
Write-Host "Run: .\tool\verify-ui-runtime-polish-v1.ps1 -FlutterProjectPath `"$FlutterProjectPath`""
Write-Host "Physical-device camera preview verification is still required." -ForegroundColor Yellow
