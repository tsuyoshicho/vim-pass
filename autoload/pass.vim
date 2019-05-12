"=============================================================================
" File: vim-pass
" Author: Tsuyoshi CHO
" Created: 2019-02-28
"=============================================================================

scriptencoding utf-8

if exists('g:autoloaded_pass')
    finish
endif
let g:autoloaded_pass = 1

let s:save_cpo = &cpo
set cpo&vim

" API get
" return value
function! pass#get(entry, ...) abort
  return pass#get#entry_value(a:entry, a:000)
endfunction

function! pass#get_test(entry, ...) abort
  return pass#test#entry_value(a:entry, a:000)
endfunction

" API get_otp
" return value
function! pass#get_otp(entry) abort
  let uri = pass#get#entry_value(a:entry, ['otp'])
  if empty(uri)
    echo 'no entry otpauth://'
    return ''
  else
    return pass#otp#value(uri)
  endif
endfunction

" API get_register
" copy to register (timered clear)
" If remote : request passphrase
function! pass#get_register(entry, ...) abort
  " set to register
  " register clear timer(at expire timer.if register remain value,then clear)
  " currently support unnamed register.
  let @" = pass#get#entry_value(a:entry, a:000)
endfunction

" API get_otp_register
" copy to register otp (timered clear)
" If remote : request passphrase
function! pass#get_otp_register(entry) abort
  " set to register
  " register clear timer(at expire timer.if register remain value,then clear)
  " currently support unnamed register.
  let uri = pass#get#entry_value(a:entry, ['otp'])
  if empty(uri)
    echo 'no entry otpauth://'
  else
    let @" = pass#otp#value(uri)
  endif
endfunction

" API get_startup_funcall
" use only while startup.at end of start up,invoke passphrase input once.
" all waited process execute
function! pass#get_startup_funcall(func,entry, ...) abort
  if v:vim_did_enter == 0
    call pass#startup#entry_setup_funcall(a:func,a:entry,a:000)
  else
    throw 'Already startup done.'
  endif
endfunction

" API get_startup_scope
" use only while startup.at end of start up,invoke passphrase input once.
" all waited process execute
function! pass#get_startup_scope(scope,set_variable,entry, ...) abort
  if v:vim_did_enter == 0
    call pass#startup#entry_setup_letval(a:scope,a:set_variable,a:entry,a:000)
  else
    throw 'Already startup done.'
  endif
endfunction

" API get_startup
" use only while startup.at end of start up,invoke passphrase input once.
" all waited process execute
function! pass#get_startup(set_variable,entry, ...) abort
  if v:vim_did_enter == 0
    call pass#startup#entry_setup_letval(v:null,a:set_variable,a:entry,a:000)
  else
    throw 'Already startup done.'
  endif
endfunction

" API resolve_startup(autocmd use)
function! pass#resolve_startup()
  call pass#startup#resolve()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
