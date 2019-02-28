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
let s:Path = vital#vimpass#import('System.Filepath')
let s:List = vital#vimpass#import('Data.List')
let s:String = vital#vimpass#import('Data.String')

" API get
function! pass#get(entry, ...) abort
  " get gpg-id
  let gpgid = s:get_id()
  " get entry
  let fullpath = s:Path.realpath(
                    \ s:Path.abspath(
                      \ expand(s:Path.remove_last_separator(g:pass_store_path) . s:Path.separator()
                                 \ . a:entry . '.gpg')))

  " work correct?
  if !(executable(g:pass_gpg_path) && filereadable(fullpath))
    " no work
    return ''
  endif

  let stdout = ['']
  let stderr = ['']
  let cmd = []

  " build gpg command
  call s:List.push(cmd, g:pass_gpg_path)
  call s:List.push(cmd, '--no-verbose')
  call s:List.push(cmd, '--quiet')
  call s:List.push(cmd, '--batch')
  call s:List.push(cmd, '--decrypt')
  if v:null != gpgid
    call s:List.push(cmd, '--local-user')
    call s:List.push(cmd, gpgid)
  endif
  call s:List.push(cmd, '--output')
  call s:List.push(cmd, '-')
  call s:List.push(cmd, fullpath)

  let result = s:Process.execute(cmd)
  let entrylist = s:String.lines(result.output)

  if len(entrylist) == 0
    " no work
    return ''
  endif

  if a:0 == 0 || a:1 == 'password'
    " need default -> first line password
    return entrylist[0]
  else
    " generate dict(key,value)
    let key = a:1
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

" v:null or ID
function! s:get_id() abort
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

let &cpo = s:save_cpo
unlet s:save_cpo
