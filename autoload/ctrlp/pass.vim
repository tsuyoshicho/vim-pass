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

let s:pass_var = {
      \ 'init': 'ctrlp#pass#init()',
      \ 'accept': 'ctrlp#pass#accept',
      \ 'lname': 'pass',
      \ 'sname': 'pass',
      \ 'type': 'path',
      \ 'nolim': 1
      \}

if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:pass_var)
else
  let g:ctrlp_ext_vars = [s:pass_var]
endif

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)

function! ctrlp#pass#id() abort
  return s:id
endfunction

function! ctrlp#pass#init() abort
  let keylist = globpath(expand(g:pass_store_path, ':p'), '**/*.gpg', 1, 1)
  " /dir/entry.gpg to dir/entry
  call map(keylist, { idx, val -> substitute(val, expand(g:pass_store_path, ':p'), '',    "") })
  call map(keylist, { idx, val -> substitute(val, '\',                             '/',   "") })
  call map(keylist, { idx, val -> substitute(val, '^/',                            '',    "") })
  call map(keylist, { idx, val -> substitute(val, '\c.gpg$',                         '',    "") })

  return keylist
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
