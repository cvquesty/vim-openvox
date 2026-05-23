# vim-openvox — Complete Technical Documentation

## Overview

**vim-openvox** is an 18-file Vim plugin providing a full Puppet 8 IDE experience. It targets Vim 8.0+ and uses async jobs for non-blocking linting. Every feature follows the [Puppet Style Guide](https://help.puppet.com/core/8/Content/PuppetCore/style_guide.htm).

**Repository:** `cvquesty/vim-openvox`  
**License:** Apache-2.0  
**Version:** 1.0.0

---

## File Inventory (18 files)

| # | Path | Lines | Purpose |
|---|------|------:|---------|
| 1 | `plugin/openvox.vim` | 121 | Global config defaults, command definitions, autocmds |
| 2 | `ftplugin/puppet.vim` | 114 | Buffer-local settings for `.pp` files (tabs, folding, mappings, compiler, omni) |
| 3 | `ftdetect/puppet.vim` | 29 | Filetype detection for `.pp`, `.epp`, `Puppetfile`, Hiera YAML, `metadata.json` |
| 4 | `syntax/puppet.vim` | 316 | Puppet 8 syntax highlighting (56 syntax groups) |
| 5 | `syntax/epuppet.vim` | 93 | EPP template syntax with host-language detection |
| 6 | `indent/puppet.vim` | 175 | Smart indentation engine |
| 7 | `autoload/openvox/lint.vim` | 448 | Async linting: puppet-lint, puppet validate, metadata-json-lint, yamllint |
| 8 | `autoload/openvox/align.vim` | 73 | Hash rocket (`=>`) alignment |
| 9 | `autoload/openvox/complete.vim` | 261 | Context-aware omni-completion |
| 10 | `autoload/openvox/navigate.vim` | 93 | Go-to-definition and block jumping |
| 11 | `autoload/openvox/doc.vim` | 43 | Browser-based documentation lookup |
| 12 | `autoload/openvox/snippets.vim` | 148 | Boilerplate generation for classes, defines, init.pp |
| 13 | `compiler/openvox_lint.vim` | 20 | `:make` integration via puppet-lint |
| 14 | `compiler/openvox.vim` | 22 | `:make` integration via puppet parser validate |
| 15 | `doc/openvox.txt` | 404 | Vim help (`:help openvox`) |
| 16 | `README.md` | 147 | GitHub README |
| 17 | `LICENSE` | 189 | Apache 2.0 full text |
| 18 | `.gitignore` | 6 | Swap files, `.DS_Store`, tags |

---

## Architecture

```
vim-openvox/
├── plugin/openvox.vim            ← loaded once globally on startup
│   ├── g:loaded_openvox guard
│   ├── 13 configuration variables (g:openvox_*)
│   ├── 15 command definitions (:Openvox*)
│   └── OpenvoxPlugin augroup (auto-lint on save, EPP/YAML settings)
│
├── ftdetect/puppet.vim           ← filetype detection (autocmds)
├── ftplugin/puppet.vim           ← buffer settings (loaded per .pp buffer)
├── syntax/puppet.vim             ← syntax rules (loaded per .pp buffer)
├── syntax/epuppet.vim            ← EPP syntax (loaded per .epp buffer)
├── indent/puppet.vim             ← indentation engine
│
├── autoload/openvox/             ← lazy-loaded on first use
│   ├── lint.vim                  ← async linting (job_start)
│   ├── align.vim                 ← arrow alignment
│   ├── complete.vim              ← omni-completion
│   ├── navigate.vim              ← go-to-definition, block jumping
│   ├── doc.vim                   ← documentation lookup
│   └── snippets.vim              ← boilerplate generation
│
├── compiler/
│   ├── openvox_lint.vim          ← :compiler openvox_lint
│   └── openvox.vim               ← :compiler openvox
│
└── doc/openvox.txt               ← :help openvox
```

**Load order:** `plugin/` runs once at startup → `ftdetect/` fires on `BufNewFile`/`BufRead` → `syntax/`, `indent/`, `ftplugin/` load per buffer → `autoload/` loads on demand when commands or mappings are invoked.

---

## Detailed File Documentation

### 1. `plugin/openvox.vim` (121 lines)

**Purpose:** The global entry point. Runs once at Vim startup. Defines all configuration defaults, commands, and autocmds.

**Guard:** `g:loaded_openvox` — prevents double-loading.

**Configuration Variables (13):**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `g:openvox_lint_command` | String | `'puppet-lint'` | Path to puppet-lint binary |
| `g:openvox_puppet_command` | String | `'puppet'` | Path to puppet binary |
| `g:openvox_metadata_lint_command` | String | `'metadata-json-lint'` | Path to metadata-json-lint binary |
| `g:openvox_yamllint_command` | String | `'yamllint'` | Path to yamllint binary |
| `g:openvox_max_line_length` | Number | `140` | Sets `textwidth` and `colorcolumn` |
| `g:openvox_fold` | Boolean | `1` | Enable code folding by indent |
| `g:openvox_no_mappings` | Boolean | `0` | Disable all default key mappings |
| `g:openvox_auto_lint` | Boolean | `1` | Auto-lint on save (`.pp`, `metadata.json`, Hiera YAML) |
| `g:openvox_lint_args` | List | `[]` | Extra args passed to puppet-lint |
| `g:openvox_lint_disabled_checks` | List | `[]` | puppet-lint checks to disable (e.g., `['80chars']`) |
| `g:openvox_metadata_lint_args` | List | `[]` | Extra args for metadata-json-lint |
| `g:openvox_yamllint_args` | List | `[]` | Extra args for yamllint (e.g., `['-c', '~/.yamllint.yml']`) |

**Commands (15):**

| Command | Args | Function Called |
|---------|------|-----------------|
| `:OpenvoxLint` | none | `openvox#lint#run()` |
| `:OpenvoxLintFix` | none | `openvox#lint#fix()` |
| `:OpenvoxValidate` | none | `openvox#lint#validate()` |
| `:OpenvoxMetadataLint` | none | `openvox#lint#metadata()` |
| `:OpenvoxYamlLint` | none | `openvox#lint#yaml()` |
| `:OpenvoxAlign` | range | `openvox#align#arrows()` |
| `:OpenvoxAlignBlock` | none | `openvox#align#block()` |
| `:OpenvoxGotoDef` | none | `openvox#navigate#goto_definition()` |
| `:OpenvoxDoc` | none | `openvox#doc#lookup()` |
| `:OpenvoxClass` | 1 arg (name) | `openvox#snippets#class()` |
| `:OpenvoxDefine` | 1 arg (name) | `openvox#snippets#define()` |
| `:OpenvoxInit` | none | `openvox#snippets#init()` |

**Autocmd Group `OpenvoxPlugin`:**
- `BufWritePost *.pp` → `openvox#lint#run()` (when `g:openvox_auto_lint == 1`)
- `BufWritePost */metadata.json` → `openvox#lint#metadata()` (if filetype matches `puppet_metadata`)
- `BufWritePost */data/*.yaml, */hieradata/*.yaml` etc. → `openvox#lint#yaml()`
- `FileType epuppet` → sets 2-space tabs
- `FileType yaml.puppet_hiera` → sets 2-space tabs

---

### 2. `ftplugin/puppet.vim` (114 lines)

**Purpose:** Buffer-local settings applied to every `.pp` file. This is the per-buffer brain.

**Guard:** `b:did_ftplugin`

**Settings applied:**
- `tabstop=2 softtabstop=2 shiftwidth=2 expandtab smarttab` — Style guide indentation
- `textwidth` and `colorcolumn` set from `g:openvox_max_line_length` (default 140)
- `commentstring=#\ %s` and `comments=:#` — Puppet uses `#` comments
- `formatoptions=croql` — auto-wrap comments, insert comment leader
- `foldmethod=indent foldlevel=99 foldminlines=3` — when `g:openvox_fold` is on
- `compiler openvox_lint` — default compiler for `:make`
- `omnifunc=openvox#complete#omnifunc` — Ctrl-X Ctrl-O completion

**Matchit integration:** `%` bounces between `if`/`elsif`/`else`, `case`/`default`, `class`/`inherits`, `{`/`}`

**vim-surround integration:** If vim-surround is loaded:
- `s` → single quotes
- `d` → double quotes
- `v` → `${}` variable interpolation

**Key mappings** (buffer-local, disabled by `g:openvox_no_mappings`):

| Mode | Mapping | Action |
|------|---------|--------|
| Visual | `<LocalLeader>a` | Align `=>` arrows |
| Normal | `<LocalLeader>l` | `:OpenvoxLint` |
| Normal | `<LocalLeader>v` | `:OpenvoxValidate` |
| Normal | `<LocalLeader>f` | `:OpenvoxLintFix` |
| Normal | `gd` | Go-to-definition |
| Normal | `K` | Documentation lookup |
| Normal | `[[` | Previous class/define/node block |
| Normal | `]]` | Next class/define/node block |

**Undo ftplugin:** Properly resets all buffer-local options on filetype change via `b:undo_ftplugin`.

---

### 3. `ftdetect/puppet.vim` (29 lines)

**Purpose:** Maps file patterns to filetypes.

| Pattern | Filetype Set | Notes |
|---------|-------------|-------|
| `*.pp` | `puppet` | Puppet manifests |
| `*.epp` | `epuppet` | EPP templates |
| `Puppetfile` | `ruby` | Module dependency file (Ruby DSL) |
| `*/data/*.yaml`, `*/data/*.yml`, `*/hieradata/*.yaml`, `*/hiera/*.yaml`, etc. | `yaml.puppet_hiera` | Compound filetype — YAML + Puppet Hiera |
| `*/metadata.json` | `json.puppet_metadata` | Only if content-sniffing confirms Puppet metadata |

**Content sniffing for `metadata.json`:** The function `s:DetectPuppetMetadata()` reads the first 20 lines and looks for telltale fields: `operatingsystem_support`, `dependencies`, `puppet`, `pdk-version`, or forge/GitHub project URLs. This prevents false positives on non-Puppet JSON files.

---

### 4. `syntax/puppet.vim` (316 lines)

**Purpose:** Full Puppet 8 syntax highlighting. Case-sensitive (`syn case match`).

**56 syntax groups organized into categories:**

| Category | Groups | What's Highlighted |
|----------|--------|--------------------|
| Comments | `puppetComment`, `puppetTodo`, `puppetCComment` | `#` comments (preferred), C-style `/* */` and `//` (discouraged) |
| Strings | `puppetSQString`, `puppetDQString`, `puppetHeredoc`, `puppetHeredocNI` | Single-quoted (no interpolation), double-quoted (with interpolation), heredocs (interpolating and non-interpolating) |
| Escapes | `puppetSQEscape`, `puppetDQEscape` | `\\`, `\'` in SQ; `\n`, `\t`, `\$`, `\uXXXX`, `\xXX` in DQ |
| Interpolation | `puppetInterpolation` | `${expression}` and `$variable` inside double-quoted strings |
| Numbers | `puppetInteger`, `puppetFloat` | Decimal, hex (`0x`), octal (`0o`), binary (`0b`), float with exponent |
| Booleans | `puppetBoolean`, `puppetUndef` | `true`, `false`, `undef` |
| Variables | `puppetVariable` | `$name`, `$module::name`, `$var[0]`, `$var['key']` |
| Resource Types | `puppetResourceType` | **7 non-conflicting core (keyword):** exec, filebucket, package, resources, service, stage, tidy. **5 contextual core (match before `{`):** file, group, notify, schedule, user. **26 core-module (keyword):** augeas, cron, host, mount, ssh\_authorized\_key, sshkey, nagios\_\*, selboolean, yumrepo, zfs, zone, zpool. **11 common-module (keyword):** anchor, concat, firewall, apt, vcsrepo, ini\_setting, file\_line |
| Metaparams | `puppetMetaparam` | **Keyword:** alias, audit, before, loglevel, noop, subscribe. **Match (before `=>`):** notify, schedule |
| Attributes | `puppetAttribute` | 50+ resource attribute names: ensure, command, content, group, owner, mode, user, etc. |
| Ensure Values | `puppetEnsureValue` | present, absent, purged, latest, installed, running, stopped, enabled, disabled, directory, link |
| Keywords | `puppetKeyword` | class, define, node, inherits, application, site, produces, consumes, type, attr, plan |
| Conditionals | `puppetConditional` | if, elsif, else, unless, case, default, selector |
| Operators | `puppetOperator`, `puppetArrow`, `puppetHashRocket` | `==`, `!=`, `=~`, `!~`, `>=`, `<=`, `and`, `or`, `not`, `!`, `+`, `-`, `*`, `/`, `%`, `<<`, `>>`, `+>`, `=`, `->`, `~>`, `<-`, `<~`, `=>`, `*`, `in` |
| Delimiters | `puppetDelimiter` | `{}`, `()`, `[]`, `:`, `,`, `;` |
| Data Types | `puppetType` | 40 types: String, Integer, Float, Boolean, Array, Hash, Optional, Variant, Enum, Pattern, Struct, Tuple, Callable, Sensitive, Deferred, SemVer, Timestamp, etc. |
| Functions | `puppetFunction` | **90+ core built-ins:** abs, alert, all, each, filter, map, reduce, lookup, template, inline\_epp, etc. **30+ stdlib:** ensure\_packages, validate\_\*, str2bool, any2array, deep\_merge, to\_json, etc. |
| Definitions | `puppetDefine` | Matches `class name`, `define name`, `node name` declarations |
| Resource Refs | `puppetResourceRef` | `File['/path']`, `Service['name']` — capitalized type with brackets |
| Collectors | `puppetCollector`, `puppetExportCollector` | `<\| \|>` (virtual), `<<\| \|>>` (exported) |
| Virtual | `puppetVirtual` | `@` and `@@` prefixes on resources |
| Regex | `puppetRegex`, `puppetRegexSpecial` | `/pattern/` with escape sequences |
| Node | `puppetNodeName`, `puppetNodeDef` | `node 'name'` declarations |
| Lambda | `puppetLambdaPipe` | `\|$var\|` lambda parameter syntax |
| EPP | `puppetEppTag` | `<% %>` tags in `.pp` files (for `inline_epp`) |
| Defaults | `puppetResDefault` | `File { owner => 'root' }` resource defaults |
| Includes | `puppetInclude` | `include`, `require`, `contain`, `realize` statements |

**Context-sensitive highlighting for dual-role words:**

Five words serve as both resource type names and attribute/metaparam names. The syntax file uses `\ze` lookahead to match them only in the correct context:

| Word | Before `{` (declaration) | Before `=>` (body) |
|------|--------------------------|---------------------|
| `file` | Type (puppetResourceType match) | — (plain text) |
| `group` | Type (puppetResourceType match) | Keyword (puppetAttribute keyword) |
| `notify` | Type (puppetResourceType match) | Special (puppetMetaparam match) |
| `schedule` | Type (puppetResourceType match) | Special (puppetMetaparam match) |
| `user` | Type (puppetResourceType match) | Keyword (puppetAttribute keyword) |

`require` and `tag` also serve as metaparams but are handled by `puppetFunction` (keywords beat matches in Vim's syntax engine, and their function usage is more common).

**Highlight link map:**

| Syntax Group | Vim Highlight | Typical Color |
|-------------|---------------|---------------|
| `puppetComment`, `puppetCComment` | Comment | grey/italic |
| `puppetSQString`, `puppetDQString`, `puppetHeredoc` | String | green/yellow |
| `puppetSQEscape`, `puppetDQEscape` | SpecialChar | orange |
| `puppetInterpolation` | Identifier | cyan |
| `puppetInteger` | Number | magenta |
| `puppetFloat` | Float | magenta |
| `puppetBoolean` | Boolean | magenta |
| `puppetUndef`, `puppetEnsureValue` | Constant | magenta |
| `puppetVariable` | Identifier | cyan |
| `puppetResourceType`, `puppetType`, `puppetResourceRef`, `puppetResDefault` | Type | green |
| `puppetMetaparam`, `puppetCollector`, `puppetExportCollector`, `puppetVirtual` | Special | purple |
| `puppetAttribute`, `puppetKeyword`, `puppetNodeDef` | Keyword | yellow/bold |
| `puppetConditional` | Conditional | yellow |
| `puppetOperator`, `puppetArrow`, `puppetHashRocket` | Operator | white/bold |
| `puppetDelimiter`, `puppetLambdaPipe` | Delimiter | white |
| `puppetFunction` | Function | cyan/bold |
| `puppetDefine` | Define | yellow |
| `puppetRegex` | String | green |
| `puppetEppTag` | PreProc | purple |
| `puppetInclude` | Statement | yellow |
| `puppetTodo` | Todo | yellow bg |

---

### 5. `syntax/epuppet.vim` (93 lines)

**Purpose:** EPP (Embedded Puppet) template syntax — like ERB but for Puppet.

**Host language detection:** Strips `.epp` from the filename, takes the remaining extension, and maps it:

| Extension | Host Syntax |
|-----------|-------------|
| `.html`, `.htm` | html |
| `.yaml`, `.yml` | yaml |
| `.json` | json |
| `.sh`, `.bash` | sh |
| `.conf`, `.cfg` | conf |
| `.ini` | dosini |
| `.toml` | toml |
| `.rb` | ruby |
| `.py` | python |

The host syntax is loaded first, then Puppet syntax is included as `@puppetSyntax` cluster.

**EPP tag types:**
- `<%= expr %>` — expression (output)
- `<% code %>` — code block (no output)
- `<%- code -%>` — code block with whitespace trimming
- `<%# comment %>` — comment
- `<%| params |%>` — parameter declaration
- `<%%` — literal `<%` escape

---

### 6. `indent/puppet.vim` (175 lines)

**Purpose:** Smart indentation engine via `indentexpr=GetPuppetIndent()`.

**Indent keys:** `0}`, `0]`, `0)`, `=elsif`, `=else`, `=unless`, `=default`, `=|`

**Helper functions (all script-local):**
- `s:IsStringOrComment(lnum, col)` — checks if position is inside a string/comment/heredoc via syntax ID
- `s:CleanLine(line)` — strips string contents and comments to avoid false pattern matches
- `s:CountUnmatched(line, open, close)` — counts unbalanced braces/parens/brackets
- `s:PrevCodeLine(lnum)` — finds previous non-blank, non-comment line
- `s:InHeredoc(lnum)` — returns `-1` (don't change indent) inside heredocs

**Indent rules (`GetPuppetIndent()`):**
1. Inside heredoc → return `-1` (preserve existing indent)
2. **Increase** by `shiftwidth` for each unmatched `{`, `(`, `[` on previous line
3. **Increase** for lines ending with `:` **only when no preceding brace increase occurred** (prevents double-indent on `resource { 'title':`)
4. Real handling for control keywords (`if`/`elsif`/`else`/`unless`/`case`) — increase when previous line opens a block without immediate `{`
5. **Decrease** when current line starts with `}`, `)`, `]`
6. **Dedent** on current line for `elsif`/`else`/`default`
7. Floor at 0 (no negative indent)

Note: This logic has been actively aligned toward the battle-tested vim-puppet gold standard. String/comment awareness in `PrevCodeLine` was improved. Further edge-case hardening (lambdas, complex chaining) is ongoing.

---

### 7. `autoload/openvox/lint.vim` (448 lines)

**Purpose:** The async linting engine. The largest file in the plugin.

**Script-local state:**
- `s:lint_job` — current `job_start()` handle (or `v:null`)
- `s:lint_output` — stdout lines collected
- `s:lint_errors` — stderr lines collected
- `s:lint_type` — which linter is running

**Public functions (6):**

| Function | Triggered By | What It Does |
|----------|-------------|--------------|
| `openvox#lint#run()` | `:OpenvoxLint`, auto-save | Runs `puppet-lint` with `--log-format` for parsable output |
| `openvox#lint#fix()` | `:OpenvoxLintFix` | Runs `puppet-lint --fix`, reloads file, then re-lints |
| `openvox#lint#validate()` | `:OpenvoxValidate` | Runs `puppet parser validate` |
| `openvox#lint#metadata()` | `:OpenvoxMetadataLint` | Runs `metadata-json-lint` |
| `openvox#lint#yaml()` | `:OpenvoxYamlLint` | Runs `yamllint -f parsable` |
| `openvox#lint#auto()` | (available for custom use) | Dispatches to the right linter based on filetype |

**All linters share the same pattern:**
1. Validate the file exists and is correct type
2. Auto-save if modified
3. Kill any running lint job (`s:kill_job()`)
4. Reset output buffers
5. Build command with user config (extra args, disabled checks)
6. Launch via `job_start()` with `in_io: null` (prevents stdin blocking), `out_mode: nl`, `err_mode: nl`
7. Collect output via `s:on_stdout` / `s:on_stderr` callbacks
8. Parse results in exit callback → populate quickfix list

**puppet-lint output format:** `path:line:column:KIND:check:message`
- Parsed into quickfix entries with type `E` (ERROR) or `W` (WARNING)
- Check name included in brackets: `[arrow_alignment] ...`

**puppet validate parsing:** Handles two output formats:
- `Error: message at file:line:col`
- `Error: message (file: path, line: N, column: N)`

**metadata-json-lint parsing:** Simple `Error:` / `Warning:` prefix matching, all errors pinned to line 1.

**yamllint parsing:** `-f parsable` format: `file:line:col: [level] message`

**Quickfix behavior:** On completion:
- 0 issues → green `✓` message, `cclose`
- Issues found → yellow/red count message, `botright copen`

**Fix flow** (`openvox#lint#fix`):
1. Run `puppet-lint --fix`
2. On success: `:edit` to reload, then re-run lint to show remaining issues
3. On failure: display error messages

---

### 8. `autoload/openvox/align.vim` (73 lines)

**Purpose:** Aligns `=>` arrows in resource bodies per style guide.

**`openvox#align#arrows()` (range function):**
1. First pass: find the longest key name (text before `=>`) across all selected lines
2. Second pass: pad each key with spaces so all `=>` align at `max_key_len + 1`
3. Uses `setline()` to rewrite each line in-place

**`openvox#align#block()`:**
1. Uses `searchpair()` to find the enclosing `{ }` block
2. Calls `arrows()` on lines between the braces (exclusive of `{` and `}` lines)
3. Restores cursor position

---

### 9. `autoload/openvox/complete.vim` (261 lines)

**Purpose:** Context-aware omni-completion.

**Static data tables:**
- `s:resource_types` — 24 types (core + common modules)
- `s:metaparameters` — 10 metaparams
- `s:common_attributes` — per-type attribute lists for exec, file, package, service, user, group, cron, mount, host, notify (10 types, ~15 attrs each)
- `s:ensure_values` — per-type ensure values (file: absent/directory/file/link/present; package: absent/held/installed/latest/present/purged; etc.)
- `s:builtin_functions` — 95 functions (core + stdlib)
- `s:data_types` — 40 Puppet type system types
- `s:keywords` — 27 language keywords

**`openvox#complete#omnifunc(findstart, base)`:**

Phase 1 (`findstart=1`): Walks backward from cursor to find word start, matching `[a-zA-Z0-9_:$]`.

Phase 2 (`findstart=0`): Context-dependent completion:

| Context | Detection | Completions Offered |
|---------|-----------|---------------------|
| Variable | `base` starts with `$` | All `$variables` found in current buffer |
| Ensure value | Line matches `ensure\s*=>\s*\w*$` | Type-specific ensure values |
| Attribute | Inside a resource body (looked up by scanning backward for `type {`) | Type-specific attributes + metaparameters |
| Data type | Line starts with uppercase letter | All 40 Puppet data types |
| General | Default | Resource types `[resource]`, functions `[function]`, types `[type]`, keywords `[keyword]` |

**Variable completion** (`s:complete_variables`): Scans entire buffer for `$word(::word)*` patterns. Returns sorted, deduplicated list.

**Resource detection** (`s:find_enclosing_resource`): Walks backward from cursor looking for `\w+ {` pattern to determine which resource type we're inside.

---

### 10. `autoload/openvox/navigate.vim` (93 lines)

**Purpose:** Code navigation.

**`openvox#navigate#goto_definition()`:**
1. Gets the `<cWORD>` under cursor
2. Strips quotes, commas, `Class[]`/`Type[]` wrappers
3. Converts `module::class::name` to file path: `module/manifests/class/name.pp`
4. Searches in order:
   - `**/modules/<module>/manifests/<rest>.pp`
   - `**/<module>/manifests/<rest>.pp`
   - `**/site/<module>/manifests/<rest>.pp`
   - `**/site-modules/<module>/manifests/<rest>.pp`
5. For single-part names: searches `**/modules/<name>/manifests/init.pp`
6. Fallback: searches current file for `class|define <name>`
7. On success: opens the file and jumps to the declaration

**`openvox#navigate#prev_block()`:** `search('^\s*\(class\|define\|node\)\s\+', 'bW')`

**`openvox#navigate#next_block()`:** `search('^\s*\(class\|define\|node\)\s\+', 'W')`

---

### 11. `autoload/openvox/doc.vim` (43 lines)

**Purpose:** Press `K` to open Puppet docs in a browser.

**URL construction:**
- If word is a known built-in resource type → `https://help.puppet.com/core/8/Content/PuppetCore/types/<word>.htm`
- If word is lowercase/underscored (likely a function) → `https://help.puppet.com/core/8/Content/PuppetCore/function.htm#<word>`
- Otherwise → `https://help.puppet.com/search?q=<word>`

**Browser launch:** `open` on macOS, `xdg-open` on Linux, `start` on Windows.

---

### 12. `autoload/openvox/snippets.vim` (148 lines)

**Purpose:** Generate Puppet Strings–documented boilerplate.

**`:OpenvoxClass <name>`** generates:
```puppet
# @summary
#   A short summary of the purpose of this class.
#
# @param param1
#   Description of param1.
#
# @example
#   include <name>
#
class <name> (
  String $param1 = 'default',
) {

}
```

**`:OpenvoxDefine <name>`** generates the same pattern but with `define` keyword and an `@param title` docstring, plus a usage example in resource declaration style.

**`:OpenvoxInit`** generates a full `init.pp` with:
- `@param manage_package`, `manage_service`, `package_ensure`, `service_ensure`, `service_enable`
- Typed Boolean/String parameters with defaults
- Conditional `package {}` and `service {}` resource declarations
- **Auto-detects module name** from file path: matches `.../modules/<name>/manifests/init.pp` or `.../site*/<name>/manifests/init.pp`
- Falls back to interactive `input()` prompt if path can't be parsed
- If buffer is empty, replaces it entirely; otherwise appends at cursor

---

### 13–14. Compiler Files

**`compiler/openvox_lint.vim` (20 lines):**
- `current_compiler = 'openvox_lint'`

---

## Development & Testing

### Linting the Plugin
```bash
vint --style .
```

### Manual Regression Testing
Always test on real manifests:
- Resource declarations with `ensure` first + arrows
- `if / elsif / else` (with and without braces on same line)
- `case` statements
- Heredocs
- Comments and strings containing `{` or `=>`

### Contributing
When porting improvements from the vim-puppet reference implementation, keep changes minimal and faithful to the Puppet Style Guide. Prefer clarity over cleverness in the indent and alignment logic.
- `makeprg` = `puppet-lint --log-format '%{path}:%{line}:%{column}:%{KIND}:%{check}:%{message}' %`
- `errorformat` = `%f:%l:%c:%t%*[A-Z]:%m`

**`compiler/openvox.vim` (22 lines):**
- `current_compiler = 'openvox'`
- `makeprg` = `<puppet_cmd> parser validate %`
- `errorformat` handles three Puppet parser output formats

Both respect `g:openvox_lint_command` and `g:openvox_puppet_command` for custom paths.

---

## Internal Namespace Convention

| Layer | Naming | Example |
|-------|--------|---------|
| Autoload functions | `openvox#<module>#<func>()` | `openvox#lint#run()` |
| Config variables | `g:openvox_<name>` | `g:openvox_auto_lint` |
| Commands | `:Openvox<Name>` | `:OpenvoxLint` |
| Plugin guard | `g:loaded_openvox` | — |
| Autocmd group | `OpenvoxPlugin` | — |
| Compiler names | `openvox`, `openvox_lint` | — |
| Syntax groups | `puppet<Name>` | `puppetKeyword` (language-level, not plugin-level) |
| Filetype names | `puppet`, `epuppet` | (Vim convention — matches syntax/indent/ftplugin filenames) |

---

## Installation & Integration

**Symlink (current setup):**
```
~/.vim/bundle/vim-openvox → ~/Projects/vim-openvox
```

**`.vimrc` integration:**
```vim
let g:pathogen_disabled = ['windsurf.vim', 'puppet-syntax-vim', 'vim-puppet']
execute pathogen#infect()
let g:openvox_align_hashes = 1
```

**External dependencies:**

| Tool | Install | Used By |
|------|---------|---------|
| puppet-lint | `gem install puppet-lint` | `:OpenvoxLint`, `:OpenvoxLintFix`, auto-lint |
| puppet | (Puppet Agent) | `:OpenvoxValidate` |
| metadata-json-lint | `gem install metadata-json-lint` | `:OpenvoxMetadataLint` |
| yamllint | `pip install yamllint` | `:OpenvoxYamlLint` |

---

## Design Decisions

### Why filetype-keyed files keep the `puppet` name

Vim requires that `syntax/X.vim`, `indent/X.vim`, `ftplugin/X.vim`, and `ftdetect/X.vim` match the filetype name. Since the language is Puppet (filetype `puppet`), these files must be named `puppet.vim`. The plugin branding (`openvox`) appears in autoload paths, commands, config variables, and the plugin entry point — everywhere the name is a choice rather than a Vim constraint.

### Why async linting uses `in_io: null`

Early testing revealed that `job_start()` defaults to creating a pipe for stdin. Some linter processes (particularly puppet-lint) would block waiting for stdin to close. Setting `'in_io': 'null'` connects stdin to `/dev/null`, preventing this hang.

### Why syntax uses `syn match` with `\ze` for some resource types

Five words (`file`, `group`, `notify`, `schedule`, `user`) serve as both resource type names and attribute/metaparam names. Using `syn keyword` (which matches globally) would give them Type color everywhere, including inside resource bodies where they should be Attribute or Metaparam color. The `\ze\s*{` lookahead restricts the Type match to declaration position only.

### Why `require` and `tag` show Function color

Both words appear in `puppetFunction` as `syn keyword` entries. Since Vim's `syn keyword` always takes priority over `syn match`, these words get Function color regardless of context. This is acceptable because `require modulename` (function) is more common than `require => Resource['x']` (metaparam), and `tag('name')` (function) is more common than `tag =>` (metaparam).

### Why `puppetAttribute` is not `contained`

Originally, `puppetAttribute` was marked `contained` to restrict it to resource body regions. However, no resource body `syn region` was defined to include it, making it dead code. Removing `contained` makes attributes highlight globally, which is acceptable because words like `ensure`, `owner`, `mode`, and `content` are distinctive enough to the Puppet domain that false positives are extremely rare.