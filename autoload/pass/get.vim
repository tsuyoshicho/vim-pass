"=============================================================================
" File: vim-pass get subroutine
" Author: Tsuyoshi CHO
" Created: 2019-04-01
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" Vital
let s:Path    = vital#vimpass#import('System.Filepath')

" v:null or ID
function! pass#get#id() abort
  " check exist
  if v:null == get(s:,'pass_gpg_id', v:null)

    let gpgidpath = s:Path.realpath(
                      \ s:Path.abspath(
                        \ expand(s:Path.remove_last_separator(g:pass_store_path) . s:Path.separator()
                                  \ . '.gpg-id')))

    if !(filereadable(gpgidpath))
      " no work
      return v:null
    endif

    let read_result = readfile(gpgidpath)

    if 0 < len(read_result)
      let s:pass_gpg_id = read_result[0]
    endif
  endif

  return get(s:,'pass_gpg_id', v:null)
endfunction

" '' or passphrase
function! pass#get#passphrase() abort
  let passphrase  = v:null
  if g:pass_use_agent == 0
    let passphrase = inputsecret('passphrase: ')
    redraw
    echo ''
  endif

  return passphrase
endfunction

" path
function! pass#get#entry_path(entry) abort
  return s:Path.realpath(
                  \ s:Path.abspath(
                    \ expand(s:Path.remove_last_separator(g:pass_store_path) . s:Path.separator()
                               \ . a:entry . '.gpg')))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
