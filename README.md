[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)
<!-- [![Powered by vital-Whisky](https://img.shields.io/badge/powered%20by-vital--Whisky-80273f.svg)](https://github.com/lambdalisue/vital-Whisky) -->

# vim-pass
Vim password-store API
see [Pass: The Standard Unix Password Manager](https://www.passwordstore.org/)

## require
- gpg
  - agent configuired as loopback enable
- password-store like saved data

## installation
```vim
dein#add('tsuyoshicho/vim-pass')
```

## usage
```vim
" in vimrc
call pass#get_startup('g:test_gh_token','Develop/Github')
call pass#get_startup('g:test_gh_username','Develop/Github','username')
```

" in plugin setting
```toml
[[plugins]]
repo = 'tsuyoshicho/vim-pass'

[[plugins]] # https://pixe.la/
repo = 'mattn/vim-pixela'
depends = ['open-browser.vim','vim-pass']
hook_add = '''
  " let g:pixela_username = 'user'
  " let g:pixela_token    = 'token'

  call pass#get_startup('g:pixela_username','Develop/Pixela','username')
  call pass#get_startup('g:pixela_token','Develop/Pixela')
'''
```

## limitation
- currently support only get(default password/entry select)
- entry select require exact match
