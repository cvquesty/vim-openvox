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
" Jobs launch as argv lists (never shell-joined). Per-job state isolates
" bufnr/type/output so kill/exit races cannot clobber a newer parse.
" Signs use group openvox_lint (never `sign unplace *`).

" ─── Job state (per-launch isolation) ─────────────────────────────
let s:next_job_id = 0
let s:jobs = {}
" Track openvox sign ids per buffer when sign_group API is unavailable
let s:sign_ids = {}

" ─── lint (openvox-lint preferred; puppet-lint compatible) ─────────

function! openvox#lint#run(...) abort
  let l:file = expand('%:p')
  if empty(l:file) || !filereadable(l:file)
    let l:tool = fnamemodify(get(g:, 'openvox_lint_command', 'openvox-lint'), ':t')
    echohl WarningMsg | echo l:tool . ': No file to lint' | echohl None
    return
  endif

  if &modified
    write
  endif

  let l:bufnr = bufnr('%')
  call s:cancel_jobs_for_bufnr(l:bufnr)

  let l:cmd = get(g:, 'openvox_lint_command', 'openvox-lint')
  let l:tool = fnamemodify(l:cmd, ':t')
  let l:args = [l:cmd]

  " Output format for parsing: filename:line:column:KIND:check:message
  call add(l:args, '--log-format')
  call add(l:args, '%{path}:%{line}:%{column}:%{KIND}:%{check}:%{message}')

  let l:extra = get(g:, 'openvox_lint_args', [])
  if type(l:extra) == v:t_list
    let l:args += l:extra
  endif

  let l:disabled = get(g:, 'openvox_lint_disabled_checks', [])
  for l:check in l:disabled
    call add(l:args, '--no-' . l:check . '-check')
  endfor

  call add(l:args, l:file)

  echon l:tool . ': checking ' . fnamemodify(l:file, ':t') . '...'

  call s:start_job(l:args, 'puppet-lint', l:bufnr, l:tool, 's:on_exit')
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

  let l:bufnr = bufnr('%')
  call s:cancel_jobs_for_bufnr(l:bufnr)

  let l:cmd = get(g:, 'openvox_lint_command', 'openvox-lint')
  let l:tool = fnamemodify(l:cmd, ':t')
  let l:args = [l:cmd, '--fix', l:file]

  echo l:tool . ': fixing ' . fnamemodify(l:file, ':t') . '...'

  call s:start_job(l:args, 'puppet-lint-fix', l:bufnr, l:tool, 's:on_fix_exit')
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

  let l:bufnr = bufnr('%')
  call s:cancel_jobs_for_bufnr(l:bufnr)

  let l:puppet_cmd = get(g:, 'openvox_puppet_command', 'puppet')
  let l:puppet_tool = fnamemodify(l:puppet_cmd, ':t')
  let l:args = [l:puppet_cmd, 'parser', 'validate', l:file]

  echon l:puppet_tool . ': validating ' . fnamemodify(l:file, ':t') . '...'

  call s:start_job(l:args, 'puppet-validate', l:bufnr, l:puppet_tool, 's:on_exit')
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

  let l:bufnr = bufnr('%')
  call s:cancel_jobs_for_bufnr(l:bufnr)

  let l:cmd = get(g:, 'openvox_metadata_lint_command', 'metadata-json-lint')
  let l:args = [l:cmd]

  let l:extra = get(g:, 'openvox_metadata_lint_args', [])
  if type(l:extra) == v:t_list
    let l:args += l:extra
  endif

  call add(l:args, l:file)

  echon 'metadata-json-lint: checking ' . fnamemodify(l:file, ':t') . '...'

  call s:start_job(l:args, 'metadata-json-lint', l:bufnr, 'metadata-json-lint', 's:on_metadata_exit')
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

  let l:bufnr = bufnr('%')
  call s:cancel_jobs_for_bufnr(l:bufnr)

  let l:cmd = get(g:, 'openvox_yamllint_command', 'yamllint')
  let l:args = [l:cmd]

  call add(l:args, '-f')
  call add(l:args, 'parsable')

  let l:extra = get(g:, 'openvox_yamllint_args', [])
  if type(l:extra) == v:t_list
    let l:args += l:extra
  endif

  call add(l:args, l:file)

  echon 'yamllint: checking ' . fnamemodify(l:file, ':t') . '...'

  call s:start_job(l:args, 'yamllint', l:bufnr, 'yamllint', 's:on_yaml_exit')
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

" Public: parse openvox-lint / puppet-lint log lines into a qflist.
" Safe for unit tests without a binary. Handles Windows drive paths.
function! openvox#lint#parse_puppet_lint_lines(lines) abort
  return s:parse_puppet_lint_lines(a:lines)
endfunction

" ─── Job launcher / callbacks ─────────────────────────────────────


" ─── Architect: Vim8 / Neovim job shim (list-form argv only) ───────
" Quality's s:start_job calls these when defined.

let s:nvim_linebuf = {}

function! s:job_start_compat(args, job_id, exit_fn) abort
  if type(a:args) != v:t_list
    echoerr 'openvox#lint: job argv must be a List (no shell string)'
    return v:null
  endif

  if has('nvim')
    let s:nvim_linebuf[a:job_id] = {'out': '', 'err': ''}
    let l:job = jobstart(a:args, {
          \ 'on_stdout': function('s:nvim_on_stdout', [a:job_id]),
          \ 'on_stderr': function('s:nvim_on_stderr', [a:job_id]),
          \ 'on_exit':   function('s:nvim_on_exit', [a:job_id, a:exit_fn]),
          \ })
    if l:job <= 0
      if has_key(s:nvim_linebuf, a:job_id)
        call remove(s:nvim_linebuf, a:job_id)
      endif
      return v:null
    endif
    return l:job
  endif

  return job_start(a:args, {
        \ 'out_cb':   function('s:on_stdout', [a:job_id]),
        \ 'err_cb':   function('s:on_stderr', [a:job_id]),
        \ 'exit_cb':  function(a:exit_fn, [a:job_id]),
        \ 'out_mode': 'nl',
        \ 'err_mode': 'nl',
        \ 'in_io':    'null',
        \ })
endfunction

function! s:job_stop_compat(job) abort
  if a:job is v:null
    return
  endif
  if has('nvim')
    if type(a:job) == v:t_number && a:job > 0
      try
        call jobstop(a:job)
      catch
      endtry
    endif
    return
  endif
  if exists('*job_status') && job_status(a:job) ==# 'run'
    call job_stop(a:job, 'kill')
  endif
endfunction

function! s:nvim_emit_lines(job_id, which, data) abort
  if !has_key(s:nvim_linebuf, a:job_id) || empty(a:data)
    return
  endif
  let l:buf = s:nvim_linebuf[a:job_id][a:which]
  let l:buf .= a:data[0]
  let l:idx = 1
  while l:idx < len(a:data)
    if a:which ==# 'out'
      call s:on_stdout(a:job_id, a:job_id, l:buf)
    else
      call s:on_stderr(a:job_id, a:job_id, l:buf)
    endif
    let l:buf = a:data[l:idx]
    let l:idx += 1
  endwhile
  let s:nvim_linebuf[a:job_id][a:which] = l:buf
endfunction

function! s:nvim_on_stdout(job_id, nvim_job, data, event) abort
  call s:nvim_emit_lines(a:job_id, 'out', a:data)
endfunction

function! s:nvim_on_stderr(job_id, nvim_job, data, event) abort
  call s:nvim_emit_lines(a:job_id, 'err', a:data)
endfunction

function! s:nvim_on_exit(job_id, exit_fn, nvim_job, exit_code, event) abort
  if has_key(s:nvim_linebuf, a:job_id)
    let l:bufs = remove(s:nvim_linebuf, a:job_id)
    if !empty(l:bufs.out)
      call s:on_stdout(a:job_id, a:nvim_job, l:bufs.out)
    endif
    if !empty(l:bufs.err)
      call s:on_stderr(a:job_id, a:nvim_job, l:bufs.err)
    endif
  endif
  call call(function(a:exit_fn, [a:job_id]), [a:nvim_job, a:exit_code])
endfunction


function! s:start_job(args, type, bufnr, tool, exit_fn) abort
  let s:next_job_id += 1
  let l:id = s:next_job_id
  let s:jobs[l:id] = {
        \ 'id':        l:id,
        \ 'bufnr':     a:bufnr,
        \ 'type':      a:type,
        \ 'tool':      a:tool,
        \ 'output':    [],
        \ 'errors':    [],
        \ 'cancelled': 0,
        \ 'job':       v:null,
        \ }

  " Keep list-form argv; never shell-join.
  " Architect may replace this Vim8 job_start with an nvim shim — preserve that if present.
  if exists('*s:job_start_compat')
    let l:job = s:job_start_compat(a:args, l:id, a:exit_fn)
  else
    let l:job = job_start(a:args, {
          \ 'out_cb':   function('s:on_stdout', [l:id]),
          \ 'err_cb':   function('s:on_stderr', [l:id]),
          \ 'exit_cb':  function(a:exit_fn, [l:id]),
          \ 'out_mode': 'nl',
          \ 'err_mode': 'nl',
          \ 'in_io':    'null',
          \ })
  endif
  let s:jobs[l:id].job = l:job
  return l:id
endfunction

function! s:cancel_jobs_for_bufnr(bufnr) abort
  for [l:key, l:st] in items(s:jobs)
    if l:st.bufnr == a:bufnr && !l:st.cancelled
      let l:st.cancelled = 1
      if l:st.job isnot v:null
        if exists('*s:job_stop_compat')
          call s:job_stop_compat(l:st.job)
        elseif exists('*job_status') && job_status(l:st.job) ==# 'run'
          call job_stop(l:st.job, 'kill')
        endif
      endif
    endif
  endfor
endfunction

function! s:on_stdout(job_id, channel, msg) abort
  if !has_key(s:jobs, a:job_id) || s:jobs[a:job_id].cancelled
    return
  endif
  if !empty(a:msg)
    call add(s:jobs[a:job_id].output, a:msg)
  endif
endfunction

function! s:on_stderr(job_id, channel, msg) abort
  if !has_key(s:jobs, a:job_id) || s:jobs[a:job_id].cancelled
    return
  endif
  if !empty(a:msg)
    call add(s:jobs[a:job_id].errors, a:msg)
  endif
endfunction

function! s:take_job(job_id) abort
  if !has_key(s:jobs, a:job_id)
    return {}
  endif
  let l:st = remove(s:jobs, a:job_id)
  return l:st
endfunction

function! s:on_exit(job_id, job, exit_code) abort
  let l:st = s:take_job(a:job_id)
  if empty(l:st) || l:st.cancelled
    return
  endif

  if l:st.type ==# 'puppet-lint'
    call s:finish_puppet_lint(l:st, a:exit_code)
  elseif l:st.type ==# 'puppet-validate'
    call s:finish_puppet_validate(l:st, a:exit_code)
  endif
endfunction

function! s:on_fix_exit(job_id, job, exit_code) abort
  let l:st = s:take_job(a:job_id)
  if empty(l:st) || l:st.cancelled
    return
  endif

  let l:tool = l:st.tool
  if a:exit_code == 0
    " Reload only if still on the same buffer
    if bufnr('%') == l:st.bufnr
      edit
      echohl MoreMsg | echo l:tool . ': fixes applied' | echohl None
      call openvox#lint#run()
    endif
  else
    echohl ErrorMsg | echo l:tool . ' --fix failed' | echohl None
    for l:line in l:st.errors
      echohl ErrorMsg | echo '  ' . l:line | echohl None
    endfor
  endif
endfunction

function! s:on_metadata_exit(job_id, job, exit_code) abort
  let l:st = s:take_job(a:job_id)
  if empty(l:st) || l:st.cancelled
    return
  endif
  call s:finish_metadata_lint(l:st, a:exit_code)
endfunction

function! s:on_yaml_exit(job_id, job, exit_code) abort
  let l:st = s:take_job(a:job_id)
  if empty(l:st) || l:st.cancelled
    return
  endif
  call s:finish_yamllint(l:st, a:exit_code)
endfunction

" ─── Sign definitions ─────────────────────────────────────────────
if !exists('s:signs_defined')
  sign define openvox_error   text=>> texthl=ErrorMsg   linehl=
  sign define openvox_warning text=>> texthl=WarningMsg linehl=
  let s:signs_defined = 1
endif

function! s:clear_openvox_signs(bufnr) abort
  if exists('*sign_unplace')
    call sign_unplace('openvox_lint', {'buffer': a:bufnr})
  elseif has_key(s:sign_ids, a:bufnr)
    for l:id in s:sign_ids[a:bufnr]
      execute 'sign unplace ' . l:id . ' buffer=' . a:bufnr
    endfor
  endif
  let s:sign_ids[a:bufnr] = []
endfunction

function! s:place_openvox_sign(bufnr, lnum, name, id) abort
  if exists('*sign_place')
    call sign_place(a:id, 'openvox_lint', a:name, a:bufnr, {'lnum': a:lnum})
  else
    execute printf('sign place %d line=%d name=%s buffer=%d',
          \ a:id, a:lnum, a:name, a:bufnr)
  endif
  if !has_key(s:sign_ids, a:bufnr)
    let s:sign_ids[a:bufnr] = []
  endif
  call add(s:sign_ids[a:bufnr], a:id)
endfunction

" ─── Display helper ──────────────────────────────────────────────

function! s:display_results(tool, qflist, bufnr) abort
  let l:bufnr = a:bufnr > 0 ? a:bufnr : bufnr('%')
  call s:clear_openvox_signs(l:bufnr)

  let l:sign_id = 1000
  for l:item in a:qflist
    let l:sign_name = l:item.type ==# 'E' ? 'openvox_error' : 'openvox_warning'
    let l:target_buf = bufnr(get(l:item, 'filename', bufname(l:bufnr)))
    if l:target_buf == -1
      let l:target_buf = l:bufnr
    endif
    call s:place_openvox_sign(l:target_buf, l:item.lnum, l:sign_name, l:sign_id)
    let l:sign_id += 1
  endfor

  if empty(a:qflist)
    echohl MoreMsg | echon a:tool . ': no issues ✓' | echohl None
    return
  endif

  let l:first = a:qflist[0]
  let l:errors = len(filter(copy(a:qflist), 'v:val.type ==# "E"'))
  let l:warnings = len(a:qflist) - l:errors

  let l:counts = []
  if l:errors > 0   | call add(l:counts, l:errors . 'E')   | endif
  if l:warnings > 0  | call add(l:counts, l:warnings . 'W') | endif

  let l:summary = a:tool . ': ' . join(l:counts, ' ')
        \ . ' | L' . l:first.lnum . ': ' . l:first.text

  let l:maxwidth = &columns - 1
  if len(l:summary) > l:maxwidth
    let l:summary = l:summary[:l:maxwidth - 4] . '...'
  endif

  let l:hl = l:errors > 0 ? 'ErrorMsg' : 'WarningMsg'
  execute 'echohl ' . l:hl | echon l:summary | echohl None

  if get(g:, 'openvox_lint_open_quickfix', 0)
    botright copen
  endif
endfunction

" ─── Parsers ──────────────────────────────────────────────────────

" Parse path:line:column:KIND:check:message without naive split(':')
" so Windows paths like C:\foo\bar.pp survive.
function! s:parse_puppet_lint_lines(lines) abort
  let l:qflist = []
  for l:line in a:lines
    let l:match = matchlist(l:line, '\v^(.{-}):(\d+):(\d+):(ERROR|WARNING):([^:]+):(.*)$')
    if empty(l:match)
      continue
    endif
    call add(l:qflist, {
          \ 'filename': l:match[1],
          \ 'lnum':     str2nr(l:match[2]),
          \ 'col':      str2nr(l:match[3]),
          \ 'type':     l:match[4] ==# 'ERROR' ? 'E' : 'W',
          \ 'text':     '[' . l:match[5] . '] ' . l:match[6],
          \ })
  endfor
  return l:qflist
endfunction

function! s:finish_puppet_lint(st, exit_code) abort
  let l:qflist = s:parse_puppet_lint_lines(a:st.output)
  call setqflist(l:qflist)
  call s:display_results(a:st.tool, l:qflist, a:st.bufnr)
endfunction

function! s:finish_puppet_validate(st, exit_code) abort
  let l:qflist = []

  for l:line in a:st.output + a:st.errors
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
  call s:display_results(a:st.tool, l:qflist, a:st.bufnr)
endfunction

function! s:finish_metadata_lint(st, exit_code) abort
  let l:qflist = []
  let l:file = bufname(a:st.bufnr)
  if empty(l:file)
    let l:file = expand('%:p')
  endif

  for l:line in a:st.output + a:st.errors
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
  call s:display_results('metadata-json-lint', l:qflist, a:st.bufnr)
endfunction

function! s:finish_yamllint(st, exit_code) abort
  let l:qflist = []

  for l:line in a:st.output
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
  call s:display_results('yamllint', l:qflist, a:st.bufnr)
endfunction
