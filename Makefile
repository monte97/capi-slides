# Makefile for capi-slides project
# Provides convenient commands for development, building, and running the Slidev presentation

# Install dependencies
install:
	npm install

# Start the development server
dev:
	npx slidev --open

# Build the static site
build:
	npx slidev build

# Export slides as PDF
export:
	npx slidev export

# Serve the built site locally
serve:
	npx serve dist

# Clean installation (remove node_modules and reinstall)
clean-install:
	rm -rf node_modules
	npm install

# Lint the codebase (if applicable)
lint:
	npm run lint

# Run any available tests
test:
	npm run test

# Deploy to production (if applicable)
deploy:
	npm run deploy

# Clean build artifacts
clean:
	rm -rf dist

# Print help message
help:
	@echo "Available commands:"
	@echo "  make install        - Install dependencies"
	@echo "  make dev            - Start development server"
	@echo "  make build          - Build static site"
	@echo "  make export         - Export slides as PDF"
	@echo "  make serve          - Serve built site locally"
	@echo "  make clean-install  - Clean install dependencies"
	@echo "  make lint           - Lint the codebase"
	@echo "  make test           - Run tests"
	@echo "  make deploy         - Deploy to production"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make help           - Show this help message"