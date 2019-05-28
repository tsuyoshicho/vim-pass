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
function! pass#util#decode(gpgid, entrypath, passphrase, keyword) abort
  let entrylist = s:decrypt_entry_gpg(a:gpgid, a:entrypath, a:passphrase)
  return s:select_entry_value(entrylist, a:keyword)
endfunction


" return cmd list
function! s:build_gpg_command(gpgid, entrypath, passphrase, appendcmds) abort
  " execute get entry
  let cmd = []

  " build gpg command
  call s:List.push(cmd, g:pass_gpg_path)

  call s:List.push(cmd, '--no-verbose')
  call s:List.push(cmd, '--quiet')
  call s:List.push(cmd, '--batch')
  if !empty(a:appendcmd)
    let cmd = s:List.concat(cmd, a:appendcmds)
  endif
  if !empty(a:passphrase)
    call s:List.push(cmd, '--pinentry-mode')
    call s:List.push(cmd, 'loopback')
    call s:List.push(cmd, '--passphrase')
    call s:List.push(cmd, a:passphrase)
  endif
  if !empty(a:gpgid)
    call s:List.push(cmd, '--local-user')
    call s:List.push(cmd, a:gpgid)
  endif
  call s:List.push(cmd, '--output')
  call s:List.push(cmd, '-')
  call s:List.push(cmd, a:entrypath)

  let result = s:Process.execute(cmd)
  let entrylist = s:String.lines(result.output)

  return entrylist
endfunction

" execute command
" CRUD : READ
" return list strings
function! s:decrypt_entry_gpg(gpgid, entrypath, passphrase) abort
  " execute get entry
  let cmd = s:build_gpg_command(a:gpgid, a:entrypath, a:passphrase, ['--decrypt'])

  let result = s:Process.execute(cmd)
  let entrylist = s:String.lines(result.output)

  return entrylist
endfunction

" execute command
" CRUD : (check)
" return bool (1 success)
function! s:check_entry_gpg_passphrase(gpgid, entrypath, passphrase) abort
  " execute get entry
  let cmd = s:build_gpg_command(a:gpgid, a:entrypath, a:passphrase, ['--dry-run']) " with decrypt (default)

  let result = s:Process.execute(cmd)
  return result.success
endfunction

" select entry value
" input entry string list / return value string
function! s:select_entry_value(entrylist, keyword) abort
  let entrylist = a:entrylist

  if empty(entrylist)
    " no work
    return ''
  endif

  let keyword = a:keyword
  let keyname = ''
  let keylist = [keyword]

  " password entry required.
  let entry_altmap  = extend(get(g:, 'pass_entry_altmap', {}),{
        \ 'password' : ['password', 'secret'],
        \}, "keep")

  for [k,v] in items(entry_altmap)
    if -1 != match(v, '\c\<' . escape(keyword,'\') . '\>')
      let keyname = k
      let keylist = v
      break
    endif
  endfor

  let retvalue = ''
  if (keyword == '') || (keyname == 'password')
    " need default -> first line password
    let retvalue = entrylist[0]
  elseif keyword == 'otp'
    " special value otpauth://
    for e in entrylist[1:]
      if 0 == match(e, '\c\V' . escape('otpauth://','\'))
        let retvalue = e
        break
      endif
    endfor
  else
    " generate dict(key, value)
    let entrymap = {}

    " ignore password(first line)
    for e in entrylist[1:]
      let split_data = s:String.split_leftright(e, '^[^:]*\zs:\s*')
      let entrymap[tolower(split_data[0])] = split_data[1]
    endfor

    " search value
    for k in keylist
      let retvalue = get(entrymap, tolower(k), '')
      if !empty(retvalue)
        break
      endif
    endfor
  endif

  return retvalue
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
