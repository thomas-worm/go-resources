GITHUB_ORGANIZATION = thomas-worm
GITHUB_REPOSITORY = go-resources
BINARY = go-resources
VERSION = 0.0.1

VET_REPORT = vet.report
TEST_REPORT = tests.xml
GOARCH = amd64

ifdef OS
    ifeq ($(OS),Windows_NT)
        DEFAULT_GOPATH := $(USERPROFILE)\go
    endif
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        DEFAULT_GOPATH := $(HOME)/go
    else ifeq ($(UNAME_S),Darwin) # macOS
        DEFAULT_GOPATH := $(HOME)/go
    else
        $(error Unsupported OS)
    endif
endif
GOPATH := $(if $(GOPATH),$(GOPATH),$(DEFAULT_GOPATH))

COMMIT = $(shell git rev-parse HEAD)
BRANCH = $(shell git rev-parse --abbrev-ref HEAD)

BUILD_DIR = ${GOPATH}/src/github.com/${GITHUB_ORGANIZATION}/${GITHUB_REPOSITORY}
CURRENT_DIR = $(shell pwd)
BUILD_DIR_LINK = $(shell readlink ${BUILD_DIR})

CONSTANTS_PACKAGE = github.com/$(GITHUB_ORGANIZATION)/$(GITHUB_REPOSITORY)/internal/pkg/constants
LDFLAGS = -ldflags "-X $(CONSTANTS_PACKAGE).version=${VERSION} -X $(CONSTANTS_PACKAGE).commit=${COMMIT} -X $(CONSTANTS_PACKAGE).branch=${BRANCH}"

.DEFAULT_GOAL:=help
.PHONY: help
help:  ## Display this help
	$(info Source of github.com/${GITHUB_ORGANIZATION}/${GITHUB_REPOSITORY})
	awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: install-go2xunit
install-go2xunit: 
	if ! hash go2xunit 2>/dev/null; then go install github.com/tebeka/go2xunit; fi

all: link clean test vet linux darwin windows  ## Builds everything

link:  ## Link the project into GOPATH
	$(info 🔗 Linking project into GOPATH...)
	mkdir -p $(dir $(abspath $(BUILD_DIR)))
	BUILD_DIR=${BUILD_DIR}; \
	BUILD_DIR_LINK=${BUILD_DIR_LINK}; \
	CURRENT_DIR=${CURRENT_DIR}; \
	if [ "$${BUILD_DIR_LINK}" != "$${CURRENT_DIR}" ]; then \
	    echo "Fixing symlinks for build"; \
	    rm -f $${BUILD_DIR}; \
	    ln -s $${CURRENT_DIR} $${BUILD_DIR}; \
	fi

.POHONY: dep
dep: link  ## Ensure dependencies are up to date.
	if ! hash dep 2>/dev/null; then (curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh); fi
	cd ${BUILD_DIR}; \
	dep ensure; \
	go mod vendor; \
	cd - >/dev/null

linux: link  ## Build linux binary
	$(info 🔨 Building Linux binary...)
	cd ${BUILD_DIR}; \
	GOOS=linux GOARCH=${GOARCH} go build ${LDFLAGS} -o ./bin/${BINARY}-linux-${GOARCH} ./cmd/$(BINARY) ; \
	cd - >/dev/null

darwin: link  ## Build MacOS binary
	$(info 🔨 Building MacOS binary...)
	cd ${BUILD_DIR}; \
	GOOS=darwin GOARCH=${GOARCH} go build ${LDFLAGS} -o ./bin/${BINARY}-darwin-${GOARCH} ./cmd/$(BINARY) ; \
	cd - >/dev/null

windows: link  ## Build windows binary
	$(info 🔨 Building Windows binary...)
	cd ${BUILD_DIR}; \
	GOOS=windows GOARCH=${GOARCH} go build ${LDFLAGS} -o ./bin/${BINARY}-windows-${GOARCH}.exe ./cmd/$(BINARY) ; \
	cd - >/dev/null

test: link dep install-go2xunit  ## Run tests
	$(info 🧪 Running tests...)
	cd ${BUILD_DIR}; \
	mkdir -p ./out/; \
	go test -v ./... 2>&1 | go2xunit -output ./out/${TEST_REPORT} ; \
	cd - >/dev/null

vet: link dep  ## Run go vet
	$(info 🔍 Checking source...)
	cd ${BUILD_DIR}; \
	mkdir -p ./out/; \
	go vet ./... > ./out/${VET_REPORT} 2>&1 ; \
	cd - >/dev/null

fmt: link  ## Run go fmt
	$(info 🗋 Formatting code...)
	cd ${BUILD_DIR}; \
	go fmt $$(go list ./... | grep -v /vendor/) ; \
	cd - >/dev/null

clean:  ## Clean
	$(info 🧹 Cleaning...)
	-rm -f ${TEST_REPORT}
	-rm -f ${VET_REPORT}
	-rm -f ${BINARY}-*

.PHONY: link linux darwin windows test vet fmt clean

.SILENT: 


