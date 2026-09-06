param(
    [string]$ProjectPath = "C:\laravel-projects\orbit_app"
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n== $Message ==" -ForegroundColor Cyan
}

function Assert-Contains([string]$Path, [string]$Needle) {
    if (-not (Test-Path $Path)) { throw "Required file is missing: $Path" }
    $content = Get-Content $Path -Raw
    if ($content -notmatch [regex]::Escape($Needle)) {
        throw "Static contract check failed: '$Needle' not found in $Path"
    }
}

function Assert-NotContains([string]$Path, [string]$Needle) {
    if (-not (Test-Path $Path)) { throw "Required file is missing: $Path" }
    $content = Get-Content $Path -Raw
    if ($content -match [regex]::Escape($Needle)) {
        throw "Static safety check failed: '$Needle' must not be present in $Path"
    }
}

function Invoke-CheckedNative {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    & $FilePath @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "$FailureMessage (exit code $exitCode)."
    }
}

Write-Step "Validating Orbit Flutter M8 installation"
$pubspec = Join-Path $ProjectPath "pubspec.yaml"
if (-not (Test-Path $pubspec)) { throw "Flutter project not found at $ProjectPath" }

foreach ($required in @(
    "lib\features\activity\presentation\activity_page.dart",
    "lib\features\notifications\presentation\notifications_page.dart",
    "tool\verify-ui-m7.ps1",
    "docs\M7_ACTIVITY_NOTIFICATIONS_CONTRACT.md"
)) {
    if (-not (Test-Path (Join-Path $ProjectPath $required))) {
        throw "M7 baseline file is missing: $required"
    }
}

$sosRepository = Join-Path $ProjectPath "lib\features\sos\data\sos_repository.dart"
foreach ($needle in @(
    "v1/sos/activate",
    "/respond",
    "/location",
    "/recording",
    "/resolve",
    "allowAuthRetry: true",
    "allowAuthRetry: false"
)) {
    Assert-Contains $sosRepository $needle
}

$sosModels = Join-Path $ProjectPath "lib\features\sos\domain\sos_models.dart"
foreach ($needle in @(
    "active('active')",
    "resolved('resolved')",
    "pending('pending')",
    "engaged('engaged')",
    "declined('declined')",
    "help_arrived"
)) {
    Assert-Contains $sosModels $needle
}

$holdButton = Join-Path $ProjectPath "lib\features\sos\presentation\widgets\sos_hold_button.dart"
Assert-Contains $holdButton "Duration(seconds: 3)"
Assert-Contains $holdButton "Hold 3 seconds to activate SOS"

$activationPage = Join-Path $ProjectPath "lib\features\sos\presentation\pages\sos_activation_page.dart"
Assert-Contains $activationPage "Include current location"
Assert-Contains $activationPage "SOS can still be activated without location"
Assert-Contains $activationPage "sos_activation_rate_limited"
Assert-Contains $activationPage "does not auto-dial emergency services"

$incidentPage = Join-Path $ProjectPath "lib\features\sos\presentation\pages\sos_incident_page.dart"
Assert-Contains $incidentPage "Duration(seconds: 15)"
Assert-Contains $incidentPage "Duration(seconds: 1)"
Assert-Contains $incidentPage "Share live SOS location"
Assert-Contains $incidentPage "Resolve SOS"

$localStore = Join-Path $ProjectPath "lib\features\sos\data\sos_local_state_store.dart"
Assert-Contains $localStore "flutter_secure_storage"
Assert-Contains $localStore "orbit.sos.active.v1"

$homePage = Join-Path $ProjectPath "lib\features\home\presentation\home_page.dart"
Assert-Contains $homePage "context.push('/sos')"
Assert-NotContains $homePage "SOS safety flows arrive in Flutter M8"
Assert-NotContains $homePage "SOS safety activation arrives in Flutter M8"

$notificationDomain = Join-Path $ProjectPath "lib\features\notifications\domain\orbit_notification.dart"
Assert-Contains $notificationDomain "kind.startsWith('sos.')"
Assert-Contains $notificationDomain "payload['sos_id']"
Assert-Contains $notificationDomain "'/sos/"

$notificationsPage = Join-Path $ProjectPath "lib\features\notifications\presentation\notifications_page.dart"
Assert-NotContains $notificationsPage "context.push(notification.deepLink"

$router = Join-Path $ProjectPath "lib\app\routing\app_router.dart"
Assert-Contains $router "path: '/sos'"
Assert-Contains $router "path: ':sosId'"
Assert-Contains $router "SosActivationPage"
Assert-Contains $router "SosIncidentPage"

$contract = Join-Path $ProjectPath "docs\M8_SOS_SAFETY_CONTRACT.md"
Assert-Contains $contract "Laravel remains authoritative"
Assert-Contains $contract "three-second hold"
Assert-Contains $contract "does **not** fake AAC capture/upload"
Assert-Contains $contract "M10"
Assert-Contains $contract "M11"

Push-Location $ProjectPath
try {
    Write-Step "Resolving Flutter dependencies"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("pub", "get") -FailureMessage "flutter pub get failed"

    Write-Step "Checking formatting"
    Invoke-CheckedNative -FilePath "dart" -Arguments @("format", "--output=none", "--set-exit-if-changed", "lib", "test") -FailureMessage "Dart formatting check failed"

    Write-Step "Running Flutter analyzer first"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Flutter analyzer failed"

    Write-Step "Running M8 SOS tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/sos") -FailureMessage "M8 SOS tests failed"

    Write-Step "Running M7 notification navigation regression"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/notifications") -FailureMessage "Notification regression tests failed"

    Write-Step "Running Home SOS integration regression"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/home/home_page_test.dart") -FailureMessage "Home integration test failed"

    Write-Step "Running complete M1-M8 regression suite"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test") -FailureMessage "Flutter regression suite failed"

    Write-Step "Building Android debug APK"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("build", "apk", "--debug") -FailureMessage "Android debug build failed"
}
finally {
    Pop-Location
}

Write-Host "`nOrbit Flutter M8 verification passed." -ForegroundColor Green
