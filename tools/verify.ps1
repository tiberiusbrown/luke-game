$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$logRoot = Join-Path $projectRoot ".codex-runtime"
$runtimeRoot = Join-Path $logRoot "runtime"
$appDataPath = Join-Path $runtimeRoot "appdata"
$localAppDataPath = Join-Path $runtimeRoot "localappdata"
$tempPath = Join-Path $runtimeRoot "temp"
$tmpPath = Join-Path $runtimeRoot "tmp"

New-Item -ItemType Directory -Force -Path @(
	$appDataPath,
	$localAppDataPath,
	$tempPath,
	$tmpPath
	$logRoot
) | Out-Null

$env:APPDATA = $appDataPath
$env:LOCALAPPDATA = $localAppDataPath
$env:TEMP = $tempPath
$env:TMP = $tmpPath

$godotCommand = (Get-Command godot -ErrorAction Stop).Source

function Invoke-Godot {
	param(
		[string[]]$Arguments,
		[string]$LogName
	)

	$godotLogPath = Join-Path $logRoot "$LogName.log"
	$stdoutLogPath = Join-Path $logRoot "$LogName.stdout.log"
	$stderrLogPath = Join-Path $logRoot "$LogName.stderr.log"
	$previousErrorActionPreference = $ErrorActionPreference
	$ErrorActionPreference = "Continue"
	& $godotCommand @Arguments "--log-file" $godotLogPath > $stdoutLogPath 2> $stderrLogPath
	$exitCode = $LASTEXITCODE
	$ErrorActionPreference = $previousErrorActionPreference
	return $exitCode
}

Write-Output "=== Godot import (headless) ==="
$importExitCode = Invoke-Godot @("--headless", "--path", $projectRoot, "--import") "godot-import"
Write-Output "Import exit code: $importExitCode (logs: $logRoot\godot-import*.log)"

Write-Output "=== GUT tests (headless) ==="
$gutExitCode = Invoke-Godot @(
	"--headless",
	"--path", $projectRoot,
	"--script", "res://addons/gut/gut_cmdln.gd"
) "godot-gut"
Write-Output "GUT exit code: $gutExitCode (logs: $logRoot\godot-gut*.log)"

Write-Output "=== Main scene smoke test (headless, 5 frames) ==="
$runExitCode = Invoke-Godot @("--headless", "--path", $projectRoot, "--quit-after", "5") "godot-smoke"
Write-Output "Main scene exit code: $runExitCode (logs: $logRoot\godot-smoke*.log)"

if ($importExitCode -ne 0 -or $gutExitCode -ne 0 -or $runExitCode -ne 0) {
	exit 1
}

exit 0
