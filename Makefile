BUILD_ID:=$(shell date +%s)

build:
	swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

release-build:
	swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12" -c release
