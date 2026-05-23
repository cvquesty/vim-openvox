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
  let l:arrow_count = 0

  " First pass: find the longest key name (text before =>).
  " We match: leading whitespace, then the key (everything up to the
  " first => that is preceded by optional whitespace). This handles
  " keys like 'ensure', 'my-key', 'some_thing', and even keys with
  " no space before => (e.g., 'ensure=>present').
  for l:line in l:lines
    let l:match = matchlist(l:line, '^\(\s*\)\(\S.\{-}\)\s*=>')
    if !empty(l:match)
      let l:key_len = len(l:match[2])
      if l:key_len > l:max_key_len
        let l:max_key_len = l:key_len
      endif
      let l:arrow_count += 1
    endif
  endfor

  if l:arrow_count == 0
    echo 'No arrows (=>) found in selection'
    return
  endif

  " Second pass: rewrite each line so => is aligned.
  " The arrow column = indent + max_key_len + 1 space.
  " Key length is measured relative to the indent, not absolute column.
  let l:lnum = a:firstline
  for l:line in l:lines
    let l:match = matchlist(l:line, '^\(\s*\)\(\S.\{-}\)\s*=>\s*\(.*\)')
    if !empty(l:match)
      let l:indent = l:match[1]
      let l:key = l:match[2]
      let l:value = l:match[3]
      " Padding = spaces needed after the key to reach the alignment column
      let l:pad = l:max_key_len - len(l:key)
      if l:pad < 0
        let l:pad = 0
      endif
      let l:new_line = l:indent . l:key . repeat(' ', l:pad) . ' => ' . l:value
      call setline(l:lnum, l:new_line)
    endif
    let l:lnum += 1
  endfor

  echo printf('Aligned %d arrow(s)', l:arrow_count)
endfunction

" Helper: check if inside string/comment/heredoc (for safe searchpair)
function! s:IsStringOrComment(lnum, col) abort
  let l:syn = synIDattr(synID(a:lnum, a:col, 1), 'name')
  return l:syn =~? 'string\|comment\|heredoc\|puppetInterpolation'
endfunction

" Auto-align: align arrows in the current resource block
function! openvox#align#block() abort
  " Find the enclosing { ... } block (skip strings/comments)
  let l:save_pos = getpos('.')

  let l:open = searchpair('{', '', '}', 'bnW', 's:IsStringOrComment(line("."), col("."))')
  if l:open == 0
    echo 'Not inside a resource block'
    return
  endif

  let l:close = searchpair('{', '', '}', 'nW', 's:IsStringOrComment(line("."), col("."))')
  if l:close == 0
    echo 'Could not find closing brace'
    return
  endif

  " Align arrows in the block (skip the { and } lines)
  execute (l:open + 1) . ',' . (l:close - 1) . 'call openvox#align#arrows()'

  call setpos('.', l:save_pos)
endfunction