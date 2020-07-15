"=============================================================================
" File: vim-pass
" Author: Tsuyoshi CHO
" Created: 2020-07-15
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! pass#set#save_entry(entry, contents) abort
  " use util CRUD Create/Update function
endfunction

function! pass#set#delete_entry(entry, contents) abort
  " use util CRUD Delete function
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
