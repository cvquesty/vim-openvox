" compiler/openvox.vim — puppet parser validate compiler integration
scriptencoding utf-8
" Maintainer: xAI
" License:    Apache-2.0

if exists('current_compiler')
  finish
endif
let current_compiler = 'openvox'

if exists(':CompilerSet') != 2
  command -nargs=* CompilerSet setlocal <args>
endif

" Executable must be a single path/name — no shell metacharacters (SEC makeprg harden).
let s:puppet_cmd = get(g:, 'openvox_puppet_command', 'puppet')
if type(s:puppet_cmd) != v:t_string || s:puppet_cmd =~# '[|;&`$<>()#!\n]'
  echoerr 'openvox: g:openvox_puppet_command must be a single executable path (no shell metacharacters)'
  finish
endif

" %:S shell-escapes the buffer filename for :make
let &l:makeprg = shellescape(s:puppet_cmd) . ' parser validate %:S'

" Error format for puppet parser validate
" Error: Could not parse for environment production: Syntax error at ... (file: path, line: N, column: N)
CompilerSet errorformat=Error:\ %m\ (file:\ %f\\,\ line:\ %l\\,\ column:\ %c)
CompilerSet errorformat+=Error:\ %m\ at\ %f:%l:%c
CompilerSet errorformat+=Error:\ %m\ at\ %f:%l
