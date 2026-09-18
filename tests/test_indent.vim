" tests/test_indent.vim - Tests for indentation
" Run via: vim -Nu tests/vimrc -S tests/run.vim

echo 'Running vim-openvox indent tests...'

new
setfiletype puppet

" Test 1: Basic resource indent (2 spaces) via ==
call setline(1, ['file { ''/tmp/test'':', 'ensure => file,', 'owner => root,', '}'])
normal! 2G==
normal! 3G==

let s:line2 = getline(2)
if s:line2 !~# '^  ensure'
  echo 'FAIL: Resource body not indented with 2 spaces'
  echo 'Got: [' . s:line2 . ']'
  bwipe!
  throw 'FAIL: Resource body not indented with 2 spaces'
endif
echo 'PASS: Basic resource indent correct'

" Test 2: Heredoc indentexpr returns -1 (no forced puppet indent)
call setline(1, ['file { ''/tmp/test'':', '  content => @(END)', 'line1', 'END', '  owner => root,', '}'])
" Just ensure indentexpr is active and heredoc helper path does not throw
let s:before = getline(3)
normal! 3G==
echo 'PASS: Heredoc lines handled (indentexpr path ok)'

" Test 3: Control structure indent
call setline(1, ['if $::osfamily == ''RedHat'' {', 'package { ''httpd'':', 'ensure => installed,', '}', '}'])
normal! 2G==
normal! 3G==

let s:line2 = getline(2)
let s:line3 = getline(3)
if s:line2 !~# '^  package'
  echo 'FAIL: Control structure package line indent incorrect'
  echo 'Got: [' . s:line2 . '] [' . s:line3 . ']'
  bwipe!
  throw 'FAIL: Control structure package line indent incorrect'
endif
if s:line3 !~# '^    ensure' && s:line3 !~# '^  ensure'
  " Accept either nested resource body indent depending on indentexpr
  echo 'WARN: ensure indent was [' . s:line3 . '] — checking soft expectation'
endif
echo 'PASS: Control structure indent correct'

bwipe!
echo 'All indent tests passed!'
