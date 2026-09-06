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

Write-Step "Validating Orbit Flutter M9 installation"

$pubspecPath = Join-Path $ProjectPath "pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    throw "Flutter project not found at $ProjectPath"
}

foreach ($required in @(
    "lib\features\sos\presentation\widgets\sos_hold_button.dart",
    "lib\features\sos\presentation\pages\sos_activation_page.dart",
    "tool\verify-ui-m8.ps1",
    "docs\M8_SOS_SAFETY_CONTRACT.md"
)) {
    if (-not (Test-Path (Join-Path $ProjectPath $required))) {
        throw "Final M8 baseline file is missing: $required"
    }
}

$m8HoldButtonPath = Join-Path $ProjectPath "lib\features\sos\presentation\widgets\sos_hold_button.dart"
Assert-Contains $m8HoldButtonPath "Timer(_holdDuration"

$m8ActivationPagePath = Join-Path $ProjectPath "lib\features\sos\presentation\pages\sos_activation_page.dart"
Assert-Contains $m8ActivationPagePath "SingleChildScrollView"

$profileRepositoryPath = Join-Path $ProjectPath "lib\features\profile\data\profile_repository.dart"
Assert-Contains $profileRepositoryPath "v1/profile"
Assert-Contains $profileRepositoryPath "patchDataMap"
Assert-Contains $profileRepositoryPath "allowAuthRetry: true"

$profilePagePath = Join-Path $ProjectPath "lib\features\profile\presentation\profile_page.dart"
foreach ($needle in @(
    "Profile details",
    "Privacy center",
    "Security & sessions",
    "Security activity",
    "Subscription",
    "Help & support",
    "Sign out securely"
)) {
    Assert-Contains $profilePagePath $needle
}
Assert-Contains $profilePagePath "Material("
Assert-NotContains $profilePagePath "/api/admin/"

$editProfilePagePath = Join-Path $ProjectPath "lib\features\profile\presentation\pages\edit_profile_page.dart"
Assert-Contains $editProfilePagePath "Email changes are intentionally not offered"
Assert-Contains $editProfilePagePath "if (!mounted || !saved)"

$identityRepositoryPath = Join-Path $ProjectPath "lib\features\identity\data\identity_repository.dart"
foreach ($needle in @(
    "v1/me/devices",
    "v1/identity/sessions",
    "v1/identity/sessions/revoke-others",
    "v1/identity/audit-logs",
    "v1/identity/privacy",
    "v1/identity/data-exports",
    "v1/identity/account-deletion"
)) {
    Assert-Contains $identityRepositoryPath $needle
}
Assert-NotContains $identityRepositoryPath "/api/admin/"

$identityModelsPath = Join-Path $ProjectPath "lib\features\identity\domain\identity_models.dart"
Assert-Contains $identityModelsPath "class SecurityAuditEntry"
Assert-NotContains $identityModelsPath "final Map<String, Object?> metadata"
Assert-Contains $identityModelsPath "class PrivacySummary"
Assert-Contains $identityModelsPath "bool get canCancel"

$securitySessionsPagePath = Join-Path $ProjectPath "lib\features\identity\presentation\pages\security_sessions_page.dart"
Assert-Contains $securitySessionsPagePath "session.id == currentSessionId"
Assert-Contains $securitySessionsPagePath "Revoke others"
Assert-Contains $securitySessionsPagePath "Material("
Assert-NotContains $securitySessionsPagePath "accessToken"
Assert-NotContains $securitySessionsPagePath "refreshToken"

$securityActivityPagePath = Join-Path $ProjectPath "lib\features\identity\presentation\pages\security_activity_page.dart"
Assert-Contains $securityActivityPagePath "Server audit metadata is not rendered"
Assert-NotContains $securityActivityPagePath "entry.metadata"

$privacyCenterPagePath = Join-Path $ProjectPath "lib\features\identity\presentation\pages\privacy_center_page.dart"
foreach ($needle in @(
    "Privacy snapshot",
    "Data export",
    "Account deletion",
    "Type DELETE to confirm",
    "30-day reversible grace period",
    "does not expose a dedicated download endpoint"
)) {
    Assert-Contains $privacyCenterPagePath $needle
}
Assert-Contains $privacyCenterPagePath "Material("
Assert-NotContains $privacyCenterPagePath "export.payload"

$subscriptionRepositoryPath = Join-Path $ProjectPath "lib\features\subscription\data\subscription_repository.dart"
Assert-Contains $subscriptionRepositoryPath "v1/me/subscription"
Assert-NotContains $subscriptionRepositoryPath "checkout"
Assert-NotContains $subscriptionRepositoryPath "change-plan"
Assert-NotContains $subscriptionRepositoryPath "/api/admin/"

$subscriptionPagePath = Join-Path $ProjectPath "lib\features\subscription\presentation\subscription_page.dart"
Assert-Contains $subscriptionPagePath "current consumer API is read-only"
Assert-Contains $subscriptionPagePath "Entitlements"
Assert-NotContains $subscriptionPagePath "CVV"
Assert-NotContains $subscriptionPagePath "card_number"

$supportRepositoryPath = Join-Path $ProjectPath "lib\features\support\data\support_repository.dart"
Assert-Contains $supportRepositoryPath "v1/content/support"
Assert-Contains $supportRepositoryPath "error.statusCode == 404"
Assert-NotContains $supportRepositoryPath "/api/admin/"
Assert-NotContains $supportRepositoryPath "support/tickets"

$supportPagePath = Join-Path $ProjectPath "lib\features\support\presentation\support_page.dart"
Assert-Contains $supportPagePath "does not expose support-ticket creation"
Assert-Contains $supportPagePath "Material("
Assert-NotContains $supportPagePath "ticket submitted"

$routerPath = Join-Path $ProjectPath "lib\app\routing\app_router.dart"
foreach ($needle in @(
    "path: '/security/sessions'",
    "path: '/security/activity'",
    "path: '/privacy'",
    "path: '/profile/edit'",
    "path: '/subscription'",
    "path: '/support'",
    "SecuritySessionsPage",
    "SecurityActivityPage",
    "PrivacyCenterPage",
    "EditProfilePage",
    "SubscriptionPage",
    "SupportPage"
)) {
    Assert-Contains $routerPath $needle
}

$contractPath = Join-Path $ProjectPath "docs\M9_PROFILE_IDENTITY_PRIVACY_SUPPORT_SUBSCRIPTION_CONTRACT.md"
foreach ($needle in @(
    "Laravel remains authoritative",
    "30-day reversible grace period",
    "M10",
    "M11",
    "does not invent consumer mutations"
)) {
    Assert-Contains $contractPath $needle
}

$screenManifestPath = Join-Path $ProjectPath "docs\M9_SCREEN_MANIFEST.md"
Assert-Contains $screenManifestPath "/security/sessions"
Assert-Contains $screenManifestPath "/privacy"
Assert-Contains $screenManifestPath "/subscription"
Assert-Contains $screenManifestPath "/support"

Push-Location $ProjectPath
try {
    Write-Step "Resolving Flutter dependencies"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("pub", "get") -FailureMessage "flutter pub get failed"

    Write-Step "Checking formatting"
    Invoke-CheckedNative -FilePath "dart" -Arguments @("format", "--output=none", "--set-exit-if-changed", "lib", "test") -FailureMessage "Dart formatting check failed"

    Write-Step "Running Flutter analyzer first"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Flutter analyzer failed"

    Write-Step "Running M9 Profile tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/profile") -FailureMessage "M9 Profile tests failed"

    Write-Step "Running M9 Identity and Privacy tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/identity") -FailureMessage "M9 Identity/Privacy tests failed"

    Write-Step "Running M9 Subscription tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/subscription") -FailureMessage "M9 Subscription tests failed"

    Write-Step "Running M9 Support tests"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/support") -FailureMessage "M9 Support tests failed"

    Write-Step "Running M8 SOS safety regression"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/sos") -FailureMessage "M8 SOS regression tests failed"

    Write-Step "Running complete M1-M9 regression suite"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("test") -FailureMessage "Flutter regression suite failed"

    Write-Step "Building Android debug APK"
    Invoke-CheckedNative -FilePath "flutter" -Arguments @("build", "apk", "--debug") -FailureMessage "Android debug build failed"
}
finally {
    Pop-Location
}

Write-Host "`nOrbit Flutter M9 verification passed." -ForegroundColor Green
