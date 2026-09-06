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

Write-Step "Validating Orbit Flutter M7 installation"
$pubspec = Join-Path $ProjectPath "pubspec.yaml"
if (-not (Test-Path $pubspec)) { throw "Flutter project not found at $ProjectPath" }

foreach ($required in @(
    "lib\features\camera\presentation\camera_page.dart",
    "lib\features\media\application\media_moment_service.dart",
    "tool\verify-ui-m6.ps1",
    "docs\M6_CAMERA_ENCRYPTED_MEDIA_MOMENTS_CONTRACT.md"
)) {
    if (-not (Test-Path (Join-Path $ProjectPath $required))) {
        throw "M6 baseline file is missing: $required"
    }
}

$envelopeClient = Join-Path $ProjectPath "lib\core\network\orbit_api_envelope_client.dart"
Assert-Contains $envelopeClient "getEnvelope"
$commandClient = Join-Path $ProjectPath "lib\core\network\orbit_api_command_client.dart"
Assert-Contains $commandClient "postNoContent"
$dioClient = Join-Path $ProjectPath "lib\core\network\dio_orbit_api_client.dart"
Assert-Contains $dioClient "OrbitApiEnvelopeClient"
Assert-Contains $dioClient "OrbitApiCommandClient"
Assert-Contains $dioClient "Future<Map<String, dynamic>> getEnvelope"
Assert-Contains $dioClient "Future<void> postNoContent"

$activityRepository = Join-Path $ProjectPath "lib\features\activity\data\activity_repository.dart"
foreach ($needle in @(
    "v1/activity/feed",
    "/hide",
    "/report",
    "allowAuthRetry: true"
)) {
    Assert-Contains $activityRepository $needle
}

$activityDomain = Join-Path $ProjectPath "lib\features\activity\domain\activity_item.dart"
foreach ($needle in @(
    "moment.published",
    "member.joined",
    "member.left",
    "alert.sos_activated",
    "alert.sos_escalated",
    "alert.sos_resolved"
)) {
    Assert-Contains $activityDomain $needle
}

$notificationsRepository = Join-Path $ProjectPath "lib\features\notifications\data\notifications_repository.dart"
foreach ($needle in @(
    "v1/notifications",
    "v1/notifications/preferences",
    "v1/notifications/circles/",
    "v1/notifications/read-all",
    "v1/communications/announcements"
)) {
    Assert-Contains $notificationsRepository $needle
}
Assert-Contains $notificationsRepository "allowAuthRetry: true"

$notificationDomain = Join-Path $ProjectPath "lib\features\notifications\domain\orbit_notification.dart"
Assert-Contains $notificationDomain "unread_count"
Assert-Contains $notificationDomain "message.received"
Assert-Contains $notificationDomain "moment.published"
Assert-Contains $notificationDomain "ping.received"

$notificationCard = Join-Path $ProjectPath "lib\features\notifications\presentation\widgets\notification_card.dart"
Assert-Contains $notificationCard "notification.summary"
Assert-NotContains $notificationCard "notification.payload["
Assert-NotContains $notificationCard "notification.deepLink"

$notificationsPage = Join-Path $ProjectPath "lib\features\notifications\presentation\notifications_page.dart"
Assert-NotContains $notificationsPage "context.push(notification.deepLink"
Assert-Contains $notificationsPage "Orbit announcements"
Assert-Contains $notificationsPage "Mark all read"

$preferencesPage = Join-Path $ProjectPath "lib\features\notifications\presentation\pages\notification_preferences_page.dart"
foreach ($needle in @(
    "In-app notifications",
    "Push notifications",
    "Messages",
    "Moments",
    "Pings",
    "Activity",
    "Enable quiet hours"
)) {
    Assert-Contains $preferencesPage $needle
}

$homePage = Join-Path $ProjectPath "lib\features\home\presentation\home_page.dart"
Assert-Contains $homePage "Smart Activity"
Assert-Contains $homePage "activityPreviewProvider"

$profile = Join-Path $ProjectPath "lib\features\profile\presentation\profile_page.dart"
Assert-Contains $profile "Notification preferences"
Assert-Contains $profile "/notifications/preferences"

$router = Join-Path $ProjectPath "lib\app\routing\app_router.dart"
Assert-Contains $router "path: '/notifications'"
Assert-Contains $router "path: '/notifications/preferences'"
Assert-Contains $router "path: '/announcements/:announcementId'"

$contract = Join-Path $ProjectPath "docs\M7_ACTIVITY_NOTIFICATIONS_CONTRACT.md"
Assert-Contains $contract "Laravel remains authoritative"
Assert-Contains $contract "never trusts or executes arbitrary"
Assert-Contains $contract "M10"

Push-Location $ProjectPath
try {
    Write-Step "Resolving Flutter dependencies"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("pub", "get") -FailureMessage "flutter pub get failed"

    Write-Step "Checking formatting"
    Invoke-CheckedNative -FilePath "dart" -Arguments @("format", "--output=none", "--set-exit-if-changed", "lib", "test") -FailureMessage "Dart formatting check failed"

    Write-Step "Running Flutter analyzer"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Flutter analyzer failed"

    Write-Step "Running M7 Activity tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/activity") -FailureMessage "M7 Activity tests failed"

    Write-Step "Running M7 Notifications tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/notifications") -FailureMessage "M7 Notifications tests failed"

    Write-Step "Running Home integration regression"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/home/home_page_test.dart") -FailureMessage "M7 Home integration test failed"

    Write-Step "Running complete M1-M7 regression suite"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test") -FailureMessage "Flutter regression suite failed"

    Write-Step "Building Android debug APK"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("build", "apk", "--debug") -FailureMessage "Android debug build failed"
}
finally {
    Pop-Location
}

Write-Host "`nOrbit Flutter M7 verification passed." -ForegroundColor Green
