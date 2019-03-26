let s:save_cpo = &cpo
set cpo&vim

command! CtrlPPass call ctrlp#init(ctrlp#pass#id())

let &cpo = s:save_cpo
unlet s:save_cpo
