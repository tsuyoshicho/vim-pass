"=============================================================================
" File: vim-pass util
" Author: Tsuyoshi CHO
" Created: 2019-03-27
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:Process = vital#vimpass#import('System.Process')
let s:List    = vital#vimpass#import('Data.List')
let s:String  = vital#vimpass#import('Data.String')

function! pass#util#list() abort
  let keylist = globpath(expand(g:pass_store_path, ':p'), '**/*.gpg', 1, 1)
  " /dir/entry.gpg to dir/entry
  call map(keylist, { idx, val -> substitute(val, expand(g:pass_store_path, ':p'), '',    "") })
  call map(keylist, { idx, val -> substitute(val, '\',                             '/',   "") })
  call map(keylist, { idx, val -> substitute(val, '\v^/',                          '',    "") })
  call map(keylist, { idx, val -> substitute(val, '\c\v\.gpg$',                    '',    "") })

  return keylist
endfunction

function! pass#util#completion(A,L,P) abort
  return join(pass#util#list(),"\n")
endfunction

" value
function! pass#util#decode(gpgid, entrypath, passphrase, keywords) abort
  let entrylist = s:execute_gpg(a:gpgid, a:entrypath, a:passphrase)
  return s:select_entry(entrylist, a:keywords)
endfunction

" execute command
" list strings
function! s:execute_gpg(gpgid, entrypath, passphrase) abort
  " execute get entry
  let stdout = ['']
  let stderr = ['']
  let cmd = []

  " build gpg command
  call s:List.push(cmd, g:pass_gpg_path)
  call s:List.push(cmd, '--no-verbose')
  call s:List.push(cmd, '--quiet')
  call s:List.push(cmd, '--batch')
  call s:List.push(cmd, '--decrypt')
  if v:null != a:passphrase
    call s:List.push(cmd, '--pinentry-mode')
    call s:List.push(cmd, 'loopback')
    call s:List.push(cmd, '--passphrase')
    call s:List.push(cmd, a:passphrase)
  endif
  if v:null != a:gpgid
    call s:List.push(cmd, '--local-user')
    call s:List.push(cmd, a:gpgid)
  endif
  call s:List.push(cmd, '--output')
  call s:List.push(cmd, '-')
  call s:List.push(cmd, a:entrypath)

  " debug
  " echomsg "pass cmd req " . ",id:" . a:gpgid . ",path:" . a:entrypath . ",pass:" . a:passphrase
  " echomsg "pass cmd exec:" . join(cmd)

  let result = s:Process.execute(cmd)
  let entrylist = s:String.lines(result.output)

  return entrylist
endfunction

" select entry
function! s:select_entry(entrylist, keywords) abort
  let entrylist = a:entrylist
  let retvalue = ''

  if len(entrylist) == 0
    " no work
    return retvalue
  endif

  if len(a:keywords) == 0 || a:keywords[0] == 'password'
    " need default -> first line password
    let retvalue = entrylist[0]
  else
    " generate dict(key,value)
    let key = a:keywords[0]
    let entrymap = {}

    " ignore password(first line)
    for e in entrylist[1:]
      let split_data = s:String.split_leftright(e, '^[^:]*\zs:\s*')
      let entrymap[split_data[0]] = split_data[1]
    endfor

    if has_key(entrymap, key)
      let retvalue = entrymap[key]
    endif
  endif

  return retvalue
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
