param(
    [string]$ProjectPath = "C:\laravel-projects\orbit_app"
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n== $Message ==" -ForegroundColor Cyan
}

function Assert-Contains([string]$Path, [string]$Needle) {
    if (-not (Test-Path $Path)) {
        throw "Required file is missing: $Path"
    }
    $content = Get-Content $Path -Raw
    if ($content -notmatch [regex]::Escape($Needle)) {
        throw "Static contract check failed: '$Needle' not found in $Path"
    }
}

function Assert-NotContains([string]$Path, [string]$Needle) {
    if (-not (Test-Path $Path)) {
        throw "Required file is missing: $Path"
    }
    $content = Get-Content $Path -Raw
    if ($content -match [regex]::Escape($Needle)) {
        throw "Static safety check failed: '$Needle' must not be present in $Path"
    }
}

function Invoke-CheckedNative {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    & $FilePath @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "$FailureMessage (exit code $exitCode)."
    }
}

Write-Step "Validating Orbit Flutter M6 installation"
$pubspec = Join-Path $ProjectPath "pubspec.yaml"
if (-not (Test-Path $pubspec)) {
    throw "Flutter project not found at $ProjectPath"
}

foreach ($required in @(
    "lib\features\messaging\application\messaging_service.dart",
    "lib\features\messaging\data\device_identity_store.dart",
    "tool\verify-ui-m5.ps1",
    "docs\M5_MESSAGING_E2EE_CONTRACT.md"
)) {
    if (-not (Test-Path (Join-Path $ProjectPath $required))) {
        throw "M5 baseline file is missing: $required"
    }
}

foreach ($dependency in @("camera:", "video_player:", "path_provider:", "crypto:")) {
    Assert-Contains $pubspec $dependency
}
Assert-Contains $pubspec "flutter_secure_storage:"

$binaryClient = Join-Path $ProjectPath "lib\core\network\orbit_binary_transfer_client.dart"
Assert-Contains $binaryClient "putBytes"
Assert-Contains $binaryClient "downloadToFile"

$coreProviders = Join-Path $ProjectPath "lib\core\providers\core_providers.dart"
Assert-Contains $coreProviders "dioOrbitApiClientProvider"
Assert-Contains $coreProviders "orbitBinaryTransferClientProvider"

$mediaRemote = Join-Path $ProjectPath "lib\features\media\data\media_remote_repository.dart"
foreach ($needle in @(
    "media/uploads",
    "/chunks/",
    "/complete",
    "/key-envelope",
    "/download",
    "X-Chunk-SHA256",
    "sha256_ciphertext"
)) {
    Assert-Contains $mediaRemote $needle
}
Assert-NotContains $mediaRemote "caption"
Assert-NotContains $mediaRemote "plaintext"
Assert-Contains $mediaRemote "allowAuthRetry: false"
Assert-Contains $mediaRemote "allowAuthRetry: true"

$fileCipher = Join-Path $ProjectPath "lib\features\media\data\orbit_media_file_cipher.dart"
foreach ($needle in @("ORBITMEDIA1", "AesGcm.with256bits", "Random.secure", "sha256", "_plainChunkSize", "keyHandedOff")) {
    Assert-Contains $fileCipher $needle
}

$keyCodec = Join-Path $ProjectPath "lib\features\media\data\media_key_envelope_codec.dart"
foreach ($needle in @("X25519", "Hmac.sha256", "AesGcm.with256bits", "orbit-media-key-x25519-aesgcm-v1")) {
    Assert-Contains $keyCodec $needle
}

$mediaService = Join-Path $ProjectPath "lib\features\media\application\media_moment_service.dart"
Assert-Contains $mediaService "MEDIA_STALE_DEVICE_SET"
Assert-Contains $mediaService "identityFingerprint"
Assert-Contains $mediaService "validatePeerDevices"
Assert-Contains $mediaService "sha256File"
Assert-Contains $mediaService "localToken = _uuid.v4()"
Assert-Contains $mediaService "expectedChunks"
Assert-Contains $mediaService "fillRange"

$momentsRemote = Join-Path $ProjectPath "lib\features\moments\data\moments_repository.dart"
foreach ($needle in @(
    "/moments",
    "/view",
    "/viewers",
    "moment_id",
    "media_asset_id"
)) {
    Assert-Contains $momentsRemote $needle
}
Assert-NotContains $momentsRemote "caption"
Assert-Contains $momentsRemote "allowAuthRetry: false"

$camera = Join-Path $ProjectPath "lib\features\camera\presentation\camera_page.dart"
Assert-Contains $camera "CameraController"
Assert-Contains $camera "enableAudio: false"
Assert-Contains $camera "MomentCaptureDraft"
Assert-Contains $camera "_deleteCapture"
Assert-Contains $camera "_videoStopInProgress"

$viewer = Join-Path $ProjectPath "lib\features\moments\presentation\pages\moment_viewer_page.dart"
Assert-Contains $viewer "_disposePendingMedia"
Assert-Contains $viewer "_deleteFile"

$messagingService = Join-Path $ProjectPath "lib\features\messaging\application\messaging_service.dart"
Assert-Contains $messagingService "validatePeerDevices"

$router = Join-Path $ProjectPath "lib\app\routing\app_router.dart"
Assert-Contains $router "path: ':circleId/moments'"
Assert-Contains $router "path: '/moments/:momentId'"
Assert-Contains $router "path: 'review'"

$androidManifest = Join-Path $ProjectPath "android\app\src\main\AndroidManifest.xml"
Assert-Contains $androidManifest "android.permission.CAMERA"
Assert-NotContains $androidManifest "android.permission.RECORD_AUDIO"

$iosPlist = Join-Path $ProjectPath "ios\Runner\Info.plist"
Assert-Contains $iosPlist "NSCameraUsageDescription"
Assert-NotContains $iosPlist "NSMicrophoneUsageDescription"

$contract = Join-Path $ProjectPath "docs\M6_CAMERA_ENCRYPTED_MEDIA_MOMENTS_CONTRACT.md"
Assert-Contains $contract "Laravel never receives the plaintext media key"
Assert-Contains $contract "MEDIA_STALE_DEVICE_SET"
Assert-Contains $contract "M10"

Push-Location $ProjectPath
try {
    Write-Step "Resolving Flutter dependencies"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("pub", "get") -FailureMessage "flutter pub get failed"

    Write-Step "Checking formatting"
    Invoke-CheckedNative -FilePath "dart" -Arguments @("format", "--output=none", "--set-exit-if-changed", "lib", "test") -FailureMessage "Dart formatting check failed"

    Write-Step "Running M6 encrypted Media tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/media") -FailureMessage "M6 Media tests failed"

    Write-Step "Running M6 Moments tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/moments") -FailureMessage "M6 Moments tests failed"

    Write-Step "Running Flutter analyzer"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Flutter analyzer failed"

    Write-Step "Running complete M1-M6 regression suite"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test") -FailureMessage "Flutter regression suite failed"

    Write-Step "Building Android debug APK for native-plugin integration"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("build", "apk", "--debug") -FailureMessage "Android debug build failed"
}
finally {
    Pop-Location
}

Write-Host "`nOrbit Flutter M6 verification passed." -ForegroundColor Green
