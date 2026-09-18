<div align="center">

# 🦊 vim-openvox

**A comprehensive Vim plugin for OpenVox and Puppet 8+ development**

[![Version](https://img.shields.io/badge/version-1.1.0-orange?style=for-the-badge)](https://github.com/cvquesty/vim-openvox/releases)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue?style=for-the-badge)](LICENSE)
[![Vim](https://img.shields.io/badge/Vim-8.0+-019833?style=for-the-badge&logo=vim&logoColor=white)](https://www.vim.org)
[![Neovim](https://img.shields.io/badge/Neovim-0.5+-57A143?style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io)
[![Language](https://img.shields.io/badge/language-Vim%20Script-019833?style=for-the-badge)](https://www.vim.org)

[![GitHub Stars](https://img.shields.io/github/stars/cvquesty/vim-openvox?style=flat-square)](https://github.com/cvquesty/vim-openvox/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/cvquesty/vim-openvox?style=flat-square)](https://github.com/cvquesty/vim-openvox/issues)
[![Last Commit](https://img.shields.io/github/last-commit/cvquesty/vim-openvox?style=flat-square)](https://github.com/cvquesty/vim-openvox/commits/development)
[![CI](https://img.shields.io/github/actions/workflow/status/cvquesty/vim-openvox/ci.yml?style=flat-square)](https://github.com/cvquesty/vim-openvox/actions)

[Features](#features) · [Installation](#installation) · [Documentation](doc/openvox.txt) · [Contributing](CONTRIBUTING.md)

</div>

---

A comprehensive Vim plugin for OpenVox and Puppet 8+ development, built around the official [Puppet Style Guide](https://help.puppet.com/core/current/Content/PuppetCore/style_guide.htm).

## Features

| Feature | Description |
|---------|-------------|
| **Syntax Highlighting** | Full Puppet 8 language — resource types, 90+ built-in functions, data types, heredocs, string interpolation, regex, operators, EPP templates |
| **Indentation** | 2-space soft tabs with significantly improved resource and conditional handling (actively ported toward gold-standard vim-puppet behavior) |
| **Arrow Alignment** | Align `=>` arrows per style guide (visual selection, block command, or optional auto-align on save) |
| **Linting** | Async openvox-lint for manifests; metadata-json-lint; yamllint for Hiera |
| **Omni-completion** | Context-aware completion for types, attributes, functions, variables, ensure values |
| **Navigation** | Go-to-definition (`gd`), block jumping (`[[` / `]]`) |
| **Documentation** | Press `K` to open Puppet docs in browser |
| **Snippets** | Generate class, defined type, and init.pp boilerplate with Puppet Strings docs |
| **EPP Templates** | Host-language syntax detection (`.conf.epp` → conf + Puppet) |
| **Filetype Detection** | `.pp`, `.epp`, `Puppetfile`, Hiera YAML, `metadata.json` |
| **Compiler** | `:make` integration via openvox-lint and puppet validate |
| **Code Folding** | Fold by indent level |

## Requirements

- **Vim 8.0+** (async job support) / **Neovim 0.5+**
- [openvox-lint](https://github.com/cvquesty/openvox-lint) — **required** for linting: `gem install openvox-lint`
- [metadata-json-lint](https://github.com/voxpupuli/metadata-json-lint) — `gem install metadata-json-lint` (optional; for `metadata.json`)
- [yamllint](https://github.com/adrienverge/yamllint) — `pip install yamllint` (optional; for Hiera YAML)

## Installation

**Pathogen:**
```bash
cd ~/.vim/bundle
git clone https://github.com/cvquesty/vim-openvox.git
```

**vim-plug:**
```vim
Plug 'cvquesty/vim-openvox'
```

**Native packages (Vim 8+):**
```bash
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone https://github.com/cvquesty/vim-openvox.git
```

## Quick Start

Syntax highlighting, folding, indentation, navigation, and mappings work out of the box after install.

For linting, install the OpenVox linter:

```bash
gem install openvox-lint
```

Optional: `gem install metadata-json-lint` and `pip install yamllint` for metadata / Hiera checks.

Useful defaults (see Configuration):

- `g:openvox_auto_lint` — auto-run openvox-lint on save (default: `0`; set to `1` to enable)
- `g:openvox_auto_align` — auto-align `=>` on save (default: `0`; set to `1` to enable)
- `g:openvox_lint_open_quickfix` — auto-open quickfix on lint errors (default: `0`)

See Key Mappings and Commands below, or `:help openvox` for the full reference.

### Key Mappings

| Mode | Mapping | Action |
|------|---------|--------|
| Normal | `<LocalLeader>l` | Run openvox-lint |
| Normal | `<LocalLeader>v` | Validate puppet syntax |
| Normal | `<LocalLeader>f` | Auto-fix lint issues |
| Normal | `gd` | Go to class/define definition |
| Normal | `K` | Open Puppet documentation |
| Normal | `[[` | Jump to previous class/define/node |
| Normal | `]]` | Jump to next class/define/node |
| Visual | `<LocalLeader>a` | Align `=>` arrows in selection |

### Commands

```vim
:OpenvoxLint            " Run openvox-lint on current file
:OpenvoxLintFix         " Auto-fix openvox-lint issues
:OpenvoxValidate        " Run puppet parser validate
:OpenvoxMetadataLint    " Lint metadata.json
:OpenvoxYamlLint        " Lint YAML file with yamllint
:OpenvoxAlign           " Align => arrows (visual selection)
:OpenvoxAlignBlock      " Align => arrows in current block
:OpenvoxGotoDef         " Jump to definition
:OpenvoxDoc             " Open documentation
:OpenvoxClass name      " Insert class boilerplate
:OpenvoxDefine name     " Insert defined type boilerplate
:OpenvoxInit            " Insert init.pp boilerplate
```

## Configuration

Add to your `.vimrc`:

```vim
" Auto-lint on save (default: 0/off). Enable with:
let g:openvox_auto_lint = 1

" Auto-align => arrows on BufWritePre (default: 0/off)
let g:openvox_auto_align = 0

" Open quickfix automatically on lint errors (default: 0/off)
" When off, a concise command-line message is shown; use :copen for details
let g:openvox_lint_open_quickfix = 0

" Line length limit — sets colorcolumn only (default: 140)
let g:openvox_max_line_length = 140

" Disable specific openvox-lint checks
let g:openvox_lint_disabled_checks = ['80chars', 'documentation']

" Custom yamllint config for Hiera files
let g:openvox_yamllint_args = ['-c', '~/.yamllint.yml']

" Custom openvox-lint path (if not in $PATH)
let g:openvox_lint_command = '/usr/local/bin/openvox-lint'
let g:openvox_puppet_command = '/opt/puppetlabs/bin/puppet'

" Disable auto-mappings
let g:openvox_no_mappings = 0

" Enable code folding (default: 1)
let g:openvox_fold = 1
```

## Replacing Other Plugins

vim-openvox aims to be a strong modern replacement. Current replacement quality:

| Old Plugin                  | Replacement Quality in vim-openvox                  | Notes |
|-----------------------------|-----------------------------------------------------|-------|
| `puppet-syntax-vim` / rodjek/vim-puppet | Good (syntax, folding, basic indent)               | Indent & alignment still being hardened to full gold-standard level |
| `vim-puppet-lint` + Syntastic/ALE | Excellent (async, multi-linter, fix, signs)       | One of the strongest parts |
| Tabular / vim-easy-align    | Good (manual + block alignment)                     | Safer now (skips strings/comments) |
| Various snippet plugins     | Basic boilerplate generators                        | Good starting point; pair with UltiSnips/LuaSnip if desired |

Full feature parity on indent/alignment with the gold-standard vim-puppet is the current active focus.

To disable old plugins with Pathogen:
```vim
let g:pathogen_disabled = ['puppet-syntax-vim', 'vim-puppet']
```

## Style Guide Compliance

Every feature is built around the
[Puppet Style Guide](https://help.puppet.com/core/current/Content/PuppetCore/style_guide.htm):

- **Indentation:** 2-space soft tabs, no hard tabs
- **Strings:** Single quotes preferred; double quotes only for interpolation
- **Resources:** `ensure` first, arrows aligned, metaparams last
- **Line length:** 140 characters (configurable)
- **Comments:** `#` only (C-style comments highlighted as warnings)
- **Variables:** `$snake_case` with namespace qualification

## Contributing & Help Wanted

vim-openvox is actively being aligned with the battle-tested vim-puppet gold standard while adding OpenVox-specific enhancements and deeper tooling.

We are looking for contributors in several areas:

- **Core improvements** — Further hardening of indentation and arrow alignment
- **Testing** — Adding regression tests for indent, alignment, and linting
- **Documentation** — Improving examples, tutorials, and the help text
- **LSP / Completion** — Integration ideas with `openvox-editor-services` or coc.nvim / nvim-lsp
- **CI & Packaging** — Making the plugin easier to test and distribute

If you're interested in helping, please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines and how to get started.

All contributions — code, documentation, testing, or ideas — are very welcome. This is a community project to make OpenVox development in Vim as smooth and powerful as possible.

## License

Apache-2.0
