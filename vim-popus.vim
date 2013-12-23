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
" context information, we define those 3 domains and related functions.

let s:po_dom_pre = {
      \  'name' : "preamble_comment_domain"
      \, 'first': { 'number': 0 }
      \, 'last' : { 'pattern': '\n\_^\s*msgid\s\+""\s*\(\n\s*\)*\_^*\s*msgstr\s\+""\s*$' }
      \, 'comment': "This domain could be empty (get_line would return 0 for first and last)"
      \}

let s:po_dom_head = {
      \  'name'  : "header_domain"
      \, 'first' : { 'info': "s:po_dom_pre.last.number + 1" }
      \, 'last'  : { 'pattern': '\n\_^\s*\(#\|msgid\s\+".*"\).*$' }
      \}

let s:po_dom_msgs = {
      \  'name'  : "messages_domain"
      \, 'first' : { 'info': "s:po_dom_head.last.number + 1" }
      \, 'last'  : { 'number': line('$') }
      \}

let s:sorted_domains = [ s:po_dom_pre, s:po_dom_head, s:po_dom_msgs ]

function! Get_po_doms_tmp()
  let saved_cursor = getpos('.')
  let search_flags = 'cW'

  let lpre = deepcopy(s:po_dom_pre)
  call cursor(lpre.first.number, 1)
  let lpre.last.number = search('\m' . s:po_dom_pre.last.pattern, search_flags)

  let lhea = deepcopy(s:po_dom_head)
  let lhea.first.number = lpre.last.number + 1
  call cursor(lhea.first.number, 1)
  let lhea.last.number = search('\m' . lhea.last.pattern, search_flags)

  let lmsg = deepcopy(s:po_dom_msgs)
  let lmsg.first.number = lhea.last.number + 1
  call cursor(lmsg.first.number, 1)

  call cursor(saved_cursor[1], saved_cursor[2])

  return [ lpre, lhea, lmsg ]
endfunction

function! Get_po_dom_on_line(line_number)
  let doms = Get_po_doms_tmp()
  for dom in doms
    if a:line_number >= dom.first.number
      if a:line_number <= dom.last.number
        return dom
      endif
    endif
  endfor
endfunction

" }}}

" Type idenfication line-wise: {{{

" Line types definitions: {{{

" Misc entries line type definitions: {{{

let s:lt_pre_cmt = {
      \  'desc': "Preamble comment"
      \, 'pattern': '\m\(^\(\s*#.*\)\s*$\)'
      \}

" Just init 's:tr_cmt' here because of cross-ref with 's:cmt'. Realy defined later.
let s:lt_msg_tr_cmt = {}

" A line matching '^\s*#\(\s\+.\+\)*$' could be of 's:tr_cmt' or 's:pre_cmt' type.
let s:lt_mlt_cmt = {
      \  'desc': "Comment -> "
      \, 'pattern': '^\s*#\(\s\+.\+\)*$'
      \, 'patt_props': { 'def_self':'true' }
      \, 'could_be': [ s:lt_pre_cmt, s:lt_msg_tr_cmt ]
      \}

let s:lt_pres = [ s:lt_pre_cmt ]

for lt_pre in s:lt_pres
  let lt_pre.domain = s:po_dom_pre
endfor

"}}}

" Header entry line type definitions: {{{

" TODO : complete header entries list

let s:lt_hd_prid = {
      \  'desc': "Project-Id-Version"
      \, 'pattern': '^\s*"Project-Id-Version\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_potdate = {
      \  'desc': "POT-Creation-Date"
      \, 'pattern': '^\s*"POT-Creation-Date\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_porevdate = {
      \  'desc': "PO-Revision-Date"
      \, 'pattern': '^\s*"PO-Revision-Date\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_last_tr = {
      \  'desc': "Last-Translator"
      \, 'pattern': '^\s*"Last-Translator\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_lang_team = {
      \  'desc': "Language-Team"
      \, 'pattern': '^\s*"Language-Team\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_language = {
      \  'desc': "Language"
      \, 'pattern': '^\s*"Language\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_mimev = {
      \  'desc': "MIME-Version"
      \, 'pattern': '^\s*"MIME-Version\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_ctype = {
      \  'desc': "Content-Type"
      \, 'pattern': '^\s*"Content-Type\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_tenc = {
      \  'desc': "Content-Transfer-Encoding"
      \, 'pattern': '^\s*"Content-Transfer-Encoding\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_xgen = {
      \  'desc': "X-Generator"
      \, 'pattern': '^\s*"X-Generator\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_hd_plurf = {
      \  'desc': "Plural-Forms"
      \, 'pattern': '^\s*"Plural-Forms\s*:\s*\(.*\)\s*"$'
      \}

let s:lt_header_entry_cont = {
      \  'desc': "Continuation line of header entry -> "
      \, 'pattern': '^\s*"\(.*\)\\n"\s*$'
      \, 'patt_props': { 'def_self':'true' }
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

for lt_hd in s:lt_hds
  let lt_hd.domain = s:po_dom_head
endfor

" }}}

" Message entry line type definitions: {{{

" TODO : add compendium duplicated entries support.

let s:lt_msg_tr_cmt = {
      \  'desc': "Translator comment"
      \, 'pattern': '\m^\s*#\s\+.*$'
      \}

let s:lt_msg_xt_cmt = {
      \  'desc': "Extracted comment"
      \, 'pattern': '^\s*#\.\s\+\(.*\)$'
      \}

let s:lt_msg_ref = {
      \  'desc': "Reference"
      \, 'pattern': '^\s*#:\s\+\(.*\)$'
      \}

let s:lt_msg_flags = {
      \  'desc': "Flags"
      \, 'pattern': '^\s*#\(,\s\+\(.*\)\)\+$'
      \}

let s:lt_msg_prv_ctxt = {
      \  'desc': "Previous context"
      \, 'pattern': '^\s*#|\s\+msgctxt\s\+\"\(.*\)"\s*$'
      \}

let s:lt_msg_prv_us = {
      \  'desc': "Previous untranslated string"
      \, 'pattern': '^\s*#|\s\+msgid\s\+\"\(.*\)"\s*$'
      \}

let s:lt_msg_prv_cont = {
      \  'desc': "Continuation line of -> "
      \, 'pattern': '^\s*#|\s\+"\(.*\)"\s*$'
      \, 'could_be': [ s:lt_msg_prv_ctxt, s:lt_msg_prv_us ]
      \}

let s:lt_msg_ctxt = {
      \  'desc': "Message context"
      \, 'pattern': '^\s*msgctxt\s\+\"\(.*\)"\s*$'
      \}

let s:lt_msg_ustr = {
      \  'desc': "Untranslated string"
      \, 'pattern': '^\s*msgid\s\+\"\(.*\)"\s*$'
      \}

let s:lt_msg_trstr = {
      \  'desc': "Translated string"
      \, 'pattern': '^\s*msgstr\s\+\"\(.*\)"\s*$'
      \}

let s:lt_msg_cont = {
      \  'desc': "Continuation line of -> "
      \, 'pattern': '^\s*".*"\s*$'
      \, 'could_be': [ s:lt_msg_ctxt, s:lt_msg_ustr, s:lt_msg_trstr ]
      \}

let s:lt_msgs = [
      \  s:lt_msg_tr_cmt
      \, s:lt_msg_tr_cmt
      \, s:lt_msg_xt_cmt
      \, s:lt_msg_ref
      \, s:lt_msg_flags
      \, s:lt_msg_prv_ctxt
      \, s:lt_msg_prv_us
      \, s:lt_msg_ctxt
      \, s:lt_msg_ustr
      \, s:lt_msg_trstr
      \]

for lt_msg in s:lt_msgs
  let lt_msg.domain = s:po_dom_msgs
endfor

" }}}

" }}}

" Line type identification: {{{

let s:line_types = s:lt_pres + s:lt_hds + s:lt_msgs

let s:lt_funcs = {}

function! s:lt_funcs.match_me(line_number)
  if match(getline(a:line_number), self.pattern) == -1
    return {}
  endif
  return self
endfunction

for lt in s:line_types
  let lt.match_me = s:lt_funcs.match_me
endfor

function! Get_line_type(line_number)
  let dom = Get_po_dom_on_line(a:line_number)
  let list = filter(copy(s:line_types), "v:val.domain.name =~# dom.name")
  for lt in list
    if !empty(lt.match_me(a:line_number))
      return lt
    endif
  endfor
  return {}
endfunction

" }}}

" }}}

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
