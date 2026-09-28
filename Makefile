# Common development tasks for Scan. Run `make` for a list of targets.
#
# To sign with your own team, see Config/Shared.xcconfig.

APP_NAME     := Scan
PROJECT      := Scan.xcodeproj
SCHEME       := Scan
DERIVED_DATA := build
INSTALL_DIR  := /Applications
BUNDLE_ID    := de.holgerkrupp.Scan

XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	-destination 'platform=macOS' -derivedDataPath $(DERIVED_DATA)

DEBUG_APP   := $(DERIVED_DATA)/Build/Products/Debug/$(APP_NAME).app
RELEASE_APP := $(DERIVED_DATA)/Build/Products/Release/$(APP_NAME).app

# Pipe through xcbeautify when available for readable output.
BEAUTIFY := $(shell command -v xcbeautify >/dev/null 2>&1 && echo "| xcbeautify" || echo "-quiet")

.PHONY: help build run release install test clean quit

help: ## Show this help
	@echo "Usage: make <target>"
	@echo
	@grep -hE '^[a-z]+:.*## ' $(firstword $(MAKEFILE_LIST)) | \
		awk 'BEGIN { FS = ":.*## " } { printf "  %-10s %s\n", $$1, $$2 }'

build: ## Build the Debug version
	set -o pipefail && $(XCODEBUILD) -configuration Debug build $(BEAUTIFY)

run: build quit ## Build Debug, then quit and relaunch the app
	open "$(DEBUG_APP)"

release: ## Build the Release version
	set -o pipefail && $(XCODEBUILD) -configuration Release build $(BEAUTIFY)

install: release quit ## Build Release and install into /Applications
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	ditto "$(RELEASE_APP)" "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Installed $(INSTALL_DIR)/$(APP_NAME).app"

test: ## Run the unit tests
	set -o pipefail && $(XCODEBUILD) test $(BEAUTIFY)

# Quit a running instance gracefully, falling back to kill after 5 seconds.
quit: ## Quit a running instance of the app
	@if pgrep -xq "$(APP_NAME)"; then \
		osascript -e 'tell application id "$(BUNDLE_ID)" to quit' >/dev/null 2>&1 || true; \
		for i in $$(seq 1 50); do pgrep -xq "$(APP_NAME)" || exit 0; sleep 0.1; done; \
		pkill -x "$(APP_NAME)" || true; \
	fi

clean: ## Remove local build products
	rm -rf $(DERIVED_DATA)
