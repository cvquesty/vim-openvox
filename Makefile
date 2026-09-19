# Makefile for vim-openvox development
# Run `make help` for available targets

.PHONY: help lint test clean ci-test

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

lint: ## Run vint linter on Vimscript files (requires vint to be installed)
	@echo "Running vint..."
	@vint -s --color --verbose autoload/ plugin/ syntax/ compiler/ ftplugin/ ftdetect/ indent/ || (echo "Lint failed. Install vint with: pip install vim-vint" && exit 1)
	@echo "Lint passed!"

test: ## Run the test suite (requires Vim/Neovim in PATH)
	@echo "Running vim-openvox tests..."
	@vim -Nu tests/vimrc -es -S tests/run.vim -c 'if get(g:, "test_failures", 1) | cquit 1 | else | qall! | endif' || (echo "Vim tests failed"; cat /tmp/vim-openvox-test-result.txt 2>/dev/null; exit 1)
	@echo "Vim tests passed."
	@if command -v nvim >/dev/null 2>&1; then \
		nvim --headless -u tests/vimrc -S tests/run.vim -c 'if get(g:, "test_failures", 1) | cquit 1 | else | qall! | endif' || (echo "Neovim tests failed"; cat /tmp/vim-openvox-test-result.txt 2>/dev/null; exit 1); \
		echo "Neovim tests passed."; \
	else \
		echo "Skipping Neovim tests (nvim not in PATH)."; \
	fi
	@echo "All tests passed."

ci-test: ## CI-friendly test (honors VIM=vim|neovim; judge pass via result file)
	@rm -f /tmp/vim-openvox-test-result.txt /tmp/editor-test.log
	@if [ "$${VIM}" = "neovim" ]; then \
		nvim --headless -u tests/vimrc -S tests/run.vim -c 'if get(g:, "test_failures", 1) | cquit 1 | else | qall! | endif' > /tmp/editor-test.log 2>&1 || true; \
	else \
		vim -Nu tests/vimrc -es -S tests/run.vim -c 'if get(g:, "test_failures", 1) | cquit 1 | else | qall! | endif' > /tmp/editor-test.log 2>&1 || true; \
	fi
	@if ! grep -q 'All tests passed!' /tmp/vim-openvox-test-result.txt 2>/dev/null; then \
		echo "CI tests failed (editor exit may be noisy under -es):"; \
		cat /tmp/editor-test.log 2>/dev/null || true; \
		cat /tmp/vim-openvox-test-result.txt 2>/dev/null || true; \
		exit 1; \
	fi
	@echo "CI tests passed."

clean: ## Clean temporary files
	@find . -name "*.swp" -o -name "*.swo" -o -name "*~" | xargs rm -f || true
	@echo "Cleaned."
