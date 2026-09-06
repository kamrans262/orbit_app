param(
    [string]$ProjectPath = "C:\laravel-projects\orbit_app",
    [string]$BackendPath = "C:\laravel-projects\orbit_api"
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n== $Message ==" -ForegroundColor Cyan
}

function Assert-Contains([string]$Path, [string]$Needle) {
    if (-not (Test-Path $Path)) { throw "Required file is missing: $Path" }
    if ((Get-Content $Path -Raw) -notmatch [regex]::Escape($Needle)) {
        throw "Static contract check failed: '$Needle' not found in $Path"
    }
}

function Assert-NotContains([string]$Path, [string]$Needle) {
    if (-not (Test-Path $Path)) { throw "Required file is missing: $Path" }
    if ((Get-Content $Path -Raw) -match [regex]::Escape($Needle)) {
        throw "Static safety check failed: '$Needle' must not be present in $Path"
    }
}

function Assert-Matches([string]$Path, [string]$Pattern, [string]$Description) {
    if (-not (Test-Path $Path)) { throw "Required file is missing: $Path" }
    if ((Get-Content $Path -Raw) -notmatch $Pattern) {
        throw "Static contract check failed: $Description in $Path"
    }
}

function Invoke-CheckedNative {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$FailureMessage (exit code $LASTEXITCODE)." }
}

Write-Step "Validating M10 installation and M9 baseline"
if (-not (Test-Path (Join-Path $ProjectPath "pubspec.yaml"))) {
    throw "Flutter project not found at $ProjectPath"
}
foreach ($relative in @(
    "tool\verify-ui-m9.ps1",
    "docs\M9_PROFILE_IDENTITY_PRIVACY_SUPPORT_SUBSCRIPTION_CONTRACT.md",
    "lib\features\sos\presentation\widgets\sos_hold_button.dart",
    "lib\features\notifications\domain\orbit_notification.dart"
)) {
    if (-not (Test-Path (Join-Path $ProjectPath $relative))) {
        throw "Final M9 baseline file is missing: $relative"
    }
}
Assert-Contains (Join-Path $ProjectPath "lib\features\sos\presentation\widgets\sos_hold_button.dart") "Timer(_holdDuration"
Assert-Contains (Join-Path $ProjectPath "lib\features\notifications\domain\orbit_notification.dart") "String? get internalRoute"

Write-Step "Validating Laravel M10 contracts read-only"
if (-not (Test-Path (Join-Path $BackendPath "composer.json"))) {
    throw "Laravel backend not found at $BackendPath"
}
Assert-Contains (Join-Path $BackendPath "composer.json") "laravel/reverb"
Assert-Contains (Join-Path $BackendPath "bootstrap\app.php") "withBroadcasting"
Assert-Contains (Join-Path $BackendPath "bootstrap\app.php") "auth:sanctum"
Assert-Contains (Join-Path $BackendPath "routes\channels.php") "users.{userId}"
Assert-Contains (Join-Path $BackendPath "routes\channels.php") "circles.{circleId}"
Assert-Contains (Join-Path $BackendPath "routes\channels.php") "devices.{deviceId}"
Assert-Contains (Join-Path $BackendPath "routes\channels_notifications.php") "orbit.user.{userId}"
Assert-Contains (Join-Path $BackendPath "routes\channels_sos.php") "orbit.circle.{circleId}"
Assert-Contains (Join-Path $BackendPath "routes\channels_sos.php") "orbit.sos.{sosId}"
Assert-Contains (Join-Path $BackendPath "app\Modules\Realtime\Broadcasts\MessageEnvelopeAvailableBroadcast.php") "EncryptedEnvelopeRealtimePayload"
Assert-Contains (Join-Path $BackendPath "app\Modules\Realtime\Broadcasts\MessageEnvelopeAvailableBroadcast.php") "devices."
Assert-Contains (Join-Path $BackendPath "app\Modules\Realtime\Broadcasts\MessageDeliveredBroadcast.php") "message.delivered"
Assert-Contains (Join-Path $BackendPath "app\Modules\Realtime\Broadcasts\TypingIndicatorBroadcast.php") "typing.updated"
Assert-Contains (Join-Path $BackendPath "app\Modules\Realtime\Broadcasts\CirclePresenceUpdatedBroadcast.php") "presence.updated"
Assert-Contains (Join-Path $BackendPath "app\Modules\Devices\Http\Requests\RegisterDeviceRequest.php") "push_token"
Assert-Contains (Join-Path $BackendPath "app\Modules\Notifications\Actions\RouteNotificationAction.php") "pending_provider"
Assert-Contains (Join-Path $BackendPath "setup\notifications\README.md") "provider-neutral boundary"
Assert-Contains (Join-Path $BackendPath "database\migrations\2026_09_02_000021_create_sos_events_table.php") "uuid('id')"
Assert-Contains (Join-Path $BackendPath "database\migrations\2026_09_01_000019_create_moments_table.php") "uuid('id')"
Assert-Contains (Join-Path $BackendPath "database\migrations\2026_09_01_000010_create_pings_table.php") "uuid('id')"
Assert-Contains (Join-Path $BackendPath "database\migrations\2026_09_01_000005_create_circles_table.php") "uuid('id')"

Write-Step "Validating M10 realtime and E2EE safety"
$reverbClient = Join-Path $ProjectPath "lib\features\realtime\data\reverb_realtime_client.dart"
foreach ($needle in @(
    "WebSocketChannel.connect",
    "pusher:connection_established",
    "pusher:subscribe",
    "authorizePrivateChannel",
    "orbit.sos.",
    "_scheduleReconnect"
)) { Assert-Contains $reverbClient $needle }
Assert-NotContains $reverbClient "accessToken"
Assert-NotContains $reverbClient "refreshToken"
Assert-NotContains $reverbClient "ciphertext']"

$broadcastClient = Join-Path $ProjectPath "lib\core\network\dio_orbit_api_client.dart"
Assert-Contains $broadcastClient "path: 'broadcasting/auth'"
Assert-Contains $broadcastClient "allowAuthRetry: true"
Assert-Contains $broadcastClient "OrbitBroadcastAuthorization"

$bridge = Join-Path $ProjectPath "lib\features\realtime\presentation\orbit_realtime_bridge.dart"
foreach ($needle in @(
    'devices.${session.deviceId}',
    'orbit.user.$userId',
    'circles.${circle.id}',
    'orbit.circle.${circle.id}',
    "message.received",
    "message.delivered",
    "applyDeliveryReceipt",
    "_lastIngressKey",
    "presence.updated",
    "notification.created",
    "sos.location.updated",
    "durable inbox remains the"
)) { Assert-Contains $bridge $needle }
Assert-NotContains $bridge "plaintext"
Assert-NotContains $bridge "event.data['ciphertext']"

Write-Step "Validating push lifecycle does not erase E2EE identity"
$pushService = Join-Path $ProjectPath "lib\features\push\data\device_push_registration_service.dart"
Assert-Contains $pushService "public_identity_key"
Assert-Contains $pushService "identity.publicIdentity.toServerValue()"
Assert-Contains $pushService "'push_token': token?.value"
Assert-Contains $pushService "Future<void> unregister()"
Assert-Contains $pushService "_identityStore.read(session.deviceId)"
Assert-NotContains $pushService "print("
Assert-NotContains $pushService "debugPrint"

$pushTokenStore = Join-Path $ProjectPath "lib\features\push\data\push_token_store.dart"
Assert-Contains $pushTokenStore "flutter_secure_storage"
Assert-Contains $pushTokenStore "orbit.push.token.v1"

$messagingRemote = Join-Path $ProjectPath "lib\features\messaging\data\messaging_remote_repository.dart"
Assert-Contains $messagingRemote "final pushToken = await _pushTokenStore?.read()"
Assert-Contains $messagingRemote "'push_token': pushToken"

$deviceIdentityStore = Join-Path $ProjectPath "lib\features\messaging\data\device_identity_store.dart"
Assert-Contains $deviceIdentityStore "Future<DevicePrivateIdentity?> read(String serverDeviceId)"

$messageLocalStore = Join-Path $ProjectPath "lib\features\messaging\data\message_local_store.dart"
Assert-Contains $messageLocalStore "status != LocalMessageStatus.delivered"
Assert-Contains $messageLocalStore "status != ?"

$authController = Join-Path $ProjectPath "lib\features\auth\presentation\auth_controller.dart"
Assert-Contains $authController "devicePushRegistrationServiceProvider"
Assert-Contains $authController ".unregister()"

$pushSource = Join-Path $ProjectPath "lib\features\push\domain\push_token_source.dart"
Assert-Contains $pushSource "UnavailablePushTokenSource"
Assert-Contains $pushSource "bool get isAvailable => false"
Assert-Contains $pushSource "must not fabricate a"

Write-Step "Validating allowlisted deep links and native registrations"
$resolver = Join-Path $ProjectPath "lib\features\deep_links\domain\orbit_deep_link_resolver.dart"
foreach ($needle in @(
    "uri.scheme.toLowerCase() != 'orbit'",
    "case 'circles':",
    "case 'moments':",
    "case 'pings':",
    "case 'sos':",
    "_isUuid",
    "[0-9A-Fa-f]{8}",
    "return null"
)) { Assert-Contains $resolver $needle }
Assert-NotContains $resolver "uri.toString()"
Assert-NotContains $resolver "^[A-Za-z0-9_-]+$"

$androidManifest = Join-Path $ProjectPath "android\app\src\main\AndroidManifest.xml"
if (Test-Path $androidManifest) {
    Assert-Contains $androidManifest 'android:scheme="orbit"'
    Assert-Matches $androidManifest '(?s)<meta-data\b(?=[^>]*android:name="flutter_deeplinking_enabled")(?=[^>]*android:value="false")[^>]*/>' "flutter_deeplinking_enabled must be false"
}
$iOSPlist = Join-Path $ProjectPath "ios\Runner\Info.plist"
if (Test-Path $iOSPlist) {
    Assert-Matches $iOSPlist '(?s)<key>FlutterDeepLinkingEnabled</key>\s*<false\s*/>' "FlutterDeepLinkingEnabled must be false"
    Assert-Contains $iOSPlist "<string>orbit</string>"
}

Write-Step "Validating SOS realtime remains server-authorized with polling fallback"
$sosPage = Join-Path $ProjectPath "lib\features\sos\presentation\pages\sos_incident_page.dart"
Assert-Contains $sosPage "Timer.periodic(const Duration(seconds: 15)"
Assert-Contains $sosPage "watchSos(widget.sosId)"
Assert-Contains $sosPage "retrySos(widget.sosId)"
Assert-Contains $sosPage "Laravel confirmed engagement"

Write-Step "Validating messaging typing UI is ephemeral"
$messagePage = Join-Path $ProjectPath "lib\features\messaging\presentation\pages\circle_messages_page.dart"
Assert-Contains $messagePage "realtimeTypingProvider"
Assert-Contains $messagePage "realtimeActiveConversationProvider"
Assert-Contains $messagePage "Someone is typing…"
Assert-Contains $messagePage "End-to-end encrypted"

Write-Step "Validating M10 docs"
$contract = Join-Path $ProjectPath "docs\M10_REALTIME_PUSH_DEEP_LINKS_CONTRACT.md"
foreach ($needle in @(
    "Laravel Reverb",
    "E2EE",
    "Presence remains server-authoritative",
    "provider-neutral",
    "message.delivered",
    "unregister",
    "orbit://circles/{circleId}/chat",
    "polling fallback",
    "M11"
)) { Assert-Contains $contract $needle }
Assert-Contains (Join-Path $ProjectPath "docs\M10_SCREEN_MANIFEST.md") "No new route-level screens"

Push-Location $ProjectPath
try {
    Write-Step "Resolving Flutter dependencies"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("pub", "get") -FailureMessage "flutter pub get failed"

    Write-Step "Checking formatting"
    Invoke-CheckedNative -FilePath "dart" -Arguments @("format", "--output=none", "--set-exit-if-changed", "lib", "test") -FailureMessage "Dart formatting check failed"

    Write-Step "Checking installer staging hygiene"
    if (Test-Path (Join-Path $ProjectPath "overlay")) {
        throw "M10 staging overlay leaked into the Flutter project. Re-run the repaired M10 installer before verification."
    }

    Write-Step "Running Flutter analyzer first"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Flutter analyzer failed"

    Write-Step "Running M10 realtime, push and deep-link tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/realtime", "test/features/push", "test/features/deep_links") -FailureMessage "M10 tests failed"

    Write-Step "Running M5 messaging/E2EE regression"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/messaging") -FailureMessage "Messaging regression tests failed"

    Write-Step "Running Presence and Ping regression"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/presence", "test/features/ping") -FailureMessage "Presence/Ping regression tests failed"

    Write-Step "Running M7 notifications regression"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/notifications") -FailureMessage "Notification regression tests failed"

    Write-Step "Running Moments and Activity regression"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/moments", "test/features/activity") -FailureMessage "Moments/Activity regression tests failed"

    Write-Step "Running M8 SOS safety regression"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/sos") -FailureMessage "SOS regression tests failed"

    Write-Step "Running complete M1-M10 regression suite"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test") -FailureMessage "Flutter regression suite failed"

    Write-Step "Building Android debug APK"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("build", "apk", "--debug") -FailureMessage "Android debug build failed"
}
finally {
    Pop-Location
}

Write-Host "`nOrbit Flutter M10 verification passed." -ForegroundColor Green
