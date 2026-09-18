" indent/puppet.vim — Puppet / OpenVox indentation (rodjek/vim-puppet approach)
scriptencoding utf-8
" Maintainer: xAI
" License:    Apache-2.0
"
" Ported from rodjek/vim-puppet indent/puppet.vim (searchpair / OpenBrace,
" multiline string handling, include-list commas, }-> chains, closing
" brace/elsif patterns). Keeps GetPuppetIndent for tests, OpenVox synID
" awareness (Comment/String/Heredoc/Interpolation), and heredoc => -1.

if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

setlocal autoindent
setlocal indentexpr=GetPuppetIndent()
setlocal indentkeys+=0},0],0),=elsif,=else,=unless,=default,=\|

let b:undo_indent = 'setlocal autoindent< indentexpr< indentkeys<'

if exists('*GetPuppetIndent')
  finish
endif

" Skip expression for searchpair: ignore string/comment/heredoc/interp
let s:skip_syn = 'synIDattr(synID(line("."), col("."), 0), "name") =~? "Comment\\|String\\|Heredoc\\|Interpolation"'

" include foo,
"     bar,
"     baz
function! s:PartOfInclude(lnum) abort
  let l:lnum = a:lnum
  while l:lnum
    let l:lnum = l:lnum - 1
    let l:line = getline(l:lnum)
    if l:line !~# ',$'
      break
    endif
    if l:line =~# '^\s*include\s\+[^,]\+,$' && l:line !~# '[=>]>'
      return 1
    endif
  endwhile
  return 0
endfunction

function! s:OpenBrace(lnum) abort
  call cursor(a:lnum, 1)
  return searchpair('{\|\[\|(', '', '}\|\]\|)', 'nbW', s:skip_syn)
endfunction

function! s:InsideMultilineString(lnum) abort
  let l:syn = synIDattr(synID(a:lnum, 1, 0), 'name')
  return l:syn =~? 'String\|Heredoc'
endfunction

function! s:InHeredoc(lnum) abort
  return synIDattr(synID(a:lnum, 1, 0), 'name') =~? 'Heredoc'
endfunction

function! s:PrevNonMultilineString(lnum) abort
  let l:lnum = a:lnum
  while l:lnum > 0 && s:InsideMultilineString(l:lnum)
    let l:lnum = l:lnum - 1
  endwhile
  return l:lnum
endfunction

""
" @param a:1 (optional) line number; defaults to v:lnum
function! GetPuppetIndent(...) abort
  let l:lnum = get(a:, 1, v:lnum)

  " Heredoc body: do not rewrite contents (tests expect -1)
  if s:InHeredoc(l:lnum)
    return -1
  endif

  let l:pnum = prevnonblank(l:lnum - 1)
  if l:pnum == 0
    return 0
  endif

  let l:line = getline(l:lnum)
  let l:pline = getline(l:pnum)
  let l:ind = indent(l:pnum)
  let l:sw = shiftwidth()

  " Comment-only previous line: keep indent unless current closes a pair
  if l:pline =~# '^\s*#' && l:line !~# '^\s*\(}\(,\|;\)\?$\|]:\|],\|}]\|];\?$\|)\)'
    return l:ind
  endif

  " Inside a multi-line string (non-heredoc): preserve buffer indent
  if s:InsideMultilineString(l:lnum)
    return indent(l:lnum)
  endif

  " Previous line was inside a multi-line string: restore indent from before it
  if s:InsideMultilineString(l:pnum)
    if l:pnum - 1 == 0
      return l:ind
    endif
    let l:ind = indent(s:PrevNonMultilineString(l:pnum - 1))
  endif

  let l:bracket_eol = '\({\|\[\|(\|:\)\s*\(#.*\)\?$'
  if l:pline =~# l:bracket_eol
    let l:i = match(l:pline, l:bracket_eol)
    let l:syntaxType = synIDattr(synID(l:pnum, l:i + 1, 0), 'name')
    if l:syntaxType !~# '\(Comment\|String\|Heredoc\|Interpolation\)$'
      let l:ind += l:sw
    endif
  elseif l:pline =~# ';$' && l:pline !~# '[^:]\+:.*[=+]>.*'
    let l:ind -= l:sw
  elseif l:pline =~# '^\s*include\s\+.*,$' && l:pline !~# '[=+]>'
    let l:ind += l:sw
  endif

  if l:pline !~# ',$' && s:PartOfInclude(l:pnum)
    let l:ind -= l:sw
  endif

  " Match } }, }; ] ]: ], ]; )
  if l:line =~# '^\s*\(}\(,\|;\)\?$\|]:\|],\|}]\|];\?$\|)\)'
    let l:ind = indent(s:OpenBrace(l:lnum))
  endif

  " } else { / } elsif {
  if l:line =~# '^\s*}\s*els\(e\|if\).*{\s*$'
    let l:ind -= l:sw
  endif

  " Ordering / notification chain continuation: } ->  or line ending ->
  if l:line =~# '->$' || l:line =~# '^\s*}\s*->'
    let l:ind -= l:sw
  endif

  if l:ind < 0
    let l:ind = 0
  endif

  return l:ind
endfunction
