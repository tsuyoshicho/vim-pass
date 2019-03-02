"=============================================================================
" File: vim-pass
" Author: Tsuyoshi CHO
" Created: 2019-02-28
"=============================================================================

scriptencoding utf-8

if exists('g:loaded_pass')
    finish
endif
let g:loaded_pass = 1

let s:save_cpo = &cpo
set cpo&vim

" global variable option
let g:pass_store_path = get(g:, 'pass_store_path', '~/.password-store')
let g:pass_gpg_path   = get(g:, 'pass_gpg_path', 'gpg')

let s:local = 1
if $SSH_CONNECTION != ''
  let s:local = 0
  let g:pass_use_agent = 0 " remote force set : input only
endif
let g:pass_use_agent  = get(g:, 'pass_use_agent', s:local)


command! -nargs=+ PassGet         :echo pass#get(<f-args>)
command! -nargs=+ PassGetRegister :call pass#get_register(<f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
