# Contributing to vim-openvox

Thank you for your interest in contributing to vim-openvox! This plugin aims to be a high-quality, modern Vim experience for OpenVox and Puppet 8+ users, closely aligned with the official style guide and the battle-tested vim-puppet reference implementation.

## Ways to Contribute

We welcome contributions in many forms:

- **Bug reports** — Especially around indentation, arrow alignment, and linting integration.
- **Feature requests** — New completion sources, better navigation, LSP integration ideas, etc.
- **Code contributions** — Fixes, improvements, and new features.
- **Documentation** — Improvements to README, help text, or this guide.
- **Testing** — Running the plugin on real-world Puppet/OpenVox codebases and reporting issues.

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/cvquesty/vim-openvox.git
   cd vim-openvox
   ```

2. For Vim development, you can load the plugin directly from the directory using Pathogen, vim-plug (with a local path), or Vim 8+ packages.

3. Useful tools:
   - `vint` (Vim script linter): `pip install vim-vint`
   - A recent Vim 8.1+ or Neovim for testing async features.

## Code Style & Guidelines

- Follow the existing code style (2-space indentation in Vim files).
- Keep changes minimal and focused.
- When porting or aligning logic with the vim-puppet reference, prefer clarity and style-guide fidelity over cleverness.
- Add clear comments for non-obvious logic (especially in `indent/` and `align/`).

## Submitting Changes

1. Create a feature branch from `development`:
   ```bash
   git checkout development
   git checkout -b fix/some-issue
   ```

2. Make your changes, test them thoroughly (especially indentation and alignment on real manifests).

3. Commit with a clear message following the style of recent commits (e.g., `fix(indent): ...`, `docs: ...`).

4. Push your branch and open a Pull Request against the `development` branch.

5. In the PR description, please include:
   - What problem it solves
   - How you tested it
   - Any related issues

## Reporting Issues

When reporting bugs, please include:
- Vim or Neovim version (`:version`)
- Output of `:PuppetLint` or `:OpenvoxLint` if relevant

## Testing

- `make lint`: Run vint style check.
- `make test`: Run full suite in Vim + Neovim (via tests/run.vim + isolated vimrc).
- `make ci-test`: Non-interactive version for CI.
- Add regression tests in `tests/test_*.vim` (core, align, indent) and source them from `run.vim`.
- Always test alignment and indentation on real manifests before submitting.

## Pre-Commit & CI Automation (Estate/Harness)

**MANDATORY before any push/PR:**
- Run `make lint && make test` (or `make ci-test` for non-interactive).
- Follow full checklist in AGENTS.md (CHANGELOG + docs + lint/tests + stage/commit/push).
- Use `todo_write` (or equivalent) for multi-step changes.

CI (GitHub Actions) enforces this on development branch:
- lint.yml: vint via make lint.
- test.yml: matrix (Vim primary, as user works exclusively in Vim; Neovim compat) via make ci-test + artifact upload on failure.
- release.yml: skeleton on tags (draft from CHANGELOG; finalize manually per policy).

See .github/workflows/ and AGENTS.md for details. This aligns with global Harness pre-commit and "ship code, not excuses".
- A minimal reproducible example (a small `.pp` snippet)
- Expected vs actual behavior

## Recognition

Contributors will be acknowledged in the README or release notes as the project matures. Every improvement helps make OpenVox development more pleasant in Vim.

Thank you for helping make vim-openvox great!

---

*This document is part of the v1.0.0 release candidate effort.*