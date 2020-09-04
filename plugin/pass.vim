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

if ($SSH_CONNECTION != '' || ((has('win32') || has('win64')) == 0 && $DISPLAY == ''))
  let g:pass_use_agent = 0 " remote/non-gui force set : input only
endif
let g:pass_use_agent = get(g:, 'pass_use_agent', 1)

" case-insensitive
" password entry required. add default (in code process)
let g:pass_entry_altmap  = extend(get(g:, 'pass_entry_altmap', {}),{
      \ 'username' : ['user', 'username', 'id', 'account'],
      \ 'host'     : ['host', 'url',      'uri'          ],
      \}, "keep")

let g:pass_passphrase_verify_retry = get(g:, 'pass_passphrase_verify_retry', 3)

" API Pass_get_startup_funcall
" use only while startup.at end of start up,invoke passphrase input once.
" all waited process execute
function! Pass_get_startup_funcall(func,entry, ...) abort
  let keyword = (a:0 > 0) ? a:1 : ''
  if v:vim_did_enter == 0
    call s:pass_startup_entry_setup_funcall(a:func, a:entry, keyword)
  else
    throw 'Already startup done.'
  endif
endfunction

" API Pass_get_startup_scope
" use only while startup.at end of start up,invoke passphrase input once.
" all waited process execute
function! Pass_get_startup_scope(scope,set_variable,entry, ...) abort
  let keyword =  (a:0 > 0) ? a:1 : ''
  if v:vim_did_enter == 0
    call s:pass_startup_entry_setup_letval(a:scope, a:set_variable, a:entry, keyword)
  else
    throw 'Already startup done.'
  endif
endfunction

" API Pass_get_startup
" use only while startup.at end of start up,invoke passphrase input once.
" all waited process execute
function! Pass_get_startup(set_variable,entry, ...) abort
  let keyword =  (a:0 > 0) ? a:1 : ''
  if v:vim_did_enter == 0
    call s:pass_startup_entry_setup_letval(v:null, a:set_variable, a:entry, keyword)
  else
    throw 'Already startup done.'
  endif
endfunction

" request queue
let s:pass_startup_request = []

function! s:pass_startup_entry_setup_letval(scope, set_variable, entry, keyword) abort
  let Fn = function('s:letval_resolver',[a:scope,a:set_variable,a:entry,a:keyword])
  let s:pass_startup_request = add(s:pass_startup_request, Fn)
endfunction

function! s:pass_startup_entry_setup_funcall(func, entry, keyword) abort
  let Fn = function('s:funcall_resolver',[a:func,a:entry,a:keyword])
  let s:pass_startup_request = add(s:pass_startup_request, Fn)
endfunction

function! s:pass_startup_resolve() abort
  echomsg 'plugin type pass startup:' s:pass_startup_request

  if len(s:pass_startup_request) == 0
    return
  endif

  try
    let passphrase = pass#get#passphrase()
  catch
    " passphrase correct?
    " no work
    return
  endtry

  " resolved all promises
  for Fn in s:pass_startup_request
    call Fn()
  endfor

  let s:pass_startup_request = []
endfunction

function! s:letval_resolver(scope,set_variable, entry, keyword) abort
  let value = pass#get#entry_value(a:entry, a:keyword)

  if v:null == a:scope
    call execute('let ' . a:set_variable . '=' . "'" . value . "'")
  else
    let a:scope[a:set_variable] = value
  endif
endfunction

function! s:funcall_resolver(func, entry, keyword) abort
  let value = pass#get#entry_value(a:entry, a:keyword)

  call call(a:func,[value])
endfunction

command! -nargs=+ -complete=custom,pass#util#completion PassGet    :echo pass#get(<f-args>)
command! -nargs=1 -complete=custom,pass#util#completion PassGetOtp :echo pass#get_otp(<f-args>)
command! -nargs=+ -complete=custom,pass#util#completion PassGetRegister    :call pass#get_register(<f-args>)
command! -nargs=1 -complete=custom,pass#util#completion PassGetOtpRegister :call pass#get_otp_register(<f-args>)

augroup pass-startup
  autocmd!
  autocmd VimEnter * call s:pass_resolve_startup()
  " deprecated API
  autocmd VimEnter * call pass#resolve_startup()
  autocmd VimEnter * autocmd! pass-startup
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
