" autoload/openvox/align.vim — Arrow (=>) alignment for resource bodies
scriptencoding utf-8
" Maintainer: xAI
" License:    Apache-2.0
"
" Puppet Style Guide: All arrows in a resource body should be aligned.
"   file { '/etc/foo':
"     ensure => 'file',
"     owner  => 'root',
"     mode   => '0644',
"   }
"
" Safety model:
" - Only arrows (`=>`) that are in "code" context are considered.
" - Arrows inside strings, comments, heredocs, or interpolations are ignored.
" - This prevents corrupting content, regexes, or comments that happen to contain '=>'.
" - Multiline values are left untouched (the line containing the key+arrow is still aligned).

function! openvox#align#arrows() range abort
  let l:lines = getline(a:firstline, a:lastline)
  let l:max_key_len = 0
  let l:arrow_count = 0
  let l:safe_lines = []   " list of {lnum, key, indent, value, arrow_col}

  " First pass: find longest *safe* key (only code-context arrows).
  let l:lnum = a:firstline
  for l:line in l:lines
    let l:arrow_col = s:FindFirstSafeArrowCol(l:line, l:lnum)
    if l:arrow_col >= 0
      " Extract indent + key (everything before the safe =>)
      let l:prefix = l:line[0 : l:arrow_col - 1]
      let l:match = matchlist(l:prefix, '^\(\s*\)\(\S.*\)$')
      if !empty(l:match)
        let l:indent = l:match[1]
        let l:key = substitute(l:match[2], '\s\+$', '', '')   " trim trailing ws
        let l:key_len = len(l:key)

        if l:key_len > l:max_key_len
          let l:max_key_len = l:key_len
        endif

        " Capture the rest of the line after this safe arrow for rewriting
        let l:after = l:line[l:arrow_col + 2 : ]   " skip '=>'
        let l:value = substitute(l:after, '^\s*', '', '')    " trim leading ws after =>
        call add(l:safe_lines, {
              \ 'lnum': l:lnum,
              \ 'indent': l:indent,
              \ 'key': l:key,
              \ 'value': l:value,
              \ })
        let l:arrow_count += 1
      endif
    endif
    let l:lnum += 1
  endfor

  if l:arrow_count == 0
    echo 'No arrows (=>) found in selection (in code context)'
    return
  endif

  " Second pass: rewrite only the safe lines so => is aligned.
  " arrow column = indent + max_key_len + 1 (one space before =>)
  for l:entry in l:safe_lines
    let l:pad = l:max_key_len - len(l:entry.key)
    if l:pad < 0 | let l:pad = 0 | endif

    let l:new_line = l:entry.indent . l:entry.key
          \ . repeat(' ', l:pad) . ' => ' . l:entry.value

    call setline(l:entry.lnum, l:new_line)
  endfor

  echo printf('Aligned %d arrow(s)', l:arrow_count)
endfunction

" Return byte column of first '=>' that is NOT inside string/comment/heredoc.
" Returns -1 if no safe arrow on the line.
function! s:FindFirstSafeArrowCol(line, lnum) abort
  let l:col = 0
  while 1
    let l:col = match(a:line, '=>', l:col)
    if l:col < 0
      return -1
    endif
    " Check around the arrow (the '=' or the '>')
    if !s:IsInStringOrComment(a:lnum, l:col + 1)
      return l:col
    endif
    let l:col += 2
  endwhile
endfunction

" Helper: is the given position inside a string, comment, heredoc or interpolation?
" Matches the syntax groups defined in syntax/puppet.vim.
function! s:IsInStringOrComment(lnum, col) abort
  let l:syn = synIDattr(synID(a:lnum, a:col, 1), 'name')
  " Covers: puppetComment, puppetCComment, puppetSQString, puppetDQString,
  "         puppetHeredoc*, puppetHeredocNI, puppetInterpolation, etc.
  return l:syn =~? 'Comment\|String\|Heredoc\|Interpolation'
endfunction

" Auto-align: align arrows in the current resource (or hash) block.
" Uses searchpair with string/comment skipping for finding the block.
function! openvox#align#block() abort
  let l:save_pos = getpos('.')

  let l:open = searchpair('{', '', '}', 'bnW', 's:IsInStringOrComment(line("."), col("."))')
  if l:open == 0
    echo 'Not inside a { ... } block'
    return
  endif

  let l:close = searchpair('{', '', '}', 'nW', 's:IsInStringOrComment(line("."), col("."))')
  if l:close == 0
    echo 'Could not find closing brace'
    return
  endif

  " Align only the interior lines (skip the opening { line and closing } line)
  execute (l:open + 1) . ',' . (l:close - 1) . 'call openvox#align#arrows()'

  call setpos('.', l:save_pos)
endfunction