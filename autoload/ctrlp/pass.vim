"=============================================================================
" File: vim-pass ctrlp plugin
" Author: Tsuyoshi CHO
" Created: 2019-03-25
"=============================================================================

scriptencoding utf-8

if exists('g:loaded_ctrlp_pass') && g:loaded_ctrlp_pass
  finish
endif
let g:loaded_ctrlp_pass = 1
let s:save_cpo = &cpo
set cpo&vim

call add(g:ctrlp_ext_vars, {
      \ 'init': 'ctrlp#pass#init()',
      \ 'accept': 'ctrlp#pass#accept',
      \ 'lname': 'pass',
      \ 'sname': 'pass',
      \ 'type': 'path',
      \ 'nolim': 1
      \})

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)

function! ctrlp#pass#id() abort
  return s:id
endfunction

function! ctrlp#pass#init() abort
  return pass#util#list()
endfunction

function! ctrlp#pass#accept(mode, str) abort
  call ctrlp#exit()
  " insert secret to current pos
  let secret = pass#get(a:str)

  let @* = secret
  " currently not work direct paste : alt force copy to clipbord
  " if g:pass_ctrlp_to_clipbord
  "   let @* = secret
  " else
  "   let @" = secret
  "   call execute('p' , "silent")
  "   let @" = ''
  " endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
