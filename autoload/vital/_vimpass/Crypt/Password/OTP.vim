" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not modify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_vimpass#Crypt#Password#OTP#import() abort', printf("return map({'_vital_depends': '', 'hotp': '', '_vital_created': '', 'totp': '', '_vital_loaded': ''}, \"vital#_vimpass#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
" Utilities for HOTP/TOTP
" RFC 4226 - HOTP: An HMAC-Based One-Time Password Algorithm https://tools.ietf.org/html/rfc4226
" RFC 6238 - TOTP: Time-Based One-Time Password Algorithm https://tools.ietf.org/html/rfc6238

let s:save_cpo = &cpo
set cpo&vim

let s:DEFAULTS = {
      \ 'HOTP' : {
      \   'digit'   : 6,
      \   'algo'    : 'SHA1',
      \   'counter' : 8,
      \ },
      \ 'TOTP' : {
      \   'digit'   : 6,
      \   'algo'    : 'SHA1',
      \   'period'  : 30,
      \ },
      \}

function! s:_vital_created(module) abort
  let a:module.defaults = s:DEFAULTS
endfunction

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Bitwise  = s:V.import('Bitwise')
  let s:Type     = s:V.import('Vim.Type')
  let s:HMAC     = s:V.import('Crypt.MAC.HMAC')
  let s:List     = s:V.import('Data.List')
  let s:DateTime = s:V.import('DateTime')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise',
        \ 'Vim.Type',
        \ 'Crypt.MAC.HMAC',
        \ 'Data.List',
        \ 'DateTime',
        \ 'Data.List.Byte']
endfunction

function! s:hotp(key, counter, algo, digit) abort
  let hmac = s:HMAC.new(a:algo, a:key)
  if s:DEFAULTS.HOTP.counter == len(a:counter)
    let counter = copy(a:counter)
  elseif s:DEFAULTS.HOTP.counter > len(a:counter)
    let counter = s:List.new(s:DEFAULTS.HOTP.counter, {-> 0})
    for i in range(s:DEFAULTS.HOTP.counter)
      if 0 <= (i - (s:DEFAULTS.HOTP.counter - len(a:counter)))
        let counter[i] = a:counter[i - (s:DEFAULTS.HOTP.counter - len(a:counter))]
      endif
    endfor
  else
    call s:_throw(printf('counter size over:%d', len(a:counter)))
  endif

  let hmac_list =  hmac.calc(counter)

  let offset = s:Bitwise.and(hmac_list[-1],0xf)
  let bincode = s:Bitwise.and(s:ByteArray.to_int(hmac_list[offset : offset+3]), 0x7FFFFFFF)

  let modulo_base = float2nr(pow(10, a:digit))
  let hotp_value = bincode % modulo_base

  return printf('%0' . string(a:digit) . 'd', hotp_value)
endfunction

function! s:totp(key, period, algo, digit, ...) abort
  if a:0
    let typeval = type(a:1)
    if typeval == s:Type.types.number
      let datetime = s:DateTime.from_unix_time(a:1)
    elseif typeval == s:Type.types.dict && 'DateTime' ==# get(a:1,'class','')
      let datetime = a:1
    else
      call s:_throw('non-support extra datetime data (support only unix epoch int value or DateTime object)')
    endif
  endif
  if !exists('datetime')
    let datetime = s:DateTime.now()
  endif

  let now_sec = datetime.unix_time()
  let epoch_sec = 0

  if has('num64')
    let counter =  s:ByteArray.from_int(float2nr(floor((now_sec - epoch_sec) / a:period)), 64)
  else
    let counter =  s:ByteArray.from_int(float2nr(floor((now_sec - epoch_sec) / a:period)), 32)
  endif

  return s:hotp(a:key, counter, a:algo, a:digit)
endfunction

function! s:_throw(message) abort
  throw 'vital: Crypt.Password.OTP: ' . a:message
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
