" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not mofidify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_vimpass#Vim#Type#import() abort', printf("return map({'is_comparable': '', '_vital_created': '', 'is_predicate': '', 'is_numeric': '', 'is_special': ''}, \"vital#_vimpass#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
let s:types = {
\   'number': 0,
\   'string': 1,
\   'func': 2,
\   'list': 3,
\   'dict': 4,
\   'float': 5,
\   'bool': 6,
\   'none': 7,
\   'job': 8,
\   'channel': 9,
\ }
lockvar 1 s:types

let s:type_names = {
\   '0': 'number',
\   '1': 'string',
\   '2': 'func',
\   '3': 'list',
\   '4': 'dict',
\   '5': 'float',
\   '6': 'bool',
\   '7': 'none',
\   '8': 'job',
\   '9': 'channel',
\ }
lockvar 1 s:type_names

function! s:_vital_created(module) abort
  let a:module.types = s:types
  let a:module.type_names = s:type_names
endfunction


function! s:is_numeric(value) abort
  let t = type(a:value)
  return t == s:types.number || t == s:types.float
endfunction

function! s:is_special(value) abort
  let t = type(a:value)
  return t == s:types.bool || t == s:types.none
endfunction

function! s:is_predicate(value) abort
  let t = type(a:value)
  return t == s:types.number || t == s:types.string ||
  \ t == s:types.bool || t == s:types.none
endfunction

function! s:is_comparable(value1, value2) abort
  if !exists('s:is_comparable_cache')
    let s:is_comparable_cache = s:_make_is_comparable_cache()
  endif
  return s:is_comparable_cache[type(a:value1)][type(a:value2)]
endfunction

function! s:_make_is_comparable_cache() abort
  let vals = [
  \   0, '', function('type'), [], {}, 0.0,
  \   get(v:, 'false'),
  \   get(v:, 'null'),
  \   exists('*test_null_job') ? test_null_job() : 0,
  \   exists('*test_null_channel') ? test_null_channel() : 0,
  \ ]

  let result = []
  for l:V1 in vals
    let result_V1 = []
    let result += [result_V1]
    for l:V2 in vals
      try
        let _ = V1 == V2
        let result_V1 += [1]
      catch
        let result_V1 += [0]
      endtry
      unlet V2
    endfor
    unlet V1
  endfor
  return result
endfunction
