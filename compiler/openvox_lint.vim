" compiler/openvox_lint.vim — puppet-lint compiler integration
" Maintainer: xAI
" License:    Apache-2.0

if exists('current_compiler')
  finish
endif
let current_compiler = 'openvox_lint'

if exists(':CompilerSet') != 2
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cmd = get(g:, 'openvox_lint_command', 'puppet-lint')

CompilerSet makeprg=puppet-lint\ --log-format\ '%{path}:%{line}:%{column}:%{KIND}:%{check}:%{message}'\ %

" Errorformat for puppet-lint output
" Format: path:line:column:KIND:check:message
CompilerSet errorformat=%f:%l:%c:%t%*[A-Z]:%m