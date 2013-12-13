" *********************************************************************
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
" *********************************************************************

" Informations for translators/users: {{{
"
" DESCRIPTION:  This Vim plugin provides PO files translators with a convenient
" message centric view. The initial intent was just to highlight differences
" between a "previous-untranslated-string" and the corresponding new
" "untranslated-string" msgid, and it ends up with a set a functionnalities
" and views which allow for a full PO translation workflow.
"
" INSTALLATION: just put this in ~/.vim/ftplugin and make sure you have the
" following in your ~/.vimrc
" .. TODO
"
" UNINSTALLATION: just remove this file from ~/.vim/ftplugin.
"   
" USAGE: TODO
"
" CONFIGURATION: There are a few items you should add in your ~/.vimrc for this
" plugin to automatically update some PO header's entries, namely:
" PO-Revision-Date, Last-Translator, Language-Team.
" TODO
" See below for shortcut customization.
"
" SHORTCUTS: TODO

" }}}

" Informations about this plugin developpment {{{

" For PO files specifications, I referred to: {{{
" $ info gettext 'po files'
" $ …            'header entry'
" $ …            'creating compendia'
" $ …            'translating plural forms'
" }}}

" }}}

" PO files specifications {{{

" Some lines type can not be identified unambiguously.  For instance, a line
" matching '^\s*".\+"$' could be a continuation for any of 's:ctxt', 's:ustr'
" or 's:trstr' type, or a line matching '^\s*#\s\+.*$' could be of 's:tr_cmt'
" or 's:pre_cmt' type. For those line, we add a dictionary key 'could_be' with
" all candidate types, as hint for disambiguation in a context check.

" Special comments: {{{

let s:cmt = {
      \  'desc': "Comment"
      \, 'patt': '^\s*#\s\+.*$'
      \, 'could_be': [ s:pre_cmt, s:tr_cmt ]
      \}

let s:pre_cmt = {
      \  'desc': "Preamble comments"
      \, 'patt': '\(^\s*\(#.*\)*\n\)*^\s*msgid\s\+""\s*$'
      \, 'disamb': { 'dir':'down', 'anyof':'', 'till':'^\s*msgid\s\+""\s*$' }
      \}

"}}}

" Header entry elements: {{{

let s:prid = {
      \  'desc': "Project-Id-Version"
      \, 'type': "header-element"
      \, 'patt': '^\s*"Project-Id-Version\s*:\s*\(.*\)\s*"$'
      \}

let s:potdate = {
      \  'desc': "POT-Creation-Date"
      \, 'type': "header-element"
      \, 'patt': '^\s*"POT-Creation-Date\s*:\s*\(.*\)\s*"$'
      \}

" }}}

" Message entry elements: {{{

let s:tr_cmt = {
      \  'desc': "Translator comment"
      \, 'patt': '^\s*#\s\+\(.*\)$'
      \}

let s:xt_cmt = {
      \  'desc': "Extracted comment"
      \, 'patt': '^\s*#\.\s\+\(.*\)$'
      \}

let s:ref = {
      \  'desc': "Reference"
      \, 'patt': '^\s*#:\s\+\(.*\)$'
      \}

let s:flags = {
      \  'desc': "Flags"
      \, 'patt': '^\s*#\(,\s\+\(.*\)\)\+$'
      \}

let s:prv_ctxt = {
      \  'desc': "Previous context"
      \, 'patt': '^\s*#|\s\+msgctxt\s\+\"\(.*\)"\s*$'
      \}

let s:prv_us = {
      \  'desc': "Previous untranslated string"
      \, 'patt': '^\s*#|\s\+msgid\s\+\"\(.*\)"\s*$'
      \}

let s:prv_cont = {
      \  'desc': "Previous untranslated-string or msgcontext continuation"
      \, 'patt': '^\s*#|\s\+"\(.*\)"\s*$'
      \, 'could_be': [ s:prv_ctxt, s:prv_us ]
      \}

let s:ctxt = {
      \  'desc': "Message context"
      \, 'patt': '^\s*msgctxt\s\+\"\(.*\)"\s*$'
      \}

let s:ustr = {
      \  'desc': "Untranslated string"
      \, 'patt': '^\s*msgid\s\+\"\(.*\)"\s*$'
      \}

let s:trstr = {
      \  'desc': "Translated string"
      \, 'patt': '^\s*msgstr\s\+\"\(.*\)"\s*$'
      \}

let s:cont = {
      \  'desc': "[un]translated-string or msgctxt continuation"
      \, 'patt': '^\s*".*"\s*$'
      \, 'could_be': [ s:ctxt, s:ustr, s:trstr ]
      \}


"}}}

" PO files structure {{{

let s:msg_entry_elements = [
      \  s:tr_cmt
      \, s:xt_cmt
      \, s:ref
      \, s:flags
      \, s:prv_ctxt
      \, s:prv_us
      \, s:prv_cont
      \, s:ctxt
      \, s:ustr
      \, s:trstr
      \, s:cont
      \]

let s:msg_entry_strict_order = [
      \  s:tr_cmt
      \, s:xt_cmt
      \, s:ref
      \, s:flags
      \, s:prv_ctxt
      \, s:prv_cont
      \, s:prv_us
      \, s:prv_cont
      \, s:ctxt
      \, s:cont
      \, s:ustr
      \, s:cont
      \, s:trstr
      \, s:cont
      \]

let s:header_entry_strict_order = [
      \  s:prid
      \, s:potdate
      \]

let s:po_files_entry = [ s:pre_cmt ] + s:header_entry_strict_order + s:msg_entry_strict_order

" }}}

"}}}

" Bordel/tests {{{

function! Ragout()
  for elem in s:po_files_entry
    echo elem['patt']
    unlet elem
  endfor
endfunction

function! Tst()
  echo match(getline('.'), s:pre_cmt['patt'])
endfunction

function! Det()
  let l:curr_line = getline (line('.'))
  for elem in s:po_files_entry
    if has_key(elem, 'patt') &&
          \ match(l:curr_line, elem['patt']) > -1
      echo elem['desc']
      return
    endif
    unlet elem
  endfor
  echo "Ca correspond à rien ducon"
endfunction

function! Fupbound()
  let l:patt = '^\s*msg\(str\|id\)\s\+"\.*"\s*$'
  let l:lnum = search(l:patt, "bcWn")
  echo l:lnum
endfunction

" }}}

" Misc functions: {{{

function! Check_encoding_vs_header_declaration()
  TODO
endfunction

function! Display_nbsp_as_dot()
  autocmd Filetype po setlocal listchars=nbsp:· list
endfunction


" }}}

" { vim: set foldmethod=marker : zM }
