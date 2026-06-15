" test/test_align.vim - Tests for arrow alignment
" Run via: vim -Nu test/vimrc -S test/run.vim

echo 'Running vim-openvox align tests...'

" Test 1: Basic alignment of arrows
" Setup a buffer with misaligned resource
call setline(1, ['file { ''/tmp/test'':', '  ensure => ''file'',', 'owner => ''root'',', '  mode => ''0644'',', '}'])
" Call align on the block (lines 1-5, but simulate interior)
" For test, we can call the function on range or use block logic simulation
" Since block uses searchpair, simulate by calling arrows on lines 2-4
2,4call openvox#align#arrows()

let l:line2 = getline(2)
let l:line3 = getline(3)
let l:line4 = getline(4)

if l:line2 !~# 'ensure  =>' || l:line3 !~# 'owner   =>' || l:line4 !~# 'mode    =>'
  echo 'FAIL: Basic alignment did not pad keys correctly'
  echo 'Got: ' . l:line2 . ' | ' . l:line3 . ' | ' . l:line4
  cquit 1
endif
echo 'PASS: Basic alignment works'

" Test 2: Safety - arrows inside strings should be ignored
call setline(1, ['file { ''/tmp/test'':', '  content => "key => value",', '  ensure  => ''file'',', '}'])
2,3call openvox#align#arrows()

let l:line2 = getline(2)
if l:line2 !~# 'content => "key => value"'
  echo 'FAIL: Did not preserve arrow inside string'
  cquit 1
endif
echo 'PASS: Arrows inside strings are ignored'

" Test 3: Block alignment (simulate resource block)
" Reset buffer
call setline(1, ['file { ''/tmp/test'':', '  ensure => file,', '  owner=>root,', '  mode => ''0644'',', '}'])
" Use block function (assumes cursor inside)
" For test, position cursor and call
normal! 3G
call openvox#align#block()

let l:line2 = getline(2)
let l:line3 = getline(3)
if l:line2 !~# 'ensure =>' || l:line3 !~# 'owner  =>'
  echo 'FAIL: block() did not align correctly'
  cquit 1
endif
echo 'PASS: block() alignment works'

echo 'All align tests passed!'
qall! 0