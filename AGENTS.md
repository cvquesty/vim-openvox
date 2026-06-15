# vim-openvox

Comprehensive Vim/Neovim plugin for OpenVox and Puppet 8+ development.

Enforces Puppet Style Guide: 2-space soft tabs, aligned => arrows in resources, 'ensure' first in attributes, single-quoted strings preferred (double only for interpolation), 140 char lines, # comments only, etc.

## Harness Integration
Follow global `~/.grok/Agents.md` "Harness Capabilities & Active Leverage" section at all times.

- For any changes: use `/commit` (enforce pre-commit checklist: update CHANGELOG, docs, lint, tests if added).
- Vim plugin work: test indent/align manually or with future tests; run vint or equivalent lint.
- Use `plan mode` for major refactors (e.g., full indent rewrite).
- `todo_write` for multi-step fixes (e.g., alignment overhaul; M1 used for harness compliance).
- Project `.grok/` for local rules (this seeds it).
- `grok inspect` to verify loaded rules/skills.

This project had challenges: bad alignment discipline, weird artifacts in code, missed style-guide violations. YOLO mode per user: be aggressive in fixes.

## Project Specifics
- **Core Modules** (autoload/openvox/):
  - align.vim: Arrow alignment logic (critical – has had discipline issues; M1: dead target_col removed, proper column misalignment detection, silent param + auto BufWritePre, only real violations echoerr).
  - lint.vim: Async integration with openvox-lint/puppet-lint, fix, metadata/yaml lint (M1: dynamic tool echoes, no-op YOLO removed).
  - indent is in indent/puppet.vim (not autoload; M1: IsStringOrComment synced to align precision).
  - complete.vim, navigate.vim, snippets.vim, doc.vim.
- **Indent**: indent/puppet.vim – must strictly follow 2-space, resource/conditional handling.
- **Syntax**: syntax/puppet.vim (and epuppet) – must highlight per style (e.g., metaparams, ensure values).
- **Ftplugin**: ftplugin/puppet.vim – sets tabstop=2, comments=# , mappings, surround.
- **Style Enforcement**: Currently relies on external lint + manual align/indent commands. Need to catch more violations proactively (e.g., unaligned arrows as errors, wrong ordering). g:openvox_auto_align (default 0 in plugin; see wiring in plugin/openvox.vim, align auto augroup).
- **Artifacts**: Remove any debug echoes, leftover "puppet" strings that should be openvox, instantiated test code in prod paths, stray prints.
- **Known Issues**: Addressed in Phase 4 (see below and PHASE4_PLAN.md).
- **Testing**: Automated via `make test` / `make lint` (see M2/M3).
- **No prior AGENTS**: Seeded per estate plan; now at Phase 4 maturity.

## Phase 4 Complete
Phase 4 (Polish, Automation & Estate Maturity) complete (M1-M5):
- M1: Core bugfixes/hardening/wiring (alignment with silent auto + column detection, lint dynamic branding, g:openvox_auto_align, no-op YOLO removed).
- M2: Tests/Makefile (vimrc/run/test_*.vim + make lint/test/ci-test, modeled on vim-grok).
- M3: CI (lint.yml + test.yml with Vim primary, release.yml skeleton), pre-commit automation mandated.
- M4: Docs sync (DOCUMENTATION.md inventory/sections, doc/openvox.txt cleaned for openvox-lint preference + auto_align, README/CONTRIBUTING/AGENTS updated, RELEASE_PROCESS.md created).
- M5: Estate alignment (harness use: todo_write, subagents, plan mode; pre-commit via Makefile+CI; .grok/ rules).

See PHASE4_PLAN.md (in session memory or prior) and this AGENTS for details. YOLO history addressed via structured work.

## Development Commands
- `make lint`: Run vint --style-check on Vimscript (autoload/, plugin/, syntax/, etc.).
- `make test`: Run full suite in Vim + Neovim (tests/run.vim + isolated vimrc; covers core, align, indent).
- `make ci-test`: Non-interactive for CI (logs to /tmp).
- Test align: visual select resource body, use :OpenvoxAlign or mapping (or `let g:openvox_auto_align=1` + :w).
- Test indent: == on blocks or resources.
- Test lint: :OpenvoxLint, :OpenvoxLintFix, etc.
- Always: follow pre-commit (this AGENTS + global: CHANGELOG + docs + lint/tests + stage/commit/push). Use `todo_write` for multi-step.
- CI: Run `make lint && make ci-test` (or equivalent) locally before any push/PR. See .github/workflows/ (lint.yml + test.yml).

**CI Status**: GitHub Actions runs lint (vint) + test matrix (Vim primary per user; Neovim for compat) on push/PR to development. Use the "CI" badge in README. Artifacts for test logs on failure.

Run `grok inspect` regularly. Follow global Harness for subagents/plan on big changes.

See CONTRIBUTING.md, README.md, doc/openvox.txt for more.

## Development Commands
- `make lint`: Run vint --style-check on Vimscript (autoload/, plugin/, syntax/, etc.).
- `make test`: Run full suite in Vim + Neovim (tests/run.vim + isolated vimrc; covers core, align, indent).
- `make ci-test`: Non-interactive for CI (logs to /tmp).
- Test align: visual select resource body, use :OpenvoxAlign or mapping (or `let g:openvox_auto_align=1` + :w).
- Test indent: == on blocks or resources.
- Test lint: :OpenvoxLint, :OpenvoxLintFix, etc.
- Always: follow pre-commit (this AGENTS + global: CHANGELOG + docs + lint/tests + stage/commit/push). Use `todo_write` for multi-step.
- CI: Run `make lint && make ci-test` (or equivalent) locally before any push/PR. See .github/workflows/ (lint.yml + test.yml).

**CI Status**: GitHub Actions runs lint (vint) + test matrix (Vim primary per user; Neovim for compat) on push/PR to development. Use the "CI" badge in README. Artifacts for test logs on failure.

Run `grok inspect` regularly. Follow global Harness for subagents/plan on big changes.

See CONTRIBUTING.md, README.md, doc/openvox.txt for more.