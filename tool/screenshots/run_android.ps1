<#
.SYNOPSIS
  Regenerates the Play Store raw screenshots (assets/store/play-store/**/0N_raw.png).

.DESCRIPTION
  Builds the screenshot entry point (lib/main_screenshots.dart), boots each
  dedicated AVD (see create_avds.ps1), pins the status bar via SystemUI demo
  mode, runs the Maestro flows in tool/screenshots/flows and overwrites the raws
  in place, then runs check_output.py.

.PARAMETER Device
  phone, tablet or all (default).

.PARAMETER Screens
  Screen numbers to capture, e.g. -Screens 3,7. Default: all flows.

.PARAMETER SkipBuild
  Reuse the last built APK.

.PARAMETER KeepRunning
  Leave the emulators running (faster reruns while fixing a flow).

.PARAMETER TileWaitMs
  Fixed wait for live map tiles on screen 07.
#>
param(
    [ValidateSet('phone', 'tablet', 'all')]
    [string]$Device = 'all',
    [int[]]$Screens,
    [switch]$SkipBuild,
    [switch]$KeepRunning,
    [int]$TileWaitMs = 20000
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$flowsDir = Join-Path $PSScriptRoot 'flows'
$appId = 'com.jonaskeller14.bike_setup_tracker'
$apk = Join-Path $repoRoot 'build\app\outputs\flutter-apk\app-debug.apk'

# Finale Ligure, to match the Add Setup name on screen 03.
$gpsLon = '8.3439'
$gpsLat = '44.1690'

$devices = @{
    phone  = @{ Avd = 'screenshots_phone'; Port = 5580; Folder = 'play-store/phone' }
    tablet = @{ Avd = 'screenshots_tablet'; Port = 5582; Folder = 'play-store/tablet_10-inch' }
}
$selected = if ($Device -eq 'all') { @('phone', 'tablet') } else { @($Device) }

$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { $env:ANDROID_SDK_ROOT }
if (-not $sdk) { throw 'ANDROID_HOME (or ANDROID_SDK_ROOT) is not set.' }
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'

$maestro = (Get-Command maestro -ErrorAction SilentlyContinue).Source
if (-not $maestro) {
    $maestro = Join-Path $env:USERPROFILE '.maestro\maestro\bin\maestro.bat'
    if (-not (Test-Path $maestro)) { throw 'Maestro CLI not found. See tool/screenshots/README.md.' }
}
$env:MAESTRO_CLI_NO_ANALYTICS = '1'
$env:MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED = 'true'

$flows = Get-ChildItem $flowsDir -Filter '*.yaml' | Where-Object Name -Match '^\d\d_' | Sort-Object Name
if ($Screens) {
    $flows = $flows | Where-Object { [int]$_.Name.Substring(0, 2) -in $Screens }
}
if (-not $flows) { throw 'No flows selected.' }

function Invoke-Adb([string]$serial, [string[]]$arguments) {
    & $adb -s $serial @arguments
    if ($LASTEXITCODE -ne 0) { throw "adb $($arguments -join ' ') failed on $serial" }
}

function Start-Avd($config) {
    $serial = "emulator-$($config.Port)"
    $running = (& $adb devices) -match "^$serial\s+device"
    if (-not $running) {
        Write-Host "Booting $($config.Avd) as $serial ..."
        Start-Process -FilePath $emulator -WindowStyle Minimized -ArgumentList @(
            '-avd', $config.Avd, '-port', $config.Port, '-no-snapshot-save', '-no-boot-anim', '-no-audio'
        )
    }
    & $adb -s $serial wait-for-device
    $deadline = (Get-Date).AddMinutes(5)
    while ((& $adb -s $serial shell getprop sys.boot_completed 2>$null) -ne '1') {
        if ((Get-Date) -gt $deadline) { throw "$serial did not finish booting." }
        Start-Sleep -Seconds 2
    }
    return $serial
}

function Set-DemoStatusBar([string]$serial) {
    Invoke-Adb $serial @('shell', 'settings', 'put', 'global', 'sysui_demo_allowed', '1')
    $commands = @(
        # After a cold boot the real wifi icon can register once demo mode is
        # already on and then shows next to the demo one. Re-entering drops it.
        @('exit'),
        @('enter'),
        @('clock', '-e', 'hhmm', '0941'),
        @('battery', '-e', 'level', '100', '-e', 'plugged', 'false', '-e', 'powersave', 'false'),
        @('network', '-e', 'wifi', 'show', '-e', 'level', '4', '-e', 'fully', 'true'),
        # The Android 16 SystemUI ignores `datatype` and always labels a demo
        # mobile signal "3G", so the mobile icon is hidden instead.
        @('network', '-e', 'mobile', 'hide'),
        @('notifications', '-e', 'visible', 'false')
    )
    foreach ($command in $commands) {
        Invoke-Adb $serial (@('shell', 'am', 'broadcast', '-a', 'com.android.systemui.demo', '-e', 'command') + $command) | Out-Null
    }
}

function Initialize-Device([string]$serial) {
    Invoke-Adb $serial @('install', '-r', $apk) | Out-Null
    foreach ($permission in 'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION') {
        Invoke-Adb $serial @('shell', 'pm', 'grant', $appId, "android.permission.$permission")
    }
    # Play services' Location Accuracy prompt is handled in the flows.
    Invoke-Adb $serial @('shell', 'cmd', 'location', 'set-location-enabled', 'true')
    Invoke-Adb $serial @('emu', 'geo', 'fix', $gpsLon, $gpsLat) | Out-Null
    # Gboard otherwise opens its "Try out your stylus" onboarding over a focused
    # text field and swallows the flow's input.
    Invoke-Adb $serial @('shell', 'settings', 'put', 'secure', 'stylus_handwriting_enabled', '0')
}

# Maestro connects to every entry in `adb devices` and reports no device at all
# when a single one is not ready (offline, authorizing, unauthorized), even an
# unrelated emulator.
$notReady = @((& $adb devices) -match '^\S+\s+(?!device$)\S+$') -replace '\s+', ' '
if ($notReady) {
    throw "Maestro cannot see any device while these adb entries are not ready: $($notReady -join ', '). Shut them down (adb -s <serial> emu kill) or unplug them, then rerun."
}

if (-not $SkipBuild) {
    Push-Location $repoRoot
    try {
        flutter build apk --debug -t lib/main_screenshots.dart
        if ($LASTEXITCODE -ne 0) { throw 'flutter build apk failed.' }
    } finally { Pop-Location }
}
if (-not (Test-Path $apk)) { throw "APK not found: $apk" }

$failed = @()
$checkedFolders = @()
foreach ($name in $selected) {
    $config = $devices[$name]
    $serial = Start-Avd $config
    try {
        Initialize-Device $serial

        $outDir = Join-Path ([System.IO.Path]::GetTempPath()) "screenshots_$name"
        Remove-Item $outDir -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $outDir | Out-Null
        $targetDir = Join-Path $repoRoot "assets\store\$($config.Folder)"

        foreach ($flow in $flows) {
            # The emulator's adb transport can drop briefly (seen right after
            # installing the APK), which kills Maestro's device server: wait for
            # the device before each attempt and retry a failed flow once.
            foreach ($attempt in 1, 2) {
                Write-Host "[$name] $($flow.Name)$(if ($attempt -gt 1) { ' (retry)' })"
                & $adb -s $serial wait-for-device
                Set-DemoStatusBar $serial
                Push-Location $flowsDir
                try {
                    & $maestro --device $serial test $flow.Name `
                        --test-output-dir $outDir `
                        -e "APP_ID=$appId" `
                        -e "DEVICE=$name" `
                        -e "TILE_WAIT_MS=$TileWaitMs"
                    $ok = $LASTEXITCODE -eq 0
                } finally { Pop-Location }
                if ($ok) { break }
            }

            $shot = Get-ChildItem $outDir -Recurse -Filter "$($flow.Name.Substring(0, 2))_raw.png" | Select-Object -First 1
            if ($ok -and $shot) {
                Copy-Item $shot.FullName $targetDir -Force
            } else {
                $failed += "$name/$($flow.Name)"
            }
        }
        $checkedFolders += $config.Folder
    } finally {
        # Best effort: a dropped adb transport here must not abort the next device.
        & $adb -s $serial shell am broadcast -a com.android.systemui.demo -e command exit 2>&1 | Out-Null
        if (-not $KeepRunning) { & $adb -s $serial emu kill 2>&1 | Out-Null }
    }
}

python (Join-Path $PSScriptRoot 'check_output.py') @checkedFolders
$checkExit = $LASTEXITCODE

if ($failed) {
    Write-Host "Failed flows (raws left unchanged): $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
exit $checkExit
