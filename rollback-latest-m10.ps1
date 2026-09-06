param(
    [string]$ProjectPath = "C:\laravel-projects\orbit_app"
)

$ErrorActionPreference = "Stop"
$backupBase = Join-Path $ProjectPath ".orbit-backups"
$baseline = Get-ChildItem $backupBase -Directory -Filter "ui-m10-*" -ErrorAction SilentlyContinue |
    Sort-Object Name |
    Select-Object -First 1
if ($null -eq $baseline) {
    throw "No Orbit Flutter M10 baseline backup was found in $backupBase"
}

Write-Host "Restoring Orbit Flutter M9 baseline checkpoint: $($baseline.FullName)" -ForegroundColor Cyan
foreach ($relative in @(
    "lib", "test", "tool", "docs", "pubspec.yaml", "pubspec.lock",
    "android\app\src\main\AndroidManifest.xml", "ios\Runner\Info.plist"
)) {
    $source = Join-Path $baseline.FullName $relative
    if (-not (Test-Path $source)) { continue }
    $destination = Join-Path $ProjectPath $relative
    if (Test-Path $destination) { Remove-Item $destination -Recurse -Force }
    $parent = Split-Path -Parent $destination
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Copy-Item $source $destination -Recurse -Force
}

$stagingOverlay = Join-Path $ProjectPath "overlay"
if (Test-Path $stagingOverlay) {
    Remove-Item $stagingOverlay -Recurse -Force
}

Write-Host "Rollback finished. Run .\tool\verify-ui-m9.ps1." -ForegroundColor Green
