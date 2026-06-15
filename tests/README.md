# Testing vim-openvox

This directory contains automated regression tests (modeled after vim-grok).

## Running Tests
```bash
make test          # Run in Vim + Neovim (interactive)
make ci-test       # CI-friendly (captures output, no TTY)
make lint          # Run vint on Vimscript
```

Tests use an isolated vimrc and run via `tests/run.vim`.

## Test Files
- `test_core.vim`: Plugin load, commands, functions, defaults, indent settings.
- `test_align.vim`: Arrow alignment (basic, safety for strings/heredocs, block()).
- `test_indent.vim`: 2-space indent for resources, heredocs, control structures.

## Adding Tests
Add new `test_*.vim` files and source them in `run.vim`.

See `Makefile` for targets and `AGENTS.md` for development commands.

## Future
- Expand coverage (lint integration, completion, navigation).
- Add Vader.vim or headless verification if needed.
