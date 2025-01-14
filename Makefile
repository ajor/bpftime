.PHONY: install coverage test docs help build clean build-arm run-arm run-arm64 build-arm64 build-arm32
.DEFAULT_GOAL := help

define BROWSER_PYSCRIPT
import os, webbrowser, sys

try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z\d_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python3 -c "$$BROWSER_PYSCRIPT"
INSTALL_LOCATION := ~/.local

help:
	@python3 -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

test: ## test the package
	make -C third_party/libbpf/src
	make -C runtime/test/bpf
	cp -r runtime/test/bpf/* build/runtime/test/
	cd build/runtime && ctest -VV

build: ## build the package
	cmake -Bbuild  -DBPFTIME_ENABLE_UNIT_TESTING=1 -DUSE_NEW_BINUTILS=1
	cmake --build build --config Debug

build-old-binutils: ## build the package with old binutils
	cmake -Bbuild  -DBPFTIME_ENABLE_UNIT_TESTING=1 -DUSE_NEW_BINUTILS=0
	cmake --build build --config Debug

release: ## build the package
	(cmake -Bbuild  -DBPFTIME_ENABLE_UNIT_TESTING=0 && cmake --build build --config Release -j --target install) || (cmake -Bbuild  -DBPFTIME_ENABLE_UNIT_TESTING=0 -DUSE_NEW_BINUTILS=YES && cmake --build build --config Release -j  --target install)

build-vm: ## build only the core library
	make -C vm build

build-llvm: ## build with llvm as jit backend
	cmake -Bbuild  -DBPFTIME_ENABLE_UNIT_TESTING=1 -DBPFTIME_LLVM_JIT=1
	cmake --build build --config Debug

clean: ## clean the project
	rm -rf build
	make -C runtime clean
	make -C vm clean
install: release ## Invoke cmake to install..
