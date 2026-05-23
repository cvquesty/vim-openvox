# vim-openvox

A comprehensive Puppet 8 IDE plugin for Vim. Replaces multiple Puppet-related
plugins with a single, cohesive solution built around the official
[Puppet Style Guide](https://help.puppet.com/core/current/Content/PuppetCore/style_guide.htm).

## Features

| Feature | Description |
|---------|-------------|
| **Syntax Highlighting** | Full Puppet 8 language — resource types, 90+ built-in functions, data types, heredocs, string interpolation, regex, operators, EPP templates |
| **Indentation** | 2-space soft tabs with significantly improved resource and conditional handling (actively ported toward gold-standard vim-puppet behavior) |
| **Arrow Alignment** | Manual + block alignment for `=>` (improved safety against strings/comments) |
| **metadata-json-lint** | Validates module `metadata.json` files |
| **yamllint** | Lints Hiera YAML data files |
| **Omni-completion** | Context-aware completion for types, attributes, functions, variables, ensure values |
| **Arrow Alignment** | Align `=>` arrows per style guide (visual selection or auto-detect block) |
| **Navigation** | Go-to-definition (`gd`), block jumping (`[[` / `]]`) |
| **Documentation** | Press `K` to open Puppet docs in browser |
| **Snippets** | Generate class, defined type, and init.pp boilerplate with Puppet Strings docs |
| **EPP Templates** | Host-language syntax detection (`.conf.epp` → conf + Puppet) |
| **Filetype Detection** | `.pp`, `.epp`, `Puppetfile`, Hiera YAML, `metadata.json` |
| **Compiler** | `:make` integration via puppet-lint and puppet validate |
| **Code Folding** | Fold by indent level |

## Requirements

- **Vim 8.0+** (async job support)
- [openvox-lint](https://github.com/cvquesty/openvox-lint) — `gem install openvox-lint` (preferred)
- [puppet-lint](https://puppetlabs.github.io/puppet-lint/) — `gem install puppet-lint` (also supported)
- [metadata-json-lint](https://github.com/voxpupuli/metadata-json-lint) — `gem install metadata-json-lint`
- [yamllint](https://github.com/adrienverge/yamllint) — `pip install yamllint`

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

vim-openvox works out of the box for syntax, folding, linting, and basic navigation.

**Note on indentation & alignment**: Core features are functional. We are actively porting battle-tested logic from the vim-puppet gold standard to make auto-indent and block alignment rock-solid. Current behavior is good for most cases and improving rapidly.

### Key Mappings

| Mode | Mapping | Action |
|------|---------|--------|
| Normal | `<LocalLeader>l` | Run puppet-lint |
| Normal | `<LocalLeader>v` | Validate puppet syntax |
| Normal | `<LocalLeader>f` | Auto-fix lint issues |
| Normal | `gd` | Go to class/define definition |
| Normal | `K` | Open Puppet documentation |
| Normal | `[[` | Jump to previous class/define/node |
| Normal | `]]` | Jump to next class/define/node |
| Visual | `<LocalLeader>a` | Align `=>` arrows in selection |

### Commands

```vim
:OpenvoxLint            " Run puppet-lint on current file
:OpenvoxLintFix         " Auto-fix puppet-lint issues
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
" Auto-lint on save (default: 1)
let g:openvox_auto_lint = 1

" Line length limit (default: 140)
let g:openvox_max_line_length = 140

" Disable specific puppet-lint checks
let g:openvox_lint_disabled_checks = ['80chars', 'documentation']

" Custom yamllint config for Hiera files
let g:openvox_yamllint_args = ['-c', '~/.yamllint.yml']

" Custom linter paths (if not in $PATH)
" Default is openvox-lint; puppet-lint also supported
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