# Copyright 2024 HAMi Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Build variables
BINARY_NAME ?= hami
VERSION     ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT      ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE  ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GO_VERSION  ?= $(shell go version | awk '{print $$3}')

# Image variables
REGISTRY    ?= ghcr.io/hami-project
IMG_TAG     ?= $(VERSION)

# Go build flags
LD_FLAGS := -ldflags "-X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.buildDate=$(BUILD_DATE)"
GO_FLAGS := -trimpath $(LD_FLAGS)

# Directories
OUTPUT_DIR  := bin
CMD_DIR     := cmd

.PHONY: all build clean test lint fmt vet docker-build docker-push help

## all: Build all binaries
all: build

## build: Build the project binaries
build:
	@echo "Building $(BINARY_NAME) version=$(VERSION) commit=$(COMMIT)"
	@mkdir -p $(OUTPUT_DIR)
	go build $(GO_FLAGS) -o $(OUTPUT_DIR)/$(BINARY_NAME) ./$(CMD_DIR)/...

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(OUTPUT_DIR)

## test: Run unit tests
test:
	@echo "Running unit tests..."
	go test -v -race -coverprofile=coverage.out ./...

## test-coverage: Show test coverage report
test-coverage: test
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

## lint: Run golangci-lint
lint:
	@which golangci-lint > /dev/null || (echo "golangci-lint not found, installing..." && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest)
	golangci-lint run ./...

## fmt: Run go fmt
fmt:
	@echo "Running go fmt..."
	go fmt ./...

## vet: Run go vet
vet:
	@echo "Running go vet..."
	go vet ./...

## tidy: Tidy go modules
tidy:
	@echo "Tidying go modules..."
	go mod tidy

## generate: Run go generate
generate:
	@echo "Running go generate..."
	go generate ./...

## docker-build: Build Docker image
docker-build:
	@echo "Building Docker image $(REGISTRY)/$(BINARY_NAME):$(IMG_TAG)"
	docker build \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		-t $(REGISTRY)/$(BINARY_NAME):$(IMG_TAG) .

## docker-push: Push Docker image to registry
docker-push:
	@echo "Pushing Docker image $(REGISTRY)/$(BINARY_NAME):$(IMG_TAG)"
	docker push $(REGISTRY)/$(BINARY_NAME):$(IMG_TAG)

## help: Show this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/ /'
