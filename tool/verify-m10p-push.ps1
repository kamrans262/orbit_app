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

function Assert-NotContains([string]$Path, [string]$Needle) {
    if (-not (Test-Path $Path)) { throw "Required file missing: $Path" }
    if ((Get-Content $Path -Raw) -match [regex]::Escape($Needle)) {
        throw "Forbidden contract '$Needle' was found in $Path"
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

Write-Step "Validating green M10 baseline and M10P source"
Assert-Contains (Join-Path $FlutterProjectPath "tool\verify-ui-m10.ps1") "Orbit Flutter M10 verification passed"
Assert-Contains (Join-Path $FlutterProjectPath "docs\M10_REALTIME_PUSH_DEEP_LINKS_CONTRACT.md") "provider-neutral"
Assert-Contains (Join-Path $FlutterProjectPath "docs\M10P_REMOTE_PUSH_DELIVERY_CONTRACT.md") "Firebase Cloud Messaging HTTP v1"
Assert-Contains (Join-Path $BackendPath "app\Modules\Notifications\Actions\RouteNotificationAction.php") "QueueNotificationDeliveryAction"
Assert-Contains (Join-Path $BackendPath "config\orbit_push.php") "GOOGLE_APPLICATION_CREDENTIALS"

Write-Step "Validating push privacy and E2EE invariants"
$provider = Join-Path $BackendPath "app\Modules\Notifications\Services\FirebaseHttpV1PushProvider.php"
Assert-Contains $provider "notification_id"
Assert-Contains $provider "deep_link"
Assert-Contains $provider "UNREGISTERED"
Assert-NotContains $provider "latitude"
Assert-NotContains $provider "longitude"
Assert-NotContains $provider "encrypted_preview"
Assert-NotContains $provider "ciphertext"
Assert-NotContains $provider "private_key"

$payloadFactory = Join-Path $BackendPath "app\Modules\Notifications\Services\NotificationDeliveryPayloadFactory.php"
Assert-NotContains $payloadFactory "'data' => `$notification->payload"
Assert-Contains $payloadFactory "'push_type' => `$silent ? 'background' : 'alert'"

$job = Join-Path $BackendPath "app\Modules\Notifications\Jobs\DeliverPushNotificationJob.php"
Assert-Contains $job "where('push_token', `$originalToken)"
Assert-Contains $job "push_token' => null"
Assert-NotContains $job "public_identity_key' => null"
Assert-NotContains $job "Log::debug(`$device->push_token"

$deviceSync = Join-Path $FlutterProjectPath "lib\features\push\data\device_push_registration_service.dart"
Assert-Contains $deviceSync "public_identity_key"
Assert-Contains $deviceSync "'push_token': token?.value"

Write-Step "Validating Firebase stays optional and server secrets stay out of Flutter"
$firebaseEnvironment = Join-Path $FlutterProjectPath "lib\features\push\domain\orbit_firebase_environment.dart"
Assert-Contains $firebaseEnvironment "ORBIT_FIREBASE_ENABLED"
Assert-Contains $firebaseEnvironment "defaultValue: false"
$bootstrap = Join-Path $FlutterProjectPath "lib\features\push\application\orbit_push_bootstrap.dart"
Assert-Contains $bootstrap "OrbitFirebaseEnvironment.fromDartDefines"
Assert-Contains $bootstrap "FirebaseMessaging.onBackgroundMessage"
Assert-Contains $bootstrap "@pragma('vm:entry-point')"
$firebaseSource = Join-Path $FlutterProjectPath "lib\features\push\data\firebase_push_token_source.dart"
Assert-Contains $firebaseSource "getAPNSToken"
Assert-Contains $firebaseSource "onTokenRefresh"
Assert-Contains $firebaseSource "getInitialMessage"
Assert-Contains $firebaseSource "onMessageOpenedApp"
Assert-Contains $firebaseSource "onMessage"
Assert-NotContains $firebaseSource "service-account"

$flutterSecretScan = @(
    (Join-Path -Path $FlutterProjectPath -ChildPath "lib")
    (Join-Path -Path $FlutterProjectPath -ChildPath "android")
    (Join-Path -Path $FlutterProjectPath -ChildPath "ios")
) | Where-Object { Test-Path $_ }
foreach ($scanRoot in $flutterSecretScan) {
    $matches = Get-ChildItem $scanRoot -Recurse -File -ErrorAction SilentlyContinue |
        Select-String -SimpleMatch '"type": "service_account"' -ErrorAction SilentlyContinue
    if ($matches) { throw "Firebase service-account credentials must never be stored in Flutter: $($matches[0].Path)" }
}

Write-Step "Validating backend PHP syntax"
$phpFiles = @(
    "app\Console\Commands\EnqueuePendingPushDeliveriesCommand.php",
    "app\Console\Commands\TestOrbitPushCommand.php",
    "app\Modules\Notifications\Actions\QueueNotificationDeliveryAction.php",
    "app\Modules\Notifications\Actions\RouteNotificationAction.php",
    "app\Modules\Notifications\Contracts\FirebaseAccessTokenSource.php",
    "app\Modules\Notifications\Jobs\DeliverPushNotificationJob.php",
    "app\Modules\Notifications\Services\FirebaseHttpV1PushProvider.php",
    "app\Modules\Notifications\Services\GoogleServiceAccountAccessTokenSource.php",
    "app\Modules\Notifications\Services\NotificationDeliveryPayloadFactory.php",
    "app\Modules\Notifications\Services\PushProviderResult.php",
    "app\Providers\AppServiceProvider.php",
    "config\orbit_push.php",
    "routes\console_notifications.php"
)
Push-Location $BackendPath
try {
    foreach ($relative in $phpFiles) {
        Invoke-Checked -FilePath "php" -Arguments @("-l", $relative) -FailureMessage "PHP syntax failed for $relative"
    }

    if (Test-Path "vendor\bin\pint") {
        Write-Step "Checking Laravel formatting"
        Invoke-Checked -FilePath "vendor\bin\pint" -Arguments @("--test") -FailureMessage "Laravel Pint check failed"
    }

    Write-Step "Running focused Laravel push tests"
    Invoke-Checked -FilePath "php" -Arguments @(
        "artisan", "test",
        "tests/Feature/Api/V1/Notifications/PushDeliveryProviderTest.php",
        "tests/Feature/Api/V1/Notifications/PushAccessTokenTest.php",
        "tests/Feature/Api/V1/Notifications/NotificationsTest.php",
        "tests/Feature/Api/V1/Devices/DeviceTest.php"
    ) -FailureMessage "Focused Laravel push regression failed"

    Write-Step "Running complete Laravel regression suite"
    Invoke-Checked -FilePath "php" -Arguments @("artisan", "test") -FailureMessage "Laravel regression suite failed"
}
finally {
    Pop-Location
}

Push-Location $FlutterProjectPath
try {
    Write-Step "Resolving Flutter dependencies"
    Invoke-Checked -FilePath "flutter" -Arguments @("pub", "get") -FailureMessage "flutter pub get failed"

    Write-Step "Checking Flutter formatting"
    Invoke-Checked -FilePath "dart" -Arguments @("format", "--output=none", "--set-exit-if-changed", "lib", "test") -FailureMessage "Dart formatting check failed"

    Write-Step "Running Flutter analyzer early"
    Invoke-Checked -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Flutter analyzer failed"

    Write-Step "Running focused Flutter push + notification + deep-link tests"
    Invoke-Checked -FilePath "flutter" -Arguments @("test", "test/features/push", "test/features/notifications", "test/features/deep_links") -FailureMessage "Focused Flutter push regression failed"

    Write-Step "Running complete Flutter M1-M10P regression suite"
    Invoke-Checked -FilePath "flutter" -Arguments @("test") -FailureMessage "Flutter regression suite failed"

    Write-Step "Building Android debug APK with Firebase disabled-by-default"
    Invoke-Checked -FilePath "flutter" -Arguments @("build", "apk", "--debug") -FailureMessage "Android debug build failed"
}
finally {
    Pop-Location
}

Write-Host "`nOrbit M10P remote push delivery verification passed." -ForegroundColor Green
Write-Host "Automated verification does not replace the required physical-device Firebase delivery test." -ForegroundColor Yellow
