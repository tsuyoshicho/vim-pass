let s:save_cpo = &cpo
set cpo&vim

" global variable option
let g:pass_ctrlp_copy_to_clipbord = get(g:, 'pass_ctrlp_copy_to_clipbord', 1)

command! -nargs=? -complete=custom,pass#util#completion CtrlPPass :call ctrlp#pass#exec(<f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
