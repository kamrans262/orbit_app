param(
    [string]$ProjectPath = "C:\laravel-projects\orbit_app"
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n== $Message ==" -ForegroundColor Cyan
}

Write-Step "Configuring Android Orbit deep links"
$androidManifest = Join-Path $ProjectPath "android\app\src\main\AndroidManifest.xml"
if (Test-Path $androidManifest) {
    $content = Get-Content $androidManifest -Raw

    $deepLinkMetaPattern = '(?s)(<meta-data\b(?=[^>]*android:name="flutter_deeplinking_enabled")[^>]*android:value=")(?:true|false)("[^>]*/>)'
    if ($content -match 'android:name="flutter_deeplinking_enabled"') {
        if ($content -notmatch $deepLinkMetaPattern) {
            throw "Existing flutter_deeplinking_enabled metadata is malformed in $androidManifest"
        }
        $content = [regex]::Replace($content, $deepLinkMetaPattern, '${1}false${2}', 1)
    }
    else {
        $activityPattern = '(?s)(<activity\b[^>]*android:name="\.MainActivity"[^>]*>)'
        if ($content -notmatch $activityPattern) {
            throw "MainActivity was not found in $androidManifest"
        }
        $metadata = @'

            <!-- Orbit M10: app_links owns custom deep-link dispatch. -->
            <meta-data
                android:name="flutter_deeplinking_enabled"
                android:value="false" />
'@
        $content = [regex]::Replace(
            $content,
            $activityPattern,
            { param($match) $match.Groups[1].Value + $metadata },
            1
        )
    }

    if ($content -notmatch 'android:scheme="orbit"') {
        $activityPattern = '(?s)(<activity\b[^>]*android:name="\.MainActivity"[^>]*>)(.*?)(</activity>)'
        $intent = @'

            <!-- Orbit M10: backend-defined orbit:// deep links only. -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="orbit" />
            </intent-filter>
'@
        if ($content -notmatch $activityPattern) {
            throw "Could not patch MainActivity deep links in $androidManifest"
        }
        $content = [regex]::Replace(
            $content,
            $activityPattern,
            { param($match) $match.Groups[1].Value + $match.Groups[2].Value + $intent + $match.Groups[3].Value },
            1
        )
    }

    Set-Content -Path $androidManifest -Value $content -Encoding UTF8
}
else {
    Write-Host "Android manifest not found; Android native configuration skipped." -ForegroundColor Yellow
}

Write-Step "Configuring iOS Orbit deep links"
$infoPlist = Join-Path $ProjectPath "ios\Runner\Info.plist"
if (Test-Path $infoPlist) {
    $content = Get-Content $infoPlist -Raw

    $deepLinkKeyPattern = '(?s)(<key>FlutterDeepLinkingEnabled</key>\s*)<(?:true|false)\s*/>'
    if ($content -match '<key>FlutterDeepLinkingEnabled</key>') {
        if ($content -notmatch $deepLinkKeyPattern) {
            throw "Existing FlutterDeepLinkingEnabled entry is malformed in $infoPlist"
        }
        $content = [regex]::Replace($content, $deepLinkKeyPattern, '${1}<false/>', 1)
    }
    else {
        $rootClose = $content.LastIndexOf('</dict>')
        if ($rootClose -lt 0) {
            throw "Invalid iOS Info.plist: root dict was not found."
        }
        $entry = @'
    <!-- Orbit M10: app_links owns custom deep-link dispatch. -->
    <key>FlutterDeepLinkingEnabled</key>
    <false/>
'@
        $content = $content.Insert($rootClose, $entry)
    }

    if ($content -notmatch '<string>orbit</string>') {
        if ($content -match '<key>CFBundleURLTypes</key>') {
            $urlTypesPattern = '(?s)(<key>CFBundleURLTypes</key>\s*<array>)'
            if ($content -notmatch $urlTypesPattern) {
                throw "Existing CFBundleURLTypes entry is malformed in $infoPlist"
            }
            $orbitType = @'

        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLName</key>
            <string>Orbit</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>orbit</string>
            </array>
        </dict>
'@
            $content = [regex]::Replace(
                $content,
                $urlTypesPattern,
                { param($match) $match.Groups[1].Value + $orbitType },
                1
            )
        }
        else {
            $rootClose = $content.LastIndexOf('</dict>')
            if ($rootClose -lt 0) {
                throw "Invalid iOS Info.plist: root dict was not found."
            }
            $entry = @'
    <!-- Orbit M10: backend-defined orbit:// custom scheme. -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLName</key>
            <string>Orbit</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>orbit</string>
            </array>
        </dict>
    </array>
'@
            $content = $content.Insert($rootClose, $entry)
        }
    }

    Set-Content -Path $infoPlist -Value $content -Encoding UTF8
}
else {
    Write-Host "iOS Info.plist not found; iOS native configuration skipped." -ForegroundColor Yellow
}

Write-Host "`nOrbit M10 native deep-link configuration complete." -ForegroundColor Green
