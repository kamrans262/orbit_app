param(
    [string]$FlutterProjectPath = "C:\laravel-projects\orbit_app",
    [string]$BackendPath = "C:\laravel-projects\orbit_api"
)

$ErrorActionPreference = "Stop"

function Restore-Latest([string]$ProjectPath) {
    $base = Join-Path $ProjectPath ".orbit-backups"
    $backup = Get-ChildItem $base -Directory -Filter "m10p-push-*" -ErrorAction SilentlyContinue |
        Sort-Object Name | Select-Object -First 1
    if (-not $backup) { throw "No M10P baseline backup found under $base" }

    foreach ($target in @("lib", "test", "tool", "docs", "app", "config", "routes", "tests", "setup")) {
        $saved = Join-Path $backup.FullName $target
        if (-not (Test-Path $saved)) { continue }
        $current = Join-Path $ProjectPath $target
        if (Test-Path $current) { Remove-Item $current -Recurse -Force }
        Copy-Item $saved $current -Recurse -Force
    }
    foreach ($file in @("pubspec.yaml", "pubspec.lock", ".env.example")) {
        $saved = Join-Path $backup.FullName $file
        if (Test-Path $saved) { Copy-Item $saved (Join-Path $ProjectPath $file) -Force }
    }

    return $backup.FullName
}

$flutterBackup = Restore-Latest $FlutterProjectPath
$backendBackup = Restore-Latest $BackendPath

Push-Location $FlutterProjectPath
try { flutter pub get } finally { Pop-Location }
Push-Location $BackendPath
try { php artisan config:clear } finally { Pop-Location }

Write-Host "Restored Flutter: $flutterBackup" -ForegroundColor Green
Write-Host "Restored Laravel: $backendBackup" -ForegroundColor Green
Write-Host "Run .\tool\verify-ui-m10.ps1 to confirm the original green M10 baseline."
