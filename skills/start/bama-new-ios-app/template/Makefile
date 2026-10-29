# __APP_NAME__: every step from the shell, with no Xcode window.
#   make generate      project.yml -> __APP_NAME__.xcodeproj (XcodeGen)
#   make build-sim     build for the simulator
#   make run-sim       build, install, and open the app on the iPhone Duo simulator
#   make snapshot      build, then every page in light and dark with sample data: /tmp/__APP_NAME__-shots
#   make selftest      build, then the in-app self-test on the simulator: PASS or FAIL per check
#   make test          Kit unit tests on this Mac (Swift Testing)
#   make check         the grid lint and the layout check of the last snapshots
#   make build-device  compile for a real iPhone, unsigned
#   make deploy        install on your iPhone (tools/deploy.sh, from the bama-deploy-to-device skill)
# APP_DEVICE="iPhone 18 Pro" make snapshot runs on another simulator.

.PHONY: generate build-sim run-sim snapshot selftest test check build-device deploy

generate:
	@zsh -c 'source tools/env.sh && generate' && echo "wrote __APP_NAME__.xcodeproj"

build-sim:
	@tools/build.sh sim

run-sim:
	@tools/run.sh

snapshot: build-sim
	@tools/snap.sh

selftest: build-sim
	@tools/selftest.sh

test:
	@zsh -c 'source tools/env.sh && swift test --package-path Kit --scratch-path "$$HOME/Library/Developer/__APP_NAME__/test-build"'

check:
	@tools/grid-lint.sh
	@zsh -c 'source tools/env.sh && swift tools/check-layout.swift /tmp/__APP_NAME__-shots/*-layout.json'

build-device:
	@tools/build.sh device

deploy:
	@if [ -x tools/deploy.sh ]; then tools/deploy.sh; else echo "No tools/deploy.sh yet: call the bama-deploy-to-device skill."; exit 1; fi
