"=============================================================================
" File: vim-pass util
" Author: Tsuyoshi CHO
" Created: 2019-03-27
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:Job      = vital#vimpass#import('System.Job')
let s:List     = vital#vimpass#import('Data.List')
let s:String   = vital#vimpass#import('Data.String')
let s:Filepath = vital#vimpass#import('System.Filepath')

function! pass#util#list() abort
  if exists('+shellslash')
    let ss = &shellslash
    set noshellslash
  endif
  if exists('+completeslash')
    let cs = &completeslash
    set completeslash=
  endif
  let root = glob(s:Filepath.abspath(expand(g:pass_store_path)))
  let keylist = globpath(root, '**/*.gpg', 1, 1)
  if exists('ss')
    let &shellslash = ss
  endif
  if exists('cs')
    let &completeslash = cs
  endif
  unlet ss
  unlet cs

  " /dir/entry.gpg to dir/entry
  call map(keylist, { idx, val -> substitute(val, escape(root,'\'), '',  "" ) })
  call map(keylist, { idx, val -> substitute(val, '\\',             '/', "g") })
  call map(keylist, { idx, val -> substitute(val, '\v^/',           '',  "" ) })
  call map(keylist, { idx, val -> substitute(val, '\c\v\.gpg$',     '',  "" ) })

  return keylist
endfunction

function! pass#util#completion(A,L,P) abort
  return join(pass#util#list(),"\n")
endfunction

" value
function! pass#util#decode(gpgid, entrypath, passphrase, keyword) abort
  let entrycontent = s:decrypt_entry_gpg(a:gpgid, a:entrypath, a:passphrase)
  return s:select_entry_value(entrycontent, a:keyword)
endfunction

" passphrase
function! pass#util#passphrase_verify(gpgid, passphrase) abort
  let entrylist = pass#util#list()
  if empty(entrylist)
    return 0
  else
    return s:check_entry_gpg_passphrase(a:gpgid, pass#get#entry_path(entrylist[0]), a:passphrase)
  endif
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
  if !empty(a:appendcmds)
    let cmd = s:List.concat([cmd, a:appendcmds])
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

  return cmd
endfunction

function! s:on_stdout(data) abort dict
  let self.stdout[-1] .= a:data[0]
  call extend(self.stdout, a:data[1:])
endfunction

function! s:on_stderr(data) abort dict
  let self.stderr[-1] .= a:data[0]
  call extend(self.stderr, a:data[1:])
endfunction

function! s:on_exit(exitval) abort dict
  let self.exit_status = a:exitval
endfunction

" execute command
" CRUD : READ
" return list strings
function! s:decrypt_entry_gpg(gpgid, entrypath, passphrase) abort
  " execute get entry
  let cmd = s:build_gpg_command(a:gpgid, a:entrypath, a:passphrase, ['--decrypt'])

  let job = s:Job.start(cmd, {
        \ 'stdout': [''],
        \ 'stderr': [''],
        \ 'exit_status': -1,
        \ 'on_stdout': function('on_stdout'),
        \ 'on_stderr': function('on_stderr'),
        \ 'on_exit': function('on_exit'),
        \})
  call job.wait()
  return job.stdout
endfunction

" execute command
" CRUD : (check)
" return bool (1 success)
function! s:check_entry_gpg_passphrase(gpgid, entrypath, passphrase) abort
  " execute get entry
  let cmd = s:build_gpg_command(a:gpgid, a:entrypath, a:passphrase, ['--dry-run']) " with decrypt (default)

  let job = s:Job.start(cmd, {
        \ 'stdout': [''],
        \ 'stderr': [''],
        \ 'exit_status': -1,
        \ 'on_stdout': function('on_stdout'),
        \ 'on_stderr': function('on_stderr'),
        \ 'on_exit': function('on_exit'),
        \})
  call job.wait()
  return job.exit_status
endfunction

" select entry value
" input entry string list / return value string
function! s:select_entry_value(entrycontent, keyword) abort
  let entrycontent = a:entrycontent

  if empty(entrycontent)
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
    let retvalue = entrycontent[0]
  elseif keyword == 'otp'
    " special value otpauth://
    for e in entrycontent[1:]
      if 0 == match(e, '\c\V' . escape('otpauth://','\'))
        let retvalue = e
        break
      endif
    endfor
  else
    " generate dict(key, value)
    let entrymap = {}

    " ignore password(first line)
    for e in entrycontent[1:]
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
