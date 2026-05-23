# Testing vim-openvox

This directory is for regression tests (currently manual).

## Indent Tests
Place `.pp` files here with comments showing expected indentation.

Example test file structure:
```puppet
" Test: basic resource
file { '/tmp/test':
  ensure => file,           " expected indent: 2 spaces
  owner  => root,
}
```

Run manual verification with `vim -u NONE -S tests/indent.vim somefile.pp` or just open files and use `==`.

## Future
- Add Vader.vim or native Vim script tests
- Headless indent verification
