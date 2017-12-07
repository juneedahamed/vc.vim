"===============================================================================
" File:         autoload/vc/gopshdlr.vim
" Description:  Handle generic call backs/operations
" Author:       Juneed Ahamed
"===============================================================================

"Key mappings  menuops {{{2
fun! vc#gopshdlr#menuops()
   retu { "\<Enter>" : {"bop":"<enter>", "fn":'vc#gopshdlr#handlemenuops'},
           \ "\<C-u>" : {"bop":"<c-u>", "fn":'vc#stack#pop'},
           \ "\<C-t>" : {"bop":"<c-t>", "fn":'vc#stack#top'},
           \ }
endf
"2}}}

fun! vc#gopshdlr#handlemenuops(argsd) "{{{2
    let [adict, akey] = [a:argsd.dict, a:argsd.key]
    if akey == 'err' | retu vc#nofltrclear() | en
    retu call(adict.menud.contents[akey].callback, [a:argsd])
endf
"2}}}

fun! vc#gopshdlr#togglewrap(...) "{{{2
    setl wrap! 
    retu vc#nofltrclear()
endf
"2}}}

fun! vc#gopshdlr#sargsd(meta, key, line, path, revision, opt) "{{{2
    retu {
        \ "meta": a:meta, 
        \ "key": a:key,
        \ "line": a:line,
        \ "path": a:path,
        \ "revision": a:revision,
        \ "opt": a:opt,
        \ }
endf
"2}}}

fun! vc#gopshdlr#openfile(argsd) "{{{2
    let [adict, akey, aline, aopt] = [a:argsd.dict, a:argsd.key,
                \ a:argsd.line, a:argsd.opt]
    if akey == 'err' | retu vc#nofltrclear() | en

    if has_key(adict, 'logd') && has_key(adict.logd.contents, akey)
        let sargsd = vc#gopshdlr#sargsd(adict.meta, akey, aline,
                    \ adict.meta.entity,  adict.logd.contents[akey].revision, aopt)
        call vc#select#add(sargsd)
        if adict.meta.isdir | retu vc#log#affectedfiles(a:argsd)|en

    elseif has_key(adict, 'browsed')
        if !vc#select#exists(akey) | call vc#gopshdlr#select(a:argsd) | en

    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        "D is for delete in git
        if index(["INFO", "P", "D"], adict.statusd.contents[akey].modtype) >=0 | retu | endif
        if !vc#utils#isdir(adict.statusd.contents[akey].fpath)
            if !vc#select#exists(akey) | call vc#gopshdlr#select(a:argsd) | en
        endif
    endif

    retu vc#select#openfiles(a:argsd.opt[0], g:vc_max_open_files)
endf
"2}}}

fun! vc#gopshdlr#openfltrdfiles(argsd) "{{{2
    let [adict, akey] = [a:argsd.dict, a:argsd.key]
    if akey == 'err' | retu vc#nofltrclear() | en
    call vc#gopshdlr#selectfltrd(a:argsd)
    retu vc#select#openfiles(a:argsd.opt[0], g:vc_max_open_files)
endf
"2}}}

fun! vc#gopshdlr#changes(argsd) "{{{2
    let [adict, akey, aline, aopt] = [a:argsd.dict, a:argsd.key, a:argsd.line, a:argsd.opt]
    if akey == 'err' | retu vc#nofltrclear() | en
    if has_key(adict, 'logd') && has_key(adict.logd.contents, akey)
        let revision = adict.logd.contents[akey].revision
        let new_argsd = {
                    \ 'meta': adict.meta,
                    \ 'revision': revision,
                    \ 'cargs': '',
                    \ 'op': 'Diff: ' . revision,
                    \ 'addops': 1,
                    \ }
        call vc#stack#setnavline()
        retu vc#act#handleNoParseCmd(new_argsd, 'diff.changes')
    endif
endf
"2}}}

fun! vc#gopshdlr#select(argsd) "{{{2
    "select line for log, browse and status dict
    let [adict, akey, aline, aopt] = [a:argsd.dict, a:argsd.key,
                \ a:argsd.line, a:argsd.opt]
    if akey == 'err' | retu vc#nofltrclear() | en
    if vc#select#remove(akey) | retu vc#nofltrclear() | en
    
    let sargsd = vc#gopshdlr#sargsd(adict.meta, akey, aline, adict.meta.entity,  "", aopt)

    if has_key(adict, 'logd') && has_key(adict.logd.contents, akey)
        let sargsd.line = adict.logd.contents[akey].line
        let sargsd.revision = adict.logd.contents[akey].revision
        retu vc#select#add(sargsd)

    elseif has_key(adict, 'browsed')
        if matchstr(aline, g:vc_info_str) != "" | retu vc#nofltrclear() | en
        let sargsd.path = vc#utils#joinpath(adict.bparent, aline)
        if has_key(adict, "grep") | let sargsd.grep = adict.grep | en
        if !filereadable(sargsd.path)
            let sargsd.meta = vc#repos#meta(sargsd.path, "")
        endif
        retu vc#select#add(sargsd)

    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        if adict.statusd.contents[akey].modtype == "INFO" | retu vc#nofltrclear() | endif
        let sargsd.revision = s:useaffectedrevison(adict, aopt)
        if sargsd.revision != "" && has_key(adict.statusd.contents[akey], 'repoUrl')
            let sargsd.path = adict.statusd.contents[akey].repoUrl
        else
            let sargsd.path = adict.statusd.contents[akey].fpath
        endif
        retu vc#select#add(sargsd)
    endif
    retu vc#nofltrclear()
endf
"2}}}

fun! vc#gopshdlr#selectfltrd(argsd) "{{{2
    let [adict, akey, aline, aopt] = [a:argsd.dict, a:argsd.key, a:argsd.line, a:argsd.opt]
    if akey == 'err' | retu vc#nofltrclear() | en
    if has_key(adict, 'browsed')
        retu s:selectfltrdbrowsed(a:argsd)
    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        retu s:selectfltrdstatusd(a:argsd)
    endif
    retu vc#nofltrclear()
endf

fun! s:selectfltrdbrowsed(argsd)
    let [adict, akey, aline, aopt] = [a:argsd.dict, a:argsd.key,
                \ a:argsd.line, a:argsd.opt]
    for i in range(1, line('$'))
        let [key, line] = vc#utils#extractkey(getline(i))
        if matchstr(line, g:vc_info_str) != "" | cont | en
        if vc#select#remove(key) | cont | en
        if key != "err" && line != ""
            let pathurl = vc#utils#joinpath(adict.bparent, line)
            if vc#utils#isdirdirtycheck(pathurl) | cont | en
            let sargsd = vc#gopshdlr#sargsd(adict.meta, key, aline, pathurl,  "", aopt)
            if !filereadable(pathurl)
                let sargsd.meta = vc#repos#meta(pathurl, "")
            endif

            if has_key(adict, "grep") | let sargsd.grep = adict.grep | en
            call vc#select#add(sargsd)
        endif
    endfor
    retu vc#nofltrclear() 
endf

fun! s:selectfltrdstatusd(argsd)
    let [adict, akey, aline, aopt] = [a:argsd.dict, a:argsd.key,
                \ a:argsd.line, a:argsd.opt]
    let keys =  vc#utils#keyscurbufflines()
    if len(keys) <= 0 | retu vc#passed() | en
    let affectedrevision = s:useaffectedrevison(adict, aopt)
    call vc#select#dict()
    for key in keys
        if vc#select#remove(key) == vc#passed() | cont | endif
        if has_key(adict.statusd.contents, key)
            if adict.statusd.contents[key].modtype == "INFO" | cont | endif
            let sargsd = vc#gopshdlr#sargsd(adict.meta, key, 
                        \ adict.statusd.contents[key].line, adict.statusd.contents[key].fpath,
                        \ affectedrevision, aopt)
            call vc#select#add(sargsd)
        endif
    endfor
    retu vc#nofltrclear()
endf
"2}}}

fun! s:useaffectedrevison(adict, options)  "{{{2
    if len(a:options) > 1 && a:options[1] == "revisioned" && has_key(a:adict, "affectedrevision") 
        "If Ctrl-Enter for affected files open command
        call vc#select#addrevisionforall(a:adict.affectedrevision)
        return a:adict.affectedrevision
    endif
    retu vc#prompt#openrevisioned() ? a:adict.affectedrevision : ""
endf
"2}}}

fun! vc#gopshdlr#selectall(argsd) "{{{2
    let [adict, akey, aline, aopt] = [a:argsd.dict, a:argsd.key, a:argsd.line, a:argsd.opt]
    if akey == 'err' | retu vc#nofltrclear() | en
    if has_key(adict, 'browsed')
        call s:selectfltrdbrowsed(a:argsd)
    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        call s:selectfltrdstatusd(a:argsd)
    endif
    call vc#select#resign(a:argsd.dict)
    retu vc#nofltrclear()
endf
"2}}}

fun! vc#gopshdlr#book(argsd) "{{{2
    let [adict, akey, aline] = [a:argsd.dict, a:argsd.key, a:argsd.line]
    if akey == 'err' | retu vc#nofltrclear() | en
    if has_key(adict, 'browsed')
        let path = fnamemodify(vc#utils#joinpath(adict.bparent, aline), ":p")
        call vc#select#book(path)
    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        let path = fnamemodify(adict.statusd.contents[akey].fpath, ":p")
        call vc#select#book(path)
    endif
    retu vc#nofltrclear()
endf
"2}}}

fun! vc#gopshdlr#diffinfo(repo, revision, entity) "{{{2
    let info = ""
    if exists("b:vc_revision") && vc#repos#hasop(a:repo, 'diff.infocmds')[0] == vc#passed()
        let meta = vc#repos#meta(a:entity, a:repo)
        let argsd = {"meta": meta, "revision": b:vc_revision}
        let cmdstuple = vc#repos#call(a:repo, 'diff.infocmds', argsd)
        for [title, cmd] in cmdstuple
            let info = info ."\n----" . title . "-------------------\n"
            try
                let info = info . vc#utils#execshellcmd(cmd)
            catch | endtry
        endfor
    endif
    retu info != "" ? vc#utils#showconsolemsg(info, 1) : vc#passed()
endf
"2}}}

fun! vc#gopshdlr#info(argsd) "{{{2
    let [adict, akey, aline] = [a:argsd.dict, a:argsd.key, a:argsd.line]
    if akey == 'err' | retu vc#nofltrclear() | en
    let info = ""
    try
        if has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
            let target =  adict.statusd.contents[akey].fpath
            let meta = vc#repos#meta(target, adict.meta.repo)
            let info = vc#repos#call(meta.repo, "info", {"meta" : meta})
        elseif has_key(adict, 'logd') && has_key(adict.logd.contents, akey)
            let argsd = {"meta": adict.meta, "revision": adict.logd.contents[akey].revision }
            let info = vc#repos#call(adict.meta.repo, "log.info", argsd)
        elseif has_key(adict, 'browsed') 
            let target = vc#utils#joinpath(adict.bparent, aline)
            let meta = vc#repos#meta(target, adict.forcerepo)
            let info = vc#repos#call(meta.repo, "info", {"meta" : meta})
        endif
        if info != "" | call vc#utils#showconsolemsg(info, 1) | en
        retu vc#nofltrclear() 
    catch
        call vc#utils#showerr(v:exception)
    endtry
    retu vc#nofltrclear() 
endf
"2}}}

fun! vc#gopshdlr#displayaffectedfiles(dict, title, slist, affectedrevision) "{{{2
    try
        let title = a:dict.meta.repo . " Affected :" . a:title
        let sdict = vc#dict#new(title, {'meta' : deepcopy(a:dict.meta)})
        let sdict.affectedrevision = a:affectedrevision
        if empty(a:slist)
            call vc#dict#adderrup(sdict, 'No affected files found ..' , '' )
        else
            let aops = vc#repos#call(a:dict.meta.repo, 'affectedfiles.ops')
            call extend(aops, vc#utils#topop())
            call extend(aops, vc#utils#upop())
            call extend(aops, vc#utils#revisionrequiredop())
            call vc#dict#addentries(sdict, 'statusd', a:slist, aops)
        endif
        call vc#stack#push('vc#gopshdlr#displayaffectedfiles', 
                    \ [a:dict, a:title, a:slist, a:affectedrevision])
        call vc#winj#populate(sdict)
    catch
        call vc#utils#dbgmsg("At vc#gopshdlr#affectedfiles", v:exception)
    endtry
    retu vc#passed()
endf
"2}}}

fun! vc#gopshdlr#cmd(argsd) "{{{2
    let [adict, akey] = [a:argsd.dict, a:argsd.key]
    if akey == 'err' | retu vc#nofltrclear() | en
    let x = has_key(adict, "meta") && has_key(adict.meta, "cmd") ? 
                \ vc#utils#showconsolemsg(adict.meta.cmd, 1) : 0
    retu vc#nofltrclear() 
endf
"2}}}

fun! vc#gopshdlr#showcommits(dict, svncmd, title) "{{{2
    let sdict = vc#dict#new(a:title, {'meta' : deepcopy(a:dict.meta)})
    let [slist, sdict.meta.cmd] = vc#svn#summary(a:svncmd)
    if empty(slist)
        call vc#dict#adderrtop(sdict, 'No commits found ..' , '' )
    else
        let ops = vc#status#statusops() | call extend(ops, vc#utils#topop())
        call vc#dict#addentries(sdict, 'statusd', slist, ops)
    endif
    call vc#winj#populate(sdict)
endf
"2}}}

fun! vc#gopshdlr#commit(argsd) "{{{2
    let [adict, akey, aline] = [a:argsd.dict, a:argsd.key, a:argsd.line]
    if akey == 'err' | retu vc#nofltrclear() | en

    if !vc#select#exists(akey) | call vc#gopshdlr#select(a:argsd) | en

    let g:vc_files_to_commit = s:addorcommitfiles(a:argsd, "commit", "commit.cmdops")
    if len(g:vc_files_to_commit) > 0
        call vc#commit#prepcommit()
        retu vc#fltrclearandexit() "clear filter, feed esc
    endif
    retu vc#nofltrclear()
endf

fun! vc#gopshdlr#add(argsd) 
    let [adict, akey, aline] = [a:argsd.dict, a:argsd.key, a:argsd.line]
    if akey == 'err' | retu vc#nofltrclear() | en
    if !vc#select#exists(akey) | call vc#gopshdlr#select(a:argsd) | en

    let g:vc_files_to_commit = s:addorcommitfiles(a:argsd, "add", "add.cmdops")
    if len(g:vc_files_to_commit) > 0
        call vc#add#prepadd()
        retu vc#fltrclearandexit() "clear filter, feed esc
    endif
    retu vc#nofltrclear()
endf

fun! s:addorcommitfiles(argsd, cmd, cmdops)
    let [adict, akey, aline] = [a:argsd.dict, a:argsd.key, a:argsd.line]
    let addorcommitfileslst = []
    if has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        let thefiles = map(values(vc#select#dict()), 'v:val.path')
        if len(thefiles) > 0
            let argsd = {"meta": adict.meta, "files": thefiles}
            call add(addorcommitfileslst, argsd)
        endif
    elseif has_key(adict, 'browsed') 
        let parent = adict.bparent == "" ? "." : adict.bparent
        let forcerepo = has_key(adict, 'forcerepo') ? adict.forcerepo : ''
        let thefiles = map(values(vc#select#dict()), 'v:val.path')
        let addorcommitfileslst = vc#utils#filesbywrd(thefiles, forcerepo, 1, ["-fs",])
    else
        call vc#utils#showerr("Not supported from here")
    endif
    let cargs = vc#cmpt#prompt(adict.meta.repo, a:cmd, a:cmdops)
    if len(cargs) > 0 && len(addorcommitfileslst) > 0
        let argslst = split(cargs)
        let comments =  vc#argsremoveparam(argslst, "-m", 0, 1)
        let cargs = join(argslst)
        for elem in addorcommitfileslst | let elem["cargs"] = cargs | endfor
        for elem in addorcommitfileslst | let elem["comments"] = comments | endfor
    endif
    retu addorcommitfileslst
endf
"2}}}

fun! vc#gopshdlr#closebuffer(argsd) "{{{2
    let [adict, akey, aline] = [a:argsd.dict, a:argsd.key, a:argsd.line]
    let curbufname = a:argsd.opt[0]
    if has_key(adict, 'browsed') 
        let buffile = vc#utils#joinpath(adict.bparent, aline)
        try
            if a:argsd.opt[0] == buffile | retu | en
            exec "bd " fnameescape(buffile)
            call vc#buffer#_browse('vc#winj#populate', curbufname)
        catch | call vc#utils#dbgmsg("At vc#gopshdlr#closebuffer: ", v:exception) | endt
    endif
endf
"2}}}

fun! vc#gopshdlr#removesticky(...) "{{{2
    if !vc#prompt#isploop()
        call feedkeys("\<C-s>")
    endif
endf
"2}}}


