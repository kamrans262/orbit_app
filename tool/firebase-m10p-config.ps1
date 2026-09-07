param(
    [string]$AndroidConfigPath = "$HOME\Downloads\google-services.json",
    [string]$IosConfigPath = "$HOME\Downloads\GoogleService-Info.plist"
)

$ErrorActionPreference = "Stop"

function Quote-Define([string]$Name, [string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    return "--dart-define=$Name=$Value"
}

Write-Host "`nOrbit M10P Firebase Dart defines" -ForegroundColor Cyan

if (Test-Path $AndroidConfigPath) {
    $json = Get-Content $AndroidConfigPath -Raw | ConvertFrom-Json
    $client = @($json.client)[0]
    $projectId = [string]$json.project_info.project_id
    $senderId = [string]$json.project_info.project_number
    $apiKey = [string](@($client.api_key)[0].current_key)
    $appId = [string]$client.client_info.mobilesdk_app_id

    Write-Host "`nAndroid:" -ForegroundColor Green
    @(
        Quote-Define "ORBIT_FIREBASE_ENABLED" "true"
        Quote-Define "ORBIT_FIREBASE_PROJECT_ID" $projectId
        Quote-Define "ORBIT_FIREBASE_MESSAGING_SENDER_ID" $senderId
        Quote-Define "ORBIT_FIREBASE_ANDROID_API_KEY" $apiKey
        Quote-Define "ORBIT_FIREBASE_ANDROID_APP_ID" $appId
    ) | Where-Object { $_ } | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "Android config not found: $AndroidConfigPath" -ForegroundColor Yellow
}

if (Test-Path $IosConfigPath) {
    [xml]$plist = Get-Content $IosConfigPath -Raw
    $dict = $plist.plist.dict
    $values = @{}
    for ($i = 0; $i -lt $dict.ChildNodes.Count; $i++) {
        if ($dict.ChildNodes[$i].Name -ne 'key') { continue }
        $key = [string]$dict.ChildNodes[$i].InnerText
        if ($i + 1 -lt $dict.ChildNodes.Count) {
            $values[$key] = [string]$dict.ChildNodes[$i + 1].InnerText
        }
    }

    Write-Host "`niOS:" -ForegroundColor Green
    @(
        Quote-Define "ORBIT_FIREBASE_ENABLED" "true"
        Quote-Define "ORBIT_FIREBASE_PROJECT_ID" $values['PROJECT_ID']
        Quote-Define "ORBIT_FIREBASE_MESSAGING_SENDER_ID" $values['GCM_SENDER_ID']
        Quote-Define "ORBIT_FIREBASE_IOS_API_KEY" $values['API_KEY']
        Quote-Define "ORBIT_FIREBASE_IOS_APP_ID" $values['GOOGLE_APP_ID']
        Quote-Define "ORBIT_FIREBASE_IOS_BUNDLE_ID" $values['BUNDLE_ID']
    ) | Where-Object { $_ } | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "iOS config not found: $IosConfigPath" -ForegroundColor Yellow
}

Write-Host "`nThese are client configuration values. Never put a Firebase service-account private key in Flutter." -ForegroundColor DarkGray
