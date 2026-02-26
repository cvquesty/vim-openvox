" plugin/openvox.vim — Plugin commands and global configuration
" Maintainer: xAI
" License:    Apache-2.0
"
" vim-openvox: A comprehensive Puppet IDE plugin for Vim
" Supports Puppet 8 with full style guide compliance

if exists('g:loaded_openvox') || &compatible
  finish
endif
let g:loaded_openvox = 1

" ─── Configuration defaults ──────────────────────────────────────

" puppet-lint command path
if !exists('g:openvox_lint_command')
  let g:openvox_lint_command = 'puppet-lint'
endif

" puppet command path
if !exists('g:openvox_puppet_command')
  let g:openvox_puppet_command = 'puppet'
endif

" metadata-json-lint command path
if !exists('g:openvox_metadata_lint_command')
  let g:openvox_metadata_lint_command = 'metadata-json-lint'
endif

" yamllint command path
if !exists('g:openvox_yamllint_command')
  let g:openvox_yamllint_command = 'yamllint'
endif

" Maximum line length (style guide default: 140)
if !exists('g:openvox_max_line_length')
  let g:openvox_max_line_length = 140
endif

" Enable code folding (default: on)
if !exists('g:openvox_fold')
  let g:openvox_fold = 1
endif

" Disable default key mappings
if !exists('g:openvox_no_mappings')
  let g:openvox_no_mappings = 0
endif

" Auto-lint on save (default: on)
if !exists('g:openvox_auto_lint')
  let g:openvox_auto_lint = 1
endif

" Extra puppet-lint arguments (list)
if !exists('g:openvox_lint_args')
  let g:openvox_lint_args = []
endif

" Disabled puppet-lint checks (list of check names without -check suffix)
if !exists('g:openvox_lint_disabled_checks')
  let g:openvox_lint_disabled_checks = []
endif

" Extra metadata-json-lint arguments (list)
if !exists('g:openvox_metadata_lint_args')
  let g:openvox_metadata_lint_args = []
endif

" Extra yamllint arguments (list)
if !exists('g:openvox_yamllint_args')
  let g:openvox_yamllint_args = []
endif

" Open quickfix window automatically on lint errors (default: off)
" When off, errors display as a concise message on the command line.
" The quickfix list is always populated — use :copen to see full details.
if !exists('g:openvox_lint_open_quickfix')
  let g:openvox_lint_open_quickfix = 0
endif

" ─── Commands ─────────────────────────────────────────────────────

" Linting
command! -nargs=0 OpenvoxLint      call openvox#lint#run()
command! -nargs=0 OpenvoxLintFix   call openvox#lint#fix()
command! -nargs=0 OpenvoxValidate  call openvox#lint#validate()
command! -nargs=0 OpenvoxMetadataLint call openvox#lint#metadata()
command! -nargs=0 OpenvoxYamlLint  call openvox#lint#yaml()

" Arrow alignment
command! -range OpenvoxAlign       <line1>,<line2>call openvox#align#arrows()
command! -nargs=0 OpenvoxAlignBlock call openvox#align#block()

" Navigation
command! -nargs=0 OpenvoxGotoDef   call openvox#navigate#goto_definition()

" Documentation
command! -nargs=0 OpenvoxDoc       call openvox#doc#lookup()

" Snippets / boilerplate
command! -nargs=1 OpenvoxClass     call openvox#snippets#class(<q-args>)
command! -nargs=1 OpenvoxDefine    call openvox#snippets#define(<q-args>)
command! -nargs=0 OpenvoxInit      call openvox#snippets#init()

" ─── Autocmds ─────────────────────────────────────────────────────

augroup OpenvoxPlugin
  autocmd!

  " Auto-lint on save
  if get(g:, 'openvox_auto_lint', 1)
    autocmd BufWritePost *.pp call openvox#lint#run()
    autocmd BufWritePost */metadata.json
          \ if &filetype =~# 'puppet_metadata' |
          \   call openvox#lint#metadata() |
          \ endif
    autocmd BufWritePost */data/*.yaml,*/data/*.yml,*/hieradata/*.yaml,*/hieradata/*.yml
          \ call openvox#lint#yaml()
  endif

  " EPP template ftplugin settings
  autocmd FileType epuppet setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab

  " Hiera YAML settings
  autocmd FileType yaml.puppet_hiera setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab

augroup END