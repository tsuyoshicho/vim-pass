"=============================================================================
" File: vim-pass get subroutine
" Author: Tsuyoshi CHO
" Created: 2019-04-01
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" Vital
let s:Path    = vital#vimpass#import('System.Filepath')

let &cpo = s:save_cpo
unlet s:save_cpo
