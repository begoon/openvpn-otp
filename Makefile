.PHONY: build release

all: run

release: clean build
	-rm -rf release
	mkdir release
	cp -r build/OTP/VPN.app release
	open release/
	
build:
	xcodebuild -scheme connector CONFIGURATION_BUILD_DIR=$(PWD)/build

clean:
	-rm -rf build release

clean-git:
	git clean -fdx
