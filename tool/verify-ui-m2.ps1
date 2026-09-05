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

Write-Step "Validating Orbit Flutter M2 installation"
$pubspec = Join-Path $ProjectPath "pubspec.yaml"
if (-not (Test-Path $pubspec)) {
    throw "Flutter project not found at $ProjectPath"
}

$requiredPackages = @(
    "dio",
    "flutter_riverpod",
    "go_router",
    "flutter_secure_storage",
    "device_info_plus",
    "package_info_plus",
    "uuid"
)
$pubspecContent = Get-Content $pubspec -Raw
foreach ($package in $requiredPackages) {
    if ($pubspecContent -notmatch "(?m)^\s*$([regex]::Escape($package))\s*:") {
        throw "Required package '$package' is missing from pubspec.yaml."
    }
}

$authRepository = Join-Path $ProjectPath "lib\features\auth\data\auth_repository.dart"
Assert-Contains $authRepository "v1/auth/email-otp/request"
Assert-Contains $authRepository "v1/auth/email-otp/verify"
Assert-Contains $authRepository "v1/devices"
Assert-Contains $authRepository "v1/identity/sessions"
Assert-Contains $authRepository "v1/identity/logout"
Assert-Contains $authRepository "v1/identity/device-approvals"
Assert-Contains $authRepository "approver_device_id"

$refreshCoordinator = Join-Path $ProjectPath "lib\core\network\session_refresh_coordinator.dart"
Assert-Contains $refreshCoordinator "v1/auth/refresh"
Assert-Contains $refreshCoordinator "refresh_token"
Assert-Contains $refreshCoordinator "device_id"

$debugManifest = Join-Path $ProjectPath "android\app\src\debug\AndroidManifest.xml"
Assert-Contains $debugManifest "usesCleartextTraffic"

Push-Location $ProjectPath
try {
    Write-Step "Resolving Flutter dependencies"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("pub", "get") -FailureMessage "flutter pub get failed"

    Write-Step "Checking formatting"
    Invoke-CheckedNative -FilePath "dart" -Arguments @("format", "--output=none", "--set-exit-if-changed", "lib", "test") -FailureMessage "Dart formatting check failed"

    Write-Step "Running M2 authentication tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/auth") -FailureMessage "M2 authentication tests failed"

    Write-Step "Running Flutter analyzer"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Flutter analyzer failed"

    Write-Step "Running complete regression suite"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test") -FailureMessage "Flutter regression suite failed"
}
finally {
    Pop-Location
}

Write-Host "`nOrbit Flutter M2 verification passed." -ForegroundColor Green
