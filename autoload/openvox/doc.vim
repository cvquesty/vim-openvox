" autoload/openvox/doc.vim — Documentation lookup for Puppet types/functions
scriptencoding utf-8
" Maintainer: xAI
" License:    Apache-2.0
"
" Opens Puppet documentation for the word under the cursor.

function! openvox#doc#lookup() abort
  let l:word = expand('<cword>')
  if empty(l:word)
    echo 'No word under cursor'
    return
  endif

  " Known resource types → open type docs
  let l:builtin_types = ['exec', 'file', 'filebucket', 'group', 'notify',
        \ 'package', 'resources', 'schedule', 'service', 'stage', 'tidy', 'user']

  let l:base_url = 'https://help.puppet.com/core/8/Content/PuppetCore'

  if index(l:builtin_types, l:word) >= 0
    let l:url = l:base_url . '/types/' . l:word . '.htm'
  elseif l:word =~# '^[a-z_]\+$'
    " Might be a function
    let l:url = l:base_url . '/function.htm#' . l:word
  else
    " General search
    let l:url = 'https://help.puppet.com/search?q=' . l:word
  endif

  " Try to open in browser
  if has('mac') || has('macunix')
    call system('open ' . shellescape(l:url) . ' &')
  elseif has('unix')
    call system('xdg-open ' . shellescape(l:url) . ' &')
  elseif has('win32')
    call system('start ' . shellescape(l:url))
  else
    echo 'Open: ' . l:url
    return
  endif

  echo 'Puppet docs: ' . l:word . ' → ' . l:url
endfunction