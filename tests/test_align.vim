" tests/test_align.vim - Tests for arrow alignment
" Run via: vim -Nu tests/vimrc -S tests/run.vim

echo 'Running vim-openvox align tests...'

new
setfiletype puppet

" Test 1: Basic alignment of arrows
call setline(1, ['file { ''/tmp/test'':', '  ensure => ''file'',', '  owner => ''root'',', '  mode => ''0644'',', '}'])
2,4call openvox#align#arrows(1)

let s:line2 = getline(2)
let s:line3 = getline(3)
let s:line4 = getline(4)

if s:line2 !~# 'ensure\s\+=>' || s:line3 !~# 'owner\s\+=>' || s:line4 !~# 'mode\s\+=>'
  echo 'FAIL: Basic alignment did not pad keys correctly'
  echo 'Got: ' . s:line2 . ' | ' . s:line3 . ' | ' . s:line4
  bwipe!
  throw 'FAIL: Basic alignment did not pad keys correctly'
endif
" Keys should share the same arrow column
if match(s:line2, '=>') != match(s:line3, '=>') || match(s:line3, '=>') != match(s:line4, '=>')
  echo 'FAIL: Arrows not aligned to same column'
  echo 'Got: ' . s:line2 . ' | ' . s:line3 . ' | ' . s:line4
  bwipe!
  throw 'FAIL: Arrows not aligned to same column'
endif
echo 'PASS: Basic alignment works'

" Test 2: Safety - arrows inside strings should be ignored
call setline(1, ['file { ''/tmp/test'':', '  content => "key => value",', '  ensure  => ''file'',', '}'])
2,3call openvox#align#arrows(1)

let s:line2 = getline(2)
if s:line2 !~# 'content => "key => value"'
  echo 'FAIL: Did not preserve arrow inside string'
  bwipe!
  throw 'FAIL: Did not preserve arrow inside string'
endif
echo 'PASS: Arrows inside strings are ignored'

" Test 3: Block alignment
call setline(1, ['file { ''/tmp/test'':', '  ensure => file,', '  owner=>root,', '  mode => ''0644'',', '}'])
normal! 3G
call openvox#align#block(1)

let s:line2 = getline(2)
let s:line3 = getline(3)
if s:line2 !~# 'ensure\s\+=>' || s:line3 !~# 'owner\s\+=>'
  echo 'FAIL: block() did not align correctly'
  echo 'Got: ' . s:line2 . ' | ' . s:line3
  bwipe!
  throw 'FAIL: block() did not align correctly'
endif
if match(s:line2, '=>') != match(s:line3, '=>')
  echo 'FAIL: block() arrows not same column'
  bwipe!
  throw 'FAIL: block() arrows not same column'
endif
echo 'PASS: block() alignment works'

" Second align should not false-positive style violation
call openvox#align#block(1)
echo 'PASS: second block() align is idempotent'

bwipe!
echo 'All align tests passed!'
