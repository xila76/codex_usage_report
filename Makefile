APP_NAME = codex_usage_report
DIST_DIR = dist

# Build targets
PLATFORMS = \
	linux/amd64 \
	linux/arm64 \
	windows/amd64 \
	windows/arm64 \
	darwin/amd64 \
	darwin/arm64

# Detect OS
UNAME_S := $(shell uname -s 2>/dev/null || echo Unknown)
ifeq ($(OS),Windows_NT)
	PLATFORM_OS := windows
else ifeq ($(UNAME_S),Darwin)
	PLATFORM_OS := darwin
else ifeq ($(UNAME_S),Linux)
	PLATFORM_OS := linux
else
	PLATFORM_OS := unknown
endif

# Create dist folder
$(DIST_DIR):
	mkdir -p $(DIST_DIR)

# Default build for current system
build: $(DIST_DIR)
	go build -o $(DIST_DIR)/$(APP_NAME) ./cmd/$(APP_NAME)

# Cross-compile for all platforms
build-all: $(DIST_DIR)
	@for platform in $(PLATFORMS); do \
		GOOS=$${platform%/*}; \
		GOARCH=$${platform#*/}; \
		ext=""; \
		if [ $$GOOS = "windows" ]; then ext=".exe"; fi; \
		output="$(DIST_DIR)/$(APP_NAME)_$${GOOS}_$${GOARCH}$$ext"; \
		echo "Building $$output"; \
		GOOS=$$GOOS GOARCH=$$GOARCH go build -o $$output ./cmd/$(APP_NAME) || exit 1; \
	done

# Clean binaries
clean:
	rm -rf $(DIST_DIR)

# Shortcut: build everything for release
release: clean build-all
	@echo "✅ All binaries have been generated in $(DIST_DIR)/"

# Cross-platform install (auto-detect)
install:
ifeq ($(PLATFORM_OS),windows)
	$(MAKE) build-all
	@install.bat
else ifeq ($(PLATFORM_OS),linux)
	$(MAKE) build
	@chmod +x install.sh
	@./install.sh || ./install.sh --user
else ifeq ($(PLATFORM_OS),darwin)
	$(MAKE) build
	@chmod +x install.sh
	@./install.sh || ./install.sh --user
else
	@echo "❌ Unsupported platform: $(PLATFORM_OS)"
endif

# Cross-platform uninstall
uninstall:
ifeq ($(PLATFORM_OS),windows)
	@echo "🗑️ Removing $(APP_NAME).exe from PATH (Windows)..."
	@del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\$(APP_NAME).exe" 2>nul || echo "⚠️ Binary not found"
else ifeq ($(PLATFORM_OS),linux)
	@echo "🗑️ Removing $(APP_NAME) from ~/.local/bin and /usr/local/bin..."
	@rm -f "$(HOME)/.local/bin/$(APP_NAME)" || true
	@sudo rm -f "/usr/local/bin/$(APP_NAME)" || true
else ifeq ($(PLATFORM_OS),darwin)
	@echo "🗑️ Removing $(APP_NAME) from ~/.local/bin and /usr/local/bin..."
	@rm -f "$(HOME)/.local/bin/$(APP_NAME)" || true
	@sudo rm -f "/usr/local/bin/$(APP_NAME)" || true
else
	@echo "❌ Unsupported platform: $(PLATFORM_OS)"
endif

# Show available targets
help:
	@echo "Available make commands:"
	@echo "  make build        - Build for the current system"
	@echo "  make build-all    - Cross-compile for all platforms"
	@echo "  make clean        - Remove dist/ and all binaries"
	@echo "  make release      - Build all binaries (clean + build-all)"
	@echo "  make install      - Install the binary (auto-detect OS)"
	@echo "  make uninstall    - Remove installed binary"
	@echo "  make help         - Show this help message"

# Declare phony targets
.PHONY: build build-all clean release install uninstall help

