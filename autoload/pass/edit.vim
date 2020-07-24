"=============================================================================
" File: vim-pass
" Author: Tsuyoshi CHO
" Created: 2020-07-15
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! pass#edit#new(args) abort
  " need prompt
  let entry = len(a:args) == 0 ? '' : a:args[0]
  " get gpg-id
  let gpgid = pass#get#id()
  " get entry
  let entrypath = pass#get#entry_path(entry)

  " read
  " create secure scratch
  new
  " setup (need same setting in editing at read item)
  setlocal filetype=pass-gpg
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal noswapfile

  " buffer local var save
  let b:entry = entry

  " buffer save hook/autocmd
  nnoremap w call pass#set#save_entry(b:entry,getline(0,?))
  " edit mapping
  " i item insert(suggest keys (username))
  " p password edit
  " o otp secret edit
  " format
  "   <password>
  "   <otp> (if exists)
  "   <item1>:...
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
