" =============================================================================
" File:         autoload/dict.vim
" Description:  The main dict used to populate contents
" Author:       Juneed Ahamed
" =============================================================================

"vc#dict.vim {{{1

"script vars {{{2
let [s:metakey, s:logkey, s:statuskey, s:commitskey, s:browsekey, 
            \ s:menukey, s:errorkey] = vc#utils#getkeys()
"2}}}

"dict proto {{{2
let s:entryd = {'contents':{}, 'ops':{}}
let s:dict = {}
fun! vc#dict#new(...)
    call s:dict.discardentries()
    let obj = copy(s:dict)
    let obj.title = a:0 >= 1 ? a:1 : ''
    let obj.idx = 0
    let obj.bparent = ""
    let obj.brecursive = 0
    let obj.forcerepo = ""
    let obj.hasbufops = 0
    let obj.affectedrevision = ""
    let obj.infolist = 0
    if a:0 >= 2 | call extend(obj, a:2) | en
    retu obj
endf

fun! s:dict.setmeta(meta) dict
    let self.meta = a:meta
endf

fun! s:dict.nextkey() dict
    let self.idx += 1
    retu self.idx
endf

fun! s:dict.lines() dict
    let [dislines, mlines, lines] = [[], [], []]
    if has_key(self, s:logkey) | call extend(lines, self[s:logkey].format()) | en
    if has_key(self, s:statuskey) | call extend(lines, self[s:statuskey].format()) | en
    if has_key(self, s:commitskey) | call extend(lines, self[s:commitskey].format()) | en
    if has_key(self, s:browsekey) | call extend(lines, self[s:browsekey].formatbrwsd()) | en
    call extend(dislines, lines[ : g:vc_max_buf_lines])

    if has_key(self, s:menukey) | call extend(mlines, self[s:menukey].format()) | en
    call extend(dislines, mlines)
    call extend(lines, mlines)
    retur [lines, dislines]
endf

fun! s:dict.entries() dict
    let rlst = []
    if has_key(self, s:logkey) | call add(rlst, self.logd) | en
    if has_key(self, s:statuskey) | call add(rlst, self.statusd) | en
    if has_key(self, s:commitskey) | call add(rlst, self.commitsd) | en
    if has_key(self, s:browsekey) | call add(rlst, self.browsed) | en
    if has_key(self, s:menukey) | call add(rlst, self.menud) | en
    retu rlst
endf

fun! s:dict.discardentries() dict
    for ekey in vc#utils#getEntryKeys()
        if has_key(self, ekey) | call remove(self, ekey) | en
    endfor
endf

fun! s:dict.clear() dict
    call self.discardentries()
    let self.idx = 0
    if has_key(self, s:metakey) | call remove(self, s:metakey) | en
endf

fun! s:dict.getops(key) dict
    if a:key == "err" && self.haserror() && has_key(self.error, "ops") 
        retu self.error.ops
    endif
    for thedict in self.entries()
        if has_key(self, s:browsekey) | retu thedict.ops | en
        if has_key(thedict.contents, a:key) | retu thedict.ops | en
    endfor
    retu {}
endf

fun! s:dict.getallops() dict
    let allops = {}
    for thedict in self.entries()
        if has_key(thedict, 'ops') | call extend(allops, thedict.ops) | en
    endfor
    if self.haserror() && has_key(self.error, "ops") 
        call extend(allops, self.error.ops)
    endif
    retu allops
endf

fun! s:dict.sethasbufops() dict
    if self.hasbufops == 1 | retu | en
    for [key, thedict] in items(self.getallops())
        if has_key(thedict, "bop") | let self.hasbufops = 1 | break | en
    endfor
endf

fun! s:dict.haserror() dict
    retu has_key(self, s:errorkey)
endf

fun! s:dict.browsedict() dict
    if has_key(self, s:browsekey) 
        retu self[s:browsekey].contents
    endif
    retu {}
endf

fun! s:entryd.format() dict
    let lines = []
    for key in sort(keys(self.contents), 'vc#utils#sortconvint')
        let line = printf("%5d:%s", key, self.contents[key].line)
        call add(lines, line)
    endfor
    retu lines
endf
"2}}}

fun! vc#dict#addbrowseentries(dict, key, entries, ops)
    if !has_key(a:dict, a:key)
        let a:dict[a:key] = deepcopy(s:entryd)
    endif
    let a:dict[a:key].contents = vc#dict#formatbrowsedentries(a:entries)
    call vc#dict#addops(a:dict, a:key, a:ops)
endf

fun! vc#dict#formatbrowsedentries(entries) 
    let entries = []
    let linenum = 0
    for entry in a:entries
        let linenum += 1
        let entry = printf("%5d:%s", linenum, entry)
        call add(entries, entry)
    endfor
    retu entries
endf

fun! s:entryd.formatbrwsd() dict
    retu self.contents
endf

"Helpers {{{2
fun! vc#dict#adderr(dict, descr, msg)
    let [estart, eend, errsyntax] = vc#utils#getErrSyn()
    let a:dict.error = {}
    let a:dict.error.line = estart.a:descr . ' | ' . a:msg
    call s:addcommonops(a:dict, 'error')
    call a:dict.sethasbufops()
endf

fun! vc#dict#adderrup(dict, descr, msg)
    call vc#dict#adderr(a:dict, a:descr, a:msg)
    let a:dict.error.ops = vc#utils#upop()
    call s:addcommonops(a:dict, 'error')
    call a:dict.sethasbufops()
endf

fun! vc#dict#adderrtop(dict, descr, msg)
    call vc#dict#adderr(a:dict, a:descr, a:msg)
    let a:dict.error.ops = vc#utils#topop()
    call s:addcommonops(a:dict, 'error')
    call a:dict.sethasbufops()
endf

fun! vc#dict#addops(dict, key, ops)
    if !has('gui_running') && has_key(a:ops, "\<C-s>")
        call remove(a:ops, "\<C-s>")
    endif
    if !has_key(a:dict, a:key) | th a:key.' Not Present' | en
    if len(a:ops) > 0 | call extend(a:dict[a:key].ops, a:ops) | en
    call s:addcommonops(a:dict, a:key)
    call a:dict.sethasbufops()
endf

fun! s:addcommonops(dict, key)
    let commonops = {
                \ "\<F4>"  : {"fn":'vc#prompt#toggleargsmode'},
                \ "\<F5>"  : {"fn":'vc#act#forceredr'},
                \ "\<F6>"  : {"fn":'vc#act#logit'},
                \ "\<F8>"  : {"fn":'vc#prompt#sort'},
                \ "\<C-e>" : {"bop":"<c-e>", "fn":'vc#gopshdlr#selectall'},
                \ "\<C-s>" : {"fn":'vc#prompt#setNoLoop'},
                \ }
    try
        if !has_key(a:dict[a:key], 'ops') | let a:dict[a:key].ops = {} | en
        call extend(a:dict[a:key].ops, filter(commonops, '!has_key(a:dict, v:key)'))
    catch | endtry
endf

fun! vc#dict#addentries(dict, key, entries, ops)
    if !has_key(a:dict, a:key)
        let a:dict[a:key] = deepcopy(s:entryd)
    endif

    for entry in a:entries
        let idx = a:dict.nextkey()
        let a:dict[a:key].contents[idx] = entry
    endfor
    call vc#dict#addops(a:dict, a:key, a:ops)
endf

"convert = branch2trunk | branch2branch | trunk2branch
fun! vc#dict#menuitem(title, callback, convert)
    let menu_item = {}
    let menu_item.line = g:vc_menu_start_str.a:title. g:vc_menu_end_str
    let menu_item.title = a:title
    let menu_item.callback = a:callback
    let menu_item.convert = a:convert
    retu menu_item
endf
"2}}}
"1}}}
