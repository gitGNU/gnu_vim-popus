" ----------------------------------------------------------------------
" Copyright (C) 2013 Alexandre Hoïde <alexandre.hoide@gmail.com>
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
" ----------------------------------------------------------------------
"     Script: vim-popus.vim
"  Hosted At: http://savannah.nongnu.org/projects/vim-popus
"   ___________________          \ /
"  | $ post_tenebras ↲ |       -- * --
"  | GNU               |       . / \
"  | $ who ↲           |     o/
"  | Alexandre Hoïde   |_-- ~|
"   -------------------     / \
"       Date:	Dec 20, 2013
" Installing: TODO	:help vim-popus-install
"      Usage:	TODO :help vim-popus
"
" ---------------------------------------------------------------------
" Constructors: {{{1
"
function! s:ltCons(desc, name, pattern, ...)
  let ltObj = {}
  let ltObj.desc    = a:desc
  let ltObj.name    = a:name
  let ltObj.pattern = a:pattern
  let ltObj.concatenated_pattern = ''
  let ltObj.concatenated_name    = ''
  let ltObj.recursiveConcatenation = s:ltConsFunc.recursiveConcatenation
  let ltObj.recursiveMatch         = s:ltConsFunc.recursiveMatch
  return ltObj
endfunction

" ----------------------------------------------------------------------
"  Functions: {{{1
"
"  Line Types Functions: {{{2
let s:ltConsFunc = {}

function! s:ltConsFunc.recursiveConcatenation(faKey)
  if a:faKey !~# '^\(pattern\|name\)$'
    return 0
  endif
  let concatenated_key = 'concatenated_' . a:faKey
  if empty(self[concatenated_key])
    let self[concatenated_key] = self[a:faKey]
  endif
  for key in keys(self)
    if type(self[key]) == 4 && has_key(self[key], a:faKey)
      if empty(self[key][concatenated_key])
        let self[key][concatenated_key] = self[concatenated_key] . self[key][a:faKey]
      endif
      call self[key].recursiveConcatenation(a:faKey)
    endif
  endfor
endfunction

function! s:ltConsFunc.recursiveMatch(...)
  if a:0 == 2
    let last_match = a:1
    let wline = a:2
  else
    let last_match = 'NO-MATCH!'
    let wline = getline(prevnonblank('.'))
  endif
  for key in keys(self)
    if type(self[key]) == 4 && has_key(self[key], 'concatenated_pattern')
      if match(wline, self[key].concatenated_pattern) != -1
        return self[key].recursiveMatch(self[key].concatenated_name, wline)
      endif
    endif
  endfor
  return last_match
endfunction

" ----------------------------------------------------------------------
"  Message Functions: {{{2
"
let s:msgFunc = {}

function! s:msgFunc.parseFlags(line_number)
  let flag_list = split(getline(a:line_number), '#*,\s*')
  let unknown_flags = []
  let valid_flags = []
  for flag in flag_list
    if index(s:po_flags, flag) == -1
      call add(unknown_flags, flag)
    else
      call add(valid_flags, flag)
    endif
  endfor
  if len(unknown_flags) > 0
    echoerr 'Unknown PO message flags found: ' string(unknown_flags)
  endif
  return valid_flags
endfunction

" ----------------------------------------------------------------------
"  Move Functions: {{{2
"
let s:msgMove = {}

function! s:msgMove.goFuzzy(dir)
  " TODO go previous message before searching previous.
  if a:dir !~# '^\(next\|previous\)$'
    return 0
  endif
  let search_flags = a:dir =~# 'next' ? 'W' : 'Wb'
  let pattern = s:lt.cmt.flags.concatenated_pattern . '\zsfuzzy'
  let line = search(pattern, search_flags)
  if line == 0
    echomsg 'No fuzzy message found ' a:dir == 'next' ? 'below ' : 'above ' 'line number ' line('.')
  else
    let pattern = s:lt.msg.str.concatenated_pattern
    call search(pattern, 'W')
    normal! z.$
  endif
endfunction

function! s:msgMove.goMsg(dir, where)
endfunction

" ----------------------------------------------------------------------
" Line Types Def: {{{1
"
let s:lt = s:ltCons(
      \  'line type root'
      \, ''
      \, '\m\C^\s*'
      \)

let s:lt.continuation = s:ltCons(
      \  'continuation line'
      \, 'Cont'
      \, '\\\@<!".*\\\@<!"'
      \)

" ----------------------------------------------------------------------
" Message: {{{2
"
let s:lt.msg = s:ltCons(
      \  'Message base'
      \, ''
      \, 'msg'
      \)

let s:lt.msg.id = s:ltCons(
      \  'Untranslated string base'
      \, 'UNTRANSLATED-STRING'
      \, 'id'
      \)

let s:lt.msg.id.singular = s:ltCons(
      \  'UNTRANSLATED-STRING'
      \, ''
      \, '\s\+".*\\\@<!"\s*'
      \)

let s:lt.msg.id.plural = s:ltCons(
      \  'UNTRANSLATED-STRING-PLURAL'
      \, '-PLURAL'
      \, '_plural\s\+".*\\\@<!"\s*'
      \)

let s:lt.msg.str = s:ltCons(
      \  'Translated string base'
      \, 'TRANSLATED-STRING'
      \, 'str'
      \)

let s:lt.msg.str.single = s:ltCons(
      \  'TRANSLATED-STRING'
      \, ''
      \, '\s\+".*\\\@<!"\s*'
      \)

let s:lt.msg.str.plural = s:ltCons(
      \  'TRANSLATED-STRING-PLURAL'
      \, '-PLURAL'
      \, '\[\d]\s\+".*\\\@<!"\s*'
      \)

let s:lt.msg.ctxt = s:ltCons(
      \  'CONTEXT'
      \, 'CONTEXT'
      \, 'ctxt\s\+".*\\\@<!"\s*'
      \)

" ----------------------------------------------------------------------
" Comments: {{{2
"
let s:lt.cmt = s:ltCons(
      \  'Comment base'
      \, ''
      \, '#'
      \)

let s:lt.cmt.translator = s:ltCons(
      \  'TRANSLATOR-COMMENT'
      \, 'TRANSLATOR-COMMENT'
      \, '\s\+'
      \)

let s:lt.cmt.extracted = s:ltCons(
      \  'EXTRACTED-COMMENT'
      \, 'EXTRACTED-COMMENT'
      \, '\.\s\+'
      \)

let s:lt.cmt.reference = s:ltCons(
      \  'REFERENCE'
      \, 'REFERENCE'
      \, ':\s\+'
      \)

let s:lt.cmt.flags = s:ltCons(
      \  'FLAGS'
      \, 'FLAGS'
      \, '\%(,\s\+\%(.*\)\)\+'
      \)

let s:lt.cmt.previous = s:ltCons(
      \  'PREVIOUS'
      \, 'PREVIOUS-'
      \, '|\s\+'
      \)

let s:lt.cmt.obsolete = s:ltCons(
      \  'OBSOLETE'
      \, 'OBSOLETE'
      \, '\v\~(:|,|\.|\|)*\s+'
      \)

let s:lt.cmt.previous.msg = deepcopy(s:lt.msg)
let s:lt.cmt.previous.continuation = deepcopy(s:lt.continuation)

" ----------------------------------------------------------------------
" Update Tree: {{{2
"
call s:lt.recursiveConcatenation('pattern')
call s:lt.recursiveConcatenation('name')

" ----------------------------------------------------------------------
"  PO Specs: {{{1 
"
let s:po_flags = [
      \  'fuzzy'
      \, 'no-wrap'
      \, 'c-format'
      \, 'no-c-format'
      \, 'objc-format'
      \, 'no-objc-format'
      \, 'sh-format'
      \, 'no-sh-format'
      \, 'python-format'
      \, 'no-python-format'
      \, 'python-brace-format'
      \, 'no-python-brace-format'
      \, 'lisp-format'
      \, 'no-lisp-format'
      \, 'elisp-format'
      \, 'no-elisp-format'
      \, 'librep-format'
      \, 'no-librep-format'
      \, 'scheme-format'
      \, 'no-scheme-format'
      \, 'smalltalk-format'
      \, 'no-smalltalk-format'
      \, 'java-format'
      \, 'no-java-format'
      \, 'csharp-format'
      \, 'no-csharp-format'
      \, 'awk-format'
      \, 'no-awk-format'
      \, 'object-pascal-format'
      \, 'no-object-pascal-format'
      \, 'ycp-format'
      \, 'no-ycp-format'
      \, 'tcl-format'
      \, 'no-tcl-format'
      \, 'perl-format'
      \, 'no-perl-format'
      \, 'perl-brace-format'
      \, 'no-perl-brace-format'
      \, 'php-format'
      \, 'no-php-format'
      \, 'gcc-internal-format'
      \, 'no-gcc-internal-format'
      \, 'gfc-internal-format'
      \, 'no-gfc-internal-format'
      \, 'qt-format'
      \, 'no-qt-format'
      \, 'qt-plural-format'
      \, 'no-qt-plural-format'
      \, 'kde-format'
      \, 'no-kde-format'
      \, 'boost-format'
      \, 'no-boost-format'
      \, 'lua-format'
      \, 'no-lua-format'
      \, 'javascript-format'
      \, 'no-javascript-format'
      \]

" Line Types Def OLD TODO: {{{1
"
let s:lt_hd_prid = {
      \  'desc': "Project-Id-Version"
      \, 'pattern': '\m\C^\s*"Project-Id-Version\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_potdate = {
      \  'desc': "POT-Creation-Date"
      \, 'pattern': '\m\C^\s*"POT-Creation-Date\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_porevdate = {
      \  'desc': "PO-Revision-Date"
      \, 'pattern': '\m\C^\s*"PO-Revision-Date\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_last_tr = {
      \  'desc': "Last-Translator"
      \, 'pattern': '\m\C^\s*"Last-Translator\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_lang_team = {
      \  'desc': "Language-Team"
      \, 'pattern': '\m\C^\s*"Language-Team\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_language = {
      \  'desc': "Language"
      \, 'pattern': '\m\C^\s*"Language\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_mimev = {
      \  'desc': "MIME-Version"
      \, 'pattern': '\m\C^\s*"MIME-Version\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_ctype = {
      \  'desc': "Content-Type"
      \, 'pattern': '\m\C^\s*"Content-Type\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_tenc = {
      \  'desc': "Content-Transfer-Encoding"
      \, 'pattern': '\m\C^\s*"Content-Transfer-Encoding\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_xgen = {
      \  'desc': "X-Generator"
      \, 'pattern': '\m\C^\s*"X-Generator\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_plurf = {
      \  'desc': "Plural-Forms"
      \, 'pattern': '\m\C^\s*"Plural-Forms\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_header_entry_cont = {
      \  'desc': "Continuation line of header entry -> "
      \, 'pattern': '\m\C^\s*"\(.*\)\\n"\s*$'
      \}

let s:lt_hds = [
      \  s:lt_hd_prid
      \, s:lt_hd_potdate
      \, s:lt_hd_porevdate
      \, s:lt_hd_last_tr
      \, s:lt_hd_lang_team
      \, s:lt_hd_language
      \, s:lt_hd_mimev
      \, s:lt_hd_ctype
      \, s:lt_hd_tenc
      \, s:lt_hd_xgen
      \, s:lt_hd_plurf
      \]

" ----------------------------------------------------------------------
" Debug: {{{1
"
function! MyEcho(obj)
    echo s:{a:obj}
endfunction
function! MyUnlet(obj)
    unlet s:{a:obj}
endfunction
function! MyLet(obj, value)
    let s:{a:obj} = a:value
endfunction
function! MyReturn(obj)
  let tempo = eval('s:' . a:obj)
  return tempo
endfunction

" vim: foldmethod=marker nowrap
