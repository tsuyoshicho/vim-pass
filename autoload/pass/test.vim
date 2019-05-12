"=============================================================================
" File: vim-pass util
" Author: Tsuyoshi CHO
" Created: 2019-03-27
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" Vital
let s:Path    = vital#vimpass#import('System.Filepath')
let s:Process = vital#vimpass#import('System.Process')
let s:List    = vital#vimpass#import('Data.List')
let s:String  = vital#vimpass#import('Data.String')
let s:AsyncProcess = vital#vimpass#import('Async.Promise.Process')
let s:List    = vital#vimpass#import('Data.List')

" variable
let s:pass_startup_request = []

" test code

function! pass#test#list() abort
  let keylist = globpath(expand(g:pass_store_path, ':p'), '**/*.gpg', 1, 1)
  " /dir/entry.gpg to dir/entry
  call map(keylist, { idx, val -> substitute(val, expand(g:pass_store_path, ':p'), '',    "") })
  call map(keylist, { idx, val -> substitute(val, '\',                             '/',   "") })
  call map(keylist, { idx, val -> substitute(val, '\v^/',                          '',    "") })
  call map(keylist, { idx, val -> substitute(val, '\c\v\.gpg$',                    '',    "") })

  return keylist
endfunction

function! pass#test#completion(A,L,P) abort
  return join(pass#test#list(),"\n")
endfunction

" value
function! pass#test#decode(gpgid, entrypath, passphrase, keywords) abort
  let entrylist = s:decrypt_entry_gpg(a:gpgid, a:entrypath, a:passphrase)
  return s:select_entry_value(entrylist, a:keywords)
endfunction

" execute command
" CRUD : READ
" return list strings
function! s:decrypt_entry_gpg(gpgid, entrypath, passphrase) abort
  " execute get entry
  let cmd = []

  " build gpg command
  call s:List.push(cmd, g:pass_gpg_path)

  call s:List.push(cmd, '--no-verbose')
  call s:List.push(cmd, '--quiet')
  call s:List.push(cmd, '--batch')
  call s:List.push(cmd, '--decrypt')
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

  let g:Testfunc = { ->
       \ s:AsyncProcess.start(cmd)
       \.then({v -> s:select_entry_value(v.stdout, [])})
       \.then({v -> execute('echomsg v', '')})
       \}
  call s:AsyncProcess.start(cmd)
       \.then({v -> s:select_entry_value(v.stdout, [])})
       \.then({v -> execute('let g:test = v', '')})

  return entrylist
endfunction

" select entry value
" input entry string list / return value string
function! s:select_entry_value(entrylist, keywords) abort
  let entrylist = a:entrylist

  if empty(entrylist)
    " no work
    return ''
  endif

  if empty(a:keywords)
    " need default -> first line password
    return entrylist[0]
  endif

  let key = a:keywords[0]
  let keyname = ''
  let keylist = [key]

  " password entry required.
  let entry_altmap  = extend(get(g:, 'pass_entry_altmap', {}),{
        \ 'password' : ['password', 'secret'],
        \}, "keep")

  for [k,v] in items(entry_altmap)
    if -1 != match(v, '\c\V' . escape(key,'\'))
      let keyname = k
      let keylist = v
      break
    endif
  endfor

  let retvalue = ''
  if keyname == 'password'
    " need default -> first line password
    let retvalue = entrylist[0]
  elseif key == 'otp'
    " special value otpauth://
    for e in entrylist[1:]
      if 0 == match(e, '\c\V' . escape('otpauth://','\'))
        let retvalue = e
        break
      endif
    endfor
  else
    " generate dict(key,value)
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

" get entry data
function! pass#test#entry_value(entry, keywords) abort
  " get gpg-id
  let gpgid = pass#test#id()
  " get entry
  let entrypath = pass#test#entry_path(a:entry)

  " work correct?
  if !(executable(g:pass_gpg_path) && filereadable(entrypath))
    " no work
    return ''
  endif

  let passphrase = pass#test#passphrase()
  let entry_value = pass#test#decode(gpgid, entrypath, passphrase, a:keywords)

  return entry_value
endfunction

" '' or ID
function! pass#test#id() abort
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
function! pass#test#passphrase() abort
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
function! pass#test#entry_path(entry) abort
  return s:Path.realpath(
                  \ s:Path.abspath(
                    \ expand(s:Path.remove_last_separator(g:pass_store_path) . s:Path.separator()
                               \ . a:entry . '.gpg')))
endfunction

function! pass#test#entry_setup_letval(scope, set_variable, entry, keywords) abort
  let Fn = function('s:letval_resolver',[a:scope,a:set_variable,a:entry,a:keywords])
  call s:List.push(s:pass_startup_request, Fn)
endfunction

function! pass#test#entry_setup_funcall(func, entry, keywords) abort
  let Fn = function('s:funcall_resolver',[a:func,a:entry,a:keywords])
  call s:List.push(s:pass_startup_request, Fn)
endfunction

" API resolve_startup(autocmd use)
function! pass#test#resolve() abort
  if len(s:pass_startup_request) == 0
    return
  endif

  " resolved all promises
  " agent process success support 1st done -> all done -> unlet passphrase
  for Fn in s:pass_startup_request
    call Fn()
  endfor

  let s:pass_startup_request = []
endfunction

function! s:letval_resolver(scope,set_variable, entry, keywords) abort
  let value = pass#test#entry_value(a:entry, a:keywords)

  if v:null == a:scope
    call execute('let ' . a:set_variable . '=' . "'" . value . "'")
  else
    let a:scope[a:set_variable] = value
  endif
endfunction

function! s:funcall_resolver(func, entry, keywords) abort
  let value = pass#test#entry_value(a:entry, a:keywords)

  call call(a:func,[value])
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
