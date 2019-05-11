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

" Provide information get operation
" pass#get#id            get gpg-id
" pass#get#passphrase    get passphrase (passphrase management ...)
" pass#get#entry_value   get entry value
" pass#get#entry_path    get entry real file path util....
"
" new API define
" passphrase retry-able checker's result use
" pass#get#entry_async?   return Process Promise ?
"  return promise
"   has method resolve() call process
"   then chainable

" get entry data
function! pass#get#entry_value(entry, keywords) abort
  " get gpg-id
  let gpgid = pass#get#id()
  " get entry
  let entrypath = pass#get#entry_path(a:entry)

  " work correct?
  if !(executable(g:pass_gpg_path) && filereadable(entrypath))
    " no work
    return ''
  endif

  let passphrase = pass#get#passphrase()
  let entry_value = pass#util#decode(gpgid, entrypath, passphrase, a:keywords)

  return entry_value
endfunction

" '' or ID
function! pass#get#id() abort
  " check exist
  if 0 == exists('s:_pass_gpg_id')
    let s:_pass_gpg_id = ''

    let gpgidpath = s:Path.realpath(
                      \ s:Path.abspath(
                        \ expand(s:Path.remove_last_separator(g:pass_store_path) . s:Path.separator()
                                  \ . '.gpg-id')))

    if !(filereadable(gpgidpath))
      " no work
      return s:_pass_gpg_id
    endif

    let read_result = readfile(gpgidpath)

    if 0 < len(read_result)
      let s:_pass_gpg_id = read_result[0]
    endif
  endif

  return s:_pass_gpg_id
endfunction

" '' or passphrase
function! pass#get#passphrase() abort
  if 0 == exists('s:_passphrase')
    let s:_passphrase = ''
    if g:pass_use_agent == 0
      let s:_passphrase = inputsecret('passphrase: ')
      redraw
      echo ''
    endif
  endif

  return s:_passphrase
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
