"===============================================================================
" File:         autoload/vc/svn.vim
" Description:  SVN Repository
" Author:       Juneed Ahamed
"===============================================================================

" subversion svn support {{{1

"Key mappings ops for svn {{{2
fun! vc#svn#affectedops()
   return {
       \ "\<Enter>"  :{"bop":"<enter>", "fn":'vc#gopshdlr#openfile', "args":['vc#act#efile']},
       \ g:vc_ctrlenterkey : {"bop":g:vc_ctrlenterkey_buf, "dscr":vc#utils#openfiledscr(g:vc_ctrlenterkey_dscr), "fn":'vc#gopshdlr#openfile', "args":['vc#act#efile', "revisioned"]},
       \ "\<C-o>"    :{"bop":"<c-o>", "fn":'vc#gopshdlr#openfltrdfiles', "args":['vc#act#efile']},
       \ "\<C-d>"    :{"bop":"<c-d>", "fn":'vc#gopshdlr#openfile', "args":['vc#act#diff']},
       \ "\<C-i>"    :{"bop":"<c-i>", "fn":'vc#gopshdlr#info'},
       \ "\<C-w>"    :{"bop":"<c-w>", "fn":'vc#gopshdlr#togglewrap'},
       \ "\<C-y>"    :{"bop":"<c-y>", "fn":'vc#gopshdlr#cmd'},
       \ "\<C-b>"    :{"bop":"<c-b>", "fn":'vc#gopshdlr#book'},
       \ "\<C-z>"    :{"bop":"<c-z>", "fn":'vc#gopshdlr#commit'},
       \ "\<C-g>"    :{"bop":"<c-g>", "fn":'vc#gopshdlr#add'},
       \ "\<C-t>"    :{"bop":"<c-t>", "fn":'vc#stack#top'},
       \ "\<C-u>"    :{"bop":"<c-u>", "fn":'vc#stack#pop'},
       \ "\<C-l>"    :{"bop":"<c-l>", "fn":'vc#status#logs'},
       \ g:vc_selkey : {"bop":g:vc_selkey_buf, "fn":'vc#gopshdlr#select'},
       \ }
endf

fun! vc#svn#logops()
    let logops = vc#log#logops()
    call extend(logops, { 
        \ "\<C-h>"     : {"bop":"<c-h>", "fn":'vc#svn#showcommits', "args":[":HEAD"]},
        \ "\<C-p>"     : {"bop":"<c-p>", "fn":'vc#svn#showcommits', "args":[":PREV"]},
        \ }
        \)
    retu logops
endf
"2}}}

fun! vc#svn#meta(entity) "{{{2
    let metad = {}
    let metad.repo = "-svn"
    let metad.entity = vc#utils#fnameescape(a:entity)

    let metad.isdir = vc#svn#issvndir(metad.entity)
    let metad.fpath = vc#utils#fnameescape(a:entity == "" ? getcwd() : a:entity)
    let metad.wrd = vc#svn#workingroot()
    try
        let metad.repoUrl = vc#svn#url(metad.entity)
    catch 
        let metad.repoUrl = ""
    endtry

    let metad.local = vc#utils#localFS(a:entity)
    let metad.branch = ""
    retu metad
endf
"2}}}

fun! vc#svn#inrepodir(path)  "{{{2
    if vc#svn#validurl(a:path) | retu vc#passed() | en
    let [status, path] = vc#svn#fetchrootdir(a:path)
    retu status
endf
"2}}}

fun! vc#svn#validurl(target) "{{{2
    let cmd = 'svn info --non-interactive ' . a:target
    try
        let shellout = vc#utils#execshellcmd(cmd)
    catch | retu vc#failed() | endtry
    retu vc#passed()
endf
"2}}}

fun! vc#svn#iscmd(cmd) "{{{2
    return len(matchstr(a:cmd, "^svn ")) > 3
endf
"2}}}

fun! vc#svn#issvndir(absfpath) "{{{2
    try
        let cmd = 'svn info --non-interactive ' . a:absfpath
        let nodekindline = s:matchshelloutput(cmd, "^Node Kind:")
        if len(nodekindline) > 0
            retu matchstr(nodekindline, "directory") != ""
        endif
    catch | retu vc#failed() | endtry
    retu vc#failed()
endf
"2}}}

fun! vc#svn#istrunk(URL) "{{{2
    if vc#svn#isbranch(a:URL) | retu 0 | en
    retu g:p_turl != '' && stridx(a:URL, g:p_turl, 0) == 0
endf
"2}}}

fun! vc#svn#isbranch(URL) "{{{2
    retu len(filter(copy(g:p_burls), 'stridx(a:URL, v:val,0) == 0')) > 0
endf
"2}}}

fun! vc#svn#isautherr(response) "{{{2
    return matchstr(a:response, g:vc_auth_errno) == g:vc_auth_errno || 
                \ matchstr(a:response, g:vc_auth_errmsg) > 0 
endf
"2}}}

fun! vc#svn#fmtauthinfo(cmd) "{{{2
    if g:vc_auth_disable | retu a:cmd | en

    if len(g:vc_username) == 0 || len(g:vc_password) == 0
        let shellout = system(a:cmd)
        if v:shell_error != 0 && vc#svn#isautherr(shellout)
            let [status, shellout] = vc#svn#exec_with_auth(a:cmd)
        else
            retu a:cmd
        endif
        if status == vc#failed() | retu a:cmd | en
    endif
    let repstr = "svn --username=". g:vc_username . " --password=" . g:vc_password . " "
    retu substitute(a:cmd, "^svn ", repstr, "")
endf
"2}}}

fun! vc#svn#exec_with_auth(cmd) "{{{2
    let [cmd, status] = [a:cmd, vc#failed()]
    while 1
        redr
        let g:vc_username = vc#utils#input("Username for repository", "", "> ") | redr
        let g:vc_password = vc#utils#inputsecret("Password for repository", "> ")
        let repstr = "svn --username=". g:vc_username . " --password=" . g:vc_password . " "
        let cmd = substitute(a:cmd, "^svn ", repstr, "")
        let shellout = system(cmd)
        if v:shell_error != 0 && vc#svn#isautherr(shellout)
            let [g:vc_username, g:vc_password]= ["",""]
            call vc#utils#showconsolemsg("Failed authentication, try again[y/n] : ", 0)
            if vc#utils#getchar() ==? "y"  | cont | en
        else
            let status = vc#passed()
        endif
        break
    endwhile
    retu [status, shellout]
endf
"2}}}

fun! vc#svn#infolist(argsd) "{{{2
    let [parent, lines] = [a:argsd.dict.bparent, a:argsd.dict.lines()]
    let parsekeys = ["^Revision: ", "^Last Changed Rev: ", "^Last Changed Author: ", "^Last Changed Date: "]

    let bdict = vc#dict#new("Browser")
    let bdict.title = a:argsd.dict.title 
    let bdict.brecursive = a:argsd.dict.brecursive
    let bdict.bparent = a:argsd.dict.bparent
    let bdict.meta = a:argsd.dict.meta
    let bdict.forcerepo = a:argsd.dict.forcerepo
    let bdict.infolist = !a:argsd.dict.infolist

    if !bdict.infolist
        retu vc#browse#browse(bdict.bparent, "", 0,  bdict.brecursive, 'vc#winj#populate', bdict.forcerepo, "")
    endif

    let entries = []
    call add(entries, g:vc_info_str ."PATH -> REVISION -> LCR -> AUTHOR -> DATE")
    echo "Fetching SVN Data ...."
    "for line in lines[0][:200]
    for i in range(1, line('$'))
        let line = getline(i)
        let [key, path] = vc#utils#extractkey(line)
        let fpath = vc#utils#joinpath(parent, path)
        let [cmd, values] = ['svn info --non-interactive ' . fpath, []]
        let values = s:matchshelloutputs(cmd, parsekeys) 
        call add(entries, path . " -> " . join(values, " -> "))
    endfor
    call vc#dict#addbrowseentries(bdict, 'browsed', entries, vc#browse#ops())
    call call('vc#winj#populate', [bdict])
endf


fun! s:matchshelloutputs(cmd, parsekeys)
    let values = []
    try
        let svnout = vc#utils#execshellcmd(a:cmd)
        for key in a:parsekeys
            let lines = filter(split(svnout, "\n"), 'matchstr(v:val, key) != ""')
            if len(lines) >= 1
                let value = substitute(lines[0], key, "", "")
                call add(values, value)
            else
                call add(values, "-")
            endif
        endfor
    catch
        let values = []
        for pkey in a:parsekeys
            call add(values, "-")
        endfor
    endtry
    retu values
endf
"2}}}

fun! vc#svn#info(argsd) "{{{2
    let cmd = 'svn info --non-interactive ' . a:argsd.meta.entity
    retu vc#utils#execshellcmd(cmd)
endf
"2}}}

fun! vc#svn#infodiffcmds(argsd) "{{{2
    retu  [["Revision Info:", 'svn log -r ' . a:argsd.revision]]
endf
"2}}}

fun! vc#svn#infolog(argsd) "{{{2
    let result = ""
    let revision = get(a:argsd, "revision", "")
    let entity = a:argsd.meta.entity
    if revision != ""
        let entity = revision . "\ " . entity
    endif

    try
        let cmd = 'svn info --non-interactive -' . entity
        let result = result . vc#utils#execshellcmd(cmd)
        let cmd = 'svn log -v --non-interactive -' . entity
        let result = result . vc#utils#execshellcmd(cmd)
    catch
        call vc#utils#dbgmsg("vc#svn#infolog", v:exception)
        let result = v:exception
    endtry
    retu result
endf
"2}}}

fun! vc#svn#logstoponcopy(entity) "{{{2
    try
        "let cmd = 'svn log --non-interactive --stop-on-copy -q ' . a:entity
        let cmd = 'svn log --non-interactive --stop-on-copy -r1:HEAD -l1  -q ' . a:entity
        let shellout = vc#utils#execshellcmd(cmd)
        let shellist = reverse(split(shellout, '\n'))
        for i in range(0, len(shellist)-1)
            let curline = shellist[i]
            if len(matchstr(curline, '^r')) > 0 
                let contents = split(curline, '|')
                let revision = vc#utils#strip(contents[0])
                retu revision
            endif
        endfor
    catch:
        call vc#utils#dbgmsg("vc#svn#logstoponcopy", v:exception)
    endtry
    retu ""
endf
"2}}}

fun! vc#svn#addcmd(argsd) "{{{2
    let cargs = has_key(a:argsd, "cargs") ? a:argsd.cargs : ""
    retu "svn add --non-interactive " . cargs . " " . join(a:argsd.files, " ")
endf
"2}}}

fun! vc#svn#commitcmd(commitlog, commitfileslist, argsd) "{{{2
    let filestocommit = join(a:commitfileslist, " ")
    if a:commitlog == "!"
        let cmd = "svn ci --non-interactive -m \"\" " . get(a:argsd, "cargs", "") . "  " .filestocommit
    else
        let cmd = "svn ci --non-interactive -F " . a:commitlog . " ". filestocommit
    endif
    retu cmd
endf

fun! vc#svn#commitcmdops(...)
    retu [ "-m",]
endf
"2}}}

fun! vc#svn#domove(argsd)  "{{{2
    try
        let [tourl, flist] = [a:argsd.topath, a:argsd.flist]

        let alllocals = filter(copy(flist), 'vc#utils#localFS(v:val) > 0')
        let is_local =  len(alllocals) == len(flist) ? 1 : 0
        let is_repo = len(alllocals) == 0 ? 1 : 0

        if !is_local && !is_repo
            call vc#utils#showerr("Cannot move from working copy to repo or vice-versa")
            retu [vc#failed(), ""]
        endif

        if is_repo
            call vc#utils#showerr("Repository move not supported yet")
            retu [vc#failed(), ""]
        endif

        if is_local
            call add(flist, tourl)
            retu s:movewc(flist)
        endif
    catch 
        call vc#utils#dbgmsg("At vc#svn#domove", v:exception)
    endt
    retu [vc#failed(), ""]
endf

fun! s:movewc(urls) 
    let urlstr = join(a:urls, " ")
    let cmd = "svn mv --non-interactive " . urlstr
    retu [vc#passed(), cmd]
endf
"2}}}

fun! vc#svn#docopy(argsd)  "{{{2
    try
        let [tourl, flist] = [a:argsd.topath, a:argsd.flist]

        let alllocals = filter(copy(flist), 'vc#utils#localFS(v:val) > 0')
        let is_local =  len(alllocals) == len(flist) ? 1 : 0
        let is_repo = len(alllocals) == 0 ? 1 : 0

        if !is_local && !is_repo
            call vc#utils#showerr("Cannot copy from working copy to repo or vice-versa")
            retu [vc#failed(), ""]
        endif

        if is_repo || is_local
            call add(flist, tourl)
            retu call(is_repo ? 'vc#cpy#repo' : 'vc#svn#copywc', [flist])
        endif
    catch 
        call vc#utils#dbgmsg("At vc#svn#docopy", v:exception)
    endt
    retu [vc#failed(), ""]
endf
"2}}}

fun! vc#svn#copyrepo(commitlog, urls) "{{{2
    let urlstr = join(a:urls, " ")
    if a:commitlog == "!"
        let cmd = "svn cp --non-interactive -m \"\" " . urlstr
    else
        let cmd = "svn cp --non-interactive -F " . a:commitlog . " " . urlstr
    endif
    echo "Please wait sent command waiting for response ..."
    retu [vc#passed(), vc#utils#execshellcmd(cmd)]
endf
"2}}}

fun! vc#svn#copywc(urls) "{{{2
    let cmd = "svn cp --non-interactive " . join(a:urls, " ")
    retu [vc#passed(), cmd]
endf
"2}}}

fun! vc#svn#checkout(argsd) "{{{2
    let frompath = a:argsd.frompath

    if vc#svn#issvndir(frompath) && !vc#utils#isdir(frompath)
        let title = " SVN CHECKOUT : " . frompath
        let descr = "   Applicable Args are \n" .
                    \ "   . = " . getcwd() . ",\n" .
                    \ "   Enter = NoArgs,\n".
                    \ "   Esc = Abort  OR \n" .
                    \ "   type the directory name\n"
        let dest = vc#utils#input(title, descr, "Args : "  )
        if dest != "\<Esc>" 
            try
                let frompath = substitute(frompath, "/$", "", "g")
                let cmd = "svn co --non-interactive " . frompath . " " . dest

                echohl Title | echo "" | echon "Will execute : " 
                echohl Search | echon cmd  | echohl None
                echohl Question | echo "" | echon "y to continue, Any to cancel : " 
                echohl None

                if vc#utils#getchar() ==? "y"
                    call vc#utils#showconsolemsg("Performing chekout, please wait ..", 0)
                    call vc#utils#execshellcmd(cmd)
                    call vc#utils#showconsolemsg("Checked out", 1)
                endif
            catch | call vc#utils#showerr(v:exception) | endt
        endif
    else 
        call vc#utils#showerr("Should be repository dir to checkout")
    endif
    retu vc#passed()
endf
"2}}}

fun! vc#svn#url(absfpath) "{{{2
    let fileurl = a:absfpath
    let cmd = 'svn info --non-interactive ' . a:absfpath
    let urllines = s:matchshelloutput(cmd, "^URL")
    if len(urllines) > 0
        let fileurl = substitute(urllines[0], 'URL: ', '', '')
        let fileurl = substitute(fileurl, '\n', '', '')
    endif
    retu vc#utils#fnameescape(fileurl)
endf
"2}}}

fun! vc#svn#workingroot() "{{{2
    retu len(g:p_wcrp) == 0 || vc#utils#isdir(g:p_wcrp) == 0 ?
                \ vc#svn#workingcopyrootpath() : g:p_wcrp
endf
"2}}}

fun! vc#svn#workingcopyrootpath() "{{{2
    let cmd = 'svn info --non-interactive ' . getcwd()
    try
        let svnout = vc#utils#execshellcmd(cmd)
        let lines = s:matchshelloutput(cmd, "^Working Copy Root Path")
        if len(lines) >= 1
            let tokens = split(lines[0], ':')
            if len(tokens) >= 2
                let tmpworkingdir = vc#utils#strip(join(tokens[1:], ':'))
                if vc#utils#isdir(tmpworkingdir) | retu vc#utils#fnameescape(tmpworkingdir) | en
            endif
        endif
    catch
    endtry
    retu vc#utils#fnameescape(getcwd())
endf
"2}}}

fun! vc#svn#reporoot() "{{{2
    let cmd = 'svn info --non-interactive ' . vc#utils#fnameescape(getcwd())
    try
        let svnout = vc#utils#execshellcmd(cmd)
        let lines = s:matchshelloutput(cmd, "^Repository Root:")
        if len(lines) >= 1
            let root = substitute(lines[0], "^Repository Root:", "", "")
            let root = vc#utils#strip(root)
            retu root
        endif
    catch
    endtry
    retu getcwd()
endf
"2}}}

fun! vc#svn#rootversion(workingcopydir) "{{{2
    let cmd = 'svn log --non-interactive -l 1 ' . 
                \ a:workingcopydir . ' | grep ^r'
    let shellout = vc#utils#execshellcmd(cmd)
    let revisionnum = vc#utils#strip(split(shellout, '|')[0])
    retu revisionnum
endf
"2}}}

fun! vc#svn#validatesvnurlinteractive(sysURL) "{{{2
    if len(a:sysURL) == 0 || !vc#svn#validurl(a:sysURL)
        echohl WarningMsg | echo 'Failed to construct svn url: '
                    \ | echo a:sysURL | echohl None
        let inputurl = input('Enter URL : ')
        if len(inputurl) > 1 && vc#svn#validurl(inputurl)
            retu inputurl
        endif
    else
        retu a:sysURL
    endif
    throw 'Invalid URL'
endf 
"2}}}

fun! vc#svn#fetchrootdir(path)   "{{{2
    let [maxtries, path, visitedpath] = [10, a:path, ""]
    if !isdirectory(path) | let path = fnamemodify(path, ":h") | en
    while maxtries > 0 && vc#utils#isdir(path) && path != visitedpath
        if vc#svn#validurl(path) | retu [vc#passed(), path] | endif
        let [visitedpath, maxtries, path] = [path, maxtries - 1, vc#utils#fnameescape(fnamemodify(path, ":h"))]
    endwhile
    retu [vc#failed(), ""]
endf
"2}}}

fun! vc#svn#browseentries(path, argsd)   "{{{2
    let files_lister = !a:argsd.meta.local ? 'vc#svn#list' : 'vc#utils#lstfiles'
    retu call(files_lister, [a:path, a:argsd.brecursive, 0])
endf
"2}}}

fun! vc#svn#list(entity, rec, ignore_dirs)  "{{{2
    let entries = []
    if a:rec
        let shelloutlist = s:globsvnrec(a:entity)
    else
        let cmd = 'svn list --non-interactive ' . a:entity
        let shellout = vc#utils#execshellcmd(cmd)
        let shelloutlist = split(shellout, '\n')
        unlet! shellout
    endif

    for line in  shelloutlist
        if line == "" | con | en
        if len(matchstr(line, g:p_ign_fpat)) != 0 | con | en
        if a:ignore_dirs == 1 && vc#utils#isdir(line) | con | en
        call add(entries, vc#utils#fnameescape(line))
    endfor
    unlet! shelloutlist
    retu entries
endf

fun! s:globsvnrec(entity)
    let leaf = substitute(a:entity, vc#utils#getparent(a:entity), "", "")
    let burl = a:entity

    let [result, ffiles] = vc#caop#fetch("repo", burl)
    if result | retu ffiles | en

    let [files, tdirs] = [[], [""]]
    while len(files) < g:vc_browse_repo_max_files_cnt && len(tdirs) > 0
        try
            let curdir = remove(tdirs, 0)
            call vc#utils#showconsolemsg("Fetching files from repo : " . curdir, 0)
            let furl = vc#utils#joinpath(burl, curdir)
            let cmd = 'svn list --non-interactive ' . vc#utils#fnameescape(furl)
            let flist = split(vc#utils#execshellcmd(cmd), "\n")
            let [tfiles, tdirs2] =  s:slicefilesanddirs(curdir, flist)
            call extend(files, tfiles)
            call extend(files, tdirs2)
            call extend(tdirs, tdirs2)
            unlet! flist tfiles tdirs2 
        catch
            "call vc#utils#dbgmsg("At globsvnrec", v:exception)
        endt
    endwhile
    unlet! tdirs

    call vc#caop#cache("repo", burl, files)
    retu files
endf

fun! s:slicefilesanddirs(curdir, flist)
    let [files, dirs] = [[], []]
    for entry in a:flist
        if len(matchstr(entry, g:p_ign_fpat)) != 0 | con | en
        call call('add', [vc#utils#isdirdirtycheck(entry) ? dirs : files, 
                    \ vc#utils#fnameescape(vc#utils#joinpath(a:curdir,entry))])
    endfor
    retu [files, dirs]
endf
"2}}}

fun! vc#svn#logtitle(argsd)  "{{{2
    let [title, soc_rev, cache] = [a:argsd.meta.entity, "", get(a:argsd, "cache", 0)]
    try 
        let path =  a:argsd.meta.repoUrl != "" ? a:argsd.meta.repoUrl : a:argsd.meta.fpath
        if cache == 1 && vc#caop#cachedlog("svn", path) 
            retu title . ":Cached"
        endif

        if g:vc_send_soc_command && get(a:argsd, "soc", 0) == 1
            let soc_rev = vc#svn#logstoponcopy(a:argsd.meta.entity)
            let soc_rev = " soc=" . soc_rev
        endif
    catch | endt

    let currev = s:currentrevision(a:argsd.meta)
    if currev != "" | let title = title . " rev=r" . currev . " "| en

    if a:argsd.needLCR
        let lastChngdRev = vc#svn#lastchngdrev(a:argsd.meta)
        let title = title . 'upstream=r' . lastChngdRev . soc_rev
    endif

    return title
endf
"2}}}

fun! vc#svn#logs(argsd) "{{{2
    let [meta, cargs, cache, shellist] = [a:argsd.meta, a:argsd.cargs, get(a:argsd, "cache", 0), []]
    try
        if matchstr(cargs, "-l") == ""
           let cargs = cargs . " -l " . g:vc_max_logs . " "
        endif
    catch | endtry
    
    let path =  meta.repoUrl != "" ? meta.repoUrl : meta.fpath
    if cache == 1
        let [iscached, shellist] = vc#caop#fetchlog("svn", path)
    endif

    let cmd = 'svn log --non-interactive ' . cargs . ' ' . path
    if len(shellist) <= 0
    let shellout = vc#utils#execshellcmd(cmd)
    let shellist = split(shellout, '\n')
    unlet! shellout
        if g:vc_log_cache == 1 | call vc#caop#cachelog("svn", path, shellist) | en
    endif

    let logentries = []
    let g:vc_logversions = []
    try
        for idx in range(0,  len(shellist)-1)
            let curline = shellist[idx]
            if len(matchstr(curline, '^--')) > 0
                let idx = idx + 1
                if idx < len(shellist)
                    let curline = shellist[idx]
                    if len(matchstr(curline, '^r')) > 0
                        let logentry = {}
                        let contents = split(curline, '|')
                        let revision = vc#utils#strip(contents[0])
                        call add(g:vc_logversions, revision)
                        let logentry.revision = revision
                        let logentry.line = revision . ' ' . join(contents[1:], '|')
                        let idx = idx + 1
                        while idx < len(shellist)
                            let curline = shellist[idx]
                            if len(matchstr(curline, '^--')) > 0 | break | en
                            let logentry.line = logentry.line . '|' . curline
                            let idx = idx + 1
                        endwhile
                        call add(logentries, logentry)
                    endif
                endif
            else
                let idx = idx + 1
            endif
        endfor
        unlet! shellist
    catch | endtry
    retu [logentries, cmd]
endf
"2}}}

fun! vc#svn#diff(argsd) "{{{2
    let diffwith = ""
    let url = vc#svn#url(a:argsd.meta.entity)
    let lcr = "r". vc#svn#lastchngdrev(a:argsd.meta)
    let logargsd = {"meta": a:argsd.meta, "cargs": "-l " . g:vc_max_logs}
    call vc#svn#logs(logargsd)
    unlet! logargsd
    let diffwith = lcr
    if a:argsd.bang == "!"
        let diffwith = len(g:vc_logversions) > 0 ? g:vc_logversions[0] : ''
        if diffwith == lcr && len(g:vc_logversions) > 1
            let diffwith = g:vc_logversions[1]
        endif 
    endif

    if a:argsd.revision != "" | let diffwith = a:argsd.revision | en
    call vc#act#diffme(a:argsd.meta.repo, diffwith, url, get(a:argsd, "bang", ""))
endf
"2}}}

fun! vc#svn#status(argsd) "{{{2
    let target = get(a:argsd.meta, 'entity', '.')
    let cargs = get(a:argsd, 'cargs', '')
    let cmd = 'svn st --non-interactive ' . cargs . ' ' . target
    let [entries, tdir] = vc#svn#summary(cmd)
    retu [cmd, entries]
endf
"2}}}

fun! vc#svn#summary(cmd) "{{{2
    let shellout = vc#utils#execshellcmd(a:cmd)
    let shelloutlist = split(shellout, '\n')
    unlet! shellout
    let statuslist = []
    for line in shelloutlist
        let tokens = split(line)
        if len(matchstr(tokens[len(tokens)-1], g:p_ign_fpat)) != 0 | cont | en
        if matchstr(line, "Status against") != "" | cont | en
        let statusentryd = {}
        let statusentryd.modtype = tokens[0]
        let statusentryd.fpath = vc#utils#parsefilefromstatus("", tokens)
        let statusentryd.line = line
        call add(statuslist, statusentryd)
    endfor
    unlet! shelloutlist
    retu [statuslist, a:cmd]
endf
"2}}}

fun! vc#svn#affectedfilesacross(meta, revisionA, revisionB) "{{{2
    let revisiondiff = a:revisionA.':'. a:revisionB
    let cmd = 'svn diff --summarize --non-interactive  -' . 
                \ revisiondiff . ' '. a:meta.entity
    retu vc#svn#summary(cmd)
endf
"2}}}

fun! vc#svn#affectedfiles(meta, revision) "{{{2
    let revision = matchstr(a:revision, "\\d\\+")
    let cmd = 'svn diff --summarize --non-interactive -c' . revision . ' ' . a:meta.entity
    retu vc#svn#summary(cmd)
endf
"2}}}

fun! s:currentrevision(meta) "{{{2
    let revision = ''
    try
        let cmd = 'svn info --non-interactive ' . a:meta.entity
        let find = '^Revision:'
        let lines = s:matchshelloutput(cmd, find)
        let revision = vc#utils#strip(substitute(lines[0], find, '', ''))
    catch | endtry
    retu revision
endf
"2}}}

fun! vc#svn#lastchngdrev(meta) "{{{2
    let lastChngdRev = ''
    try
        let cmd = 'svn info --non-interactive ' . a:meta.repoUrl
        let find = '^Last Changed Rev:'
        let lines = s:matchshelloutput(cmd, find)
        let lastChngdRev = vc#utils#strip(substitute(lines[0], find, '', ''))
    catch | endtry
    retu lastChngdRev
endf
"2}}}

fun! vc#svn#showcommits(argsd) "{{{2
    try
        let [adict, akey] = [a:argsd.dict, a:argsd.key]
        let aheadOrPrev = a:argsd.opt[0]
        let entity = filereadable(adict.meta.fpath) || isdirectory(adict.meta.fpath) ? 
                    \ adict.meta.fpath : adict.meta.entity
        let revision =  adict.logd.contents[akey].revision
        let svncmd = 'svn diff --non-interactive -' .revision . aheadOrPrev . 
                    \ ' --summarize ' . entity
        let title = 'VCDiff:'. revision . aheadOrPrev . " " . entity
        retu vc#gopshdlr#showcommits(a:argsd.dict, svncmd, title)
    catch
        call vc#utils#dbgmsg("At vc#svn#showcommits", v:exception)
    endtry
endf
"2}}}

fun! s:matchshelloutput(cmd, patt) "{{{2
    let svnout = vc#utils#execshellcmd(a:cmd)
    retu filter(split(svnout, "\n"), 'matchstr( v:val, a:patt) != ""')
endf
"2}}}

fun! vc#svn#revertcmd(argsd) 
    retu "svn revert " . a:argsd.cargs . " ". a:argsd.meta.fpath
endf

fun! vc#svn#diffcmd(argsd)  "{{{2
    let arevision = get(a:argsd, 'revision', '')
    let apath = get(a:argsd, 'path', '' )

    let fmt_revision = len(arevision) > 0 ? " -" . arevision : ""
    let cmd = "svn cat " . fmt_revision . ' '. apath
    let cmd = vc#svn#fmtauthinfo(cmd)
    retu cmd
endf
"2}}}

fun! vc#svn#opencmd(argsd)  "{{{2
    let arevision = get(a:argsd, 'revision', '')
    let apath = get(a:argsd, 'path', '' )

    if arevision == ""
        let cmd="svn cat " . apath
    else
        let cmd="svn cat -" . arevision . ' ' . apath
    endif
    retu vc#svn#fmtauthinfo(cmd)
endf
"2}}}

fun! vc#svn#blamecmd(argsd)  "{{{2
    let cmd="svn blame -v -x-w " . a:argsd.meta.entity
    retu vc#svn#fmtauthinfo(cmd)
endf
"2}}}

fun! vc#svn#statuscmdops(argsd) "{{{2
    retu ["-u", "-q", "--no-ignore", "--ignore-externals"]
endf
"2}}}

fun! vc#svn#logcmdops(argsd) "{{{2
    let rlist = ["-l", "--stop-on-copy"]
    if g:vc_log_cache == 1
        call add(rlist, "-cache")
    endif
    retu rlist
endf
"2}}}

fun! vc#svn#frmtbranchname(name)  "{{{2
    retu a:name
endf
"2}}}

fun! vc#svn#browse(key) "{{{2
    retu vc#browse#menu('vc#winj#populate')
endf
"2}}}

fun! vc#svn#logmenu(argsd)   "{{{2
    let [entity, datadict] = [a:argsd.entity, a:argsd.meta]
    let [menus, errmsg] = [[], ""]

    if vc#svn#istrunk(entity)
        call add(menus, vc#dict#menuitem("List Branches",
                    \'vc#svn#listtopbranchURLs', "trunk2branch"))

    elseif vc#svn#isbranch(entity)
        if g:p_turl != ''
            call add(menus, vc#dict#menuitem("List Trunk Files",
                        \'vc#svn#listfilesfrom', "branch2trunk"))
        endif
        call add(menus, vc#dict#menuitem("List Branches",
                    \ 'vc#svn#listtopbranchURLs', "branch2branch"))

    elseif exists('g:p_burls') && g:vc_warn_branch_log 
        let errmsg = 'Failed to get branches/trunk' .
                    \ ' use :help g:vc_branch_url or ' .
                    \ ' set g:vc_warn_branch_log=0 at .vimrc' . 
                    \ ' to disable this message'
    endif
    call add(menus, vc#dict#menuitem("Browse", 'vc#svn#browse', ''))
    retu [menus, errmsg]
endf
"2}}}

" svn branch/trunk listers {{{2
fun! vc#svn#listfilesfrom(argsd)
    let [adict, akey] = [a:argsd.dict, a:argsd.key]
    let contents = adict.menud.contents[akey]
    let ldict = vc#dict#new(adict.title, {"meta" : deepcopy(adict.meta)})
    try
        let newroot = contents.convert ==# 'branch2trunk' ? g:p_turl : adict.title . contents.title
        let [newurl, result] = s:converturl(adict.meta.repoUrl, newroot)
        if result == "browsedisplayed"  | retu "" | en

        let ldict.meta.entity = newurl
        let ldict.meta.repoUrl = newurl
        let ldict.title = newurl
        let logargsd = {"meta": ldict.meta, "cargs": "-l " . g:vc_max_logs}
        let [entries, ldict.meta.cmd] = vc#svn#logs(logargsd)
        unlet! logargsd
        call vc#dict#addentries(ldict, 'logd', entries, vc#svn#logops())
    catch
        call vc#utils#dbgmsg("At listFilesFrom", v:exception)
        call vc#dict#adderrup(ldict, 'Failed to construct svn url',' OR File does not exist')
    endtry
    call vc#winj#populate(ldict)
endf

fun! vc#svn#listtopbranchURLs(argsd)
    let [adict, akey] = [a:argsd.dict, a:argsd.key]
    let convert = adict.menud.contents[akey].convert
    let meta = deepcopy(adict.meta)
    let ldict = vc#dict#new("branches", {"meta" : meta})
    try
        for burl in g:p_burls
            call vc#dict#addentries(ldict, 'menud',
                        \ [vc#dict#menuitem(burl,'vc#svn#listbranches',
                        \ convert)], vc#gopshdlr#menuops())
        endfor
    catch
        call vc#utils#dbgmsg("At listTopBranchURLs", v:exception)
        call vc#dict#adderr(ldict, 'Failed ', v:exception)
        call vc#winj#populate(ldict)
        retu vc#failed()
    endtry
    call vc#winj#populate(ldict)
endf

fun! vc#svn#listbranches(argsd)
    let [adict, akey] = [a:argsd.dict, a:argsd.key]
    let entity = adict.menud.contents[akey].title
    let convert = adict.menud.contents[akey].convert
    let ldict = vc#dict#new(entity, {"meta" : adict.meta})
    try
        let svncmd = 'svn ls --non-interactive ' . entity
        let bstr = vc#utils#execshellcmd(svncmd)
        let blst = split(bstr, '\n')
        for branch in blst
            call vc#dict#addentries(ldict, 'menud', 
                        \ [vc#dict#menuitem(branch, 'vc#svn#listfilesfrom',
                        \ convert)], vc#gopshdlr#menuops())
        endfor
    catch
        call vc#dict#adderr(ldict, 'Failed ', v:exception)
        retu vc#winj#populate(ldict)
    endtry
    call vc#winj#populate(ldict)
    retu vc#passed()
endf

fun! s:converturl(furl, tonewroot)
    try
        let [fromlst, tolst] = [split(a:furl, '/\zs'), split(a:tonewroot, '/\zs')]
        if len(fromlst) < len(tolst) 
            retu s:displaybrowse(a:furl, a:tonewroot)
        endif
        
        let retlst = []
        for idx in range(0, len(tolst) -1)
            if fromlst[idx] == tolst[idx]
                call add(retlst, fromlst[idx])
            else
                call extend(retlst, tolst[idx :]) "Push rest of tourl
                let fromlst = fromlst[idx + 1 :] "idx + 1 as assuming it will be branch name
                break
            endif
        endfor

        while len(fromlst) > 0 && len(retlst) > 1
            let newurl = join(retlst, "") . join(fromlst, "")
            if vc#svn#validurl(newurl) | retu [newurl, "filefound"] | en
            let fromlst = fromlst[1:]
        endwhile

    catch | call vc#utils#dbgmsg("At s:converturl", v:exception) | endt
    retu s:displaybrowse(a:furl, a:tonewroot)
endf

fun! s:displaybrowse(fromURL, tonewroot)
    let root =  s:findroot(a:fromURL, a:tonewroot)
    if len(root) > 0 
        let filepath = substitute(a:fromURL, root, "", "") "Remove one element from from
        let filepath = join(split(filepath, '/\zs')[1:], "")
        call vc#utils#input("Failed to construct url, Will provide the browse to get to it",
                    \ a:tonewroot . 
                    \ "\nNavigate:<Ctr-u> or <Ctrl-Ent> or <Enter>, Log:<Ctrl-l>, Diff:<Enter>\n",
                    \ "Any <Enter> to continue : ")
        call vc#browse#browse(a:tonewroot, root, 0, 1, 'vc#winj#populate', "-svn", "")
    endif
    retu ["", "browsedisplayed"]
endf

fun! s:findroot(url1, url2)
    let lst1 = split(a:url1, '/\zs')
    let lst2 = split(a:url2, '/\zs')
    let root = []
    for idx in range(0, (len(lst1)<=len(lst2) ? len(lst1) : len(lst2)) - 1)
        if lst1[idx] == lst2[idx] | call add(root, lst1[idx]) | cont | en
        break
    endfor
    return join(root, "")
endf
"2}}}
"1}}}
