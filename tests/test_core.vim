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

" Test 4: Default config (auto_lint opt-in / default 0)
if get(g:, 'openvox_auto_lint', -1) != 0
  echo 'FAIL: auto_lint should default to 0 (got ' . string(get(g:, 'openvox_auto_lint', -1)) . ')'
  throw 'FAIL: auto_lint should default to 0'
endif
if get(g:, 'openvox_max_line_length', 140) != 140
  echo 'FAIL: max_line_length should default to 140'
  throw 'FAIL: max_line_length should default to 140'
endif
echo 'PASS: Default configs reasonable'

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

echo 'All core tests passed!'
