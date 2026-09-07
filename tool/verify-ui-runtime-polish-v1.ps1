param(
    [Parameter(Mandatory = $false)]
    [string]$FlutterProjectPath = "C:\laravel-projects\orbit_app"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step([string]$Message) {
    Write-Host "`n== $Message ==" -ForegroundColor Cyan
}

function Require-Contains([string]$Path, [string]$Needle) {
    $text = Get-Content $Path -Raw
    if (-not $text.Contains($Needle)) {
        throw "Required contract '$Needle' is missing from $Path"
    }
}

function Require-Absent([string]$Path, [string]$Needle) {
    $text = Get-Content $Path -Raw
    if ($text.Contains($Needle)) {
        throw "Forbidden/regressed contract '$Needle' exists in $Path"
    }
}

function Invoke-CheckedNative {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $false)][string[]]$Arguments = @(),
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$FailureMessage (exit code $LASTEXITCODE)." }
}

Set-Location $FlutterProjectPath

$profile = Join-Path $FlutterProjectPath "lib\features\profile\presentation\pages\edit_profile_page.dart"
$notifications = Join-Path $FlutterProjectPath "lib\features\notifications\presentation\pages\notification_preferences_page.dart"
$header = Join-Path $FlutterProjectPath "lib\features\home\presentation\widgets\home_header.dart"
$quick = Join-Path $FlutterProjectPath "lib\features\home\presentation\widgets\quick_actions.dart"
$sos = Join-Path $FlutterProjectPath "lib\features\home\presentation\widgets\sos_floating_action.dart"
$camera = Join-Path $FlutterProjectPath "lib\features\camera\presentation\camera_page.dart"
$contractTest = Join-Path $FlutterProjectPath "test\features\ui_polish\ui_polish_source_contract_test.dart"

Write-Step "Validating UI runtime source contracts"
Require-Contains $profile "return Scaffold("
Require-Contains $notifications "return Scaffold("
Require-Absent $header "Safer people"
Require-Absent $header "brighter tomorrows"
Require-Absent $header "favorite_border_rounded"
Require-Contains $quick "scrollDirection: Axis.horizontal"
Require-Contains $quick "const visibleCardCount = 3;"
Require-Contains $quick "title: 'Circle'"
Require-Contains $quick "title: 'Location'"
Require-Contains $sos "Icons.emergency_rounded"
Require-Absent $sos "Icons.sos_rounded"
Require-Contains $camera "class _CameraPreviewSurface"
Require-Contains $camera "fit: BoxFit.cover"
Require-Contains $camera "controller.buildPreview()"
if (-not (Test-Path $contractTest)) { throw "UI polish contract test is missing." }

$dartFiles = @(
    "lib\features\profile\presentation\pages\edit_profile_page.dart",
    "lib\features\notifications\presentation\pages\notification_preferences_page.dart",
    "lib\features\home\presentation\widgets\home_header.dart",
    "lib\features\home\presentation\widgets\quick_actions.dart",
    "lib\features\home\presentation\widgets\sos_floating_action.dart",
    "lib\features\camera\presentation\camera_page.dart",
    "test\features\ui_polish\ui_polish_source_contract_test.dart"
)

Write-Step "Checking Dart formatting"
Invoke-CheckedNative -FilePath "dart" -Arguments (@("format", "--output=none", "--set-exit-if-changed") + $dartFiles) -FailureMessage "Dart format check failed"

Write-Step "Running Flutter analyzer"
Invoke-CheckedNative -FilePath "flutter" -Arguments @("analyze") -FailureMessage "Flutter analyzer failed"

Write-Step "Running focused UI polish test"
Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", "test/features/ui_polish/ui_polish_source_contract_test.dart") -FailureMessage "UI polish source contract test failed"

$focused = @(
    "test/features/home/home_page_test.dart",
    "test/features/notifications/notifications_page_test.dart"
)
foreach ($testPath in $focused) {
    if (Test-Path (Join-Path $FlutterProjectPath $testPath)) {
        Write-Step "Running $testPath"
        Invoke-CheckedNative -FilePath "flutter" -Arguments @("test", $testPath) -FailureMessage "Focused regression failed: $testPath"
    }
}

Write-Step "Running complete Flutter regression suite"
Invoke-CheckedNative -FilePath "flutter" -Arguments @("test") -FailureMessage "Complete Flutter regression suite failed"

Write-Step "Building Android debug APK"
Invoke-CheckedNative -FilePath "flutter" -Arguments @("build", "apk", "--debug") -FailureMessage "Android debug APK build failed"

Write-Host "`nOrbit Flutter UI Runtime Polish v1 verification passed." -ForegroundColor Green
Write-Host "Automated verification cannot judge physical camera geometry; verify the camera preview on the target phone." -ForegroundColor Yellow
