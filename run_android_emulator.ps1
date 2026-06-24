param(
    [string]$AvdName
)

$ErrorActionPreference = 'Stop'

$env:ANDROID_SDK_HOME = 'C:\Users\Administrator'
$env:ANDROID_AVD_HOME = 'C:\Users\Administrator\.android\avd'

$emulatorExe = Join-Path $env:LOCALAPPDATA 'Android\Sdk\emulator\emulator.exe'

if (-not (Test-Path -LiteralPath $emulatorExe)) {
    throw "Android emulator not found: $emulatorExe"
}

$availableAvds = & $emulatorExe -list-avds

if (-not $availableAvds) {
    throw 'No Android AVD found. Create one in Android Studio first.'
}

if (-not $AvdName) {
    $AvdName = $availableAvds | Select-Object -First 1
}

if ($availableAvds -notcontains $AvdName) {
    throw "AVD '$AvdName' was not found. Available AVDs: $($availableAvds -join ', ')"
}

Write-Host "Starting Android emulator: $AvdName"
Start-Process -FilePath $emulatorExe -ArgumentList @('-avd', $AvdName)
