$ErrorActionPreference = "Stop"

function Run-Step([string]$Name, [scriptblock]$Command) {
    Write-Host "`n== $Name ==" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

$ProjectPath = Split-Path -Parent $PSScriptRoot
Push-Location $ProjectPath
try {
    Run-Step "Flutter packages" { flutter pub get }
    Run-Step "Dart formatting contract" { dart format --output=none --set-exit-if-changed lib test }
    Run-Step "Flutter analyzer" { flutter analyze }
    Run-Step "Flutter tests" { flutter test }

    Write-Host "`nOrbit Flutter UI M1 verification passed." -ForegroundColor Green
}
finally {
    Pop-Location
}
