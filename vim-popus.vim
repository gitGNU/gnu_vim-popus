" ***********************************************************************
" Copyright (C) 2013 Alexandre Hoïde <alexandre.hoide@gmail.com>        "
"                                                                       "
" This program is free software: you can redistribute it and/or modify  "
" it under the terms of the GNU General Public License as published by  "
" the Free Software Foundation, either version 3 of the License, or     "
" (at your option) any later version.                                   "
"                                                                       "
" This program is distributed in the hope that it will be useful,       "
" but WITHOUT ANY WARRANTY; without even the implied warranty of        "
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         "
" GNU General Public License for more details.                          "
"                                                                       "
" You should have received a copy of the GNU General Public License     "
" along with this program.  If not, see <http://www.gnu.org/licenses/>. "
" ***********************************************************************

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

" PO files parsing {{{

" Domains: {{{
" A PO file is composed of 3 "domains" :
" 1. preamble comments (optional)
"    followed by
" 2. header entries
"    followed by
" 3. messages.
" To help disambiguation when a line type can not be identified without
" context information, we define those 3 domains and a function which returns
" a list with first/last lines of each domain.

let s:po_dom_1 = {
      \  'name' : "preamble_comment_domain"
      \, 'first': { 'number': 0 }
      \, 'last' : { 'pattern': '\n\_^\s*msgid\s\+""\s*\(\n\s*\)*\_^*\s*msgstr\s\+""\s*$' }
      \, 'comment': "This domain could be empty (get_line would return 0 for first and last)"
      \}

let s:po_dom_2 = {
      \  'name'  : "header_domain"
      \, 'first' : { 'deferred': "s:po_dom_1.get_line('last') + 1" }
      \, 'last'  : { 'pattern': '\n\_^\s*\(#\|msgid\s\+".*"\).*$' }
      \}

let s:po_dom_3 = {
      \  'name'  : "messages_domain"
      \, 'first' : { 'deferred': "s:po_dom_2.get_line('last') + 1" }
      \, 'last'  : { 'pattern': '\%$' }
      \}

let s:po_dom_funcs = { }

function! s:po_dom_funcs.get_line(key)
  if a:key !=# 'first' && a:key !=# 'last'
    return 0
  endif

  let ldict = self[a:key]
  if has_key(ldict, 'number')
    return ldict.number
  elseif has_key(ldict, 'deferred')
    return eval(ldict.deferred)
  endif

  let search_flags = 'cW'
  if a:key == 'last'
    let search_from = self.get_line('first')
  else
    let search_from = self.get_line('last')
    let search_flags .= 'b'
  endif

  if search_from == 0
    let search_from = 1
  endif

  let saved_cursor = getpos('.')
  call cursor(search_from, 1)
  let fret = search(ldict.pattern, search_flags)
  call cursor(saved_cursor[1], saved_cursor[2])
  return fret
endfunction

let s:sorted_domains = [ s:po_dom_1, s:po_dom_2, s:po_dom_3 ]

for dom in s:sorted_domains
  let dom.get_line = s:po_dom_funcs.get_line
endfor

function! Get_po_doms()
  let fret = []
  for dom in s:sorted_domains
    let fret += [ {
          \  'name'      : dom.name
          \, 'first_line': dom.get_line('first')
          \, 'last_line' : dom.get_line('last')
          \} ]
  endfor
  return fret
endfunction

" }}}

" Type idenfication line-wise: {{{

" Misc entries line type identification: {{{

" A preamble comment line has nothing else than other comments, empty lines,
" and begining of file (as ceiling) above it.
let s:lt_pre_cmt = {
      \  'desc': "Preamble comment"
      \, 'patt': '\%^'
      \, 'patt_props': { 'def_self':'false', 'is':'ceiling' }
      \}

" Just init 's:tr_cmt' here because of cross-ref with 's:cmt'. Realy defined later.
let s:lt_msg_tr_cmt = {}

" A line matching '^\s*#\(\s\+.\+\)*$' could be of 's:tr_cmt' or 's:pre_cmt' type.
let s:lt_cmt = {
      \  'desc': "Comment -> "
      \, 'patt': '^\s*#\(\s\+.\+\)*$'
      \, 'patt_props': { 'def_self':'true' }
      \, 'could_be': [ s:lt_pre_cmt, s:lt_msg_tr_cmt ]
      \}

"}}}

" Header entry line type identification: {{{

" TODO : complete header entries list

let s:lt_hd_prid = {
      \  'desc': "Project-Id-Version"
      \, 'patt': '^\s*"Project-Id-Version\s*:\s*\(.*\)\s*"$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_hd_potdate = {
      \  'desc': "POT-Creation-Date"
      \, 'patt': '^\s*"POT-Creation-Date\s*:\s*\(.*\)\s*"$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_hd_porevdate = {
      \  'desc': "PO-Revision-Date"
      \, 'patt': '^\s*"PO-Revision-Date\s*:\s*\(.*\)\s*"$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_hd_last_tr = {
      \  'desc': "Last-Translator"
      \, 'patt': '^\s*"Last-Translator\s*:\s*\(.*\)\s*"$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_hd_lang_team = {
      \  'desc': "Language-Team"
      \, 'patt': '^\s*"Language-Team\s*:\s*\(.*\)\s*"$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_hd_language = {
      \  'desc': "Language"
      \, 'patt': '^\s*"Language\s*:\s*\(.*\)\s*"$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_hd_mimev = {
      \  'desc': "MIME-Version"
      \, 'patt': '^\s*"MIME-Version\s*:\s*\(.*\)\s*"$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_hd_ctype = {
      \  'desc': "Content-Type"
      \, 'patt': '^\s*"Content-Type\s*:\s*\(.*\)\s*"$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_hd_tenc = {
      \  'desc': "Content-Transfer-Encoding"
      \, 'patt': '^\s*"Content-Transfer-Encoding\s*:\s*\(.*\)\s*"$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_hd_xgen = {
      \  'desc': "X-Generator"
      \, 'patt': '^\s*"X-Generator\s*:\s*\(.*\)\s*"$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_hd_plurf = {
      \  'desc': "Plural-Forms"
      \, 'patt': '^\s*"Plural-Forms\s*:\s*\(.*\)\s*"$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_header_entry_cont = {
      \  'desc': "Continuation line of header entry -> "
      \, 'patt': '^\s*"\(.*\)\\n"\s*$'
      \, 'patt_props': { 'def_self':'true' }
      \, 'could_be': s:header_entry_elements
      \}

" }}}

" Message entry line type identification: {{{

" TODO : add compendium duplicated entries support.

" A Translator comment line has nothing else than other comments,
" empty lines, and another valid element type (as ceiling) above it.
let s:lt_msg_tr_cmt = {
      \  'desc': "Translator comment"
      \, 'patt': '^\%(' . s:lt_cmt.patt . '\|\s*$\)\@!'
      \, 'patt_props': { 'def_self':'false', 'is':'ceiling' }
      \}

let s:lt_msg_xt_cmt = {
      \  'desc': "Extracted comment"
      \, 'patt': '^\s*#\.\s\+\(.*\)$'
      \, 'patt_props': { 'def_self':'true' }
      \}

let s:lt_msg_ref = {
      \  'desc': "Reference"
      \, 'patt': '^\s*#:\s\+\(.*\)$'
      \, 'patt_props': { 'def_self':'true' }
      \}

let s:lt_msg_flags = {
      \  'desc': "Flags"
      \, 'patt': '^\s*#\(,\s\+\(.*\)\)\+$'
      \, 'patt_props': { 'def_self':'true' }
      \}

let s:lt_msg_prv_ctxt = {
      \  'desc': "Previous context"
      \, 'patt': '^\s*#|\s\+msgctxt\s\+\"\(.*\)"\s*$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_msg_prv_us = {
      \  'desc': "Previous untranslated string"
      \, 'patt': '^\s*#|\s\+msgid\s\+\"\(.*\)"\s*$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_msg_prv_cont = {
      \  'desc': "Continuation line of -> "
      \, 'patt': '^\s*#|\s\+"\(.*\)"\s*$'
      \, 'patt_props': { 'def_self':'true' }
      \, 'could_be': [ s:lt_msg_prv_ctxt, s:lt_msg_prv_us ]
      \}

let s:lt_msg_ctxt = {
      \  'desc': "Message context"
      \, 'patt': '^\s*msgctxt\s\+\"\(.*\)"\s*$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_msg_ustr = {
      \  'desc': "Untranslated string"
      \, 'patt': '^\s*msgid\s\+\"\(.*\)"\s*$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_msg_trstr = {
      \  'desc': "Translated string"
      \, 'patt': '^\s*msgstr\s\+\"\(.*\)"\s*$'
      \, 'patt_props': { 'def_self':'true', 'is':'top' }
      \}

let s:lt_msg_cont = {
      \  'desc': "Continuation line of -> "
      \, 'patt': '^\s*".*"\s*$'
      \, 'patt_props': { 'def_self':'true' }
      \, 'could_be': [ s:lt_msg_ctxt, s:lt_msg_ustr, s:lt_msg_trstr ]
      \}

"}}}

" }}}

" PO files structure {{{

" Elements: {{{

let s:misc_elements = [ s:lt_pre_cmt, s:lt_cmt ]

let s:header_entry_elements = [
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

let s:msg_entry_elements = [
      \  s:lt_msg_tr_cmt
      \, s:lt_msg_xt_cmt
      \, s:lt_msg_ref
      \, s:lt_msg_flags
      \, s:lt_msg_prv_ctxt
      \, s:lt_msg_prv_us
      \, s:lt_msg_prv_cont
      \, s:lt_msg_ctxt
      \, s:lt_msg_ustr
      \, s:lt_msg_trstr
      \, s:lt_msg_cont
      \]

let s:po_files_entries =
      \  s:misc_elements
      \+ s:header_entry_elements
      \+ s:msg_entry_elements

" TODO : généraliser
function! Line_match_list()
  let l:list = []
  for elem in s:po_files_entries
    if elem.patt_props.def_self  ==# 'true'
      call add(l:list, elem)
    endif
  endfor
  return l:list
endfunction

let s:line_match_list = Line_match_list()

"}}}


" }}}

" }}}

" Bordel/tests {{{

function! Det_line_type(...)
  let l:wline = getline(a:0 == 0 ? '.' : a:1)
  for elem in s:line_match_list
    if match(l:wline, elem.patt) > -1
      let l:retstr = elem.desc
      if has_key(elem, 'could_be')
        let l:retstr .= "TODO : function to return 'parent' type"
      endif
      return l:retstr
    endif
  endfor
  return "Unable to parse type of line"
endfunction

" }}}

" Misc functions: {{{

function! Check_encoding_vs_header_declaration()
  TODO
endfunction

function! Display_nbsp_as_dot()
  autocmd Filetype po setlocal listchars=nbsp:· list
endfunction

" Call to clean last plugin search from history (to avoid trashing user history).
function! Clean_psh()
  let @/=""
  call histdel("/", -1)
endfunction

" }}}

" { vim: set foldmethod=marker : zM }
