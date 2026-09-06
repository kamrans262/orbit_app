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

Write-Step "Validating Orbit Flutter M4 installation"
$pubspec = Join-Path $ProjectPath "pubspec.yaml"
if (-not (Test-Path $pubspec)) {
    throw "Flutter project not found at $ProjectPath"
}

foreach ($required in @(
    "lib\features\presence\data\presence_repository.dart",
    "lib\features\ping\data\ping_repository.dart",
    "tool\verify-ui-m3.ps1"
)) {
    if (-not (Test-Path (Join-Path $ProjectPath $required))) {
        throw "M3 baseline file is missing: $required"
    }
}

$repository = Join-Path $ProjectPath "lib\features\circles\data\circles_repository.dart"
foreach ($needle in @(
    "v1/circles",
    "v1/circles/join",
    "/invites",
    "/members",
    "/leave"
)) {
    Assert-Contains $repository $needle
}
Assert-NotContains $repository "allowAuthRetry: true"

$domain = Join-Path $ProjectPath "lib\features\circles\domain\orbit_circle.dart"
foreach ($needle in @("owner", "admin", "member", "restricted", "standard", "temporary")) {
    Assert-Contains $domain $needle
}

$permissions = Join-Path $ProjectPath "lib\features\circles\domain\circle_permissions.dart"
Assert-Contains $permissions "target.role == CircleRole.owner"
Assert-Contains $permissions "circle.myRole == CircleRole.admin"

$router = Join-Path $ProjectPath "lib\app\routing\app_router.dart"
foreach ($needle in @(
    "path: 'create'",
    "path: 'join'",
    "path: ':circleId'",
    "path: ':circleId/members'",
    "path: ':circleId/invite'",
    "path: ':circleId/settings'"
)) {
    Assert-Contains $router $needle
}

$contract = Join-Path $ProjectPath "docs\M4_CIRCLES_CONTRACT.md"
Assert-Contains $contract "does not expose an ownership-transfer route"

Push-Location $ProjectPath
try {
    Write-Step "Resolving Flutter dependencies"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("pub", "get") -FailureMessage "flutter pub get failed"

    Write-Step "Checking formatting"
    Invoke-CheckedNative -FilePath "dart" -Arguments @("format", "--output=none", "--set-exit-if-changed", "lib", "test") -FailureMessage "Dart formatting check failed"

    Write-Step "Running M4 Circles tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/circles") -FailureMessage "M4 Circles tests failed"

    Write-Step "Running Flutter analyzer"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Flutter analyzer failed"

    Write-Step "Running complete M1-M4 regression suite"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test") -FailureMessage "Flutter regression suite failed"
}
finally {
    Pop-Location
}

Write-Host "`nOrbit Flutter M4 verification passed." -ForegroundColor Green
