.PHONY: build install clean test fmt run lint release help
.PHONY: build-all docker-build docker-run docker-clean
.PHONY: check test-coverage

BINARY_NAME=mycli
VERSION=$(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_DIR=./build
LDFLAGS=-ldflags "-s -w -X github.com/samzong/cli-template/cmd.Version=$(VERSION)"
PLATFORMS=linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64

.DEFAULT_GOAL := help

build: ## Build binary for current platform
	@mkdir -p $(BUILD_DIR)
	@CGO_ENABLED=0 go build -trimpath $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) .

build-all: ## Build binaries for all platforms
	@mkdir -p $(BUILD_DIR)
	@for platform in $(PLATFORMS); do \
		OS=$$(echo $$platform | cut -d'/' -f1); \
		ARCH=$$(echo $$platform | cut -d'/' -f2); \
		OUTPUT_NAME=$(BUILD_DIR)/$(BINARY_NAME)-$$OS-$$ARCH; \
		[ "$$OS" = "windows" ] && OUTPUT_NAME=$$OUTPUT_NAME.exe; \
		CGO_ENABLED=0 GOOS=$$OS GOARCH=$$ARCH go build -trimpath $(LDFLAGS) -o $$OUTPUT_NAME . || exit 1; \
	done

install: ## Install binary
	@CGO_ENABLED=0 go install $(LDFLAGS) .

fmt: ## Format code
	@command -v goimports >/dev/null 2>&1 || go install golang.org/x/tools/cmd/goimports@latest
	@goimports -w .
	@go fmt ./...
	@go mod tidy

lint: ## Run linter
	@command -v golangci-lint >/dev/null 2>&1 || \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin latest
	@golangci-lint run

lint-fix: ## Run linter with auto-fix
	@command -v golangci-lint >/dev/null 2>&1 || \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin latest
	@golangci-lint run --fix

test: ## Run tests with race detection
	@go test -v -race ./...

test-coverage: ## Run tests with coverage
	@mkdir -p $(BUILD_DIR)
	@go test -v -coverprofile=$(BUILD_DIR)/coverage.out ./...
	@go tool cover -html=$(BUILD_DIR)/coverage.out -o $(BUILD_DIR)/coverage.html

check: fmt lint test ## Run all quality checks

docker-build: ## Build Docker image
	@docker build -t ghcr.io/samzong/$(BINARY_NAME):$(VERSION) .
	@docker tag ghcr.io/samzong/$(BINARY_NAME):$(VERSION) ghcr.io/samzong/$(BINARY_NAME):latest

docker-run: docker-build ## Run Docker container
	@docker run --rm -it ghcr.io/samzong/$(BINARY_NAME):$(VERSION)

docker-clean: ## Clean Docker images
	@docker rmi ghcr.io/samzong/$(BINARY_NAME):$(VERSION) ghcr.io/samzong/$(BINARY_NAME):latest 2>/dev/null || true
	@docker system prune -f

release: check ## Create release
	@[ -n "$(TAG)" ] || (echo "Usage: make release TAG=v1.0.0" && exit 1)
	@git tag $(TAG) || (echo "Tag $(TAG) already exists" && exit 1)
	@git push origin $(TAG)

run: build ## Build and run binary
	@$(BUILD_DIR)/$(BINARY_NAME) $(ARGS)

clean: ## Remove build artifacts
	@rm -rf $(BUILD_DIR)
	@go clean

version: ## Show version information
	@echo "Binary: $(BINARY_NAME)"
	@echo "Version: $(VERSION)"

all: clean fmt lint build test

help: ## Show help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
