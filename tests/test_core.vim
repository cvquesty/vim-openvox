" test/test_core.vim - Core tests for vim-openvox
" Run via: vim -Nu test/vimrc -S test/run.vim

echo 'Running vim-openvox core tests...'

" Test 1: Plugin loaded
if !exists('g:loaded_openvox')
  echo 'FAIL: Plugin not loaded'
  cquit 1
else
  echo 'PASS: Plugin loaded'
endif

" Test 2: Commands are defined
let l:commands = ['OpenvoxLint', 'OpenvoxLintFix', 'OpenvoxValidate', 'OpenvoxMetadataLint', 'OpenvoxYamlLint', 'OpenvoxAlign', 'OpenvoxAlignBlock', 'OpenvoxGotoDef', 'OpenvoxDoc', 'OpenvoxClass', 'OpenvoxDefine', 'OpenvoxInit']
for cmd in l:commands
  if !exists(':' . cmd)
    echo 'FAIL: Command :' . cmd . ' not defined'
    cquit 1
  endif
endfor
echo 'PASS: All core commands defined'

" Test 3: Key functions exist (autoload)
" Check for main autoload functions
if !exists('*openvox#align#arrows')
  echo 'FAIL: openvox#align#arrows not defined'
  cquit 1
endif
if !exists('*openvox#lint#run')
  echo 'FAIL: openvox#lint#run not defined'
  cquit 1
endif
if !exists('*openvox#complete#omnifunc')
  echo 'FAIL: openvox#complete#omnifunc not defined'
  cquit 1
endif
echo 'PASS: Core functions defined'

" Test 4: Default config
if get(g:, 'openvox_auto_lint', 1) != 1
  echo 'FAIL: auto_lint should default to 1'
  cquit 1
endif
if get(g:, 'openvox_max_line_length', 140) != 140
  echo 'FAIL: max_line_length should default to 140'
  cquit 1
endif
echo 'PASS: Default configs reasonable'

" Test 5: Indent setup
if &shiftwidth != 2 || &expandtab == 0
  echo 'FAIL: Indent not set to 2-space soft tabs'
  cquit 1
endif
echo 'PASS: Indent settings correct'

echo 'All core tests passed!'
qall! 0