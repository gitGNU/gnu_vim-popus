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
" Everything is message, including headers which is the only type of message
" which can and must be started ('#' comments appart) with an empty msgid.
" Basically, has the form :
"   # comment line (0 or more)
"   msgid ""
"   ...continued
"   msgstr ""
"   ...continued
"
"   ->next message
"
" WARNING: Does not accept msgid+msgstr on same line (msgcat does).

" Type idenfication line-wise: {{{

" Line types definitions: {{{

" Misc entries line type definitions: {{{

let s:lt_cmt_gen = {
      \  'desc': "Comment"
      \, 'pattern': '\m^\s*#.*$'
      \}

let s:lt_pres = [ s:lt_cmt_gen ]

"}}}

" Header entry line type definitions: {{{

" TODO : complete header entries list

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

" }}}

" Message entry line type definitions: {{{

" TODO : add compendium duplicated entries support.

let s:lt_msg_tr_cmt = {
      \  'desc': "Translator comment"
      \, 'pattern': '\m^\s*#\s\+.*$'
      \}

let s:lt_msg_xt_cmt = {
      \  'desc': "Extracted comment"
      \, 'pattern': '\m\C^\s*#\.\s\+\(.*\)$'
      \}

let s:lt_msg_ref = {
      \  'desc': "Reference"
      \, 'pattern': '\m\C^\s*#:\s\+\(.*\)$'
      \}

let s:lt_msg_flags = {
      \  'desc': "Flags"
      \, 'pattern': '\m\C^\s*#\(,\s\+\(.*\)\)\+$'
      \}

let s:lt_msg_prv_ctxt = {
      \  'desc': "Previous context"
      \, 'pattern': '\m\C^\s*#|\s\+msgctxt\s\+\"\(.*\)"\s*$'
      \}

let s:lt_msg_prv_us = {
      \  'desc': "Previous untranslated string"
      \, 'pattern': '\m\C^\s*#|\s\+msgid\s\+\"\(.*\)"\s*$'
      \}

let s:lt_msg_prv_cont = {
      \  'desc': "Continuation line of -> "
      \, 'pattern': '\m\C^\s*#|\s\+"\(.*\)"\s*$'
      \, 'could_be': [ s:lt_msg_prv_ctxt, s:lt_msg_prv_us ]
      \}

let s:lt_msg_ctxt = {
      \  'desc': "Message context"
      \, 'pattern': '\m\C^\s*msgctxt\s\+\"\(.*\)"\s*$'
      \}

let s:lt_msg_ustr = {
      \  'desc': "Untranslated string"
      \, 'pattern': '\m\C^\s*msgid\s\+"'
      \}

let s:lt_msg_trstr = {
      \  'desc': "Translated string"
      \, 'pattern': '\m\C^\s*msgstr\s\+\"\(.*\)"\s*$'
      \}

let s:lt_msg_cont = {
      \  'desc': "Continuation line of -> "
      \, 'pattern': '\m\C^\s*".*"\s*$'
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

" }}}

" }}}

" Line type identification: {{{

let s:line_types = s:lt_pres + s:lt_hds + s:lt_msgs

let s:lt_fnc = {}

function! s:lt_fnc.match_me(line_number)
  if match(getline(a:line_number), self.pattern) == -1
    return {}
  else
    return self
  endif
endfunction

for lt in s:line_types
  let lt.match_me = s:lt_fnc.match_me
endfor

function! Get_line_type(line_number)
endfunction

" }}}

let s:msg_fcn = {}

function! s:msg_fcn.msgid_line_number()
  let w_line = prevnonblank(line('.'))
  let search_flags = 'cWn'
  if w_line != 0 && match(getline(w_line), s:lt_cmt_gen.pattern) == -1
    let search_flags .= 'b'
  endif
  return search(s:lt_msg_ustr.pattern, search_flags)
endfunction

function! s:msg_fcn.msg_top_line()
  let last_match = s:msg_fcn.msgid_line_number()
  let run_line = prevnonblank(last_match - 1)
  while run_line != 0 && match(getline(run_line), s:lt_cmt_gen.pattern) != -1
    let last_match = run_line
    let run_line = prevnonblank(run_line - 1)
  endwhile
  return last_match
endfunction

function! s:msg_fcn.msg_bottom_line()
  let last_match = s:msg_fcn.msgid_line_number()
  let run_line = nextnonblank(last_match + 1)
  let pattern = '\m\%(' . s:lt_cmt_gen.pattern . '\)\|\%(' . s:lt_msg_ustr.pattern . '\)'
  let last_file_line = line('$')
  while run_line != last_file_line && match(getline(run_line), pattern) == -1
    let last_match = run_line
    let run_line = nextnonblank(run_line + 1)
  endwhile
  return last_match
endfunction

function! s:msg_fcn.msg_search_bounds(above_or_below, pattern_limit, pattern_true_or_false)
endfunction

let s:new_lt_msg_ustr = {
      \  'desc': "Untranslated string"
      \, 'loose_pattern': '\m\C^\s*msgid\s\+"'
      \, 'strict_pattern': ''
      \, 'limits_from_self': []
            \  { 'what': 'msg'
                  \, { 'dir': 'above', 'pattern': '', 'match': 'true/false' }
                  \, { 'dir': 'below', 'pattern': '', 'match': 'true/false' }
                  \}
            \, { 'what': 'self'
                  \, { 'dir': 'above', 'pattern': '', 'match': 'true/false' }
                  \, { 'dir': 'below', 'pattern': '', 'match': 'true/false' }
                  \}
            \}
      \]

let s:new_lt_msg_ustr.

let s:new_lt_msg_ustr.limits.what[

function! s:msg_fcn.box_me()
  return {
        \  'first_line': s:msg_fcn.msg_top_line()
        \, 'last_line' : s:msg_fcn.msg_bottom_line()
        \}
endfunction

function! MTempo()
  return s:msg_fcn.box_me()
endfunction

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

let s:misc_fcn = {}

function! s:misc_fcn.restore_cursor(getpos_formated_list)
  let poslist = copy(a:getpos_formated_list)
  call remove(poslist, 0)
  call cursor(poslist)
endfunction

" }}}

" { vim: set foldmethod=marker : zM }
