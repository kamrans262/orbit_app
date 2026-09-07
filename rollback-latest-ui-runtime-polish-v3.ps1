param(
    [Parameter(Mandatory = $false)]
    [string]$FlutterProjectPath = "C:\laravel-projects\orbit_app"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$BackupBase = Join-Path $FlutterProjectPath ".orbit-backups"
$Backup = Get-ChildItem $BackupBase -Directory -Filter "ui-runtime-polish-*" -ErrorAction SilentlyContinue |
    Sort-Object Name |
    Select-Object -First 1

if ($null -eq $Backup) {
    throw "No UI Runtime Polish rollback checkpoint was found."
}

$metaPath = Join-Path $Backup.FullName "backup-meta.json"
if (-not (Test-Path $metaPath)) {
    throw "Rollback metadata is missing: $metaPath"
}

$metadata = Get-Content $metaPath -Raw | ConvertFrom-Json
foreach ($entry in @($metadata)) {
    $relative = [string]$entry.relative
    $target = Join-Path $FlutterProjectPath $relative
    if ([bool]$entry.existed) {
        $source = Join-Path $Backup.FullName $relative
        if (-not (Test-Path $source)) { throw "Backup file missing: $relative" }
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Copy-Item $source $target -Force
    } else {
        Remove-Item $target -Force -ErrorAction SilentlyContinue
    }
}

# Repair packages may add verifier files that did not exist in the original baseline.
@("v1", "v2", "v3") | ForEach-Object {
    Remove-Item (Join-Path $FlutterProjectPath "tool\verify-ui-runtime-polish-$_.ps1") -Force -ErrorAction SilentlyContinue
}

Set-Location $FlutterProjectPath
& flutter analyze
if ($LASTEXITCODE -ne 0) { throw "Flutter analyzer failed after rollback." }

Write-Host "Restored checkpoint: $($Backup.FullName)" -ForegroundColor Green
