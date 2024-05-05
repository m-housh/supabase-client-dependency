BIN_PATH = $(shell swift build --show-bin-path)
XCTEST_PATH = $(shell find "$(BIN_PATH)" -name '*.xctest')
COV_BIN = "$(XCTEST_PATH)"/Contents/MacOs/$(shell basename "$(XCTEST_PATH)" .xctest)

PLATFORM_IOS = iOS Simulator,name=iPhone 14 Pro
PLATFORM_MACOS = macOS
PLATFORM_MAC_CATALYST = macOS,variant=Mac Catalyst
PLATFORM_TVOS = tvOS Simulator,name=Apple TV
PLATFORM_WATCHOS = watchOS Simulator,name=Apple Watch Series 8 (45mm)

SCHEME = supabase-client-dependency
DOCC_TARGET = SupabaseDependencies

CONFIG := debug

clean:
	rm -rf .build

test-macos: clean reset-db
		set -o pipefail && \
		xcodebuild test \
				-skipMacroValidation \
				-scheme "$(SCHEME)" \
				-configuration "$(CONFIG)" \
				-destination platform="$(PLATFORM_MACOS)"

test-ios: clean reset-db
		set -o pipefail && \
		xcodebuild test \
				-skipMacroValidation \
				-scheme "$(SCHEME)" \
				-configuration "$(CONFIG)" \
				-destination platform="$(PLATFORM_IOS)"

test-mac-catalyst: clean reset-db
		set -o pipefail && \
		xcodebuild test \
				-skipMacroValidation \
				-scheme "$(SCHEME)" \
				-configuration "$(CONFIG)" \
				-destination platform="$(PLATFORM_MAC_CATALYST)"

test-tvos: clean reset-db
		set -o pipefail && \
		xcodebuild test \
				-skipMacroValidation \
				-scheme "$(SCHEME)" \
				-configuration "$(CONFIG)" \
				-destination platform="$(PLATFORM_TVOS)"

test-watchos: clean reset-db
		set -o pipefail && \
		xcodebuild test \
				-skipMacroValidation \
				-scheme "$(SCHEME)" \
				-configuration "$(CONFIG)" \
				-destination platform="$(PLATFORM_WATCHOS)"

test-swift: reset-db
	swift test --enable-code-coverage

test-library: test-macos test-ios test-mac-catalyst test-tvos test-watchos

test-integration: reset-db
	set -o pipefail && \
	xcodebuild test \
		-skipMacroValidation \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIG)" \
		-destination="$(PLATFORM_MACOS)"

code-cov-report:
		@xcrun llvm-cov report \
			$(COV_BIN) \
			-instr-profile=.build/debug/codecov/default.profdata \
			-ignore-filename-regex=".build|Tests" \
			-use-color

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--recursive \
		./Package.swift \
		./Sources

build-example:
	xcodebuild build \
		-workspace supabase-client-dependency.xcworkspace \
		-scheme Examples \
		-destination="$(PLATFORM_IOS)" || exit 1;

build-documentation:
	swift package \
		--allow-writing-to-directory ./docs \
		generate-documentation \
		--target "$(DOCC_TARGET)" \
		--disable-indexing \
		--transform-for-static-hosting \
		--hosting-base-path "$(SCHEME)" \
		--output-path ./docs

preview-documentation:
	swift package \
		--disable-sandbox \
		preview-documentation \
		--target "$(DOCC_TARGET)"

reset-db:
	@supabase db reset
