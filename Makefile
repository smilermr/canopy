# Canopy Network developer and release automation.

GO_BIN_DIR ?= $(HOME)/go/bin
CLI_DIR := ./cmd/main/...
AUTO_UPDATE_DIR := ./cmd/auto-update/...
WALLET_DIR := ./cmd/rpc/web/wallet
EXPLORER_DIR := ./cmd/rpc/web/explorer
DOCKER_DIR := ./.docker/compose.yaml

.PHONY: help build/canopy build/canopy-full build/wallet build/explorer build/auto-update \
	build/auto-update-local build/all test test/all test/race test/fuzz fmt vet check \
	dev/deps docker/build docker/up docker/down docker/up-fast docker/logs \
	run/auto-update run/auto-update-build build/plugin build/kotlin-plugin build/go-plugin \
	build/typescript-plugin build/python-plugin build/csharp-plugin build/all-plugins \
	docker/plugin docker/run docker/run-kotlin docker/run-go docker/run-typescript \
	docker/run-python docker/run-csharp

# ==================================================================================== #
# HELPERS
# ==================================================================================== #

## help: print available commands
help:
	@echo "Canopy Network developer commands:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  /'

# ==================================================================================== #
# BUILDING
# ==================================================================================== #

## build/canopy: build the production Canopy binary
build/canopy:
	@mkdir -p $(GO_BIN_DIR)
	npm ci --prefix $(EXPLORER_DIR)
	npm run build --prefix $(EXPLORER_DIR)
	go build -trimpath -o $(GO_BIN_DIR)/canopy $(CLI_DIR)

## build/canopy-full: build Canopy together with wallet and explorer assets
build/canopy-full: build/wallet build/explorer build/canopy

## build/wallet: build the wallet web application
build/wallet:
	npm ci --prefix $(WALLET_DIR)
	npm run build --prefix $(WALLET_DIR)

## build/explorer: build the explorer web application
build/explorer:
	npm ci --prefix $(EXPLORER_DIR)
	npm run build --prefix $(EXPLORER_DIR)

## build/auto-update: build the automatic update binary
build/auto-update:
	@mkdir -p $(GO_BIN_DIR)
	go build -trimpath -o $(GO_BIN_DIR)/canopy-auto-update $(AUTO_UPDATE_DIR)

## build/auto-update-local: build local CLI and auto-update binaries
build/auto-update-local:
	go build -trimpath -o ./cli $(CLI_DIR)
	go build -trimpath -o $(GO_BIN_DIR)/canopy-auto-update $(AUTO_UPDATE_DIR)

# ==================================================================================== #
# QUALITY / TESTING
# ==================================================================================== #

## fmt: format Go source files
fmt:
	gofmt -w $$(find . -type f -name '*.go' -not -path './vendor/*')

## vet: run the Go static analyzer
vet:
	go vet ./...

## test: run the complete Go test suite
test:
	go test ./... -p=1

## test/all: backwards-compatible alias for the complete test suite
test/all: test

## test/race: run tests with the Go race detector
test/race:
	go test -race ./... -p=1

## test/fuzz: run the repository's supported fuzz targets
test/fuzz:
	go test -fuzz=FuzzKeyDecodeEncode ./store -fuzztime=5s
	go test -fuzz=FuzzBytesToBits ./store -fuzztime=5s

## check: run formatting, static analysis, and tests
check: fmt vet test

# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

## dev/deps: vendor Go dependencies for reproducible/offline development
dev/deps:
	go mod vendor

ifeq ($(shell uname -s),Darwin)
	DOCKER_COMPOSE_CMD = docker-compose
else
	DOCKER_COMPOSE_CMD = docker compose
endif

## docker/build: build Docker Compose services
docker/build:
	$(DOCKER_COMPOSE_CMD) -f $(DOCKER_DIR) build

## docker/up: rebuild and start Docker Compose services
docker/up:
	$(DOCKER_COMPOSE_CMD) -f $(DOCKER_DIR) down
	$(DOCKER_COMPOSE_CMD) -f $(DOCKER_DIR) up --build -d

## docker/down: stop Docker Compose services
docker/down:
	$(DOCKER_COMPOSE_CMD) -f $(DOCKER_DIR) down

## docker/up-fast: start existing Docker Compose images without rebuilding
docker/up-fast:
	$(DOCKER_COMPOSE_CMD) -f $(DOCKER_DIR) down
	$(DOCKER_COMPOSE_CMD) -f $(DOCKER_DIR) up -d

## docker/logs: follow the latest Docker Compose logs
docker/logs:
	$(DOCKER_COMPOSE_CMD) -f $(DOCKER_DIR) logs -f --tail=1000

# ==================================================================================== #
# AUTO UPDATE
# ==================================================================================== #

## run/auto-update: run the auto-update service using ./cli
run/auto-update:
	BIN_PATH=./cli go run $(AUTO_UPDATE_DIR) start

## run/auto-update-build: build the local CLI and run auto-update
run/auto-update-build: build/auto-update-local
	BIN_PATH=./cli go run $(AUTO_UPDATE_DIR) start

# ==================================================================================== #
# PLUGINS
# ==================================================================================== #

PLUGIN ?= kotlin

## build/plugin: build one plugin with PLUGIN=kotlin|go|typescript|python|csharp|all
build/plugin:
ifeq ($(PLUGIN),kotlin)
	cd plugin/kotlin && ./gradlew fatJar --no-daemon
else ifeq ($(PLUGIN),go)
	cd plugin/go && go build -trimpath -o go-plugin .
else ifeq ($(PLUGIN),typescript)
	cd plugin/typescript && npm ci && npm run build:all
else ifeq ($(PLUGIN),python)
	cd plugin/python && make dev
else ifeq ($(PLUGIN),csharp)
	cd plugin/csharp && rm -rf bin && dotnet publish -c Release -r linux-x64 --self-contained true -o bin
else ifeq ($(PLUGIN),all)
	$(MAKE) build/plugin PLUGIN=go
	$(MAKE) build/plugin PLUGIN=kotlin
	$(MAKE) build/plugin PLUGIN=typescript
	$(MAKE) build/plugin PLUGIN=python
	$(MAKE) build/plugin PLUGIN=csharp
else
	@echo "Unknown plugin: $(PLUGIN). Options: kotlin, go, typescript, python, csharp, all"
	@exit 1
endif

## build/kotlin-plugin: build the Kotlin plugin
build/kotlin-plugin:
	$(MAKE) build/plugin PLUGIN=kotlin

## build/go-plugin: build the Go plugin
build/go-plugin:
	$(MAKE) build/plugin PLUGIN=go

## build/typescript-plugin: build the TypeScript plugin
build/typescript-plugin:
	$(MAKE) build/plugin PLUGIN=typescript

## build/python-plugin: build the Python plugin
build/python-plugin:
	$(MAKE) build/plugin PLUGIN=python

## build/csharp-plugin: build the C# plugin
build/csharp-plugin:
	$(MAKE) build/plugin PLUGIN=csharp

## build/all-plugins: build all supported plugins
build/all-plugins:
	$(MAKE) build/plugin PLUGIN=all

## docker/plugin: build a plugin Docker image
# Usage: make docker/plugin PLUGIN=go
docker/plugin:
	docker build -f plugin/$(PLUGIN)/Dockerfile -t canopy-$(PLUGIN) .

## docker/run: run the selected plugin container
# Usage: make docker/run PLUGIN=go
docker/run:
	docker run --rm -v $(HOME)/.canopy:/root/.canopy canopy-$(PLUGIN)

## docker/run-kotlin: run the Kotlin plugin container
docker/run-kotlin:
	$(MAKE) docker/run PLUGIN=kotlin

## docker/run-go: run the Go plugin container
docker/run-go:
	$(MAKE) docker/run PLUGIN=go

## docker/run-typescript: run the TypeScript plugin container
docker/run-typescript:
	$(MAKE) docker/run PLUGIN=typescript

## docker/run-python: run the Python plugin container
docker/run-python:
	$(MAKE) docker/run PLUGIN=python

## docker/run-csharp: run the C# plugin container
docker/run-csharp:
	$(MAKE) docker/run PLUGIN=csharp
