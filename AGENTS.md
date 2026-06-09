# vim-openvox

Comprehensive Vim/Neovim plugin for OpenVox and Puppet 8+ development.

Enforces Puppet Style Guide: 2-space soft tabs, aligned => arrows in resources, 'ensure' first in attributes, single-quoted strings preferred (double only for interpolation), 140 char lines, # comments only, etc.

## Harness Integration
Follow global `~/.grok/Agents.md` "Harness Capabilities & Active Leverage" section at all times.

- For any changes: use `/commit` (enforce pre-commit checklist: update CHANGELOG, docs, lint, tests if added).
- Vim plugin work: test indent/align manually or with future tests; run vint or equivalent lint.
- Use `plan mode` for major refactors (e.g., full indent rewrite).
- `todo_write` for multi-step fixes (e.g., alignment overhaul).
- Project `.grok/` for local rules (this seeds it).
- `grok inspect` to verify loaded rules/skills.

This project had challenges: bad alignment discipline, weird artifacts in code, missed style-guide violations. YOLO mode per user: be aggressive in fixes.

## Project Specifics
- **Core Modules** (autoload/openvox/):
  - align.vim: Arrow alignment logic (critical – has had discipline issues).
  - lint.vim: Async integration with openvox-lint/puppet-lint, fix, metadata/yaml lint.
  - indent is in indent/puppet.vim (not autoload).
  - complete.vim, navigate.vim, snippets.vim, doc.vim.
- **Indent**: indent/puppet.vim – must strictly follow 2-space, resource/conditional handling.
- **Syntax**: syntax/puppet.vim (and epuppet) – must highlight per style (e.g., metaparams, ensure values).
- **Ftplugin**: ftplugin/puppet.vim – sets tabstop=2, comments=# , mappings, surround.
- **Style Enforcement**: Currently relies on external lint + manual align/indent commands. Need to catch more violations proactively (e.g., unaligned arrows as errors, wrong ordering).
- **Artifacts**: Remove any debug echoes, leftover "puppet" strings that should be openvox, instantiated test code in prod paths, stray prints.
- **Known Issues (YOLO fixes needed)**:
  - Alignment: padding/ safe detection not strict enough; doesn't always enforce in practice.
  - Violations: lint doesn't catch blatant style (e.g., double quotes, misordered attrs, >140 lines in real-time).
  - Artifacts: search for debug, system in wrong lists, etc.
- **Testing**: Currently manual (tests/README). Future: add Vader or native tests for indent/align/style.
- **No prior AGENTS**: This seeds per estate plan for high-value vim trees.

## YOLO Mode Rules
- Be direct and aggressive in code changes to fix discipline, remove artifacts, add violation catching.
- Update tests/docs/CHANGELOG on every meaningful edit.
- Use estate pre-commit: lint (vint if applicable), manual style check, update AGENTS if rules change.
- Prioritize fixes for alignment first, then lint catching, then clean artifacts.

## Development Commands
- `make lint` (if present) or manual vint on Vimscript.
- Test align: visual select resource body, use :OpenvoxAlign or mapping.
- Test indent: == on blocks.
- Test lint: :OpenvoxLint etc.

Run `grok inspect` regularly. Follow global Harness for subagents/plan on big changes.

See CONTRIBUTING.md, README.md, doc/openvox.txt for more.