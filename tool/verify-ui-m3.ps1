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

Write-Step "Validating Orbit Flutter M3 installation"
$pubspec = Join-Path $ProjectPath "pubspec.yaml"
if (-not (Test-Path $pubspec)) {
    throw "Flutter project not found at $ProjectPath"
}

$pubspecContent = Get-Content $pubspec -Raw
foreach ($package in @("dio", "flutter_riverpod", "go_router", "location")) {
    if ($pubspecContent -notmatch "(?m)^\s*$([regex]::Escape($package))\s*:") {
        throw "Required package '$package' is missing from pubspec.yaml."
    }
}

$presenceRepository = Join-Path $ProjectPath "lib\features\presence\data\presence_repository.dart"
Assert-Contains $presenceRepository "v1/presence/me"
Assert-Contains $presenceRepository "v1/presence"
Assert-Contains $presenceRepository "v1/presence/settings"
Assert-Contains $presenceRepository "v1/circles/"
Assert-Contains $presenceRepository "/members/"
Assert-Contains $presenceRepository "global_ghost_mode"
Assert-Contains $presenceRepository "device_id"

$pingRepository = Join-Path $ProjectPath "lib\features\ping\data\ping_repository.dart"
Assert-Contains $pingRepository "v1/pings/inbox"
Assert-Contains $pingRepository "v1/pings/sent"
Assert-Contains $pingRepository "v1/pings"
Assert-Contains $pingRepository "/respond"
Assert-Contains $pingRepository "/dismiss"
Assert-Contains $pingRepository "recipient_membership_id"
Assert-NotContains $pingRepository "allowAuthRetry: true"

$homeRepository = Join-Path $ProjectPath "lib\features\home\data\api_home_overview_repository.dart"
Assert-Contains $homeRepository "v1/circles"
Assert-Contains $homeRepository "/presence"

$router = Join-Path $ProjectPath "lib\app\routing\app_router.dart"
Assert-Contains $router "path: '/presence'"
Assert-Contains $router "path: '/pings'"

$androidManifest = Join-Path $ProjectPath "android\app\src\main\AndroidManifest.xml"
Assert-Contains $androidManifest "android.permission.ACCESS_COARSE_LOCATION"
Assert-Contains $androidManifest "android.permission.ACCESS_FINE_LOCATION"
Assert-NotContains $androidManifest "android.permission.ACCESS_BACKGROUND_LOCATION"

$iosPlist = Join-Path $ProjectPath "ios\Runner\Info.plist"
Assert-Contains $iosPlist "NSLocationWhenInUseUsageDescription"
Assert-NotContains $iosPlist "NSLocationAlwaysUsageDescription"
Assert-NotContains $iosPlist "NSLocationAlwaysAndWhenInUseUsageDescription"
Assert-NotContains $iosPlist "<string>location</string>"

Push-Location $ProjectPath
try {
    Write-Step "Resolving Flutter dependencies"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("pub", "get") -FailureMessage "flutter pub get failed"

    Write-Step "Checking formatting"
    Invoke-CheckedNative -FilePath "dart" -Arguments @("format", "--output=none", "--set-exit-if-changed", "lib", "test") -FailureMessage "Dart formatting check failed"

    Write-Step "Running M3 Presence tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/presence") -FailureMessage "M3 Presence tests failed"

    Write-Step "Running M3 Ping tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/ping") -FailureMessage "M3 Ping tests failed"

    Write-Step "Running M3 Home tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/home") -FailureMessage "M3 Home tests failed"

    Write-Step "Running Flutter analyzer"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Flutter analyzer failed"

    Write-Step "Running complete regression suite"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test") -FailureMessage "Flutter regression suite failed"
}
finally {
    Pop-Location
}

Write-Host "`nOrbit Flutter M3 verification passed." -ForegroundColor Green
