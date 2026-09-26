<#
.SYNOPSIS
  Creates the two dedicated screenshot AVDs (one-time setup).

.DESCRIPTION
  screenshots_phone  : 1080x2400 @ 420 dpi -> assets/store/play-store/phone
  screenshots_tablet : 1200x1920 @ 240 dpi -> assets/store/play-store/tablet_10-inch

  The resolutions must match the raw PNGs that assets/store/screenshots.af
  links; check_output.py fails loudly if they drift.

.PARAMETER Force
  Recreate the AVDs if they already exist.
#>
param([switch]$Force)

$ErrorActionPreference = 'Stop'

$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { $env:ANDROID_SDK_ROOT }
if (-not $sdk) { throw 'ANDROID_HOME (or ANDROID_SDK_ROOT) is not set.' }
$avdManager = Join-Path $sdk 'cmdline-tools\latest\bin\avdmanager.bat'
$sdkManager = Join-Path $sdk 'cmdline-tools\latest\bin\sdkmanager.bat'
$image = 'system-images;android-36;google_apis;x86_64'
$avdHome = if ($env:ANDROID_AVD_HOME) { $env:ANDROID_AVD_HOME } else { Join-Path $env:USERPROFILE '.android\avd' }

$avds = @(
    @{ Name = 'screenshots_phone'; Device = 'pixel_8'; Width = 1080; Height = 2400; Density = 420 },
    @{ Name = 'screenshots_tablet'; Device = 'Nexus 7 2013'; Width = 1200; Height = 1920; Density = 240 }
)

if (-not (Test-Path (Join-Path $sdk ($image -replace ';', '\')))) {
    Write-Host "Installing $image ..."
    & $sdkManager $image
    if ($LASTEXITCODE -ne 0) { throw "sdkmanager failed to install $image" }
}

foreach ($avd in $avds) {
    $config = Join-Path $avdHome "$($avd.Name).avd\config.ini"
    if ((Test-Path $config) -and -not $Force) {
        Write-Host "$($avd.Name) already exists (use -Force to recreate)."
        continue
    }

    Write-Host "Creating $($avd.Name) ..."
    'no' | & $avdManager create avd --force --name $avd.Name --package $image --device $avd.Device
    if ($LASTEXITCODE -ne 0) { throw "avdmanager failed to create $($avd.Name)" }

    # Pin the exact output resolution; the device profiles only approximate it.
    $overrides = [ordered]@{
        'hw.lcd.width'      = $avd.Width
        'hw.lcd.height'     = $avd.Height
        'hw.lcd.density'    = $avd.Density
        'hw.keyboard'       = 'yes'
        'hw.initialOrientation' = 'portrait'
        'showDeviceFrame'   = 'no'
        'skin.dynamic'      = 'yes'
        'skin.name'         = "$($avd.Width)x$($avd.Height)"
        'skin.path'         = "$($avd.Width)x$($avd.Height)"
        'disk.dataPartition.size' = '6G'
    }
    $lines = Get-Content $config | Where-Object { ($_ -split '=', 2)[0].Trim() -notin $overrides.Keys }
    $lines += $overrides.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }
    Set-Content -Path $config -Value $lines -Encoding ascii
}

Write-Host 'Done. AVDs:'
& (Join-Path $sdk 'emulator\emulator.exe') -list-avds
