" compiler/openvox_lint.vim — openvox-lint compiler integration
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

" Executable must be a single path/name — no shell metacharacters (SEC makeprg harden).
let s:cmd = get(g:, 'openvox_lint_command', 'openvox-lint')
if type(s:cmd) != v:t_string || s:cmd =~# '[|;&`$<>()#!\n]'
  echoerr 'openvox: g:openvox_lint_command must be a single executable path (no shell metacharacters)'
  finish
endif

" shellescape for exe; %:S shell-escapes the buffer name on :make;
" \% keeps puppet-lint %{…} tokens out of Vim's %-expansion.
let &l:makeprg = shellescape(s:cmd) . ' --log-format ''\%{path}:\%{line}:\%{column}:\%{KIND}:\%{check}:\%{message}'' %:S'

" Errorformat for openvox-lint output
" Format: path:line:column:KIND:check:message
CompilerSet errorformat=%f:%l:%c:%t%*[A-Z]:%m
