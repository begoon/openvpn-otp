.PHONY: build release

default: release

release: clean test build package

build:
	NSUnbufferedIO=YES \
	xcodebuild -quiet -scheme connector \
	-derivedDataPath $(PWD)/build 

test:
	NSUnbufferedIO=YES \
	xcodebuild -scheme connector \
	-derivedDataPath $(PWD)/build \
	test

revision:
	@echo "let gitCommit = \"$(shell git rev-parse --short HEAD)\"" > connector/commit.swift

package:
	-rm -rf release
	mkdir release
	cp -r build/Build/Products/Debug/OTP/VPN.app release
	open release/
	
clean:
	-rm -rf build release

clean-git:
	git clean -fdx
