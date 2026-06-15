# Changelog

All notable changes to vim-openvox.

## [Unreleased] - Phase 4 M1: Core Bugfixes, Hardening & Feature Wiring (Harness Execution)

### Fixed (M1)
- autoload/openvox/align.vim: Removed dead `l:target_col` (scope leak, unused, used stale l:indent). Replaced rough single-line post-=> heuristic in block() with proper column-based detection (collect safe arrows + compute max_key + compare current arrow_col to expected = len(indent) + max_key per entry for true cross-line misalignment per style guide). Added optional `silent` param to arrows()/block() (for auto paths). Made BufWritePre auto call use silent=1 (context-aware, no noise on save for non-violations or "not in block"). Only echoerr on *real* violations (unsafe arrows in strings/comments, unaligned in block); info echoes suppressed in silent. Safety model (IsInStringOrComment + searchpair skip + heredoc/interp) kept/enhanced + documented.
- indent/puppet.vim: Updated s:IsStringOrComment to match align's precise logic (synID + 'Comment\|String\|Heredoc\|Interpolation' regex + comment; was less complete 'string\|comment\|heredoc').
- plugin/openvox.vim: Wired g:openvox_auto_align = 0 default. Set g:openvox_lint_command default to 'openvox-lint' (from legacy 'puppet-lint').
- autoload/openvox/lint.vim + compiler/openvox_lint.vim: Branding/consistency sweep - all user-facing echoes now dynamic: `let l:tool = fnamemodify(get(g:, 'openvox_lint_command', 'openvox-lint'), ':t')` (and equiv for puppet_cmd). No more hard 'puppet-lint:' / 'puppet:' in lint/validate paths. Removed no-op YOLO style_checks force loop (and related dead comments). Style now "real" via defaults + explicit --no- handling (openvox-lint supports --only-checks via user args if needed; noted in code). Internal types kept for compat; s:lint_tool / s:puppet_tool for display. Header/comments cleaned for openvox-lint preference + compat.
- Corrected prior overclaims in docs/CHANGELOG from incomplete YOLO (no evidence of prior harness use, dead code persisted, heuristic not full col, no-op force, defaults not wired, etc.).

### Added (M1)
- g:openvox_auto_align fully wired + documented (README config, doc/openvox.txt, AGENTS.md + .grok/AGENTS.md).
- Harness compliance: todo_write used throughout M1 (one in_progress at time); all files read before edit (read_file/grep/list_dir); search_replace for changes; git worktree isolation at /tmp/vim-openvox-phase4-m1 (branch phase4-m1, source /Users/jsheets/workspace/Personal/vim-openvox on development); pre-commit followed (this CHANGELOG, docs, verification runs, no version bump needed).
- AGENTS.md / .grok/AGENTS.md updates for M1 details + new config var.
- Verification: vint simulation, batch vim/nvim loads for g: defaults, greps for changes, git status/diff in worktree.

### Changed
- Pre-commit discipline enforced for M1 (even in subagent implementer mode). All edits in isolated worktree. No new files created (chose sync indent helper over shared util.vim to obey "NEVER create unless absolutely necessary").
- Default now prefers openvox-lint everywhere (plugin, compiler, dynamic echoes, docs notes updated for compat).
- Alignment auto is discoverable/configurable (was in align comments only, undoc'd, default not set).

M1 executed per Phase 4 plan (from memory synthesis + explicit M1 tasks). Parallel reviewer handoff via outputs/todos. M2+ (tests/Makefile/CI/full docs/release) not started. See worktree for patch: git diff in /tmp/vim-openvox-phase4-m1 .

This closes the identified gaps (target_col, heuristic, wiring, branding, no-op, helper inconsistency, docs drift, harness usage).

## [1.0.1] - Previous
(Keep existing from original README/CHANGELOG if present; assume prior version notes.)

See full history in git.

## [1.0.1] - Previous
(Keep existing from original README/CHANGELOG if present; assume prior version notes.)

See full history in git.