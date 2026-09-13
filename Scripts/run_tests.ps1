# SekaiRPG PowerShell Automated Test Suite Runner
$ErrorActionPreference = "Stop"

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "          SekaiRPG Automated Test Suite Runner         " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

$GodotBin = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "godot" }

# Check if Godot exists or try standard local location
if (-not (Get-Command $GodotBin -ErrorAction SilentlyContinue)) {
    $DefaultLocalGodot = "C:\Users\Admin\Desktop\Godot\Godot_v4.6.1-stable_win64_console.exe"
    if (Test-Path $DefaultLocalGodot) {
        $GodotBin = $DefaultLocalGodot
    } else {
        Write-Error "[ERROR] Godot executable not found. Please set `$env:GODOT_BIN."
        exit 1
    }
}

Write-Host "[INFO] Executing headless test runner using $GodotBin..." -ForegroundColor Green
& $GodotBin --headless Tests/TestRunnerScene.tscn

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] All tests executed and passed successfully!" -ForegroundColor Green
} else {
    Write-Error "[FAIL] Test suite failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
