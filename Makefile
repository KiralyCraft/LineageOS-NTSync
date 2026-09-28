SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help
.PHONY: help server-preflight test zip verify device-test publish
help:
	@printf '%s\n' 'make server-preflight' 'make test' 'make zip' 'make verify' 'make device-test (after manual installation)' 'make publish (after device validation)'
server-preflight:
	@./scripts/remote-build.sh preflight
test:
	@python3 -m unittest discover -s tests -p 'test_*.py'
	@for script in module/*.sh scripts/*.sh build-support/*.sh; do bash -n "$$script"; done
zip:
	@./scripts/remote-build.sh zip
verify:
	@python3 scripts/verify-dist.py dist
device-test:
	@./scripts/device-test.sh
publish:
	@./scripts/publish.sh
