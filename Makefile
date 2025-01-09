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
		-destination "platform=$(call platform_ios)"
	xcodebuild build \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination "platform=$(call platform_ios)"
test-macos:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination "platform=$(call platform_macos)"
	xcodebuild build \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination "platform=$(call platform_macos)"
test-tvos:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination "platform=$(call platform_tvos)"
	xcodebuild build \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination "platform=$(call platform_tvos)"
test-watchos:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination "platform=$(call platform_watchos)"
	xcodebuild build \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination "platform=$(call platform_watchos)"

test-examples:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme CaseStudies \
		-destination "platform=$(call platform_ios)"

DOC_WARNINGS := $(shell xcodebuild clean docbuild \
	-scheme SwiftUINavigation \
		-destination "platform=$(call platform_macos)" \
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
		-destination "platform=$(call platform_ios)" \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
		OTHER_SWIFT_FLAGS=$(OTHER_SWIFT_FLAGS)

	xcodebuild build \
	  -skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme UIKitNavigation \
		-destination "platform=$(call platform_ios)" \
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

define platform_ios
iOS Simulator,name=$(call name_for,iOS $(IOS_VERSION),iPhone \d\+ Pro [^M])
endef

define platform_watchos
watchOS Simulator,name=$(call name_for,watchOS $(WATCHOS_VERSION),Watch)
endef

define platform_tvos
tvOS Simulator,name=$(call name_for,tvOS $(TVOS_VERSION),TV)
endef

define platform_macos
macOS
endef
