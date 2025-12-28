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

  try
    let passphrase = pass#get#passphrase()
  catch
    " passphrase correct?
    " no work
    return ''
  endtry

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
  if exists('s:_get_passphrase')
    return s:_get_passphrase()
  endif

  " passphrase detect
  if g:pass_use_agent
    " work pinentry
    return ''
  endif

  " check loop
  let s:_passphrase = ''

  for i in range(g:pass_passphrase_verify_retry)
    let s:_passphrase = inputsecret('passphrase: ')
    " verify
    if pass#util#passphrase_verify(pass#get#id(), s:_passphrase)
      " success
      redraw!
      " setup passphrase closure
      function! s:_generate_get_passphrase_closure(passphrase)
        return {-> a:passphrase}
      endfunction

      let s:_get_passphrase = s:_generate_get_passphrase_closure(s:_passphrase)

      unlet s:_passphrase
      " exit
      break
    endif

    unlet s:_passphrase

    " failure
    redraw!
    if (i + 1) == g:pass_passphrase_verify_retry
      echo 'passphrase verify failed [' .
            \ string(i + 1) . '/' .
            \ string(g:pass_passphrase_verify_retry) . ']' .
            \ ' abort'
      " All failed, throw exception
      throw 'vim-pss: passphrase verify all failed'
    else
      echo 'passphrase verify failed [' .
            \ string(i + 1) . '/' .
            \ string(g:pass_passphrase_verify_retry) . ']' .
            \ ' retry'
      sleep 3
      redraw!
    endif
  endfor

  " Passed verification
  return s:_get_passphrase()
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
