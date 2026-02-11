" ftdetect/puppet.vim — Filetype detection for Puppet ecosystem
" Maintainer: xAI
" License:    Apache-2.0

" Puppet manifests
autocmd BufNewFile,BufRead *.pp setfiletype puppet

" EPP (Embedded Puppet) templates
autocmd BufNewFile,BufRead *.epp setfiletype epuppet

" Puppetfile (module dependency management)
autocmd BufNewFile,BufRead Puppetfile setfiletype ruby

" Hiera data files — detect YAML files under common Hiera paths
" These get the puppet_yaml compound filetype so we can layer yamllint
autocmd BufNewFile,BufRead */data/*.yaml,*/data/*.yml,*/hieradata/*.yaml,*/hieradata/*.yml,*/hiera/*.yaml,*/hiera/*.yml
      \ setfiletype yaml.puppet_hiera

" metadata.json for Puppet modules
autocmd BufNewFile,BufRead */metadata.json call s:DetectPuppetMetadata()

function! s:DetectPuppetMetadata() abort
  " Only set if the JSON looks like Puppet module metadata
  let l:lines = getline(1, min([20, line('$')]))
  let l:text = join(l:lines, ' ')
  if l:text =~# '"operatingsystem_support"\|"dependencies"\|"puppet"\|"pdk-version"\|"source".*forge\|"project_page".*github'
    setfiletype json.puppet_metadata
  endif
endfunction