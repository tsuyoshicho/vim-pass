" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not modify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_vimpass#Prelude#import() abort', printf("return map({'escape_pattern': '', 'is_funcref': '', 'path2directory': '', 'wcswidth': '', 'is_string': '', 'input_helper': '', 'is_number': '', 'is_cygwin': '', 'path2project_directory': '', 'strwidthpart_reverse': '', 'input_safe': '', 'is_list': '', 'truncate_skipping': '', 'glob': '', 'truncate': '', 'is_dict': '', 'set_default': '', 'is_numeric': '', 'getchar_safe': '', 'substitute_path_separator': '', 'is_infinity': '', 'is_mac': '', 'strwidthpart': '', 'getchar': '', 'is_unix': '', 'is_windows': '', 'globpath': '', 'is_float': '', 'smart_execute_command': ''}, \"vital#_vimpass#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
let s:save_cpo = &cpo
set cpo&vim

function! s:glob(expr) abort
  return glob(a:expr, 1, 1)
endfunction

function! s:globpath(path, expr) abort
  return globpath(a:path, a:expr, 1, 1)
endfunction

" Wrapper functions for type().
let [
\   s:__TYPE_NUMBER,
\   s:__TYPE_STRING,
\   s:__TYPE_FUNCREF,
\   s:__TYPE_LIST,
\   s:__TYPE_DICT,
\   s:__TYPE_FLOAT] = [
      \   v:t_number,
      \   v:t_string,
      \   v:t_func,
      \   v:t_list,
      \   v:t_dict,
      \   v:t_float]

" Number or Float
function! s:is_numeric(Value) abort
  let _ = type(a:Value)
  return _ ==# s:__TYPE_NUMBER
  \   || _ ==# s:__TYPE_FLOAT
endfunction

" Number
function! s:is_number(Value) abort
  return type(a:Value) ==# s:__TYPE_NUMBER
endfunction

" String
function! s:is_string(Value) abort
  return type(a:Value) ==# s:__TYPE_STRING
endfunction

" Funcref
function! s:is_funcref(Value) abort
  return type(a:Value) ==# s:__TYPE_FUNCREF
endfunction

" List
function! s:is_list(Value) abort
  return type(a:Value) ==# s:__TYPE_LIST
endfunction

" Dictionary
function! s:is_dict(Value) abort
  return type(a:Value) ==# s:__TYPE_DICT
endfunction

" Float
function! s:is_float(Value) abort
  return type(a:Value) ==# s:__TYPE_FLOAT
endfunction

" Infinity
if exists('*isinf')
  function! s:is_infinity(Value) abort
    return isinf(a:Value)
  endfunction
else
  function! s:is_infinity(Value) abort
    if type(a:Value) ==# s:__TYPE_FLOAT
      let s = string(a:Value)
      if s ==# 'inf'
        return 1
      elseif s ==# '-inf'
        return -1
      endif
    endif
    return 0
  endfunction
endif


function! s:truncate_skipping(str, max, footer_width, separator) abort
  call s:_warn_deprecated('truncate_skipping', 'Data.String.truncate_skipping')

  let width = s:wcswidth(a:str)
  if width <= a:max
    let ret = a:str
  else
    let header_width = a:max - s:wcswidth(a:separator) - a:footer_width
    let ret = s:strwidthpart(a:str, header_width) . a:separator
          \ . s:strwidthpart_reverse(a:str, a:footer_width)
  endif

  return s:truncate(ret, a:max)
endfunction

function! s:truncate(str, width) abort
  " Original function is from mattn.
  " http://github.com/mattn/googlereader-vim/tree/master

  call s:_warn_deprecated('truncate', 'Data.String.truncate')

  if a:str =~# '^[\x00-\x7f]*$'
    return len(a:str) < a:width ?
          \ printf('%-'.a:width.'s', a:str) : strpart(a:str, 0, a:width)
  endif

  let ret = a:str
  let width = s:wcswidth(a:str)
  if width > a:width
    let ret = s:strwidthpart(ret, a:width)
    let width = s:wcswidth(ret)
  endif

  if width < a:width
    let ret .= repeat(' ', a:width - width)
  endif

  return ret
endfunction

function! s:strwidthpart(str, width) abort
  call s:_warn_deprecated('strwidthpart', 'Data.String.strwidthpart')

  if a:width <= 0
    return ''
  endif
  let ret = a:str
  let width = s:wcswidth(a:str)
  while width > a:width
    let char = matchstr(ret, '.$')
    let ret = ret[: -1 - len(char)]
    let width -= s:wcswidth(char)
  endwhile

  return ret
endfunction
function! s:strwidthpart_reverse(str, width) abort
  call s:_warn_deprecated('strwidthpart_reverse', 'Data.String.strwidthpart_reverse')

  if a:width <= 0
    return ''
  endif
  let ret = a:str
  let width = s:wcswidth(a:str)
  while width > a:width
    let char = matchstr(ret, '^.')
    let ret = ret[len(char) :]
    let width -= s:wcswidth(char)
  endwhile

  return ret
endfunction

function! s:wcswidth(str) abort
  call s:_warn_deprecated('wcswidth', 'Data.String.wcswidth')
  return strwidth(a:str)
endfunction

let s:is_windows = has('win32') " This means any versions of windows https://github.com/vim-jp/vital.vim/wiki/Coding-Rule#how-to-check-if-the-runtime-os-is-windows
let s:is_cygwin = has('win32unix')
let s:is_mac = !s:is_windows && !s:is_cygwin
      \ && (has('mac') || has('macunix') || has('gui_macvim') ||
      \   (!isdirectory('/proc') && executable('sw_vers')))
let s:is_unix = has('unix')

function! s:is_windows() abort
  return s:is_windows
endfunction

function! s:is_cygwin() abort
  return s:is_cygwin
endfunction

function! s:is_mac() abort
  return s:is_mac
endfunction

function! s:is_unix() abort
  return s:is_unix
endfunction

function! s:_warn_deprecated(name, alternative) abort
  try
    echohl Error
    echomsg 'Prelude.' . a:name . ' is deprecated!  Please use ' . a:alternative . ' instead.'
  finally
    echohl None
  endtry
endfunction

function! s:smart_execute_command(action, word) abort
  execute a:action . ' ' . (a:word ==# '' ? '' : '`=a:word`')
endfunction

function! s:_escape_file_searching(buffer_name) abort
  return escape(a:buffer_name, '*[]?{}, ')
endfunction

function! s:escape_pattern(str) abort
  call s:_warn_deprecated(
        \ 'escape_pattern',
        \ 'Data.String.escape_pattern',
        \)
  return escape(a:str, '~"\.^$[]*')
endfunction

function! s:getchar(...) abort
  let c = call('getchar', a:000)
  return type(c) == type(0) ? nr2char(c) : c
endfunction

function! s:getchar_safe(...) abort
  let c = s:input_helper('getchar', a:000)
  return type(c) == type('') ? c : nr2char(c)
endfunction

function! s:input_safe(...) abort
  return s:input_helper('input', a:000)
endfunction

function! s:input_helper(funcname, args) abort
  let success = 0
  if inputsave() !=# success
    throw 'vital: Prelude: inputsave() failed'
  endif
  try
    return call(a:funcname, a:args)
  finally
    if inputrestore() !=# success
      throw 'vital: Prelude: inputrestore() failed'
    endif
  endtry
endfunction

function! s:set_default(var, val) abort
  if !exists(a:var) || type({a:var}) != type(a:val)
    let {a:var} = a:val
  endif
endfunction

function! s:substitute_path_separator(path) abort
  return s:is_windows ? substitute(a:path, '\\', '/', 'g') : a:path
endfunction

function! s:path2directory(path) abort
  return s:substitute_path_separator(isdirectory(a:path) ? a:path : fnamemodify(a:path, ':p:h'))
endfunction

function! s:_path2project_directory_git(path) abort
  let parent = a:path

  while 1
    let path = parent . '/.git'
    if isdirectory(path) || filereadable(path)
      return parent
    endif
    let next = fnamemodify(parent, ':h')
    if next == parent
      return ''
    endif
    let parent = next
  endwhile
endfunction

function! s:_path2project_directory_svn(path) abort
  let search_directory = a:path
  let directory = ''

  let find_directory = s:_escape_file_searching(search_directory)
  let d = finddir('.svn', find_directory . ';')
  if d ==# ''
    return ''
  endif

  let directory = fnamemodify(d, ':p:h:h')

  " Search parent directories.
  let parent_directory = s:path2directory(
        \ fnamemodify(directory, ':h'))

  if parent_directory !=# ''
    let d = finddir('.svn', parent_directory . ';')
    if d !=# ''
      let directory = s:_path2project_directory_svn(parent_directory)
    endif
  endif
  return directory
endfunction

function! s:_path2project_directory_others(vcs, path) abort
  let vcs = a:vcs
  let search_directory = a:path

  let find_directory = s:_escape_file_searching(search_directory)
  let d = finddir(vcs, find_directory . ';')
  if d ==# ''
    return ''
  endif
  return fnamemodify(d, ':p:h:h')
endfunction

function! s:path2project_directory(path, ...) abort
  let is_allow_empty = get(a:000, 0, 0)
  let search_directory = s:path2directory(a:path)
  let directory = ''

  " Search VCS directory.
  for vcs in ['.git', '.bzr', '.hg', '.svn']
    if vcs ==# '.git'
      let directory = s:_path2project_directory_git(search_directory)
    elseif vcs ==# '.svn'
      let directory = s:_path2project_directory_svn(search_directory)
    else
      let directory = s:_path2project_directory_others(vcs, search_directory)
    endif
    if directory !=# ''
      break
    endif
  endfor

  " Search project file.
  if directory ==# ''
    for d in ['build.xml', 'prj.el', '.project', 'pom.xml', 'package.json',
          \ 'Makefile', 'configure', 'Rakefile', 'NAnt.build',
          \ 'P4CONFIG', 'tags', 'gtags']
      let d = findfile(d, s:_escape_file_searching(search_directory) . ';')
      if d !=# ''
        let directory = fnamemodify(d, ':p:h')
        break
      endif
    endfor
  endif

  if directory ==# ''
    " Search /src/ directory.
    let base = s:substitute_path_separator(search_directory)
    if base =~# '/src/'
      let directory = base[: strridx(base, '/src/') + 3]
    endif
  endif

  if directory ==# '' && !is_allow_empty
    " Use original path.
    let directory = search_directory
  endif

  return s:substitute_path_separator(directory)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
