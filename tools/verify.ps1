$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$runtimeRoot = Join-Path $projectRoot ".godot\verify_runtime"
$appDataPath = Join-Path $runtimeRoot "appdata"
$localAppDataPath = Join-Path $runtimeRoot "localappdata"
$tempPath = Join-Path $runtimeRoot "temp"
$tmpPath = Join-Path $runtimeRoot "tmp"

New-Item -ItemType Directory -Force -Path @(
	$appDataPath,
	$localAppDataPath,
	$tempPath,
	$tmpPath
) | Out-Null

$env:APPDATA = $appDataPath
$env:LOCALAPPDATA = $localAppDataPath
$env:TEMP = $tempPath
$env:TMP = $tmpPath

$godotCommand = (Get-Command godot -ErrorAction Stop).Source

Write-Output "=== Godot import (headless) ==="
& $godotCommand --headless --path $projectRoot --import
$importExitCode = $LASTEXITCODE
Write-Output "Import exit code: $importExitCode"

Write-Output "=== Main scene smoke test (headless, 5 frames) ==="
& $godotCommand --headless --path $projectRoot --quit-after 5
$runExitCode = $LASTEXITCODE
Write-Output "Main scene exit code: $runExitCode"

if ($importExitCode -ne 0 -or $runExitCode -ne 0) {
	exit 1
}

exit 0
