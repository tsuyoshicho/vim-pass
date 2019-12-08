"=============================================================================
" File: vim-pass clap plugin
" Author: Tsuyoshi CHO
" Created: 2019-12-08
"=============================================================================

scriptencoding utf-8

if exists('g:loaded_clap_pass') && g:loaded_clap_pass
  finish
endif
let g:loaded_clap_pass = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:source() abort
  return pass#util#list()
endfunction

function! s:sink(entry) abort
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
  " only work gP
  call execute('normal! "' . regname . 'gP' , "silent")
  call setreg(regname, '', 'c') " secret is characterwise only
endfunction

let s:pass = {}
let s:pass.sink = function('s:sink')
let s:pass.source = function('s:source')

let g:clap#provider#pass# = s:pass

let &cpo = s:save_cpo
unlet s:save_cpo
