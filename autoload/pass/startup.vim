"=============================================================================
" File: vim-pass startup subroutine
" Author: Tsuyoshi CHO
" Created: 2019-04-01
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" Vital
let s:List    = vital#vimpass#import('Data.List')

" variable
let s:pass_startup_request = []

function! pass#startup#entry_setup(scope, set_variable, entry, keywords) abort
  let Fn = function('s:resolver',[a:scope,a:set_variable,a:entry,a:keywords])
  call s:List.push(s:pass_startup_request, Fn)
endfunction

function! pass#startup#entry_setup_funcall(func, entry, keywords) abort
  let Fn = function('s:funcresolver',[a:func,a:entry,a:keywords])
  call s:List.push(s:pass_startup_request, Fn)
endfunction

" API resolve_startup(autocmd use)
function! pass#startup#resolve() abort
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

function! s:funcresolver(func, entry, keywords) abort
  let value = pass#get#entry_value(a:entry, a:keywords)

  call(a:func,[value])
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
