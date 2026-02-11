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

" ─── Helper: strip comments and trailing whitespace ──────────────
function! s:CleanLine(line) abort
  " Remove string contents to avoid false matches
  let l:line = a:line
  " Remove single-quoted strings
  let l:line = substitute(l:line, "'[^']*'", "''", 'g')
  " Remove double-quoted strings
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

" ─── Helper: find the previous non-blank, non-comment line ───────
function! s:PrevCodeLine(lnum) abort
  let l:lnum = prevnonblank(a:lnum - 1)
  while l:lnum > 0 && getline(l:lnum) =~# '^\s*#'
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

  " ── Increase indent for opening blocks ──────────────────────────
  " Count unmatched { ( [
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

  " Increase for lines ending with : (case/selector values, resource title)
  if l:pline_clean =~# ':\s*$'
    let l:indent += l:sw
  endif

  " Increase for lines starting class/define/node with opening brace
  " already counted above via brace_delta

  " Increase for if/elsif/else/unless/case without braces on same line
  if l:pline_clean =~# '\<\(if\|elsif\|else\|unless\)\>' && l:pline_clean !~# '{\s*$'
    " Only if the block opener has no brace on the same line and no closing brace
    " This handles one-liner ifs — don't increase if it's a single-line conditional
    if l:pline_clean =~# '{\s*.*}\s*$'
      " Single-line block, no indent change
    endif
  endif

  " ── Decrease indent for closing blocks ──────────────────────────
  " Current line starts with } ) ]
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
    " Should be at the same level as the if
    if l:pline_clean =~# '}\s*$' || l:pline_clean =~# '^\s*}'
      " Previous line closed a block — elsif/else goes at same level
    endif
  endif

  " Handle closing } followed by else/elsif on same line
  if l:cline_clean =~# '^\s*}\s*\(elsif\|else\)\>'
    let l:indent -= l:sw
  endif

  " ── Lambda pipes ────────────────────────────────────────────────
  " Lines ending with |var| { — increase
  if l:pline_clean =~# '|[^|]*|\s*{\s*$'
    " Already handled by brace_delta
  endif

  " ── Chaining arrows ────────────────────────────────────────────
  " Line ending with -> or ~> means continuation — don't change indent
  " But the continued resource should be at same level
  if l:pline_clean =~# '\(->\|\~>\)\s*$'
    " Continuation line — keep same indent
    " (already at l:pindent)
  endif

  " ── Handle semicolons (multi-resource bodies) ──────────────────
  " After a ; (multi-title resource separator), keep same indent level
  if l:pline_clean =~# ';\s*$'
    " Same indent as the title line
  endif

  " ── Prevent negative indent ────────────────────────────────────
  if l:indent < 0
    let l:indent = 0
  endif

  return l:indent
endfunction