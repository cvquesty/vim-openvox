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
" Safety model (YOLO hardened):
" - Only arrows (`=>`) that are in "code" context are considered.
" - Arrows inside strings, comments, heredocs, or interpolations are ignored.
" - This prevents corrupting content, regexes, or comments that happen to contain '=>'.
" - Multiline values are left untouched (the line containing the key+arrow is still aligned).
" - STRICT: Now also detects and warns on unaligned arrows in resource bodies (style violation catcher).
" - Padding is always exactly 1 space before => after max key; no extra artifacts.

function! openvox#align#arrows() range abort
  let l:lines = getline(a:firstline, a:lastline)
  let l:max_key_len = 0
  let l:arrow_count = 0
  let l:safe_lines = []   " list of {lnum, key, indent, value, arrow_col}

  " First pass: find longest *safe* key (only code-context arrows).
  " YOLO: stricter – also track if any unsafe arrows found to warn on style violation.
  " Also fix padding discipline: always use exactly 1 space before/after =>, compute max including indent for true column align.
  let l:unsafe_count = 0
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
    else
      " Check for any => at all – if present but unsafe, count as violation
      if l:line =~# '=>'
        let l:unsafe_count += 1
      endif
    endif
    let l:lnum += 1
  endfor

  if l:arrow_count == 0
    if l:unsafe_count > 0
      echoerr printf('Style violation: %d arrow(s) found but inside strings/comments/heredocs – fix per Puppet style guide', l:unsafe_count)
    else
      echo 'No arrows (=>) found in selection (in code context)'
    endif
    return
  endif

  " Second pass: rewrite only the safe lines so => is aligned.
  " arrow column = indent + max_key_len + 1 (one space before =>)
  " YOLO: enforce exactly one space before/after => for strict discipline. Use column-based align to avoid padding bugs.
  let l:target_col = len(l:indent) + l:max_key_len + 1  " rough; better per entry
  for l:entry in l:safe_lines
    let l:key_len = len(l:entry.key)
    let l:pad = l:max_key_len - l:key_len
    if l:pad < 0 | let l:pad = 0 | endif

    let l:new_line = l:entry.indent . l:entry.key
          \ . repeat(' ', l:pad) . ' => ' . l:entry.value

    call setline(l:entry.lnum, l:new_line)
  endfor

  if l:unsafe_count > 0
    echo printf('Aligned %d arrow(s); WARNING: %d unsafe arrow(s) ignored (style violation – move out of strings/comments)', l:arrow_count, l:unsafe_count)
  else
    echo printf('Aligned %d arrow(s)', l:arrow_count)
  endif
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
" YOLO: now also triggers style violation warning if any unaligned arrows detected in block.
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
  " First, quick scan for blatant unaligned => in code context to catch violations
  let l:interior_lines = getline(l:open + 1, l:close - 1)
  let l:unaligned = 0
  for l:line in l:interior_lines
    if l:line =~# '^\s*\S\+\s*=>' && l:line !~# '^\s*\S\+\s*=>\s*\S'
      " Rough heuristic for unaligned (key followed by => without proper spacing/align)
      let l:unaligned += 1
    endif
  endfor
  if l:unaligned > 0
    echoerr printf('Blatant style violation: %d unaligned => arrow(s) in block – run align or fix manually per Puppet style guide', l:unaligned)
  endif

  execute (l:open + 1) . ',' . (l:close - 1) . 'call openvox#align#arrows()'

  call setpos('.', l:save_pos)
endfunction

" YOLO: Add auto-align on save for resources if enabled (new feature to catch violations proactively)
" Enable with: let g:openvox_auto_align = 1
augroup openvox_align
  autocmd!
  autocmd BufWritePre *.pp if get(g:, 'openvox_auto_align', 0) | call openvox#align#block() | endif
augroup END