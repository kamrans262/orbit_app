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

Write-Step "Validating Orbit Flutter M5 installation"
$pubspec = Join-Path $ProjectPath "pubspec.yaml"
if (-not (Test-Path $pubspec)) {
    throw "Flutter project not found at $ProjectPath"
}

foreach ($required in @(
    "lib\features\circles\data\circles_repository.dart",
    "lib\features\presence\data\presence_repository.dart",
    "tool\verify-ui-m4.ps1"
)) {
    if (-not (Test-Path (Join-Path $ProjectPath $required))) {
        throw "M4 baseline file is missing: $required"
    }
}

Assert-Contains $pubspec "cryptography:"
Assert-Contains $pubspec "sqflite:"
Assert-Contains $pubspec "path:"

$remote = Join-Path $ProjectPath "lib\features\messaging\data\messaging_remote_repository.dart"
foreach ($needle in @(
    "v1/devices",
    "v1/messaging/settings",
    "message-devices",
    "/messages",
    "message-envelopes/",
    "/delivered",
    "/read",
    "/typing"
)) {
    Assert-Contains $remote $needle
}
Assert-NotContains $remote "plaintext"

$codec = Join-Path $ProjectPath "lib\features\messaging\data\orbit_e2ee_codec.dart"
foreach ($needle in @(
    "X25519",
    "Ed25519",
    "AesGcm.with256bits",
    "Hmac.sha256",
    "orbit-e2ee-v1"
)) {
    Assert-Contains $codec $needle
}

$identityStore = Join-Path $ProjectPath "lib\features\messaging\data\device_identity_store.dart"
Assert-Contains $identityStore "FlutterSecureStorage"
Assert-Contains $identityStore "kx_private"
Assert-Contains $identityStore "sig_private"

$localStore = Join-Path $ProjectPath "lib\features\messaging\data\message_local_store.dart"
Assert-Contains $localStore "encrypted_body"
Assert-Contains $localStore "orbit.messaging.local_database_key.v1"
Assert-NotContains $localStore "plaintext_body"

$service = Join-Path $ProjectPath "lib\features\messaging\application\messaging_service.dart"
Assert-Contains $service "MESSAGING_RECIPIENT_DEVICES_CHANGED"
Assert-Contains $service "acknowledgeDelivery"
Assert-Contains $service "saveMessage"

$router = Join-Path $ProjectPath "lib\app\routing\app_router.dart"
Assert-Contains $router "path: ':circleId/messages'"
Assert-Contains $router "path: '/security/messaging'"

$contract = Join-Path $ProjectPath "docs\M5_MESSAGING_E2EE_CONTRACT.md"
Assert-Contains $contract "Private keys are persisted"
Assert-Contains $contract "M6"
Assert-Contains $contract "M10"

Push-Location $ProjectPath
try {
    Write-Step "Resolving Flutter dependencies"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("pub", "get") -FailureMessage "flutter pub get failed"

    Write-Step "Checking formatting"
    Invoke-CheckedNative -FilePath "dart" -Arguments @("format", "--output=none", "--set-exit-if-changed", "lib", "test") -FailureMessage "Dart formatting check failed"

    Write-Step "Running M5 Messaging + E2EE tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/messaging") -FailureMessage "M5 Messaging tests failed"

    Write-Step "Running Flutter analyzer"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Flutter analyzer failed"

    Write-Step "Running complete M1-M5 regression suite"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test") -FailureMessage "Flutter regression suite failed"
}
finally {
    Pop-Location
}

Write-Host "`nOrbit Flutter M5 verification passed." -ForegroundColor Green
