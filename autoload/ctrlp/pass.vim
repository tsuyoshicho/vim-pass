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

let g:ctrlp_ext_vars = add(get(g:, 'ctrlp_ext_vars', []), {
      \ 'init'  : 'ctrlp#pass#init()',
      \ 'accept': 'ctrlp#pass#accept',
      \ 'lname' : 'pass',
      \ 'sname' : 'pass',
      \ 'type'  : 'path',
      \ 'nolim' : 1
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
  call s:exec(a:str)
endfunction

function! ctrlp#pass#exec(...) abort
  if 0 == a:0
    call ctrlp#init(ctrlp#pass#id())
  else
    let entry = a:1
    if index(pass#util#list(), entry) >= 0
      call s:exec(entry)
    else
      call ctrlp#init(ctrlp#pass#id())
    endif
  endif
endfunction

function! s:exec(entry) abort
  " insert secret to current pos
  let secret = pass#get(a:entry)

  " let @* = secret
  " currently not work direct paste : alt force copy to clipbord
  if g:pass_ctrlp_copy_to_clipbord
    let @* = secret
  else
    let @" = secret
    " command style)(need option?)
    "      cursor pos(g or non) | paste pos           | style
    " p    pasted text before   | current pos after   |  ab|c -> abc|xyz
    " P    pasted text before   | current pos before  |  ab|c -> ab|xyzc
    " gp   pasted text after    | current pos after   |  ab|c -> abcxyz|
    " gP   pasted text after    | current pos before  |  ab|c -> abxyz|c
    call execute('normal! ""gp' , "silent")
    let @" = ''
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
