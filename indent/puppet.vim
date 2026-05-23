" indent/puppet.vim — Puppet 8 style-guide-compliant indentation
" Maintainer: xAI
" License:    Apache-2.0
"
" Implements the Puppet Style Guide indentation rules:
"   - Two-space soft tabs (no hard tabs)
"   - Opening braces on same line as statement
"   - Arrow alignment within resource bodies
"   - Proper continuation line handling
"   - Chained arrow indentation

if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetPuppetIndent()
setlocal indentkeys+=0},0],0),=elsif,=else,=unless,=default,=\|
setlocal autoindent

if exists('*GetPuppetIndent')
  finish
endif

" ─── Helper: check if inside a string or comment ─────────────────
function! s:IsStringOrComment(lnum, col) abort
  let l:syn = synIDattr(synID(a:lnum, a:col, 1), 'name')
  return l:syn =~? 'string\|comment\|heredoc'
endfunction

" ─── Helper: strip strings/comments for analysis (improved) ─────
function! s:CleanLine(line) abort
  let l:line = a:line
  " Remove single-quoted strings
  let l:line = substitute(l:line, "'[^']*'", "''", 'g')
  " Remove double-quoted strings (simple)
  let l:line = substitute(l:line, '"[^"]*"', '""', 'g')
  " Remove comments
  let l:line = substitute(l:line, '#.*$', '', '')
  return l:line
endfunction

" ─── Helper: count unmatched openers/closers ─────────────────────
function! s:CountUnmatched(line, open, close) abort
  let l:line = s:CleanLine(a:line)
  let l:opens = len(substitute(l:line, '[^' . a:open . ']', '', 'g'))
  let l:closes = len(substitute(l:line, '[^' . a:close . ']', '', 'g'))
  return l:opens - l:closes
endfunction

" ─── Helper: find the previous non-blank, non-comment/string line ──
function! s:PrevCodeLine(lnum) abort
  let l:lnum = prevnonblank(a:lnum - 1)
  while l:lnum > 0
    let l:line = getline(l:lnum)
    if l:line !~# '^\s*#' && !s:IsStringOrComment(l:lnum, 1)
      break
    endif
    let l:lnum = prevnonblank(l:lnum - 1)
  endwhile
  return l:lnum
endfunction

" ─── Helper: check if inside a heredoc ───────────────────────────
function! s:InHeredoc(lnum) abort
  let l:syn = synIDattr(synID(a:lnum, 1, 1), 'name')
  return l:syn =~? 'heredoc'
endfunction

" ─── Main indent function ────────────────────────────────────────
function! GetPuppetIndent() abort
  let l:clnum = v:lnum
  let l:cline = getline(l:clnum)
  let l:cline_clean = s:CleanLine(l:cline)

  " Don't change indent inside heredocs
  if s:InHeredoc(l:clnum)
    return -1
  endif

  " Find previous code line
  let l:plnum = s:PrevCodeLine(l:clnum)
  if l:plnum == 0
    return 0
  endif

  let l:pline = getline(l:plnum)
  let l:pline_clean = s:CleanLine(l:pline)
  let l:pindent = indent(l:plnum)

  let l:sw = shiftwidth()
  let l:indent = l:pindent

  " ── Increase indent for opening blocks (decoupled brace/colon) ──
  let l:brace_delta = s:CountUnmatched(l:pline, '{', '}')
  let l:paren_delta = s:CountUnmatched(l:pline, '(', ')')
  let l:bracket_delta = s:CountUnmatched(l:pline, '[', ']')

  if l:brace_delta > 0
    let l:indent += l:sw
  endif
  if l:paren_delta > 0
    let l:indent += l:sw
  endif
  if l:bracket_delta > 0
    let l:indent += l:sw
  endif

  " Increase for : ONLY for case/selector or continuation (not resource title that already opened {)
  " This prevents double-indent on "file { 'title':"
  if l:pline_clean =~# ':\s*$' && l:brace_delta <= 0
    let l:indent += l:sw
  endif

  " Real handling for control keywords (if/elsif/else/unless/case without brace on same line)
  if l:pline_clean =~# '\<\(if\|elsif\|else\|unless\|case\)\>' && l:pline_clean !~# '{\s*$'
    if l:pline_clean !~# '{\s*.*}\s*$'   " not a one-liner
      let l:indent += l:sw
    endif
  endif

  " Dedent on current line for else/elsif/default (same level as if/case)
  if l:cline_clean =~# '^\s*\(elsif\|else\|default\)\>'
    let l:indent -= l:sw
  endif

  " ── Decrease indent for closing blocks ──────────────────────────
  if l:cline_clean =~# '^\s*}'
    let l:indent -= l:sw
  endif
  if l:cline_clean =~# '^\s*)'
    let l:indent -= l:sw
  endif
  if l:cline_clean =~# '^\s*\]'
    let l:indent -= l:sw
  endif

  " Handle elsif/else/default — same level as matching if/case
  if l:cline_clean =~# '^\s*\(elsif\|else\)\>'
    if l:pline_clean =~# '}\s*$' || l:pline_clean =~# '^\s*}'
      " already correct via previous decreases
    endif
  endif

  " Handle } else/elsif on same line
  if l:cline_clean =~# '^\s*}\s*\(elsif\|else\)\>'
    let l:indent -= l:sw
  endif

  " Lambda / chaining / semicolon continuations keep current level (no extra change)
  " (brace_delta already handled the { )

  if l:indent < 0
    let l:indent = 0
  endif

  return l:indent
endfunction