# Default versions
IOS_VERSION ?= 17.5
TVOS_VERSION ?= 17.5
WATCHOS_VERSION ?= 10.5

OTHER_SWIFT_FLAGS="-DRESILIENT_LIBRARIES"
TEST_RUNNER_CI = $(CI)

default: test

test: test-ios test-macos test-tvos test-watchos test-examples

test-ios:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination "$(call destination_ios)"
	xcodebuild build \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination "$(call destination_ios)"
test-macos:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination "$(call destination_macos)"
	xcodebuild build \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination "$(call destination_macos)"
test-tvos:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination "$(call destination_tvos)"
	xcodebuild build \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination "$(call destination_tvos)"
test-watchos:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination "$(call destination_watchos)"
	xcodebuild build \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination "$(call destination_watchos)"

test-examples:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme CaseStudies \
		-destination "$(call destination_ios)"

DOC_WARNINGS := $(shell xcodebuild clean docbuild \
	-scheme SwiftUINavigation \
		-destination "$(call destination_macos)" \
	-quiet \
	2>&1 \
	| grep "couldn't be resolved to known documentation" \
	| sed 's|$(PWD)|.|g' \
	| tr '\n' '\1')
test-docs:
	@test "$(DOC_WARNINGS)" = "" \
		|| (echo "xcodebuild docbuild failed:\n\n$(DOC_WARNINGS)" | tr '\1' '\n' \
		&& exit 1)

build-for-library-evolution: build-for-library-evolution-ios build-for-library-evolution-macos

build-for-library-evolution-macos:
	swift build \
		-c release \
		--target SwiftUINavigation \
		-Xswiftc -emit-module-interface \
		-Xswiftc -enable-library-evolution \
		-Xswiftc $(OTHER_SWIFT_FLAGS)

	swift build \
		-c release \
		--target AppKitNavigation \
		-Xswiftc -emit-module-interface \
		-Xswiftc -enable-library-evolution \
		-Xswiftc $(OTHER_SWIFT_FLAGS)

build-for-library-evolution-ios:
	xcodebuild build \
	  -skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftUINavigation \
		-destination "$(call destination_ios)" \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
		OTHER_SWIFT_FLAGS=$(OTHER_SWIFT_FLAGS)

	xcodebuild build \
	  -skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme UIKitNavigation \
		-destination "$(call destination_ios)" \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
		OTHER_SWIFT_FLAGS=$(OTHER_SWIFT_FLAGS)

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--parallel \
		--recursive \
		./Examples ./Package.swift ./Sources ./Tests

.PHONY: format test-all test-docs

define name_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$1 }' | sed 's/^ *//g' | sed 's/ *$$//g')
endef

define destination_ios
platform=iOS Simulator,name=$(call name_for,iOS,iPhone 15 Pro),OS=$(IOS_VERSION)
endef

define destination_watchos
platform=watchOS Simulator,name=$(call name_for,watchOS,Watch),OS=$(WATCHOS_VERSION)
endef

define destination_tvos
platform=tvOS Simulator,name=$(call name_for,tvOS,TV),OS=$(TVOS_VERSION)
endef

define destination_macos
platform=macOS
endef
