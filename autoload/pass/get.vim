"=============================================================================
" File: vim-pass get subroutine
" Author: Tsuyoshi CHO
" Created: 2019-04-01
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" Vital
let s:Path = vital#vimpass#import('System.Filepath')

" get entry data
function! pass#get#entry_value(entry, keyword) abort
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

  " passphrase correct?
  if empty(passphrase)
    " no work
    return ''
  endif

  let entry_value = pass#util#decode(gpgid, entrypath, passphrase, a:keyword)

  return entry_value
endfunction

" '' or ID
function! pass#get#id() abort
  " check exist
  if exists('s:_pass_gpg_id')
    return s:_pass_gpg_id
  endif

  " id detect
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

  return s:_pass_gpg_id
endfunction

" '' or passphrase
function! pass#get#passphrase() abort
  if exists('s:_passphrase')
    return s:_passphrase
  endif

  " passphrase detect
  let s:_passphrase = ''
  if g:pass_use_agent
    " work pinentry
    return s:_passphrase
  endif

  " check loop
  for i in range(g:pass_passphrase_verify_retry)
    let s:_passphrase = inputsecret('passphrase: ')
    " verify
    if pass#util#passphrase_verify(pass#get#id(), s:_passphrase)
      " success
      redraw
      echo ''
      " exit
      break
    else
      " failure
      echo 'passphrase verify failed, (re)try: '
            \ . '[' . string(i + 1) . '/'. string(g:pass_passphrase_verify_retry) . ']'
      if i < (g:pass_passphrase_verify_retry - 1)
        echo 'passphrase verify all failed'
        unlet s:_passphrase
      endif

      sleep 3
      redraw
      echo ''
    endif
  endfor

  return get(s:, '_passphrase', '')
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
