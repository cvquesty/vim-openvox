" test/run.vim - Test runner for vim-openvox
" Usage: vim -Nu test/vimrc -S test/run.vim
" Or in CI: same

let s:failures = 0

function! s:RunTest(file) abort
  echo '=== Running ' . a:file . ' ==='
  try
    execute 'source ' . a:file
  catch
    echo 'ERROR in ' . a:file . ': ' . v:exception
    let s:failures += 1
  endtry
endfunction

" Run core tests
call s:RunTest('test/test_core.vim')

" Add more test files here as we expand:
call s:RunTest('test/test_align.vim')
call s:RunTest('test/test_indent.vim')
" call s:RunTest('test/test_lint.vim')

if s:failures > 0
  echo 'TESTS FAILED: ' . s:failures . ' failures'
  cquit 1
else
  echo 'All tests passed!'
  qall! 0
endif