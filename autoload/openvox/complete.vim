" autoload/openvox/complete.vim — Omni-completion for Puppet
scriptencoding utf-8
" Maintainer: xAI
" License:    Apache-2.0
"
" Provides context-aware completion for:
"   - Resource types (built-in and common modules)
"   - Resource attributes/parameters
"   - Metaparameters
"   - Built-in functions (Puppet 8)
"   - Data types (Puppet type system)
"   - Variables (from current buffer)
"   - Keywords

" ─── Completion data ──────────────────────────────────────────────

let s:resource_types = [
      \ 'augeas', 'cron', 'exec', 'file', 'filebucket', 'group',
      \ 'host', 'mount', 'notify', 'package', 'resources',
      \ 'schedule', 'service', 'ssh_authorized_key', 'sshkey',
      \ 'stage', 'tidy', 'user',
      \ 'anchor', 'concat', 'file_line', 'firewall', 'vcsrepo',
      \ 'apt', 'ini_setting', 'ini_subsetting',
      \ ]

let s:metaparameters = [
      \ 'alias', 'audit', 'before', 'loglevel', 'noop',
      \ 'notify', 'require', 'schedule', 'subscribe', 'tag',
      \ ]

let s:common_attributes = {
      \ 'exec': ['command', 'creates', 'cwd', 'environment', 'group', 'logoutput',
      \          'onlyif', 'path', 'provider', 'refresh', 'refreshonly', 'returns',
      \          'timeout', 'tries', 'try_sleep', 'unless', 'user'],
      \ 'file': ['backup', 'checksum', 'content', 'ensure', 'force', 'group',
      \          'ignore', 'links', 'mode', 'owner', 'path', 'purge', 'recurse',
      \          'recurselimit', 'replace', 'show_diff', 'source', 'sourceselect',
      \          'target', 'type', 'validate_cmd', 'validate_replacement'],
      \ 'package': ['adminfile', 'allow_virtual', 'allowcdrom', 'configfiles',
      \             'ensure', 'install_options', 'name', 'provider', 'responsefile',
      \             'source', 'uninstall_options'],
      \ 'service': ['binary', 'control', 'enable', 'ensure', 'hasrestart',
      \             'hasstatus', 'manifest', 'name', 'path', 'pattern', 'provider',
      \             'restart', 'start', 'status', 'stop'],
      \ 'user': ['allowdupe', 'comment', 'ensure', 'expiry', 'forcelocal', 'gid',
      \          'groups', 'home', 'managehome', 'membership', 'name', 'password',
      \          'password_max_age', 'password_min_age', 'provider', 'purge_ssh_keys',
      \          'shell', 'system', 'uid'],
      \ 'group': ['allowdupe', 'ensure', 'forcelocal', 'gid', 'members',
      \           'name', 'provider', 'system'],
      \ 'cron': ['command', 'ensure', 'environment', 'hour', 'minute', 'month',
      \          'monthday', 'name', 'provider', 'special', 'target', 'user',
      \          'weekday'],
      \ 'mount': ['atboot', 'blockdevice', 'device', 'dump', 'ensure', 'fstype',
      \           'name', 'options', 'pass', 'provider', 'remounts', 'target'],
      \ 'host': ['comment', 'ensure', 'host_aliases', 'ip', 'name', 'provider',
      \          'target'],
      \ 'notify': ['message', 'name', 'withpath'],
      \ }

let s:ensure_values = {
      \ 'file':    ['absent', 'directory', 'file', 'link', 'present'],
      \ 'package': ['absent', 'held', 'installed', 'latest', 'present', 'purged'],
      \ 'service': ['running', 'stopped'],
      \ 'user':    ['absent', 'present', 'role'],
      \ 'group':   ['absent', 'present'],
      \ '_default': ['absent', 'present'],
      \ }

let s:builtin_functions = [
      \ 'abs', 'alert', 'all', 'annotate', 'any', 'assert_type',
      \ 'binary_file', 'break', 'call',
      \ 'camelcase', 'capitalize', 'ceiling', 'chomp', 'chop', 'compare',
      \ 'contain', 'convert_to', 'create_resources', 'crit',
      \ 'debug', 'defined', 'dig', 'digest', 'downcase',
      \ 'each', 'emerg', 'empty', 'epp', 'err',
      \ 'fail', 'file', 'filter', 'find_file', 'find_template',
      \ 'flatten', 'floor', 'fqdn_rand',
      \ 'generate', 'get', 'getvar', 'group_by',
      \ 'hiera', 'hiera_array', 'hiera_hash', 'hiera_include',
      \ 'include', 'index', 'info', 'inline_epp', 'inline_template',
      \ 'join', 'keys',
      \ 'length', 'lest', 'lookup', 'lstrip',
      \ 'map', 'match', 'max', 'md5', 'min', 'module_directory',
      \ 'new', 'notice',
      \ 'partition', 'realize', 'reduce', 'regsubst', 'require',
      \ 'reverse_each', 'round', 'rstrip',
      \ 'scanf', 'sha1', 'sha256', 'shellquote', 'size', 'slice', 'sort',
      \ 'split', 'sprintf', 'step', 'strftime', 'strip',
      \ 'tag', 'tagged', 'template', 'then', 'tree_each', 'type',
      \ 'unique', 'unwrap', 'upcase',
      \ 'values', 'versioncmp', 'warning', 'with',
      \ 'ensure_packages', 'ensure_resource',
      \ 'pick', 'pick_default', 'deep_merge',
      \ 'to_json', 'to_json_pretty', 'to_yaml',
      \ ]

let s:data_types = [
      \ 'String', 'Integer', 'Float', 'Numeric', 'Boolean',
      \ 'Array', 'Hash', 'Regexp', 'Undef',
      \ 'Scalar', 'Data', 'Collection', 'Variant', 'Optional',
      \ 'Enum', 'Pattern', 'Struct', 'Tuple',
      \ 'Callable', 'Type', 'Any', 'Default',
      \ 'CatalogEntry', 'Resource', 'Class',
      \ 'NotUndef', 'Sensitive', 'Deferred', 'Binary',
      \ 'URI', 'SemVer', 'SemVerRange', 'Timestamp', 'Timespan',
      \ 'Init', 'Object', 'TypeSet', 'Error',
      \ 'Iterable', 'Iterator',
      \ ]

let s:keywords = [
      \ 'class', 'define', 'node', 'inherits',
      \ 'if', 'elsif', 'else', 'unless', 'case', 'default',
      \ 'and', 'or', 'not', 'in', 'true', 'false', 'undef',
      \ 'include', 'require', 'contain', 'realize',
      \ 'application', 'site', 'produces', 'consumes',
      \ 'type', 'attr', 'plan',
      \ ]

" ─── Omni-completion function ─────────────────────────────────────

function! openvox#complete#omnifunc(findstart, base) abort
  if a:findstart
    " Find the start of the word to complete
    let l:line = getline('.')
    let l:col = col('.') - 1

    " Walk backward to find word start
    while l:col > 0 && l:line[l:col - 1] =~# '[a-zA-Z0-9_:$]'
      let l:col -= 1
    endwhile

    return l:col
  endif

  " Determine context for smart completion
  let l:line = getline('.')
  let l:prev_lines = getline(max([1, line('.') - 20]), line('.'))
  let l:context = s:determine_context(l:line, l:prev_lines)

  let l:matches = []

  if a:base =~# '^\$'
    " Variable completion — find variables in current buffer
    let l:matches = s:complete_variables(a:base)
  elseif l:context ==# 'ensure_value'
    " Complete ensure values based on enclosing resource type
    let l:res_type = s:find_enclosing_resource()
    let l:vals = get(s:ensure_values, l:res_type, get(s:ensure_values, '_default', []))
    let l:matches = filter(copy(l:vals), 'v:val =~# "^" . a:base')
  elseif l:context ==# 'attribute'
    " Complete resource attributes
    let l:res_type = s:find_enclosing_resource()
    let l:attrs = get(s:common_attributes, l:res_type, []) + s:metaparameters
    let l:matches = filter(copy(l:attrs), 'v:val =~# "^" . a:base')
    let l:matches = map(l:matches, '{"word": v:val, "menu": "attr"}')
  elseif l:context ==# 'type'
    " Complete data types
    let l:matches = filter(copy(s:data_types), 'v:val =~# "^" . a:base')
    let l:matches = map(l:matches, '{"word": v:val, "menu": "type"}')
  else
    " General completion — combine all categories
    " Resource types
    for l:t in s:resource_types
      if l:t =~# '^' . a:base
        call add(l:matches, {'word': l:t, 'menu': '[resource]'})
      endif
    endfor
    " Functions
    for l:f in s:builtin_functions
      if l:f =~# '^' . a:base
        call add(l:matches, {'word': l:f, 'menu': '[function]'})
      endif
    endfor
    " Data types
    for l:d in s:data_types
      if l:d =~# '^' . a:base
        call add(l:matches, {'word': l:d, 'menu': '[type]'})
      endif
    endfor
    " Keywords
    for l:k in s:keywords
      if l:k =~# '^' . a:base
        call add(l:matches, {'word': l:k, 'menu': '[keyword]'})
      endif
    endfor
  endif

  return l:matches
endfunction

" ─── Context detection ────────────────────────────────────────────

function! s:determine_context(line, prev_lines) abort
  let l:trimmed = substitute(a:line, '^\s*', '', '')

  " After 'ensure =>' — complete with ensure values
  if l:trimmed =~# 'ensure\s*=>\s*\w*$'
    return 'ensure_value'
  endif

  " Inside a resource body (after { and before }) — complete attributes
  " Check if we're in an indented line that looks like an attribute
  if l:trimmed =~# '^\w\+\s*=>' || l:trimmed =~# '^\w*$'
    " Look upward for a resource declaration
    for l:pline in reverse(copy(a:prev_lines))
      if l:pline =~# '^\s*\(exec\|file\|package\|service\|user\|group\|cron\|mount\|host\|notify\)\s*{'
            \ || l:pline =~# '^\s*\w\+\s*{[^}]*$'
        return 'attribute'
      endif
      if l:pline =~# '^\s*}'
        break
      endif
    endfor
  endif

  " Capital letter start — likely a type
  if l:trimmed =~# '^[A-Z]'
    return 'type'
  endif

  return 'general'
endfunction

" ─── Find enclosing resource type ─────────────────────────────────

function! s:find_enclosing_resource() abort
  let l:lnum = line('.')
  while l:lnum > 0
    let l:line = getline(l:lnum)
    let l:match = matchlist(l:line, '^\s*\(\w\+\)\s*{')
    if !empty(l:match)
      return l:match[1]
    endif
    let l:lnum -= 1
  endwhile
  return ''
endfunction

" ─── Variable completion from buffer ──────────────────────────────

function! s:complete_variables(base) abort
  let l:vars = {}
  let l:pattern = '\$\w\+\(::\w\+\)*'

  for l:lnum in range(1, line('$'))
    let l:line = getline(l:lnum)
    let l:start = 0
    while 1
      let l:match = matchstr(l:line, l:pattern, l:start)
      if empty(l:match)
        break
      endif
      if l:match =~# '^' . escape(a:base, '$')
        let l:vars[l:match] = 1
      endif
      let l:start = matchend(l:line, l:pattern, l:start) + 1
    endwhile
  endfor

  return map(sort(keys(l:vars)), '{"word": v:val, "menu": "[var]"}')
endfunction