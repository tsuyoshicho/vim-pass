"=============================================================================
" File: vim-pass
" Author: Tsuyoshi CHO
" Created: 2019-02-28
"=============================================================================

scriptencoding utf-8

if exists('g:autoloaded_pass')
    finish
endif
let g:autoloaded_pass = 1

let s:save_cpo = &cpo
set cpo&vim

" Vital
let s:Process = vital#vimpass#import('System.Process')
let s:Path    = vital#vimpass#import('System.Filepath')
let s:List    = vital#vimpass#import('Data.List')
let s:String  = vital#vimpass#import('Data.String')

" variable
let s:pass_startup_request = []
" alive only during at end of startup
" let s:__passphrase

" API get
" return value
function! pass#get(entry, ...) abort
  let passphrase  = s:_get_passphrase()
  return s:_get(a:entry, passphrase, a:000)
endfunction

" API get_register
" copy to register (timered clear)
" If remote : request passphrase
function! pass#get_register(entry, ...) abort
  let passphrase  = s:_get_passphrase()
  let value = s:_get(a:entry, passphrase, a:000)
  " set to register
  " register clear timer(at expire timer.if register remain value,then clear)
endfunction

" API get_startup
" use only while startup.at end of start up,invoke passphrase input once.
" all waited process execute
function! pass#get_startup(set_variable,entry, ...) abort
  if v:vim_did_enter == 0
    let Fn = function('s:_resolve_startup',[a:set_variable,a:entry,a:000])
    call s:List.push(s:pass_startup_request, Fn)
  else
    throw 'Already startup done.'
  endif
endfunction

" API resolve_startup(autocmd use)
function! pass#resolve_startup()
  if len(s:pass_startup_request) == 0
    return
  endif

  " resolved all promises
  " agent process success support 1st done -> all done -> unlet passphrase
  let s:__passphrase = s:_get_passphrase()
  for Fn in s:pass_startup_request
    call Fn()
  endfor
  unlet s:__passphrase

  let s:pass_startup_request = []
endfunction

" inner get process
function! s:_get(entry, passphrase,keywords) abort
  " get gpg-id
  let gpgid = s:_get_id()
  " get entry
  let entrypath = s:_get_entry_path(a:entry)

  " work correct?
  if !(executable(g:pass_gpg_path) && filereadable(entrypath))
    " no work
    return ''
  endif

  let entry_value = s:_execute_pass_decode(gpgid, entrypath, a:passphrase, a:keywords)

  return entry_value
endfunction

" v:null or ID
function! s:_get_id() abort
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

" path
function! s:_get_entry_path(entry) abort
  return s:Path.realpath(
                  \ s:Path.abspath(
                    \ expand(s:Path.remove_last_separator(g:pass_store_path) . s:Path.separator()
                               \ . a:entry . '.gpg')))
endfunction

" path
function! s:_execute_pass_decode(gpgid, entrypath, passphrase, keywords) abort
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

  if len(entrylist) == 0
    " no work
    return ''
  endif

  if len(a:keywords) == 0 || a:keywords[0] == 'password'
    " need default -> first line password
    return entrylist[0]
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
      return entrymap[key]
    else
      " no work
      return ''
    endif
  endif
endfunction

function! s:_resolve_startup(set_variable, entry, keywords) abort
  let passphrase  = get(s:,'__passphrase',v:null)
  let value = s:_get(a:entry, passphrase, a:keywords)

  call execute('let ' . a:set_variable . '=' . "'" . value . "'")
endfunction


function! s:_get_passphrase() abort
  let passphrase  = v:null
  if g:pass_use_agent == 0
    let passphrase = inputsecret('passphrase: ')
    redraw
    echo ''
  endif

  return passphrase
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
