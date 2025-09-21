# PHP-iOS Makefile
# Builds the complete PHP-iOS Swift Package

.PHONY: all build test clean sample-app build-php

# Default target
all: build

# Build the Swift package
build:
	@echo "Building PHP-iOS Swift Package..."
	swift build

# Run tests
test:
	@echo "Running tests..."
	swift test

# Build sample app
sample-app:
	@echo "Building sample app..."
	cd SampleApp && swift build

# Build PHP static library
build-php:
	@echo "Building PHP static library..."
	cd Toolchain && ./build-php.sh

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	swift package clean
	rm -rf .build
	rm -rf SampleApp/.build
	rm -rf Toolchain/build
	rm -rf Toolchain/php-*

# Install dependencies
deps:
	@echo "Installing dependencies..."
	swift package resolve

# Generate Xcode project
xcode:
	@echo "Generating Xcode project..."
	swift package generate-xcodeproj

# Format code
format:
	@echo "Formatting Swift code..."
	find Sources Tests SampleApp -name "*.swift" -exec swift-format -i {} \;

# Lint code
lint:
	@echo "Linting Swift code..."
	find Sources Tests SampleApp -name "*.swift" -exec swift-format lint {} \;

# Help
help:
	@echo "Available targets:"
	@echo "  build       - Build the Swift package"
	@echo "  test        - Run tests"
	@echo "  sample-app  - Build sample app"
	@echo "  build-php   - Build PHP static library"
	@echo "  clean       - Clean build artifacts"
	@echo "  deps        - Install dependencies"
	@echo "  xcode       - Generate Xcode project"
	@echo "  format      - Format Swift code"
	@echo "  lint        - Lint Swift code"
	@echo "  help        - Show this help"