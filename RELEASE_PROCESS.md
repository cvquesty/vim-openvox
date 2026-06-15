# Release Process for vim-openvox (Phase 4)

1. Update version in:
   - plugin/openvox.vim (g:openvox_plugin_version)
   - README.md badge

2. Update CHANGELOG.md with new section (use Keep a Changelog).

3. Commit changes: Follow pre-commit (lint with `make lint`, update docs, tests if applicable, run `make test`).

4. Tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z: summary from CHANGELOG"`

5. Push: `git push origin development --tags`

6. GitHub Actions (release.yml) will:
   - Generate release from CHANGELOG.
   - Create draft or published release.

7. Post-release:
   - Update any downstream (e.g., if used in other estate projects).
   - Announce if major (e.g., via issues or README).

Deprecations: See AGENTS.md. Support for 2 minor versions minimum.

For hotfixes: Patch release vX.Y.Z+1, cherry-pick to development if needed.