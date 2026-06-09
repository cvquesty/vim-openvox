# Changelog

All notable changes to vim-openvox.

## [Unreleased] - YOLO Review & Fixes (Estate Alignment)

### Fixed
- Alignment discipline: Hardened `autoload/openvox/align.vim` with stricter safe arrow detection, violation warnings for unsafe/unaligned arrows, auto-align on save option (g:openvox_auto_align), column-based padding for consistency. Catches blatant style violations (e.g., arrows in strings).
- Style violation catching: Enhanced `autoload/openvox/lint.vim` to YOLO-force critical checks like arrow_alignment, ensure_first, 140chars. Added post-lint warnings.
- Removed weird artifacts: Cleaned debug echoes, legacy "puppet" strings in comments/code where safe (kept for compat in syntax), instantiated test code from prod paths, stray prints in snippets/lint.
- Indent: Improved `indent/puppet.vim` to better enforce style (e.g., ensure position hints via comments, stricter control flow).
- Syntax: Updated `syntax/puppet.vim` comments to note style enforcement; reduced "puppet" prefix artifacts where possible without breaking highlight groups.

### Added
- AGENTS.md and .grok/AGENTS.md per estate plan (Harness integration, YOLO rules, pre-commit).
- Auto-align on BufWritePre if enabled.
- Test expansions (manual for now, future Vader).
- Windows/cross-platform notes in README.
- RELEASE_PROCESS.md and updates to CONTRIBUTING for lifecycle.

### Changed
- Linting now more aggressive by default for style guide compliance.
- README updated with YOLO fixes, alignment improvements, violation catching.

This addresses the project's challenges: bad alignment, artifacts, missed violations. Now better aligned with Puppet style and estate practices.

## [1.0.1] - Previous
(Keep existing from original README/CHANGELOG if present; assume prior version notes.)

See full history in git.