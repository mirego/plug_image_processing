# Build configuration
# -------------------

APP_NAME ?= `grep -Eo 'app: :\w*' mix.exs | cut -d ':' -f 3`
APP_VERSION = `grep -Eo 'version: "[0-9\.]*(-?[a-z]+[0-9]*)?"' mix.exs | cut -d '"' -f 2`

# Introspection targets
# ---------------------

.PHONY: help
help: header targets

.PHONY: header
header:
	@echo "\033[34mEnvironment\033[0m"
	@echo "\033[34m---------------------------------------------------------------\033[0m"
	@printf "\033[33m%-23s\033[0m" "APP_NAME"
	@printf "\033[35m%s\033[0m" $(APP_NAME)
	@echo ""
	@printf "\033[33m%-23s\033[0m" "APP_VERSION"
	@printf "\033[35m%s\033[0m" $(APP_VERSION)
	@echo "\n"

.PHONY: targets
targets:
	@echo "\033[34mTargets\033[0m"
	@echo "\033[34m---------------------------------------------------------------\033[0m"
	@perl -nle'print $& if m{^[a-zA-Z_-\d]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'



# Build targets
# -------------

.PHONY: prepare
prepare:
	mix deps.get

# Development targets
# -------------------

.PHONY: dependencies
dependencies: ## Install dependencies
	mix deps.get

# Check, lint and format targets
# ------------------------------

.PHONY: check-test
check-test:
	mix test

.PHONY: check-format
check-format:
	mix format --dry-run --check-formatted

.PHONY: check-unused-dependencies
check-unused-dependencies:
	mix deps.unlock --check-unused

.PHONY: check-github
check-github: check-format check-unused-dependencies check-test ## Run various checks on project files and report as GitHub comment

.PHONY: format
format: ## Format project files
	mix format

.PHONY: lint
lint: lint-elixir ## Lint project files

.PHONY: lint-elixir
lint-elixir:
	mix compile --warnings-as-errors --force
	mix credo --strict
