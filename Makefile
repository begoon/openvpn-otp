.PHONY: build release

default: release

release: clean build test package

build:
	xcodebuild -scheme connector CONFIGURATION_BUILD_DIR=$(PWD)/build

test:
	xcodebuild -scheme connector test

package:
	-rm -rf release
	mkdir release
	cp -r build/OTP/VPN.app release
	open release/
	
clean:
	-rm -rf build release

clean-git:
	git clean -fdx
