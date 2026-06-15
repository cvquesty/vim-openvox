" compiler/openvox_lint.vim — openvox-lint (or puppet-lint compat) compiler integration
scriptencoding utf-8
" Maintainer: xAI
" License:    Apache-2.0

if exists('current_compiler')
  finish
endif
let current_compiler = 'openvox_lint'

if exists(':CompilerSet') != 2
  command -nargs=* CompilerSet setlocal <args>
endif

" Dynamic default to openvox-lint; runtime g:openvox_lint_command honored (basename for display elsewhere).
let s:cmd = get(g:, 'openvox_lint_command', 'openvox-lint')

execute 'CompilerSet makeprg=' . escape(s:cmd, ' \') . '\ --log-format\ ''%{path}:%{line}:%{column}:%{KIND}:%{check}:%{message}''\ %'

" Errorformat for openvox-lint / puppet-lint compatible output
" Format: path:line:column:KIND:check:message
CompilerSet errorformat=%f:%l:%c:%t%*[A-Z]:%m