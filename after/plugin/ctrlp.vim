if !exists('g:loaded_ctrlp') || g:loaded_ctrlp == 0
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! CtrlPPass call ctrlp#init(ctrlp#pass#id())

let &cpo = s:save_cpo
unlet s:save_cpo
