#!/usr/bin/env bash
set -e

echo "======================================================"
echo "          SekaiRPG Automated Test Suite Runner         "
echo "======================================================"

GODOT_BIN="${GODOT_BIN:-godot}"

if ! command -v "$GODOT_BIN" &> /dev/null; then
    echo "[ERROR] Godot executable '$GODOT_BIN' not found in PATH."
    echo "Please set GODOT_BIN environment variable or ensure godot is in PATH."
    exit 1
fi

echo "[INFO] Running headless unit tests..."
"$GODOT_BIN" --headless Tests/TestRunnerScene.tscn

echo "[SUCCESS] All tests passed successfully!"
