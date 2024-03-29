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
let g:pass_gpg_path   = get(g:, 'pass_gpg_path',   'gpg')

" CLI using check(or)
" ssh connect (safty)
" non-windows/non-mac do not have DISPLAY
if (exists('$SSH_CONNECTION') || (!(has('win32') || has('mac')) && !exists('$DISPLAY')))
  " remote/non-gui set to 0 by default
  let g:pass_use_agent = get(g:, 'pass_use_agent', 0)
endif
let g:pass_use_agent = get(g:, 'pass_use_agent', 1)

" case-insensitive
" password entry required. add default (in code process)
let g:pass_entry_altmap  = extend(get(g:, 'pass_entry_altmap', {}),{
      \ 'username' : ['user', 'username', 'id', 'account'],
      \ 'host'     : ['host', 'url',      'uri'          ],
      \}, "keep")

let g:pass_passphrase_verify_retry = get(g:, 'pass_passphrase_verify_retry', 3)

command! -nargs=+ -complete=custom,pass#util#completion PassGet    :echo pass#get(<f-args>)
command! -nargs=1 -complete=custom,pass#util#completion PassGetOtp :echo pass#get_otp(<f-args>)
command! -nargs=+ -complete=custom,pass#util#completion PassGetRegister    :call pass#get_register(<f-args>)
command! -nargs=1 -complete=custom,pass#util#completion PassGetOtpRegister :call pass#get_otp_register(<f-args>)

augroup pass-startup
  autocmd!
  autocmd VimEnter * call pass#startup#resolve() | autocmd! pass-startup
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
