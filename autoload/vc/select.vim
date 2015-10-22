" =============================================================================
" File:         plugin/select.vim
" Description:  select/marks/bmarks handler and highlighter
" Author:       Juneed Ahamed
" =============================================================================
"
" plugin/select.vim {{{1
let s:selectd = {}

"select functions {{{2
fun! vc#select#dict()
    retu s:selectd
endf

fun! vc#select#clear()
    let s:selectd = {}
endf

fun! vc#select#add(argsd)
    let s:selectd[a:argsd.key] = a:argsd
    call vc#select#sign(a:argsd.key, 1)
    retu vc#nofltrclear()
endf

fun! vc#select#addrevisionforall(revision)
   for [key, selectd] in items(s:selectd)
       let selectd.revision = a:revision
   endfor
endf

fun! vc#select#add_old(key, line, path, revision, metad, opt)
    let selectd = {'line': a:line, 'path': a:path,
                \ 'revision': a:revision, 'repo': a:metad.repo,
                \ 'branch': a:metad.branch, 'opt': a:opt}

    if get(a:metad, "rbranch", "") != ""
        let selectd.rbranch = a:metad.rbranch
    endif

    let s:selectd[a:key] = selectd
    call vc#select#sign(a:key, 1)
    retu vc#nofltrclear()
endf

fun! vc#select#remove(key)
    if has_key(s:selectd, a:key)
        call remove(s:selectd, a:key) | call vc#select#sign(a:key, 0)
        retu vc#passed()
    endif
    retu vc#failed()
endf

fun! vc#select#exists(key)
    retu has_key(s:selectd, a:key)
endf

fun! vc#select#openfiles(callback, maxopen)
    let cnt = 0
    for [key, sdict] in items(s:selectd)
        if key == 'err' || vc#utils#isdirdirtycheck(sdict.path) 
                    \ || vc#utils#isdir(sdict.path)
        cont | en
        let cnt += 1
        call call(a:callback, [sdict])
        if cnt == a:maxopen | break | en
    endfor
    if cnt != 0 | call vc#prepexit() | en
    retu vc#nofltrclear() 
endf
"2}}}

"bmark functions {{{2
fun! vc#select#book(entity)
    if has_key(g:bmarks, a:entity) 
        let eid = g:bmarks[a:entity]
        call s:signbmark(eid, 0)
        call remove(g:bmarks, a:entity)
    else
        let g:bmarkssid += 1
        let g:bmarks[a:entity] = g:bmarkssid
        call s:signbmark(g:bmarkssid, 1)
    endif
    call vc#caop#cachebmarks()
    retu vc#nofltrclear() 
endf

fun! vc#select#booked()
    retu keys(vc#caop#fetchbmarks())
endf
"2}}}

"sign functions {{{2
fun! vc#select#sign(theid, isadd)
    try
        if !g:vc_signs | retu | en
        let theid = matchstr(a:theid, "\\d\\+")
        if a:isadd | exe 'silent! sign place ' . theid . ' line=' . line('.') . 
                    \ ' name=vcmark '.' buffer='.bufnr('%')
        else | exe 'silent! sign unplace ' . theid | en
    catch 
        call vc#utils#dbgmsg("At dosign", v:exception)
    endtry
endf

fun! vc#select#clearsigns()
    exec 'silent! sign unplace *'
endf

fun! vc#select#resign(dict)
    try
        if !g:vc_signs | retu vc#passed() | en
        call vc#select#clearsigns()
        call s:resign(a:dict)
    catch | call vc#utils#dbgmsg("At vc#select#resign", v:exception) | endt
    retu vc#nofltrclear()
endf
    
fun! s:resign(dict) 
    let brwsd = has_key(a:dict, 'browsed')
    let dobmrks = brwsd ? len(g:bmarks) : 0
    let dosel = len(s:selectd)

    if (dosel || dobmrks)
        let selectpaths = []
        for [key, dict] in items(s:selectd)
            call add(selectpaths, dict.path)
        endfor
        let scmdpost = ' name=vcmark buffer=' . bufnr('%')
        let bcmdpost = ' name=vcbook buffer=' . bufnr('%')
        let linenum = 1
        for line in getbufline(bufnr('%'), 1, 80)
            let [key, value] =  vc#utils#extractkey(line)
            let tkey = printf("%5d:", key)
            let line = substitute(line, "\*", "", "")
            let linenokey = substitute(line, tkey, "", "")

            if !brwsd 
                let dosel = s:resignselect(line, key, linenum, scmdpost, dosel)
            else
                let path = vc#utils#joinpath(a:dict.bparent, vc#utils#discardbinfo(linenokey))
                if index(selectpaths, path) >=0 
                    exe 'silent! sign place ' . key . ' line=' . linenum . scmdpost
                    let dosel -= 1
                endif
                let path = vc#utils#strip(path)
                if has_key(g:bmarks, path)
                    exe 'silent! sign place ' . g:bmarks[path] . ' line=' . linenum . bcmdpost
                    let dobmrks -= 1
                endif
            endif
            if (dosel == 0 && dobmrks == 0) | break | en
            let linenum += 1
        endfor
        unlet! selectpaths
    endif
endf

fun! s:resignselect(line, key, linenum, cmdpost, selcnt)
    if !has_key(s:selectd, a:key) | retur a:selcnt | en
    let selectdline = '\V' . substitute(s:selectd[a:key].line, '\\', '\\\\', 'g')
    if matchstr(a:line, '\V'.substitute(selectdline, "*", "", "")) == ""  | retur a:selcnt | en
    exe 'silent! sign place ' . a:key . ' line=' . a:linenum . a:cmdpost
    retu a:selcnt - 1
endf

fun! s:signbmark(theid, isadd)
    try
        if !g:vc_signs | retu | en
        let theid = matchstr(a:theid, "\\d\\+")
        if a:isadd | exe 'silent! sign place ' . theid . ' line=' . line('.') . 
                    \ ' name=vcbook '.' buffer='.bufnr('%')
        else | exe 'silent! sign unplace ' . theid | en
    catch 
        call vc#utils#dbgmsg("At signbmark", v:exception)
    endtry
endf
"2}}}
"1}}}
