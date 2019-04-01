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

" Vital
let s:List    = vital#vimpass#import('Data.List')

" variable
let s:pass_startup_request = []

" API get
" return value
function! pass#get(entry, ...) abort
  return pass#get#entry_value(a:entry, a:000)
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

" API get_startup_scope
" use only while startup.at end of start up,invoke passphrase input once.
" all waited process execute
function! pass#get_startup_scope(scope,set_variable,entry, ...) abort
  if v:vim_did_enter == 0
    let Fn = function('s:resolver',[a:scope,a:set_variable,a:entry,a:000])
    call s:List.push(s:pass_startup_request, Fn)
  else
    throw 'Already startup done.'
  endif
endfunction

" API get_startup
" use only while startup.at end of start up,invoke passphrase input once.
" all waited process execute
function! pass#get_startup(set_variable,entry, ...) abort
  if v:vim_did_enter == 0
    let Fn = function('s:resolver',[v:null,a:set_variable,a:entry,a:000])
    call s:List.push(s:pass_startup_request, Fn)
  else
    throw 'Already startup done.'
  endif
endfunction

" API resolve_startup(autocmd use)
function! pass#resolve_startup()
  if len(s:pass_startup_request) == 0
    return
  endif

  " resolved all promises
  " agent process success support 1st done -> all done -> unlet passphrase
  for Fn in s:pass_startup_request
    call Fn()
  endfor

  let s:pass_startup_request = []
endfunction

function! s:resolver(scope,set_variable, entry, keywords) abort
  let value = pass#get#entry_value(a:entry, a:keywords)

  if v:null == a:scope
    call execute('let ' . a:set_variable . '=' . "'" . value . "'")
  else
    let a:scope[a:set_variable] = value
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
