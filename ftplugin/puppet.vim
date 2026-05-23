" ftplugin/puppet.vim — Buffer-local settings for Puppet files
scriptencoding utf-8
" Maintainer: xAI
" License:    Apache-2.0
"
" Implements Puppet Style Guide formatting rules:
"   - Two-space soft tabs (no hard tabs)
"   - 140-character line width (configurable)
"   - Proper comment formatting
"   - Code folding by indent level
"   - Omni-completion for Puppet keywords

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

" ─── Style Guide: Indentation ────────────────────────────────────
" Two-space soft tabs, no hard tabs
setlocal tabstop=2
setlocal softtabstop=2
setlocal shiftwidth=2
setlocal expandtab
setlocal smarttab

" ─── Style Guide: Line width ────────────────────────────────────
" puppet-lint checks 140 chars (configurable via g:openvox_max_line_length)
let s:max_line = get(g:, 'openvox_max_line_length', 140)
execute 'setlocal textwidth=' . s:max_line

" Show a color column at the limit
if exists('+colorcolumn')
  execute 'setlocal colorcolumn=' . s:max_line
endif

" ─── Comments ────────────────────────────────────────────────────
" Style guide: # for comments
setlocal commentstring=#\ %s
setlocal comments=:#

" ─── Format options ──────────────────────────────────────────────
" Auto-wrap comments, insert comment leader on <Enter>, allow gq
setlocal formatoptions=croql

" ─── Folding ─────────────────────────────────────────────────────
" Fold by syntax/indent — useful for large manifests
if get(g:, 'openvox_fold', 1)
  setlocal foldmethod=indent
  setlocal foldlevel=99
  setlocal foldminlines=3
endif

" ─── Match words ─────────────────────────────────────────────────
" Enable % to bounce between if/elsif/else/end, class { }
if exists('loaded_matchit') || exists('g:loaded_matchit')
  let b:match_words =
        \ '\<if\>:\<elsif\>:\<else\>,' .
        \ '\<case\>:\<default\>,' .
        \ '\<class\>:\<inherits\>,' .
        \ '{:}'
  let b:match_ignorecase = 0
endif

" ─── Surround mappings ──────────────────────────────────────────
" If vim-surround is loaded, add puppet-specific surroundings
if exists('g:loaded_surround')
  " s for single-quoted string
  let b:surround_{char2nr('s')} = "'\r'"
  " d for double-quoted string
  let b:surround_{char2nr('d')} = "\"\r\""
  " v for variable interpolation
  let b:surround_{char2nr('v')} = "${\\r}"
endif

" ─── Compiler ────────────────────────────────────────────────────
" Default to puppet-lint compiler
if exists(':compiler') == 2
  compiler openvox_lint
endif

" ─── Omni-completion ─────────────────────────────────────────────
setlocal omnifunc=openvox#complete#omnifunc

" ─── Buffer-local key mappings ───────────────────────────────────
" Align arrows in visual selection
if !get(g:, 'openvox_no_mappings', 0)
  " <LocalLeader>a — Align => arrows in visual selection
  vnoremap <buffer> <silent> <LocalLeader>a :call openvox#align#arrows()<CR>

  " <LocalLeader>l — Run puppet-lint on current file
  nnoremap <buffer> <silent> <LocalLeader>l :OpenvoxLint<CR>

  " <LocalLeader>v — Validate puppet syntax
  nnoremap <buffer> <silent> <LocalLeader>v :OpenvoxValidate<CR>

  " <LocalLeader>f — Auto-fix puppet-lint issues
  nnoremap <buffer> <silent> <LocalLeader>f :OpenvoxLintFix<CR>

  " gd — Go to definition (class/define)
  nnoremap <buffer> <silent> gd :call openvox#navigate#goto_definition()<CR>

  " K — Look up resource type documentation
  nnoremap <buffer> <silent> K :call openvox#doc#lookup()<CR>

  " [[ and ]] — Jump between class/define blocks
  nnoremap <buffer> <silent> [[ :call openvox#navigate#prev_block()<CR>
  nnoremap <buffer> <silent> ]] :call openvox#navigate#next_block()<CR>
endif

" ─── Undo ftplugin ───────────────────────────────────────────────
let b:undo_ftplugin = 'setlocal tabstop< softtabstop< shiftwidth< expandtab<'
      \ . ' textwidth< colorcolumn< commentstring< comments<'
      \ . ' formatoptions< foldmethod< foldlevel< foldminlines<'
      \ . ' omnifunc<'
      \ . '| unlet! b:match_words b:match_ignorecase'