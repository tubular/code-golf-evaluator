# Makefile for Code Golf Evaluator Docker Images

# Image names
BASE_IMAGE = code-golf-base
APP_IMAGE = code-golf

# Docker build context
DOCKER_DIR = docker
DOCKERFILE_BASE = $(DOCKER_DIR)/Dockerfile.base
DOCKERFILE_APP = $(DOCKER_DIR)/Dockerfile

# Competition to render results for (matches the task folder / release tag name)
COMPETITION ?= 000-hello

# Default target
.PHONY: all
all: $(APP_IMAGE)

# Build base image
.PHONY: base
base: $(BASE_IMAGE)

$(BASE_IMAGE): $(DOCKERFILE_BASE)
	@echo "Building base image: $(BASE_IMAGE)"
	docker build -f $(DOCKERFILE_BASE) -t $(BASE_IMAGE) .
	@echo "Base image built successfully"

# Build application image (depends on base image)
.PHONY: app
app: $(APP_IMAGE)

$(APP_IMAGE): $(BASE_IMAGE) $(DOCKERFILE_APP)
	@echo "Building application image: $(APP_IMAGE)"
	docker build -f $(DOCKERFILE_APP) -t $(APP_IMAGE) .
	@echo "Application image built successfully"

# Force rebuild base image
.PHONY: base-rebuild
base-rebuild:
	@echo "Force rebuilding base image: $(BASE_IMAGE)"
	docker build --no-cache -f $(DOCKERFILE_BASE) -t $(BASE_IMAGE) .
	@echo "Base image rebuilt successfully"

# Force rebuild application image
.PHONY: app-rebuild
app-rebuild: base-rebuild
	@echo "Force rebuilding application image: $(APP_IMAGE)"
	docker build --no-cache -f $(DOCKERFILE_APP) -t $(APP_IMAGE) .
	@echo "Application image rebuilt successfully"

# Test the application in Docker
.PHONY: test
test: $(APP_IMAGE)
	@echo "Running tests in Docker container"
	docker run --rm $(APP_IMAGE) test

# Show language versions
.PHONY: versions
versions: $(APP_IMAGE)
	@echo "Showing language versions in Docker container"
	docker run --rm $(APP_IMAGE) versions

# Run code-golf compile command
.PHONY: compile
compile: $(APP_IMAGE)
	@echo "Running compile command in Docker container"
	docker run --rm $(APP_IMAGE) code-golf compile

# Run code-golf evaluate command
.PHONY: evaluate
evaluate: $(APP_IMAGE)
	@echo "Running evaluate command in Docker container"
	docker run --rm $(APP_IMAGE) code-golf evaluate

# Run code-golf evaluate command with test data
.PHONY: evaluate-test
evaluate-test: $(APP_IMAGE)
	@echo "Running evaluate command with test data in Docker container"
	docker run --rm -e CODEGOLF_PATH=/app/code-golf/t/data $(APP_IMAGE) code-golf evaluate

# Render the Markdown release page locally, exactly as the release workflow does.
# Override the competition with: make release COMPETITION=000-hello
# Stdout is the page; redirect it with: make release > release.md
.PHONY: release
release: $(APP_IMAGE)
	@echo "Rendering release page for $(COMPETITION)" >&2
	docker run --rm \
		-e GIT_SHA="$$(git rev-parse HEAD)" \
		-e FINALIZED_AT="$$(date -u +%FT%TZ)" \
		$(REPO_TREE_URL:%=-e REPO_TREE_URL=%) \
		$(APP_IMAGE) code-golf release $(COMPETITION)

# Clean up Docker images
.PHONY: clean
clean:
	@echo "Removing Docker images"
	-docker rmi $(APP_IMAGE)
	-docker rmi $(BASE_IMAGE)
	@echo "Docker images removed"

# Clean up dangling Docker images
.PHONY: clean-dangling
clean-dangling:
	@echo "Removing dangling Docker images"
	-docker image prune -f
	@echo "Dangling images removed"

# Show help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all           - Build application image (default)"
	@echo "  base          - Build base image only"
	@echo "  app           - Build application image"
	@echo "  base-rebuild  - Force rebuild base image without cache"
	@echo "  app-rebuild   - Force rebuild both images without cache"
	@echo "  test          - Run tests in Docker container"
	@echo "  versions      - Show language versions in container"
	@echo "  compile       - Run compile command in container"
	@echo "  evaluate      - Run evaluate command in container"
	@echo "  evaluate-test - Run evaluate command with test data in container"
	@echo "  release       - Render the Markdown release page (COMPETITION=<tag>)"
	@echo "  clean         - Remove Docker images"
	@echo "  clean-dangling- Remove dangling Docker images"
	@echo "  help          - Show this help message"
