" tests/run.vim - Test runner for vim-openvox
" Usage (CI): vim -Nu tests/vimrc -es -S tests/run.vim -c '...'
" Only this file should exit Vim; test_*.vim must throw on failure, never qall/cquit.

let s:failures = 0
let s:log = []
let g:test_failures = 0

function! s:Log(msg) abort
  call add(s:log, a:msg)
endfunction

function! s:RunTest(file) abort
  call s:Log('=== Running ' . a:file . ' ===')
  try
    execute 'source ' . fnameescape(a:file)
    call s:Log('OK ' . a:file)
  catch
    call s:Log('ERROR in ' . a:file . ': ' . v:exception)
    let s:failures += 1
  endtry
endfunction

call s:RunTest('tests/test_core.vim')
call s:RunTest('tests/test_align.vim')
call s:RunTest('tests/test_indent.vim')

let g:test_failures = s:failures
if s:failures > 0
  call s:Log('TESTS FAILED: ' . s:failures . ' failures')
else
  call s:Log('All tests passed!')
endif
call writefile(s:log, '/tmp/vim-openvox-test-result.txt')
" Exit is left to the invoking -c / make target so -es mode always terminates.
