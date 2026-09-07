param(
    [string]$FlutterProjectPath = "C:\laravel-projects\orbit_app",
    [string]$BackendPath = "C:\laravel-projects\orbit_api"
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n== $Message ==" -ForegroundColor Cyan
}

function Assert-Contains([string]$Path, [string]$Needle) {
    if (-not (Test-Path $Path)) { throw "Required file missing: $Path" }
    if ((Get-Content $Path -Raw) -notmatch [regex]::Escape($Needle)) {
        throw "Required contract '$Needle' is missing from $Path"
    }
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$FailureMessage (exit code $LASTEXITCODE)." }
}

function Assert-PackageIntegrity([string]$Root) {
    $manifest = Join-Path $Root "PACKAGE_MANIFEST.sha256"
    if (-not (Test-Path $manifest)) { throw "Package manifest missing: $manifest" }
    foreach ($line in Get-Content $manifest) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -notmatch '^([A-Fa-f0-9]{64})  (.+)$') { throw "Invalid manifest entry: $line" }
        $relative = $Matches[2].Replace('/', [IO.Path]::DirectorySeparatorChar)
        $path = Join-Path $Root $relative
        if (-not (Test-Path $path -PathType Leaf)) { throw "Package file missing: $relative" }
        $actual = (Get-FileHash -Algorithm SHA256 $path).Hash.ToLowerInvariant()
        if ($actual -ne $Matches[1].ToLowerInvariant()) { throw "Package integrity check failed for $relative" }
    }
}

function Copy-Overlay([string]$Source, [string]$Destination) {
    Get-ChildItem $Source -Force | ForEach-Object {
        $target = Join-Path $Destination $_.Name
        if ($_.PSIsContainer) {
            if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
            Get-ChildItem $_.FullName -Force | ForEach-Object {
                Copy-Item $_.FullName $target -Recurse -Force
            }
        } else {
            Copy-Item $_.FullName $target -Force
        }
    }
}

function Backup-Targets([string]$ProjectPath, [string]$BackupRoot, [string[]]$Targets) {
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    foreach ($relative in $Targets) {
        $source = Join-Path $ProjectPath $relative
        if (-not (Test-Path $source)) { continue }
        $destination = Join-Path $BackupRoot $relative
        $parent = Split-Path -Parent $destination
        if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item $source $destination -Recurse -Force
    }
}

$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$FlutterOverlay = Join-Path $PackageRoot "flutter_overlay"
$BackendOverlay = Join-Path $PackageRoot "backend_overlay"

Write-Step "Validating M10P package integrity"
Assert-PackageIntegrity $PackageRoot

Write-Step "Validating green M10 Flutter baseline"
Assert-Contains (Join-Path $FlutterProjectPath "tool\verify-ui-m10.ps1") "Orbit Flutter M10 verification passed"
Assert-Contains (Join-Path $FlutterProjectPath "lib\features\push\domain\push_token_source.dart") "UnavailablePushTokenSource"
Assert-Contains (Join-Path $FlutterProjectPath "lib\features\deep_links\domain\orbit_deep_link_resolver.dart") "_isUuid"
Assert-Contains (Join-Path $FlutterProjectPath "lib\features\messaging\data\device_identity_store.dart") "DevicePrivateIdentity"

Write-Step "Validating Laravel notification/device baseline"
Assert-Contains (Join-Path $BackendPath "app\Modules\Notifications\Actions\RouteNotificationAction.php") "pending_provider"
Assert-Contains (Join-Path $BackendPath "app\Modules\Notifications\Services\NotificationDeliveryPayloadFactory.php") "interruption_level"
Assert-Contains (Join-Path $BackendPath "app\Modules\Devices\Actions\RegisterDeviceAction.php") "push_token"
Assert-Contains (Join-Path $BackendPath "config\queue.php") "database"

Write-Step "Creating or reusing the M10P rollback checkpoint"
$flutterBackupBase = Join-Path $FlutterProjectPath ".orbit-backups"
$backendBackupBase = Join-Path $BackendPath ".orbit-backups"
$existingFlutter = Get-ChildItem $flutterBackupBase -Directory -Filter "m10p-push-*" -ErrorAction SilentlyContinue |
    Sort-Object Name | Select-Object -First 1
$existingBackend = Get-ChildItem $backendBackupBase -Directory -Filter "m10p-push-*" -ErrorAction SilentlyContinue |
    Sort-Object Name | Select-Object -First 1

if (($null -eq $existingFlutter) -xor ($null -eq $existingBackend)) {
    throw "M10P rollback checkpoint is inconsistent between Flutter and Laravel. Restore the missing checkpoint before continuing."
}

if ($existingFlutter -and $existingBackend) {
    if ($existingFlutter.Name -ne $existingBackend.Name) {
        throw "M10P Flutter/Laravel rollback checkpoints do not match."
    }
    $flutterBackup = $existingFlutter.FullName
    $backendBackup = $existingBackend.FullName
    Write-Host "Reusing Flutter M10 baseline: $flutterBackup" -ForegroundColor DarkGray
    Write-Host "Reusing Laravel M10 baseline: $backendBackup" -ForegroundColor DarkGray
} else {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $flutterBackup = Join-Path $flutterBackupBase "m10p-push-$timestamp"
    $backendBackup = Join-Path $backendBackupBase "m10p-push-$timestamp"
    Backup-Targets $FlutterProjectPath $flutterBackup @("lib", "test", "tool", "docs", "pubspec.yaml", "pubspec.lock")
    Backup-Targets $BackendPath $backendBackup @("app", "config", "routes", "tests", "setup", ".env.example")
    Write-Host "Flutter backup: $flutterBackup" -ForegroundColor DarkGray
    Write-Host "Laravel backup: $backendBackup" -ForegroundColor DarkGray
}

Write-Step "Installing M10P Flutter overlay"
Copy-Overlay $FlutterOverlay $FlutterProjectPath

Write-Step "Installing M10P Laravel overlay"
Copy-Overlay $BackendOverlay $BackendPath

# The normal Orbit workflow copies the package itself into orbit_app. Remove
# staging overlays before analyzer so package Dart files are not analyzed twice.
foreach ($staging in @("flutter_overlay", "backend_overlay")) {
    $candidate = Join-Path $FlutterProjectPath $staging
    if (Test-Path $candidate) {
        Remove-Item $candidate -Recurse -Force
    }
}

Push-Location $FlutterProjectPath
try {
    Write-Step "Adding Firebase Flutter dependencies without broad upgrades"
    Invoke-Checked -FilePath "flutter" -Arguments @("pub", "add", "firebase_core:^4.14.0", "firebase_messaging:^16.6.0") -FailureMessage "Firebase dependency installation failed"

    Write-Step "Formatting M10P Dart sources"
    Invoke-Checked -FilePath "dart" -Arguments @("format", "lib\features\push", "lib\features\realtime\presentation\orbit_realtime_bridge.dart", "lib\main.dart", "test\features\push") -FailureMessage "Dart formatting failed"

    Write-Step "Running Flutter analyzer early"
    Invoke-Checked -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Early M10P analyzer failed"
}
finally {
    Pop-Location
}

Push-Location $BackendPath
try {
    Write-Step "Clearing Laravel config cache after provider installation"
    Invoke-Checked -FilePath "php" -Arguments @("artisan", "config:clear") -FailureMessage "Laravel config clear failed"

    Write-Step "Running focused Laravel push tests"
    Invoke-Checked -FilePath "php" -Arguments @("artisan", "test", "tests/Feature/Api/V1/Notifications/PushDeliveryProviderTest.php", "tests/Feature/Api/V1/Notifications/PushAccessTokenTest.php") -FailureMessage "M10P Laravel push tests failed"
}
finally {
    Pop-Location
}

Write-Host "`nOrbit M10P remote push delivery installed." -ForegroundColor Green
Write-Host "Push remains disabled until Firebase client/server configuration is supplied." -ForegroundColor Yellow
Write-Host "Next automated gate: .\tool\verify-m10p-push.ps1 -FlutterProjectPath `"$FlutterProjectPath`" -BackendPath `"$BackendPath`""
Write-Host "Then configure Firebase and perform the physical-device foreground/background/terminated delivery test."
