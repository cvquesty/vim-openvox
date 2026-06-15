" autoload/openvox/lint.vim — Async linting integration
scriptencoding utf-8
" Maintainer: xAI
" License:    Apache-2.0
"
" Integrates:
"   - openvox-lint (preferred; for .pp manifest files; puppet-lint compatible via g:openvox_lint_command)
"   - metadata-json-lint (for metadata.json)
"   - yamllint      (for Hiera YAML data files)
"
" All linters run asynchronously via Vim's job_start() and populate
" the quickfix or location list.

" ─── State ────────────────────────────────────────────────────────
let s:lint_job = v:null
let s:lint_output = []
let s:lint_errors = []
let s:lint_type = ''

" ─── lint (openvox-lint preferred; puppet-lint compatible) ─────────

function! openvox#lint#run(...) abort
  let l:file = expand('%:p')
  if empty(l:file) || !filereadable(l:file)
    let l:tool = fnamemodify(get(g:, 'openvox_lint_command', 'openvox-lint'), ':t')
    echohl WarningMsg | echo l:tool . ': No file to lint' | echohl None
    return
  endif

  " Save the buffer first
  if &modified
    write
  endif

  " Kill any running lint job
  call s:kill_job()

  let s:lint_output = []
  let s:lint_errors = []
  let s:lint_type = 'puppet-lint'  " internal dispatch key (log format compat)
  let l:cmd = get(g:, 'openvox_lint_command', 'openvox-lint')
  let l:tool = fnamemodify(l:cmd, ':t')
  let s:lint_tool = l:tool  " runtime basename for all user echoes/display (dynamic branding)
  let l:args = [l:cmd]

  " Output format for parsing: filename:line:column:KIND:check:message
  call add(l:args, '--log-format')
  call add(l:args, '%{path}:%{line}:%{column}:%{KIND}:%{check}:%{message}')

  " Add user-configured arguments
  let l:extra = get(g:, 'openvox_lint_args', [])
  if type(l:extra) == v:t_list
    let l:args += l:extra
  endif

  " Disabled checks
  let l:disabled = get(g:, 'openvox_lint_disabled_checks', [])
  for l:check in l:disabled
    call add(l:args, '--no-' . l:check . '-check')
  endfor

  " Critical style checks (arrow_alignment, ensure_first, 140chars, ...) are enabled by default
  " in openvox-lint/puppet-lint. Respect g:openvox_lint_disabled_checks for user overrides.
  " (No-op YOLO force loop removed; --only-checks available via g:openvox_lint_args or --only-checks if limiting desired.)
  " openvox-lint supports --only-checks CHECKS (comma sep) per --help.

  call add(l:args, l:file)

  echon l:tool . ': checking ' . fnamemodify(l:file, ':t') . '...'

  let s:lint_job = job_start(l:args, {
        \ 'out_cb':   function('s:on_stdout'),
        \ 'err_cb':   function('s:on_stderr'),
        \ 'exit_cb':  function('s:on_exit'),
        \ 'out_mode': 'nl',
        \ 'err_mode': 'nl',
        \ 'in_io':    'null',
        \ })
endfunction

function! openvox#lint#fix() abort
  let l:file = expand('%:p')
  if empty(l:file) || !filereadable(l:file)
    let l:tool = fnamemodify(get(g:, 'openvox_lint_command', 'openvox-lint'), ':t')
    echohl WarningMsg | echo l:tool . ': No file to fix' | echohl None
    return
  endif

  if &modified
    write
  endif

  call s:kill_job()

  let s:lint_output = []
  let s:lint_errors = []
  let s:lint_type = 'puppet-lint-fix'

  let l:cmd = get(g:, 'openvox_lint_command', 'openvox-lint')
  let l:tool = fnamemodify(l:cmd, ':t')
  let s:lint_tool = l:tool
  let l:args = [l:cmd, '--fix', l:file]

  echo l:tool . ': fixing ' . fnamemodify(l:file, ':t') . '...'

  let s:lint_job = job_start(l:args, {
        \ 'out_cb':   function('s:on_stdout'),
        \ 'err_cb':   function('s:on_stderr'),
        \ 'exit_cb':  function('s:on_fix_exit'),
        \ 'out_mode': 'nl',
        \ 'err_mode': 'nl',
        \ 'in_io':    'null',
        \ })
endfunction

" ─── puppet validate (syntax check) ──────────────────────────────

function! openvox#lint#validate() abort
  let l:file = expand('%:p')
  if empty(l:file) || !filereadable(l:file)
    let l:puppet_tool = fnamemodify(get(g:, 'openvox_puppet_command', 'puppet'), ':t')
    echohl WarningMsg | echo l:puppet_tool . ': No file to validate' | echohl None
    return
  endif

  if &modified
    write
  endif

  call s:kill_job()

  let s:lint_output = []
  let s:lint_errors = []
  let s:lint_type = 'puppet-validate'

  let l:puppet_cmd = get(g:, 'openvox_puppet_command', 'puppet')
  let l:puppet_tool = fnamemodify(l:puppet_cmd, ':t')
  let s:puppet_tool = l:puppet_tool
  let l:args = [l:puppet_cmd, 'parser', 'validate', l:file]

  echon l:puppet_tool . ': validating ' . fnamemodify(l:file, ':t') . '...'

  let s:lint_job = job_start(l:args, {
        \ 'out_cb':   function('s:on_stdout'),
        \ 'err_cb':   function('s:on_stderr'),
        \ 'exit_cb':  function('s:on_exit'),
        \ 'out_mode': 'nl',
        \ 'err_mode': 'nl',
        \ 'in_io':    'null',
        \ })
endfunction

" ─── metadata-json-lint ───────────────────────────────────────────

function! openvox#lint#metadata() abort
  let l:file = expand('%:p')
  if fnamemodify(l:file, ':t') !=# 'metadata.json'
    echohl WarningMsg | echo 'metadata-json-lint: Not a metadata.json file' | echohl None
    return
  endif

  if &modified
    write
  endif

  call s:kill_job()

  let s:lint_output = []
  let s:lint_errors = []
  let s:lint_type = 'metadata-json-lint'

  let l:cmd = get(g:, 'openvox_metadata_lint_command', 'metadata-json-lint')
  let l:args = [l:cmd]

  " Add user-configured arguments
  let l:extra = get(g:, 'openvox_metadata_lint_args', [])
  if type(l:extra) == v:t_list
    let l:args += l:extra
  endif

  call add(l:args, l:file)

  echon 'metadata-json-lint: checking ' . fnamemodify(l:file, ':t') . '...'

  let s:lint_job = job_start(l:args, {
        \ 'out_cb':   function('s:on_stdout'),
        \ 'err_cb':   function('s:on_stderr'),
        \ 'exit_cb':  function('s:on_metadata_exit'),
        \ 'out_mode': 'nl',
        \ 'err_mode': 'nl',
        \ 'in_io':    'null',
        \ })
endfunction

" ─── yamllint ─────────────────────────────────────────────────────

function! openvox#lint#yaml() abort
  let l:file = expand('%:p')
  if empty(l:file) || !filereadable(l:file)
    echohl WarningMsg | echo 'yamllint: No file to lint' | echohl None
    return
  endif

  if &modified
    write
  endif

  call s:kill_job()

  let s:lint_output = []
  let s:lint_errors = []
  let s:lint_type = 'yamllint'

  let l:cmd = get(g:, 'openvox_yamllint_command', 'yamllint')
  let l:args = [l:cmd]

  " Use parsable format for quickfix
  call add(l:args, '-f')
  call add(l:args, 'parsable')

  " Add user-configured arguments (e.g., -c config file)
  let l:extra = get(g:, 'openvox_yamllint_args', [])
  if type(l:extra) == v:t_list
    let l:args += l:extra
  endif

  call add(l:args, l:file)

  echon 'yamllint: checking ' . fnamemodify(l:file, ':t') . '...'

  let s:lint_job = job_start(l:args, {
        \ 'out_cb':   function('s:on_stdout'),
        \ 'err_cb':   function('s:on_stderr'),
        \ 'exit_cb':  function('s:on_yaml_exit'),
        \ 'out_mode': 'nl',
        \ 'err_mode': 'nl',
        \ 'in_io':    'null',
        \ })
endfunction

" ─── Auto-lint on save ────────────────────────────────────────────

function! openvox#lint#auto() abort
  let l:ft = &filetype
  if l:ft ==# 'puppet'
    call openvox#lint#run()
  elseif l:ft =~# 'puppet_metadata'
    call openvox#lint#metadata()
  elseif l:ft =~# 'puppet_hiera' || l:ft ==# 'yaml'
    call openvox#lint#yaml()
  endif
endfunction

" ─── Callbacks ────────────────────────────────────────────────────

function! s:on_stdout(channel, msg) abort
  if !empty(a:msg)
    call add(s:lint_output, a:msg)
  endif
endfunction

function! s:on_stderr(channel, msg) abort
  if !empty(a:msg)
    call add(s:lint_errors, a:msg)
  endif
endfunction

function! s:on_exit(job, exit_code) abort
  let s:lint_job = v:null

  if s:lint_type ==# 'puppet-lint'
    call s:parse_puppet_lint(a:exit_code)
  elseif s:lint_type ==# 'puppet-validate'
    call s:parse_puppet_validate(a:exit_code)
  endif
endfunction

function! s:on_fix_exit(job, exit_code) abort
  let s:lint_job = v:null
  let l:tool = get(s:, 'lint_tool', 'openvox-lint')
  if a:exit_code == 0
    " Reload the file after fixes
    edit
    echohl MoreMsg | echo l:tool . ': fixes applied' | echohl None
    " Run lint again to show remaining issues
    call openvox#lint#run()
  else
    echohl ErrorMsg | echo l:tool . ' --fix failed' | echohl None
    for l:line in s:lint_errors
      echohl ErrorMsg | echo '  ' . l:line | echohl None
    endfor
  endif
endfunction

function! s:on_metadata_exit(job, exit_code) abort
  let s:lint_job = v:null
  call s:parse_metadata_lint(a:exit_code)
endfunction

function! s:on_yaml_exit(job, exit_code) abort
  let s:lint_job = v:null
  call s:parse_yamllint(a:exit_code)
endfunction

" ─── Sign definitions ─────────────────────────────────────────────
" Non-intrusive gutter markers for error/warning lines
if !exists('s:signs_defined')
  sign define openvox_error   text=>> texthl=ErrorMsg   linehl=
  sign define openvox_warning text=>> texthl=WarningMsg linehl=
  let s:signs_defined = 1
endif

" ─── Display helper ──────────────────────────────────────────────
" Shows a concise one-line summary on the command line and places
" >> signs in the gutter. The quickfix list is always populated so
" :copen / :cnext / :cprev work when the user wants full details.

function! s:display_results(tool, qflist) abort
  " Clear previous signs for this buffer
  execute 'sign unplace * buffer=' . bufnr('%')

  " Place >> signs in the gutter on error/warning lines
  let l:sign_id = 1000
  for l:item in a:qflist
    let l:sign_name = l:item.type ==# 'E' ? 'openvox_error' : 'openvox_warning'
    let l:target_buf = bufnr(get(l:item, 'filename', expand('%:p')))
    if l:target_buf == -1
      let l:target_buf = bufnr('%')
    endif
    execute printf('sign place %d line=%d name=%s buffer=%d',
          \ l:sign_id, l:item.lnum, l:sign_name, l:target_buf)
    let l:sign_id += 1
  endfor

  if empty(a:qflist)
    echohl MoreMsg | echon a:tool . ': no issues ✓' | echohl None
    return
  endif

  " Build concise summary: "tool: 1E 3W | L12: [check] message"
  let l:first = a:qflist[0]
  let l:errors = len(filter(copy(a:qflist), 'v:val.type ==# "E"'))
  let l:warnings = len(a:qflist) - l:errors

  let l:counts = []
  if l:errors > 0   | call add(l:counts, l:errors . 'E')   | endif
  if l:warnings > 0  | call add(l:counts, l:warnings . 'W') | endif

  let l:summary = a:tool . ': ' . join(l:counts, ' ')
        \ . ' | L' . l:first.lnum . ': ' . l:first.text

  " Truncate to avoid "Press ENTER" prompt
  let l:maxwidth = &columns - 1
  if len(l:summary) > l:maxwidth
    let l:summary = l:summary[:l:maxwidth - 4] . '...'
  endif

  let l:hl = l:errors > 0 ? 'ErrorMsg' : 'WarningMsg'
  execute 'echohl ' . l:hl | echon l:summary | echohl None

  " Optionally open the quickfix window (off by default)
  if get(g:, 'openvox_lint_open_quickfix', 0)
    botright copen
  endif
endfunction

" ─── Parsers ──────────────────────────────────────────────────────

function! s:parse_puppet_lint(exit_code) abort
  let l:qflist = []

  for l:line in s:lint_output
    " Format: path:line:column:KIND:check:message
    let l:parts = split(l:line, ':')
    if len(l:parts) >= 6
      let l:filename = l:parts[0]
      let l:lnum = str2nr(l:parts[1])
      let l:col = str2nr(l:parts[2])
      let l:kind = l:parts[3]
      let l:check = l:parts[4]
      let l:message = join(l:parts[5:], ':')
      call add(l:qflist, {
            \ 'filename': l:filename,
            \ 'lnum':     l:lnum,
            \ 'col':      l:col,
            \ 'type':     l:kind ==# 'ERROR' ? 'E' : 'W',
            \ 'text':     '[' . l:check . '] ' . l:message,
            \ })
    endif
  endfor

  call setqflist(l:qflist)
  call s:display_results(get(s:, 'lint_tool', 'openvox-lint'), l:qflist)
endfunction

function! s:parse_puppet_validate(exit_code) abort
  let l:qflist = []

  for l:line in s:lint_output + s:lint_errors
    let l:match = matchlist(l:line, '\(Error\|Warning\):\s*\(.*\)\s\+at\s\+\(\S\+\):\(\d\+\):\?\(\d*\)')
    if !empty(l:match)
      call add(l:qflist, {
            \ 'filename': l:match[3],
            \ 'lnum':     str2nr(l:match[4]),
            \ 'col':      empty(l:match[5]) ? 0 : str2nr(l:match[5]),
            \ 'type':     l:match[1] ==# 'Error' ? 'E' : 'W',
            \ 'text':     l:match[2],
            \ })
      continue
    endif
    let l:match = matchlist(l:line, '\(Error\|Warning\):\s*\(.\{-}\)\s*(file:\s*\(\S\+\),\s*line:\s*\(\d\+\)')
    if !empty(l:match)
      call add(l:qflist, {
            \ 'filename': l:match[3],
            \ 'lnum':     str2nr(l:match[4]),
            \ 'type':     l:match[1] ==# 'Error' ? 'E' : 'W',
            \ 'text':     l:match[2],
            \ })
    endif
  endfor

  call setqflist(l:qflist)
  call s:display_results(get(s:, 'puppet_tool', 'puppet'), l:qflist)
endfunction

function! s:parse_metadata_lint(exit_code) abort
  let l:qflist = []
  let l:file = expand('%:p')

  for l:line in s:lint_output + s:lint_errors
    let l:type = 'W'
    if l:line =~# '^Error'
      let l:type = 'E'
    endif
    if l:line =~# '^\(Error\|Warning\):'
      let l:msg = substitute(l:line, '^\(Error\|Warning\):\s*', '', '')
      call add(l:qflist, {
            \ 'filename': l:file,
            \ 'lnum':     1,
            \ 'type':     l:type,
            \ 'text':     l:msg,
            \ })
    endif
  endfor

  call setqflist(l:qflist)
  call s:display_results('metadata-json-lint', l:qflist)
endfunction

function! s:parse_yamllint(exit_code) abort
  let l:qflist = []

  for l:line in s:lint_output
    let l:match = matchlist(l:line, '\(.\{-}\):\(\d\+\):\(\d\+\):\s*\[\(\w\+\)\]\s*\(.*\)')
    if !empty(l:match)
      call add(l:qflist, {
            \ 'filename': l:match[1],
            \ 'lnum':     str2nr(l:match[2]),
            \ 'col':      str2nr(l:match[3]),
            \ 'type':     l:match[4] ==# 'error' ? 'E' : 'W',
            \ 'text':     l:match[5],
            \ })
    endif
  endfor

  call setqflist(l:qflist)
  call s:display_results('yamllint', l:qflist)
endfunction

" ─── Helpers ──────────────────────────────────────────────────────

function! s:kill_job() abort
  if s:lint_job isnot v:null && job_status(s:lint_job) ==# 'run'
    call job_stop(s:lint_job, 'kill')
  endif
  let s:lint_job = v:null
endfunction