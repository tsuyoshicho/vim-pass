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

let s:ctrlp_builtins = ctrlp#getvar('g:ctrlp_builtins')

let g:ctrlp_ext_vars = get(g:, 'ctrlp_ext_vars', []) + [
      \  {
      \    'init'  : 'ctrlp#pass#init()',
      \    'accept': 'ctrlp#pass#accept',
      \    'lname' : 'pass',
      \    'sname' : 'pass',
      \    'type'  : 'path',
      \    'nolim' : 1
      \  }
      \]

let s:id = s:ctrlp_builtins + len(g:ctrlp_ext_vars)
unlet s:ctrlp_builtins

function! ctrlp#pass#id() abort
  return s:id
endfunction

function! ctrlp#pass#init() abort
  return pass#util#list()
endfunction

function! ctrlp#pass#accept(mode, str) abort
  call ctrlp#exit()
  call s:exec(a:mode, a:str)
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

function! s:exec(mode, entry) abort
  " insert secret to current pos
  let secret = pass#get(a:entry)

  let regname = '"'
  " currently not work direct paste : alt force copy to clipbord
  if g:pass_ctrlp_copy_to_clipbord
    let regname = '*'
  endif

  call setreg(regname, secret, 'c') " secret is characterwise only

  " command style(need option?)
  "      cursor pos(g or non) | paste pos(p or P)   | style
  " p    pasted text before   | current pos after   |  ab|c -> abc|xyz
  " P    pasted text before   | current pos before  |  ab|c -> ab|xyzc
  " gp   pasted text after    | current pos after   |  ab|c -> abcxyz|
  " gP   pasted text after    | current pos before  |  ab|c -> abxyz|c

  " 'mode' is 'h' / <C-x>  : only copy to register
  " 'mode' is 'e' / <CR>   : put before cursor, 'P'
  " 'mode' is 'v' / <C-v>  : put after  cursor, 'p'
  " 'mode' is 't' / <C-t>  : put OTP?
  if a:mode ==? 'h'
    " no care , no clear register
  elseif a:mode ==? 'e'
    call execute('normal! "' . regname . 'gP' , "silent")
    call setreg(regname, '', 'c') " secret is characterwise only
  elseif a:mode ==? 'v'
    call execute('normal! "' . regname . 'gp' , "silent")
    call setreg(regname, '', 'c') " secret is characterwise only
  else
    " all other unsupport mode
    " clear register
    call setreg(regname, '', 'c') " secret is characterwise only
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
