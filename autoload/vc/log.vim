"===============================================================================
" File:         autoload/vc/log.vim
" Description:  VC Log
" Author:       Juneed Ahamed
"===============================================================================

"vc#log {{{1

fun! vc#log#logops() "{{{2
    retu { 
        \ "\<Enter>"  :{"bop":"<enter>", "dscr": vc#utils#difffiledscr("Enter"), "fn":'vc#gopshdlr#openfile', "args":['vc#act#diff']},
        \ g:vc_ctrlenterkey :{"bop":g:vc_ctrlenterkey_buf, "dscr":vc#utils#openfiledscr(g:vc_ctrlenterkey_dscr), "fn":'vc#gopshdlr#openfile', "args":['vc#act#efile']},
        \ "\<C-v>"    :{"bop":"<c-v>", "fn":'vc#gopshdlr#openfile', "args":['vc#act#vs']},
        \ "\<C-w>"    :{"bop":"<c-w>", "fn":'vc#gopshdlr#togglewrap'},
        \ "\<C-u>"    :{"bop":"<c-u>", "fn":'vc#stack#pop'},
        \ "\<C-a>"    :{"bop":"<c-a>", "fn":'vc#log#affectedfiles'},
        \ "\<C-i>"    :{"bop":"<c-i>", "fn":'vc#gopshdlr#info'},
        \ "\<C-y>"    :{"bop":"<c-y>", "fn":'vc#gopshdlr#cmd'},
        \ "\<C-t>"     :{"bop":"<c-t>", "fn":'vc#stack#top'},
        \ g:vc_selkey : {"bop":g:vc_selkey_buf, "fn":'vc#gopshdlr#select'},
        \ }
endf
"2}}}

"Log {{{2
fun! vc#log#Log(bang, ...)
    try
        call vc#init()
        let disectd = vc#argsdisectlst(a:000, "all")
        if exists('b:vc_path') && disectd.target ==# b:vc_path
            retu vc#log#logs(a:bang, b:vc_path, disectd.cargs, 'vc#winj#populateJWindow', 0, disectd.forcerepo)
        endif
    catch
        let ldict = vc#dict#new("Log")
        call vc#dict#adderr(ldict, 'Failed ', v:exception)
        retu vc#winj#populateJWindow(ldict)
        unlet! ldict
    endtry
    call vc#log#logs(a:bang, disectd.target, disectd.cargs, 'vc#winj#populateJWindow', 1, disectd.forcerepo)
endf

fun! vc#log#logs(bang, target, cargs, populatecb, needLCR, forcerepo)
    let [entries, menus, errmsg, cargs, needLCR, cache] = [[], [], "", a:cargs, a:needLCR, 0]

    let ldict = vc#dict#new("Log")
    try
        let ldict.meta = vc#repos#meta(a:target, a:forcerepo)
        let cargs = cargs == "vc_stop_for_args" ?
                    \ vc#cmpt#prompt(ldict.meta.repo, "log", "log.cmdops") : cargs
        let logops = vc#repos#call(ldict.meta.repo, 'log.ops')

        if matchstr(cargs, '-cache') != ""
            let cargs = substitute(cargs,  "-cache", "", "")
            let cache = g:vc_log_cache == 1 ? 1: 0
        endif

        let logtitleargd = {"meta": ldict.meta, "needLCR": needLCR, "cache": cache, "soc": needLCR}
        let logtitle = vc#repos#call(ldict.meta.repo, 'log.title', logtitleargd)
        let logargsd = {"meta": ldict.meta, "cargs": cargs, "cache": cache}
        let [entries, ldict.meta.cmd] = vc#repos#call(ldict.meta.repo, 'log.rtrv', logargsd)
        unlet! logargsd

        if empty(entries)
            call vc#dict#adderrup(ldict, "Nothing here : ", ldict.meta.cmd)
        else
            call vc#dict#addentries(ldict, 'logd', entries, logops)
        endif

        if vc#repos#hasop(ldict.meta.repo, 'log.menu')[0] == vc#passed()
            let argsd = {"entity": ldict.meta.repoUrl, "meta": ldict.meta}
            let [menus, errmsg] = vc#repos#call(ldict.meta.repo, 'log.menu', argsd)
            if !empty(menus)
                call vc#dict#addentries(ldict, 'menud', menus, vc#gopshdlr#menuops())
            endif
        endif

        if len(errmsg) > 0 
            call vc#dict#adderr(ldict, errmsg, "")
        endif

        call s:addtotitle(ldict, logtitle, 0)
        call vc#stack#push('vc#log#logs', ["", a:target, cargs, 
                    \ 'vc#winj#populate', 0, a:forcerepo])
    catch
        call vc#dict#adderrup(ldict, 'Failed ', v:exception)
    endtry

    if exists('b:vc_revision')
        let ldict['callback_when_populated'] = ['vc#log#findandsetcursor', b:vc_revision]
        if a:bang == "!"
            exec "bd!"
        endif
    endif
    call call(a:populatecb, [ldict])
    retu vc#passed()
endf

fun! vc#log#findandsetcursor(revision)
    try
        let matchedat = match(getline(1, "$"), '\v\c:'. a:revision)
        if matchedat >= 0 | call cursor(matchedat + 1, 0) | en
    catch | endt
    "catch | call vc#utils#dbgmsg("At findandsetcursor", v:exception) | endt
endf
"2}}}

"callbacks {{{2
fun! vc#log#affectedfiles(argsd)
    try
        let [adict, akey] = [a:argsd.dict, a:argsd.key]
        let [title, revision] = ["", ""]
        let entity = filereadable(adict.meta.fpath) || isdirectory(adict.meta.fpath) ? 
                    \ adict.meta.fpath : adict.meta.entity
        let slist = []
        
        if !vc#select#exists(akey)
            let sargsd = vc#gopshdlr#sargsd(adict.meta, akey, adict.logd.contents[akey].line,
                        \ entity, adict.logd.contents[akey].revision, "")
           call vc#select#add(sargsd)
        endif

        let [revisionA, revisionB] = ["", ""]
        for [key, sdict] in items(vc#select#dict())
            if sdict.revision != ""
                if revisionA == "" | let revisionA = sdict.revision | cont | en
                if revisionB == "" | let revisionB = sdict.revision | cont | en
            endif
        endfor

        let relpath = fnamemodify(entity, ':.')
        let relpath = relpath == "" ? "." : relpath 

        if revisionA != "" && revisionB != ""
            let title = revisionB . ':' . revisionA . '@' .  relpath
            let [slist, adict.meta.cmd] = vc#repos#call(adict.meta.repo, "affectedfilesAcross", adict.meta, revisionA, revisionB)
        else 
            let revision = adict.logd.contents[akey].revision
            let branch = ""
            if vc#repos#hasop(adict.meta.repo, "frmtbranchname")[0] == vc#passed()
                let branch = vc#repos#call(adict.meta.repo, "frmtbranchname", adict.meta.branch)
            endif
            let title = branch . revision . '@' . relpath
            let [slist, adict.meta.cmd] = vc#repos#call(adict.meta.repo, "affectedfiles", adict.meta, revision)
        endif
        call vc#select#clear()
        retu vc#gopshdlr#displayaffectedfiles(adict, title, slist, revision)
    catch
        call vc#utils#dbgmsg("At vc#log#affectedfiles", v:exception)
    endtry
endf
"2}}}

fun! s:addtotitle(ldict, msg, prefix) "{{{2
    try | let a:ldict.title = a:prefix == 1 ?  a:msg. ' '. a:ldict.title : 
                \ a:ldict.title. ' ' . a:msg
    catch | endtry
endf
"2}}}
"1}}}

