.PHONY: all test lint import export-android clean help

GODOT_BIN ?= godot

all: test

help:
	@echo "SekaiRPG Build & Test Commands:"
	@echo "  make test             - Run master automated test runner headlessly"
	@echo "  make lint             - Run GDScript linter (gdlint)"
	@echo "  make import           - Headless project resource import"
	@echo "  make export-android   - Build debug APK for Android"
	@echo "  make clean            - Clean temporary export files"

test:
	$(GODOT_BIN) --headless Tests/TestRunnerScene.tscn

lint:
	gdlint Scripts/ Entities/ Tests/

import:
	$(GODOT_BIN) --headless --editor --quit || true

export-android:
	mkdir -p Export/Android
	$(GODOT_BIN) --headless --export-debug "Android" Export/Android/SekaiRPG_debug.apk

clean:
	rm -rf Export/Android/*.apk .godot/
