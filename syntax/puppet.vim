" syntax/puppet.vim — Puppet 8 syntax highlighting
scriptencoding utf-8
" Maintainer: xAI
" License:    Apache-2.0
" Based on the Puppet 8 language specification and style guide

if exists('b:current_syntax')
  finish
endif

" ─── Case sensitivity ─────────────────────────────────────────────
syn case match

" ─── Comments ─────────────────────────────────────────────────────
" Style guide: use # comments, not /* */ or //
syn match   puppetComment       '#.*$' contains=puppetTodo,@Spell
syn keyword puppetTodo          contained TODO FIXME XXX NOTE HACK BUG WARN

" C-style comments (valid but discouraged by style guide)
syn region  puppetCComment      start='/\*' end='\*/' contains=puppetTodo,@Spell
syn match   puppetCComment      '//.*$' contains=puppetTodo,@Spell

" ─── Strings ──────────────────────────────────────────────────────
" Single-quoted strings (no interpolation, style guide prefers these)
syn region  puppetSQString      start=+'+  skip=+\\['\\]+  end=+'+
      \ contains=puppetSQEscape
syn match   puppetSQEscape      contained +\\[\\']+ 

" Double-quoted strings (with interpolation)
syn region  puppetDQString      start=+"+  skip=+\\["\\]+  end=+"+
      \ contains=puppetDQEscape,puppetInterpolation,@Spell
syn match   puppetDQEscape      contained +\\[nrtsa$"\\]+ 
syn match   puppetDQEscape      contained +\\u[0-9a-fA-F]\{4}+
syn match   puppetDQEscape      contained +\\x[0-9a-fA-F]\{1,2}+

" Heredoc strings (Puppet 4+ style)
syn region  puppetHeredoc       start=+@(\s*"\?\w\+"\?\s*/*[tnrsL$]*)+
      \ end=+^\s*|\?\s*\w\+\s*$+
      \ contains=puppetDQEscape,puppetInterpolation

syn region  puppetHeredocNI     start=+@(\s*'\w\+'\s*/*[tnrsL$]*)+
      \ end=+^\s*|\?\s*\w\+\s*$+

" String interpolation: $variable and ${expression}
syn region  puppetInterpolation contained start=+\${+ end=+}+
      \ contains=puppetVariable,puppetDelimiter,puppetDQString,puppetSQString,
      \          puppetInteger,puppetFloat,puppetBoolean
syn match   puppetInterpolation contained '\$[a-zA-Z_]\w*\(\(::\)\?[a-zA-Z_]\w*\)*'

" ─── Numbers ──────────────────────────────────────────────────────
syn match   puppetInteger       '\<\d\+\>'
syn match   puppetInteger       '\<0[xX][0-9a-fA-F]\+\>'
syn match   puppetInteger       '\<0[oO]\?[0-7]\+\>'
syn match   puppetInteger       '\<0[bB][01]\+\>'
syn match   puppetFloat         '\<\d\+\.\d\+\([eE][+-]\?\d\+\)\?\>'

" ─── Booleans & Undef ─────────────────────────────────────────────
syn keyword puppetBoolean       true false
syn keyword puppetUndef         undef

" ─── Variables ────────────────────────────────────────────────────
" Style guide: use $snake_case, $module::variable
syn match   puppetVariable      '\$[a-zA-Z_]\w*' nextgroup=puppetVarScope
syn match   puppetVariable      '\$\(::\)\?[a-zA-Z_]\w*\(::[a-zA-Z_]\w*\)*'
syn match   puppetVariable      '\$\w\+\(\[\d\+\]\|\[[''"]\w\+['"]\]\)*'

" ─── Resource types (built-in core) ───────────────────────────────
" Types with no attribute/metaparam name conflicts — safe as keywords
syn keyword puppetResourceType
      \ exec filebucket package
      \ resources service stage tidy

" Types that also serve as attribute/metaparam names (file, group,
" notify, schedule, user) — only highlight in declaration position
" (before {) so they don't override attribute coloring inside bodies
syn match   puppetResourceType '\<\(file\|group\|notify\|schedule\|user\)\>\ze\s*{'

" Resource types from core modules (commonly used)
syn keyword puppetResourceType
      \ augeas cron host mount ssh_authorized_key
      \ sshkey k5login mailalias maillist nagios_command
      \ nagios_contact nagios_contactgroup nagios_host
      \ nagios_hostdependency nagios_hostescalation
      \ nagios_hostextinfo nagios_hostgroup
      \ nagios_service nagios_servicedependency
      \ nagios_serviceescalation nagios_serviceextinfo
      \ nagios_servicegroup nagios_timeperiod
      \ selboolean selmodule yumrepo zfs zone zpool

" Common module resource types
syn keyword puppetResourceType
      \ anchor concat concat_file concat_fragment
      \ firewall firewallchain
      \ apt apt_key
      \ vcsrepo
      \ ini_setting ini_subsetting
      \ file_line

" ─── Metaparameters ───────────────────────────────────────────────
" Style guide: these go at the end of resource declarations
syn keyword puppetMetaparam
      \ alias audit before loglevel noop subscribe

" Metaparams that conflict with resource type names — match only
" in attribute position (before =>) so they don't steal declaration color
syn match   puppetMetaparam '\<\(notify\|schedule\)\>\ze\s*=>'

" NOTE: 'require' and 'tag' also serve as metaparams but are already
" in puppetFunction (keywords beat matches), so they get Function color.
" This is acceptable — both are more commonly used as functions.

" ─── Resource attributes (common) ─────────────────────────────────
" Style guide: 'ensure' should be the first attribute
" Attribute names — the left-hand side of =>
syn keyword puppetAttribute
      \ ensure
      \ command creates cwd environment group logoutput
      \ onlyif provider refreshonly returns timeout
      \ tries try_sleep unless path refresh
      \ content source target owner mode recurse
      \ purge force backup checksum
      \ gid groups home managehome membership password
      \ password_max_age password_min_age shell system uid user
      \ allowdupe comment expiry
      \ enable hasrestart hasstatus manifest pattern start
      \ status stop binary control
      \ name title

" Ensure values and resource states — the right-hand side of =>
syn keyword puppetEnsureValue
      \ present absent purged latest installed
      \ running stopped enabled disabled
      \ directory link

" ─── Language keywords ────────────────────────────────────────────
syn keyword puppetKeyword       class define node inherits
syn keyword puppetKeyword       application site produces consumes
syn keyword puppetKeyword       type attr plan

" ─── Control flow ─────────────────────────────────────────────────
syn keyword puppetConditional   if elsif else unless case default
syn keyword puppetConditional   selector

" ─── Operators ────────────────────────────────────────────────────
" Comparison
syn match   puppetOperator      '==\|!=\|=\~\|!\~'
syn match   puppetOperator      '>=\?\|<=\?'
" Boolean
syn keyword puppetOperator      and or not
syn match   puppetOperator      '!'
" Arithmetic
syn match   puppetOperator      '[+\-\*/%]'
syn match   puppetOperator      '<<\|>>'
" String
syn match   puppetOperator      '+>'
" Regular assignment
syn match   puppetOperator      '='
" Arrow operators (resource relationships)
syn match   puppetArrow         '->'
syn match   puppetArrow         '\~>'
" Chaining (left-to-right only per style guide)
syn match   puppetArrow         '<-'
syn match   puppetArrow         '<\~'
" Hash rocket
syn match   puppetHashRocket    '=>'
" Splat
syn match   puppetOperator      '\*'
" In operator
syn keyword puppetOperator      in

" ─── Brackets and delimiters ──────────────────────────────────────
syn match   puppetDelimiter     '[{}()\[\]]'
syn match   puppetDelimiter     ':'
syn match   puppetDelimiter     ','
syn match   puppetDelimiter     ';'

" ─── Data types (Puppet type system) ──────────────────────────────
syn keyword puppetType
      \ String Integer Float Numeric Boolean
      \ Array Hash Regexp Undef
      \ Scalar Data Collection Variant Optional
      \ Enum Pattern Struct Tuple
      \ Callable Type Any Default
      \ CatalogEntry Resource Class
      \ NotUndef Sensitive Deferred Binary
      \ URI SemVer SemVerRange Timestamp Timespan
      \ Init Object TypeSet Error
      \ Iterable Iterator

" ─── Built-in functions (Puppet 8 core) ───────────────────────────
syn keyword puppetFunction
      \ abs alert all annotate any assert_type
      \ binary_file break call
      \ camelcase capitalize ceiling chomp chop compare
      \ contain convert_to create_resources crit
      \ debug defined dig digest downcase
      \ each emerg empty epp err
      \ eyaml_lookup_key
      \ fail filter find_file find_template
      \ flatten floor fqdn_rand
      \ generate get getvar group_by
      \ hiera hiera_array hiera_hash hiera_include
      \ hocon_data
      \ import include index info inline_epp inline_template
      \ join json_data keys
      \ length lest lookup lstrip
      \ map match max md5 min module_directory
      \ new notice
      \ partition realize reduce regsubst require
      \ reverse_each round rstrip
      \ scanf sha1 sha256 shellquote size slice sort
      \ split sprintf step strftime strip
      \ tag tagged template then tree_each type
      \ unique unwrap upcase
      \ values versioncmp warning with yaml_data

" ─── Stdlib functions (commonly used) ─────────────────────────────
syn keyword puppetFunction
      \ ensure_packages ensure_resource
      \ is_array is_bool is_float is_hash is_integer is_numeric is_string
      \ validate_absolute_path validate_array validate_bool
      \ validate_hash validate_integer validate_numeric
      \ validate_re validate_string validate_slength
      \ str2bool bool2str num2bool bool2num
      \ any2array any2bool count delete delete_at
      \ difference has_key intersection
      \ is_domain_name is_function_available is_ip_address is_mac_address
      \ loadyaml parseyaml parsejson
      \ prefix suffix range member
      \ pick pick_default deep_merge
      \ to_bytes to_json to_json_pretty to_yaml
      \ try_get_value

" ─── Class/define declarations ────────────────────────────────────
syn match   puppetDefine        '\<\(class\|define\|node\)\s\+\S\+' contains=puppetKeyword

" ─── Resource references ──────────────────────────────────────────
" Capitalized type reference: File['/path'], Service['name']
syn match   puppetResourceRef   '\u[a-zA-Z_]*\(\(::\)\u[a-zA-Z_]*\)*\s*\[' contains=puppetResourceRefBracket
syn match   puppetResourceRefBracket contained '\['

" ─── Resource collectors ──────────────────────────────────────────
syn region  puppetCollector     start='<|' end='|>' contains=puppetOperator,puppetString,puppetVariable
syn region  puppetExportCollector start='<<|' end='|>>' contains=puppetOperator,puppetString,puppetVariable

" ─── Virtual and exported resources ───────────────────────────────
syn match   puppetVirtual       '@@\?\ze\s*\l' nextgroup=puppetResourceType

" ─── Regular expressions ──────────────────────────────────────────
syn region  puppetRegex         start=+/[^/\*]+ skip=+\\/+ end=+/+
      \ contains=puppetRegexSpecial
syn match   puppetRegexSpecial  contained '\\[/.dDwWsSbB\[\](){}|^$*+?]'

" ─── Node definitions ────────────────────────────────────────────
syn match   puppetNodeName      contained '[a-zA-Z0-9._-]\+'
syn match   puppetNodeDef       '\<node\s\+' nextgroup=puppetNodeName,puppetSQString,puppetDQString,puppetRegex

" ─── Lambda syntax ────────────────────────────────────────────────
syn match   puppetLambdaPipe    '|[^|]*|' contained contains=puppetVariable,puppetType

" ─── EPP tags (in .pp files for inline_epp) ───────────────────────
syn region  puppetEppTag        start='<%' end='%>' contains=puppetVariable,puppetFunction

" ─── Resource default declarations ────────────────────────────────
" e.g., File { owner => 'root' }
syn match   puppetResDefault    '\u\w*\s*{'

" ─── Relationship arrows in chains ────────────────────────────────
" Class['foo'] -> Class['bar'] ~> Class['baz']
" Highlighted via puppetArrow above

" ─── Include-like statements ──────────────────────────────────────
syn match   puppetInclude       '\<\(include\|require\|contain\|realize\)\s\+'
      \ nextgroup=puppetSQString,puppetDQString,puppetVariable

" ─── Highlight links ─────────────────────────────────────────────
hi def link puppetComment         Comment
hi def link puppetTodo            Todo
hi def link puppetCComment        Comment
hi def link puppetSQString        String
hi def link puppetDQString        String
hi def link puppetHeredoc         String
hi def link puppetHeredocNI       String
hi def link puppetSQEscape        SpecialChar
hi def link puppetDQEscape        SpecialChar
hi def link puppetInterpolation   Identifier
hi def link puppetInteger         Number
hi def link puppetFloat           Float
hi def link puppetBoolean         Boolean
hi def link puppetUndef           Constant
hi def link puppetVariable        Identifier
hi def link puppetResourceType    Type
hi def link puppetMetaparam       Special
hi def link puppetAttribute       Keyword
hi def link puppetEnsureValue    Constant
hi def link puppetKeyword         Keyword
hi def link puppetConditional     Conditional
hi def link puppetOperator        Operator
hi def link puppetArrow           Operator
hi def link puppetHashRocket      Operator
hi def link puppetDelimiter       Delimiter
hi def link puppetType            Type
hi def link puppetFunction        Function
hi def link puppetDefine          Define
hi def link puppetResourceRef     Type
hi def link puppetCollector       Special
hi def link puppetExportCollector Special
hi def link puppetVirtual         Special
hi def link puppetRegex           String
hi def link puppetRegexSpecial    SpecialChar
hi def link puppetNodeName        String
hi def link puppetNodeDef         Keyword
hi def link puppetLambdaPipe      Delimiter
hi def link puppetEppTag          PreProc
hi def link puppetResDefault      Type
hi def link puppetInclude         Statement

let b:current_syntax = 'puppet'