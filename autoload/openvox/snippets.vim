" autoload/openvox/snippets.vim — Boilerplate code generation
" Maintainer: xAI
" License:    Apache-2.0
"
" Generates style-guide-compliant boilerplate for classes, defined types,
" and module init.pp files.

" ─── Class boilerplate ────────────────────────────────────────────
" Usage: :OpenvoxClass mymodule::myclass

function! openvox#snippets#class(name) abort
  let l:lines = [
        \ '# @summary',
        \ '#   A short summary of the purpose of this class.',
        \ '#',
        \ '# @param param1',
        \ '#   Description of param1.',
        \ '#',
        \ '# @example',
        \ '#   include ' . a:name,
        \ '#',
        \ 'class ' . a:name . ' (',
        \ '  String $param1 = ''default'',',
        \ ') {',
        \ '',
        \ '}',
        \ ]

  call append(line('.') - 1, l:lines)
  echo 'Inserted class boilerplate: ' . a:name
endfunction

" ─── Defined type boilerplate ─────────────────────────────────────
" Usage: :OpenvoxDefine mymodule::mytype

function! openvox#snippets#define(name) abort
  let l:lines = [
        \ '# @summary',
        \ '#   A short summary of the purpose of this defined type.',
        \ '#',
        \ '# @param title',
        \ '#   The namevar for this defined type.',
        \ '#',
        \ '# @param param1',
        \ '#   Description of param1.',
        \ '#',
        \ '# @example',
        \ '#   ' . a:name . ' { ''example'':',
        \ '#     param1 => ''value'',',
        \ '#   }',
        \ '#',
        \ 'define ' . a:name . ' (',
        \ '  String $param1 = ''default'',',
        \ ') {',
        \ '',
        \ '}',
        \ ]

  call append(line('.') - 1, l:lines)
  echo 'Inserted define boilerplate: ' . a:name
endfunction

" ─── Module init.pp boilerplate ───────────────────────────────────
" Usage: :OpenvoxInit (auto-detects module name from path)

function! openvox#snippets#init() abort
  " Try to determine module name from file path
  let l:path = expand('%:p')
  let l:module = ''

  " Match .../modules/MODULENAME/manifests/init.pp
  let l:match = matchlist(l:path, '.*/\(\w\+\)/manifests/init\.pp$')
  if !empty(l:match)
    let l:module = l:match[1]
  endif

  " Match .../site/MODULENAME/manifests/init.pp
  if empty(l:module)
    let l:match = matchlist(l:path, '.*/site[^/]*/\(\w\+\)/manifests/init\.pp$')
    if !empty(l:match)
      let l:module = l:match[1]
    endif
  endif

  if empty(l:module)
    let l:module = input('Module name: ')
    if empty(l:module)
      echo 'Cancelled'
      return
    endif
  endif

  let l:lines = [
        \ '# @summary',
        \ '#   Main class for the ' . l:module . ' module.',
        \ '#',
        \ '# @param manage_package',
        \ '#   Whether to manage the package. Default: true.',
        \ '#',
        \ '# @param manage_service',
        \ '#   Whether to manage the service. Default: true.',
        \ '#',
        \ '# @param package_ensure',
        \ '#   The ensure value for the package. Default: ''present''.',
        \ '#',
        \ '# @param service_ensure',
        \ '#   The ensure value for the service. Default: ''running''.',
        \ '#',
        \ '# @param service_enable',
        \ '#   Whether to enable the service at boot. Default: true.',
        \ '#',
        \ '# @example',
        \ '#   include ' . l:module,
        \ '#',
        \ 'class ' . l:module . ' (',
        \ '  Boolean $manage_package = true,',
        \ '  Boolean $manage_service = true,',
        \ '  String  $package_ensure = ''present'',',
        \ '  String  $service_ensure = ''running'',',
        \ '  Boolean $service_enable = true,',
        \ ') {',
        \ '',
        \ '  if $manage_package {',
        \ '    package { ''' . l:module . ''':',
        \ '      ensure => $package_ensure,',
        \ '    }',
        \ '  }',
        \ '',
        \ '  if $manage_service {',
        \ '    service { ''' . l:module . ''':',
        \ '      ensure => $service_ensure,',
        \ '      enable => $service_enable,',
        \ '    }',
        \ '  }',
        \ '',
        \ '}',
        \ ]

  " Replace entire buffer if it's empty (new file)
  if line('$') == 1 && empty(getline(1))
    call setline(1, l:lines[0])
    call append(1, l:lines[1:])
  else
    call append(line('.') - 1, l:lines)
  endif

  echo 'Inserted init.pp boilerplate for: ' . l:module
endfunction