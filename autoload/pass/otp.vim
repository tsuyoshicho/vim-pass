"=============================================================================
" File: vim-pass otp subroutine
" Author: Tsuyoshi CHO
" Created: 2019-04-28
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" Vital
let s:URI      = vital#vimpass#import('Web.URI')
let s:Base32cf = vital#vimpass#import('Data.Base32.Crockford')
let s:OTP      = vital#vimpass#import('Crypt.Password.OTP')

" get entry data
function! pass#otp#value(otpauth) abort
  " like otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example

  let otpauth_result = s:URI.new(a:otpauth)
  let type = otpauth_result.host()

  let paramlist = split(otpauth_result.query(),'&')
  let parammap  = {}
  for i in range(0,len(paramlist) - 1)
    let splitparam = split(paramlist[i],'=')
    let parammap[tolower(splitparam[0])] = splitparam[1]
  endfor


  if type != 'totp'
    throw 'vim-pass: otp: currently support only totp'
  endif

  " currently support this fixed values(like Google Authenticator):
  " algo SHA1
  " digit 6
  " period 30

  if !has_key(parammap, 'secret')
    throw 'vim-pass: otp: need secret'
  endif

  let secret = s:Base32cf.decode(parammap['secret'])

  return s:OTP.totp(secret,
        \ s:OTP.defaults.TOTP.period,
        \ vital#vimpass#import('Hash.' . s:OTP.defaults.TOTP.algo),
        \ s:OTP.defaults.TOTP.digit)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
