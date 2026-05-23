" autoload/openvox/navigate.vim — Navigation helpers for Puppet files
scriptencoding utf-8
" Maintainer: xAI
" License:    Apache-2.0
"
" Provides:
"   - Jump to class/define definition
"   - Navigate between class/define blocks with [[ and ]]

" ─── Go to definition ─────────────────────────────────────────────
" Tries to find the class or defined type under the cursor

function! openvox#navigate#goto_definition() abort
  " Get the word under cursor (handles module::class paths)
  let l:word = expand('<cWORD>')

  " Clean up quotes and commas
  let l:word = substitute(l:word, "^['\"]\\|['\",;]$", '', 'g')

  " Remove leading Class[] or similar type references
  let l:word = substitute(l:word, '^\u\w*\[', '', '')
  let l:word = substitute(l:word, '\]$', '', '')
  let l:word = substitute(l:word, "^['\"]\\|['\"]$", '', 'g')

  if empty(l:word)
    echo 'No identifier under cursor'
    return
  endif

  " Convert :: to directory path for manifests
  " e.g., profile::base::linux → profile/manifests/base/linux.pp
  let l:parts = split(l:word, '::')
  if len(l:parts) < 1
    echo 'Not a valid Puppet class name: ' . l:word
    return
  endif

  " Construct possible file paths
  let l:candidates = []

  " Module-style: modulename::classname → modules/modulename/manifests/classname.pp
  if len(l:parts) >= 2
    let l:module = l:parts[0]
    let l:rest = join(l:parts[1:], '/')
    call add(l:candidates, '**/modules/' . l:module . '/manifests/' . l:rest . '.pp')
    call add(l:candidates, '**/' . l:module . '/manifests/' . l:rest . '.pp')
    " Site modules, roles, profiles patterns
    call add(l:candidates, '**/site/' . l:module . '/manifests/' . l:rest . '.pp')
    call add(l:candidates, '**/site-modules/' . l:module . '/manifests/' . l:rest . '.pp')
  endif

  " Module init: modulename → modules/modulename/manifests/init.pp
  if len(l:parts) == 1
    call add(l:candidates, '**/modules/' . l:parts[0] . '/manifests/init.pp')
    call add(l:candidates, '**/' . l:parts[0] . '/manifests/init.pp')
  endif

  " Try each candidate path
  for l:glob in l:candidates
    let l:files = glob(l:glob, 0, 1)
    if !empty(l:files)
      execute 'edit ' . fnameescape(l:files[0])
      " Try to find the class/define declaration in the file
      let l:pattern = '\<\(class\|define\)\s\+' . escape(l:word, ':')
      call search(l:pattern, 'w')
      echo 'Found: ' . l:files[0]
      return
    endif
  endfor

  " Fallback: search in current file
  let l:save_pos = getpos('.')
  call cursor(1, 1)
  let l:pattern = '\<\(class\|define\)\s\+' . escape(l:word, ':')
  if search(l:pattern, 'W')
    echo 'Found in current file'
  else
    call setpos('.', l:save_pos)
    echo 'Definition not found: ' . l:word
  endif
endfunction

" ─── Jump to previous class/define/node block ─────────────────────

function! openvox#navigate#prev_block() abort
  call search('^\s*\(class\|define\|node\)\s\+', 'bW')
endfunction

" ─── Jump to next class/define/node block ─────────────────────────

function! openvox#navigate#next_block() abort
  " Move forward past current line first
  call search('^\s*\(class\|define\|node\)\s\+', 'W')
endfunction