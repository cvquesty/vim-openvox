# Local .grok Rules for vim-openvox

Local overrides for this tree (highest precedence).

- Follow top-level AGENTS.md strictly (Phase 4 complete; see updates for harness, pre-commit via make, structured over YOLO).
- For Vimscript: enforce 2-space indent, no tabs, consistent alignment in code itself.
- Pre-commit: require `make lint && make test` (or ci variant) before commits; reference top AGENTS + PHASE4_PLAN.md.
- Use `todo_write` for multi-step (e.g., this phase).
- Direct fixes ok within structured process.

See top-level AGENTS.md and global ~/.grok/Agents.md.