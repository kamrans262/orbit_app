param(
    [string]$ProjectPath = "C:\laravel-projects\orbit_app",
    [string]$BackendPath = "C:\laravel-projects\orbit_api"
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n== $Message ==" -ForegroundColor Cyan
}

function Invoke-CheckedNative {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage (exit code $LASTEXITCODE)."
    }
}

function Assert-PackageIntegrity([string]$Root) {
    $manifestPath = Join-Path $Root "PACKAGE_MANIFEST.sha256"
    if (-not (Test-Path $manifestPath)) {
        throw "Package manifest is missing: $manifestPath"
    }

    $listed = @{}
    foreach ($line in Get-Content $manifestPath) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -notmatch '^([A-Fa-f0-9]{64})  (.+)$') {
            throw "Invalid package manifest entry: $line"
        }
        $expected = $Matches[1].ToLowerInvariant()
        $manifestRelative = $Matches[2].Replace('\', '/')
        if ($listed.ContainsKey($manifestRelative)) {
            throw "Duplicate package manifest entry: $manifestRelative"
        }
        $listed[$manifestRelative] = $true
        $relative = $manifestRelative.Replace('/', [IO.Path]::DirectorySeparatorChar)
        $path = Join-Path $Root $relative
        if (-not (Test-Path $path -PathType Leaf)) {
            throw "Package file is missing: $relative"
        }
        $actual = (Get-FileHash -Algorithm SHA256 -Path $path).Hash.ToLowerInvariant()
        if ($actual -ne $expected) {
            throw "Package integrity check failed for $relative"
        }
    }

    if ($listed.Count -eq 0) {
        throw "Package manifest is empty."
    }

    # The installer is intentionally designed to be copied into an existing Orbit
    # Flutter project. That project contains generated/runtime files that are not
    # part of the M10 package (for example .flutter-plugins-dependencies). Integrity
    # therefore applies to every manifest-controlled M10 file, not to unrelated
    # files already present beside the package.
}

function Assert-Contains([string]$Path, [string]$Needle) {
    if (-not (Test-Path $Path)) { throw "Required file is missing: $Path" }
    if ((Get-Content $Path -Raw) -notmatch [regex]::Escape($Needle)) {
        throw "Required contract '$Needle' is missing from $Path"
    }
}

$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$OverlayRoot = Join-Path $PackageRoot "overlay"
$PubspecPath = Join-Path $ProjectPath "pubspec.yaml"

Write-Step "Validating M10 package integrity"
Assert-PackageIntegrity $PackageRoot

Write-Step "Validating final M9 Flutter baseline"
if (-not (Test-Path $PubspecPath)) {
    throw "Flutter project not found at $ProjectPath"
}
foreach ($relative in @(
    "tool\verify-ui-m9.ps1",
    "docs\M9_PROFILE_IDENTITY_PRIVACY_SUPPORT_SUBSCRIPTION_CONTRACT.md",
    "lib\features\sos\presentation\pages\sos_incident_page.dart",
    "lib\features\notifications\domain\orbit_notification.dart",
    "lib\features\messaging\data\device_identity_store.dart"
)) {
    if (-not (Test-Path (Join-Path $ProjectPath $relative))) {
        throw "Expected M9 baseline file is missing: $relative. Do not install M10 before M1-M9 are complete."
    }
}
Assert-Contains (Join-Path $ProjectPath "lib\features\sos\presentation\widgets\sos_hold_button.dart") "Timer(_holdDuration"
Assert-Contains (Join-Path $ProjectPath "lib\features\notifications\domain\orbit_notification.dart") "String? get internalRoute"

Write-Step "Validating Laravel contracts without modifying the backend"
if (-not (Test-Path (Join-Path $BackendPath "composer.json"))) {
    throw "Laravel backend not found at $BackendPath"
}
Assert-Contains (Join-Path $BackendPath "composer.json") "laravel/reverb"
Assert-Contains (Join-Path $BackendPath "bootstrap\app.php") "withBroadcasting"
Assert-Contains (Join-Path $BackendPath "bootstrap\app.php") "auth:sanctum"
Assert-Contains (Join-Path $BackendPath "routes\channels.php") "devices.{deviceId}"
Assert-Contains (Join-Path $BackendPath "routes\channels_notifications.php") "orbit.user.{userId}"
Assert-Contains (Join-Path $BackendPath "routes\channels_sos.php") "orbit.sos.{sosId}"
Assert-Contains (Join-Path $BackendPath "app\Modules\Realtime\Broadcasts\MessageEnvelopeAvailableBroadcast.php") "EncryptedEnvelopeRealtimePayload"
Assert-Contains (Join-Path $BackendPath "app\Modules\Realtime\Broadcasts\MessageDeliveredBroadcast.php") "message.delivered"
Assert-Contains (Join-Path $BackendPath "app\Modules\Devices\Http\Requests\RegisterDeviceRequest.php") "push_token"
Assert-Contains (Join-Path $BackendPath "app\Modules\Notifications\Actions\RouteNotificationAction.php") "pending_provider"

Write-Step "Creating or reusing the M10 regression checkpoint"
$backupBase = Join-Path $ProjectPath ".orbit-backups"
$existingCheckpoints = @(
    Get-ChildItem $backupBase -Directory -Filter "ui-m10-*" -ErrorAction SilentlyContinue |
        Sort-Object Name
)
$partialM10Detected = (Test-Path (Join-Path $ProjectPath "lib\features\realtime")) -or
    (Test-Path (Join-Path $ProjectPath "lib\features\deep_links")) -or
    (Test-Path (Join-Path $ProjectPath "lib\features\push"))

if ($partialM10Detected -and $existingCheckpoints.Count -gt 0) {
    # A previous M10 attempt already captured the authoritative M9 baseline.
    # Reuse the oldest M10 checkpoint so a retry never replaces the rollback
    # target with a partially installed M10 tree.
    $backupRoot = $existingCheckpoints[0].FullName
    Write-Host "Reusing existing M9 baseline checkpoint: $backupRoot" -ForegroundColor DarkGray
}
else {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRoot = Join-Path $backupBase "ui-m10-$timestamp"
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    $backupTargets = @(
        "lib", "test", "tool", "docs", "pubspec.yaml", "pubspec.lock",
        "android\app\src\main\AndroidManifest.xml", "ios\Runner\Info.plist"
    )
    foreach ($relative in $backupTargets) {
        $source = Join-Path $ProjectPath $relative
        if (-not (Test-Path $source)) { continue }
        $destination = Join-Path $backupRoot $relative
        $parent = Split-Path -Parent $destination
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        if ((Get-Item $source).PSIsContainer) {
            Copy-Item $source $destination -Recurse -Force
        }
        else {
            Copy-Item $source $destination -Force
        }
    }
    Write-Host "Checkpoint: $backupRoot" -ForegroundColor DarkGray
}

Write-Step "Installing M10 overlay"
Get-ChildItem $OverlayRoot -Force | ForEach-Object {
    $destination = Join-Path $ProjectPath $_.Name
    if ($_.PSIsContainer) {
        if (-not (Test-Path $destination)) { New-Item -ItemType Directory -Path $destination -Force | Out-Null }
        Copy-Item (Join-Path $_.FullName "*") $destination -Recurse -Force
    }
    else {
        Copy-Item $_.FullName $destination -Force
    }
}

# Users commonly copy the installer package into the Flutter project before
# running it. In that workflow the staging `overlay` directory itself sits
# inside ProjectPath. Flutter analyzer recursively discovers Dart files there,
# but those staging files intentionally depend on the real M1-M9 source tree
# and are not a standalone Dart package. Remove only the staging directory
# after its contents have been merged into the project. If the installer is
# run from Downloads (PackageRoot != ProjectPath), the external package remains
# untouched.
$projectStagingOverlay = Join-Path $ProjectPath "overlay"
if (Test-Path (Join-Path $projectStagingOverlay "tool\verify-ui-m10.ps1")) {
    Remove-Item $projectStagingOverlay -Recurse -Force
    Write-Host "Removed in-project M10 staging overlay before analysis." -ForegroundColor DarkGray
}

Push-Location $ProjectPath
try {
    Write-Step "Adding M10 dependencies without churning existing pins"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @(
        "pub", "add", "app_links:^7.2.1", "web_socket_channel:^3.0.3"
    ) -FailureMessage "M10 dependency installation failed"

    Write-Step "Applying native Android/iOS deep-link configuration"
    & (Join-Path $ProjectPath "tool\configure-m10-native.ps1") -ProjectPath $ProjectPath

    Write-Step "Formatting M10 Dart sources"
    Invoke-CheckedNative -FilePath "dart" -Arguments @("format", "lib", "test") -FailureMessage "Dart formatting failed"

    Write-Step "Running Flutter analyzer early"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Early M10 analyzer failed"
}
finally {
    Pop-Location
}

Write-Step "M10 installation finished"
Write-Host "Project:  $ProjectPath"
Write-Host "Backend:  $BackendPath"
Write-Host "Backup:   $backupRoot"
Write-Host "Next:     .\tool\verify-ui-m10.ps1"
Write-Host "Realtime remains safely disabled until ORBIT_REVERB_APP_KEY is configured." -ForegroundColor Yellow
