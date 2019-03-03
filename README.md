[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)
<!-- [![Powered by vital-Whisky](https://img.shields.io/badge/powered%20by-vital--Whisky-80273f.svg)](https://github.com/lambdalisue/vital-Whisky) -->

# vim-pass
Vim password-store API.
see [Pass: The Standard Unix Password Manager](https://www.passwordstore.org/)

Currenlty *get* support. usable like `auth-source` at emacs.

## Require
- gpg
  - agent configuired as loopback enable
- password-store like saved data

## Installation
```vim
dein#add('tsuyoshicho/vim-pass')
```

## Usage
```vim
" in vimrc
" configured at end of vim startup
call pass#get_startup('g:test_gh_token','Develop/Github')
call pass#get_startup('g:test_gh_username','Develop/Github','username')

function! test() abort
  let password = pass#get('Service/foobar')
  " ...
endfunction
```

```toml
# in plugin setting(dein's toml)
[[plugins]]
repo = 'tsuyoshicho/vim-pass'

[[plugins]] # https://pixe.la/
repo = 'mattn/vim-pixela'
depends = ['open-browser.vim','vim-pass']
hook_add = '''
  " let g:pixela_username = 'user'
  " let g:pixela_token    = 'token'

  call pass#get_startup('g:pixela_username','Develop/Pixela','username')
  " VimPixela work OK
  call pass#get_startup('g:pixela_token','Develop/Pixela')
  " startup-time countup do not correct work.
  " It work or does not work depending on the processing order of events
'''

[[plugins]] # Slack
repo = 'mizukmb/slackstatus.vim'
depends = ['webapi-vim','vim-pass']
hook_add = '''
  " let g:slackstatus_token = '<YOUR_SLACK_TOKEN>'
  " my hoge
  call pass#get_startup('g:slackstatus_token','Message/Slack/myhoge.legacy')
  " vim-jp
  " call pass#get_startup('g:slackstatus_token','Message/Slack/vim-jp.legacy')
  "
  function! s:slack_list(A,L,P) abort
    let slacklist = ['myhoge','vim-jp']
    return slacklist
  endfunction

  function s:slackstatus_change_token(team) abort
    let path = 'Message/Slack/' . a:team . '.legacy'
    let g:slackstatus_token = pass#get(path)
  endfunction

  command! -nargs=1 -complete=customlist,<SID>slack_list SlackStatusChange :call <SID>slackstatus_change_token(<f-args>)
'''

```

## limitation
- Currently support API:get(default password/entry select) only
- Entry select require exact match
- When plugin's variable configure at load/starup time,sometimes it works not correctly like above Pixela startup-time countup
- *nix non-GUI environment,need `g:pass_use_agent` set as 0 manually.
