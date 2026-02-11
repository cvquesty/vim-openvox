" syntax/epuppet.vim — EPP (Embedded Puppet) template syntax
" Maintainer: xAI
" License:    Apache-2.0
"
" EPP templates contain a host language (HTML, YAML, etc.) with embedded
" Puppet expressions inside <% %> tags, similar to ERB.

if exists('b:current_syntax')
  finish
endif

" Determine the host syntax from the original filename
" e.g., foo.conf.epp → conf, foo.html.epp → html
let s:host_syntax = ''
let s:basename = expand('%:t:r')  " Strip .epp extension
let s:host_ext = fnamemodify(s:basename, ':e')

if !empty(s:host_ext)
  let s:host_map = {
        \ 'html':  'html',
        \ 'htm':   'html',
        \ 'xml':   'xml',
        \ 'yaml':  'yaml',
        \ 'yml':   'yaml',
        \ 'json':  'json',
        \ 'sh':    'sh',
        \ 'bash':  'sh',
        \ 'conf':  'conf',
        \ 'cfg':   'conf',
        \ 'ini':   'dosini',
        \ 'toml':  'toml',
        \ 'rb':    'ruby',
        \ 'py':    'python',
        \ }
  let s:host_syntax = get(s:host_map, s:host_ext, s:host_ext)
endif

" Load the host syntax if detected and available
if !empty(s:host_syntax)
  try
    execute 'runtime! syntax/' . s:host_syntax . '.vim'
    unlet! b:current_syntax
  catch
  endtry
endif

" Load Puppet syntax for the embedded regions
syn include @puppetSyntax syntax/puppet.vim
unlet! b:current_syntax

" ─── EPP tags ─────────────────────────────────────────────────────
" Expression tag: <%= expr %>
syn region  eppExpression matchgroup=eppTag
      \ start='<%=' end='%>'
      \ contains=@puppetSyntax

" Code tag: <% code %>
syn region  eppCode matchgroup=eppTag
      \ start='<%[^=%]' end='%>'
      \ contains=@puppetSyntax

syn region  eppCode matchgroup=eppTag
      \ start='<%-' end='-%>'
      \ contains=@puppetSyntax

syn region  eppCode matchgroup=eppTag
      \ start='<%-' end='%>'
      \ contains=@puppetSyntax

syn region  eppCode matchgroup=eppTag
      \ start='<%[^=%]' end='-%>'
      \ contains=@puppetSyntax

" Comment tag: <%# comment %>
syn region  eppComment matchgroup=eppTag
      \ start='<%#' end='%>'
      \ contains=puppetTodo

" Parameter tag: <%| params |%>
syn region  eppParams matchgroup=eppTag
      \ start='<%|' end='|%>'
      \ contains=puppetVariable,puppetType,puppetDelimiter

" Literal <%%
syn match   eppLiteral  '<%%'

" ─── Highlight links ─────────────────────────────────────────────
hi def link eppTag       PreProc
hi def link eppComment   Comment
hi def link eppLiteral   Special
hi def link eppParams    Special

let b:current_syntax = 'epuppet'