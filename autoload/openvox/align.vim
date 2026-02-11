" autoload/openvox/align.vim — Arrow (=>) alignment for resource bodies
" Maintainer: xAI
" License:    Apache-2.0
"
" Puppet Style Guide: All arrows in a resource body should be aligned.
"   file { '/etc/foo':
"     ensure => file,
"     owner  => 'root',
"     mode   => '0644',
"   }

function! openvox#align#arrows() range abort
  let l:lines = getline(a:firstline, a:lastline)
  let l:max_key_len = 0

  " First pass: find the longest key (text before =>)
  for l:line in l:lines
    let l:match = matchlist(l:line, '^\(\s*\)\(\S\+\)\s*=>')
    if !empty(l:match)
      let l:key_len = len(l:match[1]) + len(l:match[2])
      if l:key_len > l:max_key_len
        let l:max_key_len = l:key_len
      endif
    endif
  endfor

  if l:max_key_len == 0
    echo 'No arrows (=>) found in selection'
    return
  endif

  " Second pass: align all => to max_key_len + 1 space
  let l:lnum = a:firstline
  for l:line in l:lines
    let l:match = matchlist(l:line, '^\(\s*\)\(\S\+\)\s*=>\s*\(.*\)')
    if !empty(l:match)
      let l:indent = l:match[1]
      let l:key = l:match[2]
      let l:value = l:match[3]
      let l:padding = repeat(' ', l:max_key_len - len(l:indent) - len(l:key) + 1)
      let l:new_line = l:indent . l:key . l:padding . '=> ' . l:value
      call setline(l:lnum, l:new_line)
    endif
    let l:lnum += 1
  endfor

  echo printf('Aligned %d arrows', a:lastline - a:firstline + 1)
endfunction

" Auto-align: align arrows in the current resource block
function! openvox#align#block() abort
  " Find the enclosing { ... } block
  let l:save_pos = getpos('.')

  " Search backward for the opening {
  let l:open = searchpair('{', '', '}', 'bnW')
  if l:open == 0
    echo 'Not inside a resource block'
    return
  endif

  " Search forward for the closing }
  let l:close = searchpair('{', '', '}', 'nW')
  if l:close == 0
    echo 'Could not find closing brace'
    return
  endif

  " Align arrows in the block (skip the { and } lines)
  execute (l:open + 1) . ',' . (l:close - 1) . 'call openvox#align#arrows()'

  call setpos('.', l:save_pos)
endfunction