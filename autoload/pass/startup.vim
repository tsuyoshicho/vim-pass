"=============================================================================
" File: vim-pass startup subroutine
" Author: Tsuyoshi CHO
" Created: 2019-04-01
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" Vital
let s:List = vital#vimpass#import('Data.List')

" variable
let s:pass_startup_request = []
let s:resolved_count = 0

" event
augroup vim-pass-startup
  autocmd!
  autocmd User VimPassStartUpResolve :
augroup END

function! pass#startup#entry_setup_letval(scope, set_variable, entry, keyword) abort
  let Fn = function('s:letval_resolver',[a:scope,a:set_variable,a:entry,a:keyword])
  call s:List.push(s:pass_startup_request, Fn)
endfunction

function! pass#startup#entry_setup_funcall(func, entry, keyword) abort
  let Fn = function('s:funcall_resolver',[a:func,a:entry,a:keyword])
  call s:List.push(s:pass_startup_request, Fn)
endfunction

" API resolve_startup(autocmd use)
function! pass#startup#resolve() abort
  if len(s:pass_startup_request) == s:resolved_count
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
  call timer_start(0, { -> s:async_resolver() })
endfunction

function! s:async_resolver() abort
  for idx in range(s:resolved_count, len(s:pass_startup_request) - 1)
    call s:pass_startup_request[idx]()
  endfor
  let s:resolved_count = len(s:pass_startup_request)

  " invoke event
  doautocmd User VimPassStartUpResolve
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

let &cpo = s:save_cpo
unlet s:save_cpo
