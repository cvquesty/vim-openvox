# Makefile for vim-openvox development
# Run `make help` for available targets

.PHONY: help lint test clean ci-test

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

lint: ## Run vint linter on Vimscript files (requires vint to be installed)
	@echo "Running vint..."
	@vint --style-check --color --verbose autoload/ plugin/ syntax/ compiler/ ftplugin/ ftdetect/ indent/ || (echo "Lint failed. Install vint with: pip install vim-vint" && exit 1)
	@echo "Lint passed!"

test: ## Run the test suite (requires Vim/Neovim in PATH)
	@echo "Running vim-openvox tests..."
	@vim -Nu test/vimrc -S test/run.vim || (echo "Vim tests failed"; exit 1)
	@echo "Vim tests passed."
	@nvim -u test/vimrc -S test/run.vim || (echo "Neovim tests failed"; exit 1)
	@echo "Neovim tests passed."
	@echo "All tests passed (expand with more test_*.vim files for lint, completion, etc.)."

ci-test: ## CI-friendly test (no interactive, capture output)
	@vim -Nu test/vimrc -S test/run.vim > /tmp/vim-test.log 2>&1 || (cat /tmp/vim-test.log; exit 1)
	@nvim -u test/vimrc -S test/run.vim > /tmp/nvim-test.log 2>&1 || (cat /tmp/nvim-test.log; exit 1)
	@echo "CI tests passed."

clean: ## Clean temporary files
	@find . -name "*.swp" -o -name "*.swo" -o -name "*~" | xargs rm -f || true
	@echo "Cleaned."

# Future targets ideas:
# release: Tag and push for new version
# ci: lint + test (for CI environments)