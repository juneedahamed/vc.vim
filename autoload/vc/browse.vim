"===============================================================================
" File:         autoload/vc/browse.vim
" Description:  VC Browser
" Author:       Juneed Ahamed
"===============================================================================

"vc#browse.vim {{{1

"vars  and key mappings{{{2
fun! vc#browse#ops()
   retu { 
       \ "\<Enter>": {"bop":"<enter>", "fn":'vc#browse#digin', "args":[0, 0]},
       \ g:vc_ctrlenterkey : {"bop":g:vc_ctrlenterkey_buf, "dscr":vc#utils#digrecdescr(g:vc_ctrlenterkey_dscr), "fn":'vc#browse#digin', "args":[1]},
       \ "\<C-u>"  : {"bop":"<c-u>", "fn":'vc#browse#digout'},
       \ "\<C-n>"  : {"bop":"<c-n>", "fn":'vc#browse#newfile', "dscr": "Ctrl-n:Create new file"},
       \ "\<C-h>"  : {"bop":"<c-h>", "dscr":'C-h:Home', "fn":'vc#browse#root'},
       \ "\<C-o>"  : {"bop":"<c-o>", "fn":'vc#gopshdlr#openfltrdfiles', "args":['vc#act#efile']},
       \ "\<C-v>"  : {"bop":"<c-v>", "fn":'vc#gopshdlr#openfile', "args":['vc#act#vs']},
       \ "\<C-d>"  : {"bop":"<c-d>", "fn":'vc#gopshdlr#openfile', "args":['vc#act#diff']},
       \ "\<C-l>"  : {"bop":"<c-l>", "fn":'vc#browse#logs'},
       \ "\<C-b>"  : {"bop":"<c-b>", "fn":'vc#gopshdlr#book'},
       \ "\<C-t>"  : {"bop":"<c-t>", "fn":'vc#stack#top'},
       \ "\<C-i>"  : {"bop":"<c-i>", "fn":'vc#browse#browseinfo'},
       \ "\<C-a>"  : {"bop":"<c-a>", "fn":'vc#browse#browseinfolist'},
       \ "\<C-r>"  : {"bop":"<c-r>", "fn":'vc#browse#refresh'},
       \ "\<C-k>"  : {"bop":"<c-k>", "dscr":'C-k:CheckOut', "fn":'vc#browse#checkout'},
       \ "\<C-z>"  : {"bop":"<c-z>", "fn":'vc#gopshdlr#commit'},
       \ "\<C-g>"  : {"bop":"<c-g>", "fn":'vc#gopshdlr#add'},
       \ "\<C-p>"  : {"bop":"<c-p>", "dscr":'C-p:Paste :Copy selected files/dirs', "fn":'vc#browse#copy_move', "args":['cp']},
       \ "\<C-x>"  : {"bop":"<c-x>", "dscr":'C-x:Move selected files/dirs', "fn":'vc#browse#copy_move', "args":['mv']},
       \ "\<C-j>"  : {"bop":"<c-j>", "fn":'vc#browse#status'},
       \ g:vc_selkey : {"bop":g:vc_selkey_buf, "fn":'vc#gopshdlr#select'},
       \ }
endf
"2}}}

"Browse commands {{{2
fun! vc#browse#Menu()
    try
        call vc#init()
        call vc#browse#menu('vc#winj#populateJWindow')
    catch 
        let bdict = vc#dict#new("Browser")
        call vc#dict#adderrup(bdict, 'Failed ', v:exception)
        call vc#winj#populateJWindow(bdict)
        call vc#utils#dbgmsg('At vc#Browse', v:exception)
        call bdict.clear()
        unlet! bdict
    endtry
endf

fun! vc#browse#SVNRepo(...)
    try
        call vc#init()
        let disectd = vc#argsdisectlst(a:000, "onlydirs")
        let disectd.target = vc#utils#strip(disectd.target)

        if disectd.target == "/" 
            let disectd.target = vc#svn#reporoot()
        elseif vc#utils#localFS(disectd.target)
            let disectd.target = vc#svn#url(fnamemodify(vc#utils#fnameescape(disectd.target), ':h'))
        else
            let disectd.target = vc#utils#fnameescape(disectd.target == "" || disectd.target == "." ?
                    \ vc#svn#url(getcwd()) : disectd.target)
        endif
        call vc#browse#browse(disectd.target, "", 0, 0, 'vc#winj#populateJWindow', "-svn", "")
    catch
        let bdict = vc#dict#new("Browser")
        call vc#dict#adderr(bdict, 'Failed ', v:exception)
        call vc#winj#populateJWindow(bdict)
        unlet! bdict
    endtry
endf

fun! vc#browse#Local(recursive, ...)
    try
        call vc#init()
        let disectd = vc#argsdisectlst(a:000, "all")
        let path = vc#utils#fnameescape(disectd.target == "." || !isdirectory(disectd.target) ? getcwd() : disectd.target)
        call vc#browse#browse(path, "", 0, a:recursive, 'vc#winj#populateJWindow', disectd.forcerepo, "")
    catch
        call vc#utils#dbgmsg("At vc#browse#Local", v:exception)
        let bdict = vc#dict#new("Browser")
        call vc#dict#adderr(bdict, 'Failed ', v:exception)
        call vc#winj#populateJWindow(bdict)
        unlet! bdict
    endtry
endf
"2}}}

"menu and handlers {{{2
fun! vc#browse#menu(populatecb)
    let bdict = vc#dict#new("VC Browser Menu")
    call bdict.setmeta(vc#utils#blankmeta())

    call vc#dict#addentries(bdict, 'menud',
                \  [vc#dict#menuitem('Repository', 'vc#browse#repomenucb', "")], {})
    call vc#dict#addentries(bdict, 'menud',
                \ [vc#dict#menuitem('Working Copy/Current Dir', 'vc#browse#localmenucb', "")], {})
    call vc#dict#addentries(bdict, 'menud',
                \ [vc#dict#menuitem('MyList', 'vc#mylist#menucb', "")], {})
    call vc#dict#addentries(bdict, 'menud',
                \ [vc#dict#menuitem('BookMarks', 'vc#bookmarks#menucb', "")], {})
    call vc#dict#addentries(bdict, 'menud',
                \ [vc#dict#menuitem('Buffer', 'vc#buffer#menucb', "")], {})
    
    let menuops = { 
                \ "\<Enter>": {"bop":"<enter>", "fn":'vc#browse#menuhandler'},
                \ g:vc_ctrlenterkey  : {"bop":g:vc_ctrlenterkey_buf, "fn":'vc#browse#menuhandler', "args":["recursive"]},
                \ "\<C-u>"  : {"bop":"<c-u>", "fn":'vc#stack#pop'},
                \ "\<C-t>"  : {"bop":"<c-t>", "fn":'vc#stack#top'},
                \ }

    call vc#dict#addops(bdict, 'menud', menuops)
    call vc#stack#push('vc#browse#menu', ['vc#winj#populate'])
    call call(a:populatecb, [bdict])
endf
"2}}}

"menu handlers {{{2
fun! vc#browse#menuhandler(argsd)
    let [adict, akey] = [a:argsd.dict, a:argsd.key]
    retu call(adict.menud.contents[akey].callback, [a:argsd])
endf

fun! vc#browse#repomenucb(argsd)
    try
        let [adict, akey] = [a:argsd.dict, a:argsd.key]
        let svnurl = vc#svn#url(getcwd())
        call adict.setmeta(vc#svn#meta(svnurl))
        let entity = adict.meta.entity
        let recursive = len(a:argsd.opt) > 0 && a:argsd.opt[0] ==# 'recursive' ? 1 : 0
        let args = s:_browseargs(entity, "", 0, recursive, 'vc#winj#populate', "-svn", "")
        retu vc#browse#_browse(args)
    catch
        call vc#utils#dbgmsg("At vc#browse#repomenucb", v:exception)
        call vc#utils#showerr("Failed the current dir/file " .
                    \ "May not be a valid svn entity")
    endtry
endf

fun! vc#browse#localmenucb(argsd)
    try
        let [adict, akey] = [a:argsd.dict, a:argsd.key]
        call adict.setmeta(vc#repos#meta(getcwd(), ""))
        let fpath = adict.meta.fpath
        if fpath == "" | let fpath = getcwd() | en
        let recursive = len(a:argsd.opt) > 0 && a:argsd.opt[0] ==# 'recursive' ? 1 : 0
        let args = s:_browseargs(fpath, "", 0, recursive, 'vc#winj#populate', "", "")
        retu vc#browse#_browse(args)
    catch
        retu vc#utils#showerr("Failed the current dir/file " .
                    \ "May not be a valid svn entity")
    endtry
endf
"2}}}

" ops callbacks {{{2
fun! vc#browse#newfile(argsd) 
    try
        let [adict, akey, aline] = [a:argsd.dict, a:argsd.key, a:argsd.line]
        let path = vc#utils#joinpath(adict.bparent, aline)
        let meta = vc#repos#meta(path, adict.forcerepo)
        let [newpath, newfilename] = [adict.bparent, ""]

        if vc#utils#iserror(aline)
            let newfilename = s:newfilenameonerr(adict)
        elseif vc#utils#isdir(path)
            let newpath = path
        elseif vc#utils#isdir(fnamemodify(vc#utils#fnameescape(path), ':h'))
            let newpath = fnamemodify(vc#utils#fnameescape(path), ':h')
        else
            let newpath = path
        endif

        if newfilename == "" 
            let prompt = " Enter filename to create, Ctrl-c to cancel :"
            let answer = vc#utils#joinpath(newpath, "/" )
        else
            let prompt = " Will create file edit to change, Enter to continue, Ctrl-c to cancel:"
            let answer = vc#utils#joinpath(newpath, newfilename)
        endif
       
        let dir = fnamemodify(vc#utils#expand(answer), ":h")
        let warnmsg = vc#utils#isdir(dir) ? "" :  "      New Dir Will be Created\n"

        let createfilenamepath = vc#cmpt#browsepath(warnmsg, prompt, answer)
        if createfilenamepath == "" | retu | en

        let dir = fnamemodify(vc#utils#expand(createfilenamepath), ":h")
        if exists("*mkdir") && !vc#utils#isdir(dir) 
           call mkdir(dir, "p")
        endif
        let argsd = {
                    \ "meta": vc#fs#meta(createfilenamepath),
                    \ "path": createfilenamepath,
                    \ "onwritecallback": 'vc#browse#newfileonwrite',
                    \ "cwd": vc#utils#fnameescape(getcwd()),
                    \ "bparent":  vc#utils#fnameescape(adict.bparent),
                    \ }
        unlet! b:vc_onwrite_done
        call vc#act#newfile(argsd)
    catch
        call vc#utils#dbgmsg("At vc#browse#newfile", v:exception)
    finally
        unlet! argsd
        retu vc#fltrclearandexit()
    endtry
    retu vc#passed()
endf

fun! s:newfilenameonerr(thedict)
    let newfilename = vc#prompt#str()
    try
        let [clines, displaylines] = a:thedict.lines()
        call filter(clines, 'matchstr(v:val, "/$") == "/"')
        let splits = vc#prompt#str()
        for i in range(len(vc#prompt#str())-2, 0, -1)
            let [lines, fregex] = vc#fltr#filter(clines, splits[ : i ], 1)
            if len(lines) > 0
                let [result, parent] = vc#utils#extractkey(lines[0])
                if parent != "" 
                    retu vc#utils#joinpath(parent, splits[ i+1 : ])
                endif
            endif
        endfor
    catch | endtry
    "catch | let x = input(v:exception) | endtry
    retu newfilename 
endf

fun! vc#browse#newfileonwrite(argsd)
    if exists("b:vc_onwrite_done") | retu | en
    let b:vc_onwrite_done = 1
    try
        if vc#caop#iscached("wc", a:argsd.cwd)
            let entries = [fnamemodify(vc#utils#bufabspath(), ':.')]
            call vc#caop#cacheappend("wc", a:argsd.cwd, entries)
        endif
        if a:argsd.cwd != a:argsd.bparent && vc#caop#iscached("wc", a:argsd.bparent)
            let entries = [substitute(vc#utils#bufabspath(), "^". a:argsd.bparent, "", "")]
            call vc#caop#cacheappend("wc", a:argsd.bparent, entries)
        en
    catch
        call vc#utils#dbgmsg("At vc#browse#newfileonwrite", v:exception)
    endtry
endf

fun! vc#browse#browseinfolist(argsd) 
    try
        let meta = vc#repos#meta(a:argsd.dict.bparent, a:argsd.dict.forcerepo)
        call vc#repos#call(meta.repo, 'browse.infolist', a:argsd)
    catch
        call vc#utils#dbgmsg("At vc#browse#browseinfolist", v:exception)
    endtry
    retu vc#nofltrclear()
endf

fun! vc#browse#browseinfo(argsd) 
    try
        let [adict, akey, aline] = [a:argsd.dict, a:argsd.key, a:argsd.line]
        let path = vc#utils#joinpath(adict.bparent, aline)
        let meta = vc#repos#meta(path, adict.forcerepo)
        retu vc#repos#call(meta.repo, 'browse.info', a:argsd)
    catch
        call vc#utils#dbgmsg("At vc#browse#browseinfo", v:exception)
    endtry
endf

fun! vc#browse#status(argsd) 
    try
        let [adict, akey, aline] = [a:argsd.dict, a:argsd.key, a:argsd.line]
        try
            let bargs = s:_browseargs(adict.bparent, '', 0, adict.brecursive,
                        \ 'vc#winj#populate', adict.forcerepo, aline)
            call vc#stack#clear()
            call vc#stack#push('vc#browse#_browse', [bargs])
        catch 
            call vc#utils#dbgmsg("Exception at vc#browse#status", v:exception)
        endtry

        let path = vc#utils#joinpath(adict.bparent, aline)
        let meta = vc#repos#meta(path, adict.forcerepo)
        let sargs = {"meta":meta, "cargs": ""}
        retu vc#status#_status('vc#winj#populate', sargs)
    catch
        call vc#utils#dbgmsg("At vc#browse#status", v:exception)
    endtry
endf

fun! vc#browse#copy_move(argsd)
    try
        let [adict, aline, aop] = [a:argsd.dict, a:argsd.line, a:argsd.opt[0]]
        let topath = vc#utils#joinpath(adict.bparent, aline)

        let forcerepo = has_key(adict, 'forcerepo') ? adict.forcerepo : ''
        let[result, entries, meta] = s:makelistforcopyormove(forcerepo, topath, aop == "cp" ? "copy" : "move")
        if result == vc#failed() | retu vc#nofltrclear() | en

        let opcmd =  aop == "cp" ? "browse.copycmd" : "browse.movecmd"
        let opcargs = aop == "cp" ? "copy.cmdops" : "move.cmdops"
        let cargs = vc#cmpt#prompt(meta.repo, opcmd, opcargs) 
        let theargsd = {"meta": meta, "flist": entries, "topath" : vc#utils#fnameescape(topath), "cargs": cargs}
        let [result, cmd] = vc#repos#call(meta.repo, opcmd, theargsd)
        
        if result == vc#passed() && cmd != ""
            let [result, response] = vc#utils#execshellcmduseexec(cmd, 0)
        endif

        if result == vc#passed()
            call vc#select#clear()
            call vc#select#resign(adict)
            call feedkeys("\<C-r>")
        endif
        retu result
    catch 
        call vc#utils#showerr(v:exception) 
    endtry
    retu vc#failed()
endf

fun! vc#browse#checkout(argsd)
    try
        let [adict, aline] = [a:argsd.dict, a:argsd.line]
        let meta = vc#repos#meta(adict.bparent, "")
        let frompath = vc#utils#joinpath(adict.bparent, aline)
        let argsd = {"frompath" : frompath, "dict":adict}
        retu vc#repos#call(meta.repo, 'browse.checkout', argsd)
    catch 
        call vc#utils#showerr(v:exception)
    endtry
    retu vc#passed()
endf

fun! vc#browse#root(argsd)
    try
        let bparent = a:argsd.dict.bparent
        let brecursive = a:argsd.dict.brecursive
        let forcerepo = a:argsd.dict.forcerepo
        let entity = ""

        if vc#utils#isdir(bparent) 
            let wcrp = vc#svn#workingcopyrootpath()
            let entity = (wcrp != bparent) ? wcrp : expand("$HOME")
        endif

        if entity == "" && vc#svn#issvndir(getcwd())
            let entity = vc#svn#reporoot()
        endif

        if entity == "" | let entity = expand("$HOME") | en
        call vc#browse#browse(entity, "", 0, brecursive, 'vc#winj#populate', forcerepo, "")
        retu vc#passed()
    catch 
       call vc#utils#dbgmsg("At vc#browse#root", v:exception)
    endtry
    retu vc#failed()
endf

fun! vc#browse#affectedfiles(argsd)
    let [adict, aline] = [a:argsd.dict, a:argsd.line]
    try
        let args = s:_browseargs(adict.bparent, '', 0, 0, 'vc#winj#populate', adict.forcerepo, aline)
        call vc#stack#push('vc#browse#_browse', [args])
    catch 
        call vc#utils#dbgmsg("Exception at vc#browse#affectedfiles", v:exception)
    endt

    try
        let url = vc#utils#joinpath(adict.bparent, aline)
        let meta = vc#repos#meta(url, adict.forcerepo)
        let lcr = vc#repos#call(meta.repo, 'lcr', meta)
        if lcr == ""
            retu vc#utils#showerr("May Not be a valid repositry entity")
        endif
        let title = lcr . '@' . url
        let argsd = { "revision" : lcr, "entity": url, "meta": meta}
        
        let [slist, adict.meta.cmd] = vc#repos#call(meta.repo, 'affectedfiles', argsd)
        retu vc#gopshdlr#displayaffectedfiles(adict, title, slist, "")
    catch
        call vc#utils#dbgmsg("At vc#browse#affectedfiles", v:exception)
    endtry
endf

fun! vc#browse#refresh(argsd)
    try
        let [adict, aline] = [a:argsd.dict, a:argsd.line]
        let newurl = adict.bparent
        call vc#caop#cls("wc", newurl)
        call vc#caop#cls("repo", newurl)
        let argsd_ = s:_browseargs(newurl, adict.bparent, 0, 1, 'vc#winj#populate', adict.forcerepo, aline)
        retu vc#browse#_browse(argsd_)
    catch 
        call vc#utils#dbgmsg("At vc#browse#refresh", v:exception)
    finally
        unlet! argsd_
    endtry
endf

fun! vc#browse#logs(argsd)
    try
        let [adict, aline] = [a:argsd.dict, a:argsd.line]
        try
            let args = s:_browseargs(adict.bparent, '', 0, adict.brecursive, 'vc#winj#populate', adict.forcerepo, aline)
            call vc#stack#push('vc#browse#_browse', [args])
        catch 
            call vc#utils#dbgmsg("Exception at vc#browse#logs", v:exception)
        endtry

        let path = vc#utils#joinpath(adict.bparent, aline)
        call vc#log#logs("", path, "vc_stop_for_args", 'vc#winj#populate', 0, adict.forcerepo)
    catch 
        call vc#utils#showerr("Failed, Exception")
    endtry
    retu vc#passed()
endf

fun! s:makelistforcopyormove(forcerepo, tourl, op)
    let thefiles = map(values(vc#select#dict()), 'v:val.path')

    if len(thefiles) <= 0
        call vc#utils#showerr("Nothing copied/selected")
        return [vc#failed(), [], {}]
    endif

    let fromlst = vc#utils#filesbywrd(thefiles, a:forcerepo, 0, [])
    let tolst = vc#utils#filesbywrd([a:tourl,], a:forcerepo, 0, [])
    return vc#utils#makelistforcopyormove(fromlst, tolst, a:op)
endf
"2}}}

"helpers {{{2
fun! s:_browseargs(entity, parent, ignore_dirs, recursive, populatecb, forcerepo, cline)
    retu {
                \ 'entity' : a:entity, 
                \ 'parent' : a:parent,
                \ 'igndirs' : a:ignore_dirs,
                \ 'recursive' : a:recursive,
                \ 'populatecb' : a:populatecb,
                \ 'forcerepo' : a:forcerepo,
                \ 'cline' : a:cline,
                \ }
endf

fun! s:findandsetcursor(subdir, topdir)
    try
        let displayed_dir = substitute(a:subdir, a:topdir, "", "")
        let pattern = '\v\c:'. fnameescape(displayed_dir)
        let matchedat = match(getline(1, "$"), pattern)
        if matchedat >= 0 | call cursor(matchedat + 1, 0) | en
    catch | endt
    "catch | call vc#utils#dbgmsg("At findandsetcursor", v:exception) | endt
endf
"2}}}

fun! vc#browse#browse(path, parent, ignore_dirs, recursive, populatecb, forcerepo, cline)  "{{{2
    let args = s:_browseargs(a:path, a:parent, a:ignore_dirs, a:recursive, a:populatecb, a:forcerepo, a:cline)
    call vc#stack#push('vc#browse#browse', 
                \ [a:path, a:parent, a:ignore_dirs, a:recursive, 'vc#winj#populate', a:forcerepo, a:cline])
    call vc#browse#_browse(args)
endf

fun! vc#browse#_browse(args)
    let result = vc#passed()
    let bdict = vc#dict#new("Browser")
    try
        let entity = a:args.entity
        let bdict.meta = vc#repos#meta(entity, a:args.forcerepo)

        let bdict.bparent = entity
        let bdict.title = fnamemodify(bdict.meta.fpath, ':.')
        if bdict.title == "" | let bdict.title = bdict.meta.fpath | en
        if has_key(bdict.meta, "branch") && bdict.meta.branch != ""
            let bdict.title = "[" . bdict.meta.branch . "] " . bdict.title
        endif

        let bdict.brecursive = a:args.recursive
        let bdict.forcerepo = a:args.forcerepo

        let entries = vc#repos#call(bdict.meta.repo, "browse.entries", entity, bdict)
        if empty(entries)
            if has_key(a:args, 'parent') && a:args.parent != ""
                let args = a:args
                let args.url = a:args.parent
                let args.parent = bdict.bparent
                let args.populatecb = 'vc#winj#populate'
                call vc#stack#push('vc#browse#_browse', [args])
                call vc#dict#adderrup(bdict, "No files listed for ", entity)
            else
                call vc#dict#adderrup(bdict, "No files listed for ", entity)
            endif
            try
                call vc#dict#addops(bdict, 'error', vc#utils#newfileop())
                call vc#dict#addops(bdict, 'error', {"\<Enter>": {"bop":"<enter>", "fn":'vc#browse#digin', "args":[0, 0]}})
            catch|endtry
            let result = vc#failed()
        else
            call vc#dict#addbrowseentries(bdict, 'browsed', entries, vc#browse#ops())
        endif
        unlet! entries
    catch
        call vc#dict#adderrup(bdict, 'Failed ', v:exception)
        call vc#utils#dbgmsg("At vc#browse#_browse", v:exception)
        let result = vc#failed()
    endtry
    call call(a:args.populatecb, [bdict])
    if a:args.cline != "" && entity != "" 
        call s:findandsetcursor(a:args.cline, entity)
    endif
    unlet! bdict
    retu result
endf

fun! vc#browse#digin(argsd)
    try
        let [adict, akey, aline, aopt] = [a:argsd.dict, a:argsd.key, a:argsd.line, a:argsd.opt]
        if vc#utils#iserror(aline) | retu vc#browse#newfile(a:argsd) | en
        if matchstr(aline, g:vc_info_str) != "" | retu | en

        let arec = len(a:argsd.opt) > 0 ? a:argsd.opt[0] : 0
        let path = vc#utils#joinpath(adict.bparent, aline)
        if vc#utils#isdir(path) || vc#svn#issvndir(path)
            let args = s:_browseargs(path, adict.bparent, 0, arec, 'vc#winj#populate', adict.forcerepo, "")
            retu vc#browse#_browse(args)
        else
            if !filereadable(path) "example bookmarked svn repo url
                let adict.meta = vc#repos#meta(path, "")
            endif
            if !vc#select#exists(a:argsd.key) | call vc#gopshdlr#select(a:argsd) | en
            "1 is passed from BrowseBuffer to close on open
            if len(a:argsd.opt) >= 2 && a:argsd.opt[1]  
                call vc#select#openfiles('vc#act#efile', g:vc_max_open_files)
                retu vc#fltrclearandexit()
            else
                retu vc#select#openfiles('vc#act#efile', g:vc_max_open_files)
            endif
        endif
    catch 
       call vc#utils#dbgmsg("At vc#browse#digin", v:exception)
    endtry
    retu vc#failed()
endf

fun! vc#browse#digout(argsd)
    try
        let [adict, akey, aline] = [a:argsd.dict, a:argsd.key, a:argsd.line]
        let path = vc#utils#getparent(adict.bparent)
        let is_repo = !vc#utils#localFS(path)
        if (is_repo && !vc#svn#validurl(path)) || (!is_repo && path == "//")
            call vc#dict#adderrup(adict, "Looks, like reached tip of the SVN/FS", "")
            call vc#winj#populate(adict) | retu 0
        endif
        let args = s:_browseargs(path, adict.bparent, 0, adict.brecursive, 'vc#winj#populate', adict.forcerepo, "")
        let result = vc#browse#_browse(args)
        call s:findandsetcursor(adict.bparent, path)
        retu result
    catch 
        call vc#utils#dbgmsg("Exception at digout", v:exception)
    endtry
    retu vc#failed()
endf
"2}}}

"1}}}
