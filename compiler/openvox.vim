" compiler/openvox.vim — puppet parser validate compiler integration
" Maintainer: xAI
" License:    Apache-2.0

if exists('current_compiler')
  finish
endif
let current_compiler = 'openvox'

if exists(':CompilerSet') != 2
  command -nargs=* CompilerSet setlocal <args>
endif

let s:puppet_cmd = get(g:, 'openvox_puppet_command', 'puppet')

execute 'CompilerSet makeprg=' . escape(s:puppet_cmd, ' ') . '\ parser\ validate\ %'

" Error format for puppet parser validate
" Error: Could not parse for environment production: Syntax error at ... (file: path, line: N, column: N)
CompilerSet errorformat=Error:\ %m\ (file:\ %f\\,\ line:\ %l\\,\ column:\ %c)
CompilerSet errorformat+=Error:\ %m\ at\ %f:%l:%c
CompilerSet errorformat+=Error:\ %m\ at\ %f:%l