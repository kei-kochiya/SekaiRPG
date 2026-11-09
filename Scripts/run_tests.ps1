# SekaiRPG PowerShell Automated Test Suite Runner
# Dùng: $env:GODOT_BIN = "<đường dẫn godot>"; ./Scripts/run_tests.ps1 [TênSuite ...]
$ErrorActionPreference = "Stop"

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "          SekaiRPG Automated Test Suite Runner         " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

$GodotBin = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "godot" }

if (-not (Get-Command $GodotBin -ErrorAction SilentlyContinue)) {
    Write-Error "[ERROR] Godot executable '$GodotBin' not found. Set `$env:GODOT_BIN or add godot to PATH."
    exit 1
}

$ProjectDir = Split-Path -Parent $PSScriptRoot

Write-Host "[INFO] Executing headless test runner using $GodotBin..." -ForegroundColor Green
if ($args.Count -gt 0) {
    & $GodotBin --headless --path $ProjectDir res://Tests/TestRunnerScene.tscn -- @args
} else {
    & $GodotBin --headless --path $ProjectDir res://Tests/TestRunnerScene.tscn
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] All tests executed and passed successfully!" -ForegroundColor Green
} else {
    Write-Error "[FAIL] Test suite failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
