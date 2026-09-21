" tests/test_core.vim - Core tests for vim-openvox
" Run via: vim -Nu tests/vimrc -S tests/run.vim

echo 'Running vim-openvox core tests...'

" Test 1: Plugin loaded
if !exists('g:loaded_openvox')
  echo 'FAIL: Plugin not loaded'
  throw 'FAIL: Plugin not loaded'
endif
echo 'PASS: Plugin loaded'

" Test 2: Commands are defined
let s:commands = ['OpenvoxLint', 'OpenvoxLintFix', 'OpenvoxValidate', 'OpenvoxMetadataLint', 'OpenvoxYamlLint', 'OpenvoxAlign', 'OpenvoxAlignBlock', 'OpenvoxGotoDef', 'OpenvoxDoc', 'OpenvoxClass', 'OpenvoxDefine', 'OpenvoxInit']
for s:cmd in s:commands
  if exists(':' . s:cmd) != 2
    echo 'FAIL: Command :' . s:cmd . ' not defined'
    throw 'FAIL: Command :' . s:cmd . ' not defined'
  endif
endfor
echo 'PASS: All core commands defined'

" Test 3: Autoload functions (runtime-load; do NOT call lint#run — it starts a job)
runtime autoload/openvox/align.vim
runtime autoload/openvox/lint.vim
runtime autoload/openvox/complete.vim
if !exists('*openvox#align#arrows')
  echo 'FAIL: openvox#align#arrows not defined'
  throw 'FAIL: openvox#align#arrows not defined'
endif
if !exists('*openvox#lint#run')
  echo 'FAIL: openvox#lint#run not defined'
  throw 'FAIL: openvox#lint#run not defined'
endif
if !exists('*openvox#complete#omnifunc')
  echo 'FAIL: openvox#complete#omnifunc not defined'
  throw 'FAIL: openvox#complete#omnifunc not defined'
endif
echo 'PASS: Core functions defined'

" Test 4: Product default for auto_lint is 1.
" tests/vimrc sets g:openvox_auto_lint = 0 before plugin load so CI does not
" spawn lint jobs. Re-run the plugin's exists() assignment with the var unset.
if get(g:, 'openvox_auto_lint', -1) != 0
  echo 'FAIL: harness should force auto_lint 0 (got ' . string(get(g:, 'openvox_auto_lint', -1)) . ')'
  throw 'FAIL: harness should force auto_lint 0'
endif
let s:saved_auto_lint = g:openvox_auto_lint
let s:root = expand('<sfile>:p:h:h')
let s:plugin = readfile(s:root . '/plugin/openvox.vim')
let s:idx = -1
let s:i = 0
while s:i < len(s:plugin)
  if s:plugin[s:i] ==# "if !exists('g:openvox_auto_lint')"
    let s:idx = s:i
    break
  endif
  let s:i += 1
endwhile
if s:idx < 0 || s:idx + 2 >= len(s:plugin)
  throw 'FAIL: auto_lint default block missing from plugin/openvox.vim'
endif
let s:block = s:plugin[s:idx : s:idx + 2]
if s:block[2] !~# '^endif\s*$'
  throw 'FAIL: auto_lint default block is not a 3-line exists() guard'
endif
try
  unlet g:openvox_auto_lint
  execute join(s:block, "\n")
  if g:openvox_auto_lint != 1
    throw 'FAIL: auto_lint product default should be 1 (got ' . string(get(g:, 'openvox_auto_lint', -1)) . ')'
  endif
finally
  let g:openvox_auto_lint = s:saved_auto_lint
endtry
if get(g:, 'openvox_max_line_length', 140) != 140
  echo 'FAIL: max_line_length should default to 140'
  throw 'FAIL: max_line_length should default to 140'
endif
echo 'PASS: Default configs reasonable (auto_lint product default 1; harness forces 0)'

" Test 5: Indent setup requires puppet filetype
new
call OpenvoxTestLoadPuppet()
if &shiftwidth != 2 || !&expandtab
  echo 'FAIL: Indent not set to 2-space soft tabs (sw=' . &shiftwidth . ' et=' . &expandtab . ')'
  bwipe!
  throw 'FAIL: Indent not set to 2-space soft tabs'
endif
bwipe!
echo 'PASS: Indent settings correct'

" Test 6: Missing openvox-lint soft-fails (warn, no throw, :w still works).
" Does not require the real binary. Auto path warns once; :OpenvoxLint warns again.
let s:saved_cmd = get(g:, 'openvox_lint_command', 'openvox-lint')
let s:saved_auto = g:openvox_auto_lint
let s:pp = tempname() . '.pp'
let s:wiped = 0
try
  call writefile(['file { ''/tmp/x'':', '  ensure => present,', '}'], s:pp)
  execute 'edit' fnameescape(s:pp)
  let g:openvox_lint_command = 'openvox-lint-missing-ci-8be4'
  let g:openvox_auto_lint = 1
  let s:first = execute('write')
  if s:first !~# 'lint skipped'
    throw 'FAIL: BufWritePost auto-lint did not warn when binary missing: ' . s:first
  endif
  let s:second = execute('write')
  if s:second =~# 'lint skipped'
    throw 'FAIL: auto-lint warned more than once for a missing binary: ' . s:second
  endif
  let s:manual = execute('OpenvoxLint')
  if s:manual !~# 'lint skipped'
    throw 'FAIL: :OpenvoxLint did not warn when binary missing: ' . s:manual
  endif
  let s:auto_again = execute('call openvox#lint#run(1)')
  if s:auto_again =~# 'lint skipped'
    throw 'FAIL: auto path warned again after the once-only warning: ' . s:auto_again
  endif
  echo 'PASS: Missing openvox-lint soft-fails (warn once on save; :w still works)'
finally
  let g:openvox_lint_command = s:saved_cmd
  let g:openvox_auto_lint = s:saved_auto
  if fnamemodify(bufname('%'), ':p') ==# fnamemodify(s:pp, ':p')
    bwipe!
    let s:wiped = 1
  endif
  call delete(s:pp)
endtry
if !s:wiped && fnamemodify(bufname('%'), ':p') ==# fnamemodify(s:pp, ':p')
  bwipe!
endif

echo 'All core tests passed!'
