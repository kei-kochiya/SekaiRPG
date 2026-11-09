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

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[INFO] Running headless unit tests..."
# Tên suite truyền thêm sẽ chỉ chạy các suite đó, vd.: Scripts/run_tests.sh TestResources TestCombat
if [ "$#" -gt 0 ]; then
    "$GODOT_BIN" --headless --path "$PROJECT_DIR" res://Tests/TestRunnerScene.tscn -- "$@"
else
    "$GODOT_BIN" --headless --path "$PROJECT_DIR" res://Tests/TestRunnerScene.tscn
fi

echo "[SUCCESS] All tests passed successfully!"
