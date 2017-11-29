"===============================================================================
" File:         autoload/vc/git.vim
" Description:  Git Commands
" Author:       Juneed Ahamed
"===============================================================================

"{{{1

" vars "{{{2
let s:CMD_PRE = "git --no-pager "
"2}}}

" ops {{{2
fun! vc#git#affectedops()
   return {
       \ "\<Enter>"  :{"bop":"<enter>", "dscr" :'Ent:OpenRev', "fn":'vc#gopshdlr#openfile', "args":['vc#act#efile']},
       \ g:vc_ctrlenterkey : {"bop":g:vc_ctrlenterkey_buf, "dscr":vc#utils#openfiledscr(g:vc_ctrlenterkey_dscr), "fn":'vc#gopshdlr#openfile', "args":['vc#act#efile', "revisioned"]},
       \ "\<C-o>"    :{"bop":"<c-o>", "fn":'vc#gopshdlr#openfltrdfiles', "args":['vc#act#efile']},
       \ "\<C-i>"    :{"bop":"<c-i>", "fn":'vc#gopshdlr#info'},
       \ "\<C-w>"    :{"bop":"<c-w>", "fn":'vc#gopshdlr#togglewrap'},
       \ "\<C-y>"    :{"bop":"<c-y>", "fn":'vc#gopshdlr#cmd'},
       \ "\<C-b>"    :{"bop":"<c-b>", "fn":'vc#gopshdlr#book'},
       \ g:vc_selkey : {"bop":g:vc_selkey_buf, "fn":'vc#gopshdlr#select'},
       \ }
endf

fun! vc#git#commitcmdops(...) 
    retu ["--amend", "--dry-run"]
endf

fun! vc#git#addcmdops(...) 
    retu ["--dry-run",]
endf

fun! vc#git#commitops(meta, cargs) 
    let commitargs = {"meta": a:meta, "cargs": a:cargs}
    retu {
        \ "<c-z>": {"fn": "vc#commit#commit", "args": commitargs,},
        \ "<c-a>": {"fn": "vc#git#appendprevcommitmsg", "args": commitargs},
        \ "<c-q>": {"fn": "vc#commit#done", "args": []}, 
        \ }
endf

fun! vc#git#commitopsdscr(meta) 
    retu [
        \ "Ctrl-z: Commit Files",
        \ "Ctrl-a: Append previous commit message then edit or replace",
        \ "Ctrl-q: Quit",
        \ ]
endf
"2}}}

" formatting and cmds {{{2
fun! s:logpfrmt()
    retu printf(' --pretty=%s,%s ', g:vc_git_sha_fmt, g:vc_git_log_pfmt)
endf

fun! s:alogpfrmt()
    retu printf(' --pretty=##\ %s,%s ', g:vc_git_sha_fmt, g:vc_git_alog_pfmt)
endf

fun! s:precmd(meta)
    "retu printf('%s -C "%s" ', s:CMD_PRE, a:meta.wrd)  -C option after 1.8 only
    retu printf('%s --git-dir %s --work-tree %s ', s:CMD_PRE, a:meta.gitdir, a:meta.wrd)
endf

fun! s:listorigins(meta)
    retu s:precmd(a:meta) . 'remote show origin'
endf

fun! s:listremote(meta)
    retu s:precmd(a:meta) . 'remote -v'
endf

fun! s:branchverbose(meta)
    retu s:precmd(a:meta) . 'branch -vv'
endf

fun! s:listbranchescmd(meta)
    retu s:precmd(a:meta) . 'branch'
endf

fun! s:listrbranchescmd(meta)
    retu s:precmd(a:meta) . 'branch -r'
endf

fun! s:logcmd(meta, argslst)
    let argslst = []
    if index(a:argslst, "-n") < 0 
        call extend(argslst, ["-n", g:vc_max_logs])
    endif
    call extend(argslst, a:argslst)
    
    retu s:precmd(a:meta) . "log" . s:logpfrmt() . join(argslst, " ") . " -- " . a:meta.fpath
endf

fun! s:listafilescmd(meta, revision)
    retu s:precmd(a:meta) . "show --name-status " . s:alogpfrmt() . "-r " . a:revision
endf

fun! s:preopencmd(meta)
    retu s:precmd(a:meta) . 'show --no-color --raw -s '
endf

fun! s:pushcmd(meta, cargs)
    retu s:precmd(a:meta) . 'push ' . a:cargs
endf

fun! s:pullcmd(meta, cargs)
    retu s:precmd(a:meta) . 'pull ' . a:cargs
endf

fun! s:fetchcmd(meta, cargs)
    retu s:precmd(a:meta) . 'fetch ' . a:cargs
endf
"2}}}

fun! vc#git#meta(entity) "{{{2
    let fullpath = vc#utils#fnameescape(fnamemodify(a:entity, ':p'))
    let [result, wrd] = vc#utils#fetchwrd(a:entity, ".git")
    let metad = {}
    let metad.repo = "-git"
    let metad.entity = a:entity   "Name as given from input
    let metad.fpath = fullpath "Full path on disk
    let metad.isdir = vc#utils#isdir(fullpath) 
    let metad.local = 1
    let metad.branch = ""
    let metad.rbranch = ""
    let metad.wrd = wrd
    let metad.gitdir = vc#utils#joinpath(wrd, ".git")
    "Path with respect to repo
    let metad.repoUrl = vc#utils#fnameescape(substitute(expand(fullpath), expand(wrd), '', ''))
    retu metad
endf

fun! vc#git#inrepodir(entity)
    let [result, wrd] = vc#utils#fetchwrd(a:entity, ".git")
    retu result
endf

fun! vc#git#member(entity)
    let [result, wrd] = vc#utils#fetchwrd(a:entity, ".git")
    if result == vc#passed()
        let meta = vc#git#meta(a:entity)
        let cmd = s:precmd(meta) . "status --porcelain -s " . a:entity
        let shellout = vc#utils#execshellcmd(cmd)
        let shelloutlist = split(shellout, '\n')
        for shelloutline in shelloutlist
            if matchstr(shelloutline, "\?") != "" 
                retu vc#failed()
            endif
        endfor
    endif
    retu result
endf
"2}}}

"logs {{{2
fun! vc#git#logtitle(argsd)
    let relpath = fnamemodify(expand(a:argsd.meta.fpath), ':.')
    retu s:fmtdbranchname(a:argsd.meta) . relpath
endf

fun! vc#git#logmenu(argsd) 
    let [menus, errmsg] = [[], ""]
    call add(menus, vc#dict#menuitem("Local Branches", 'vc#git#lstlbranches', ""))
    call add(menus, vc#dict#menuitem("Remote Branches", 'vc#git#lstrbranches', ""))
    retu [menus, errmsg]
endf

fun! vc#git#lastchngdrev(meta) 
    try
        let logargsd = {"meta": a:meta, "cargs": "-n 1"}
        call vc#git#logs(logargsd)
        unlet! logargsd
    catch 
        call vc#utils#dbgmsg("At vc#git#lastchngdrev", v:exception) 
    endtry
    retu len(g:vc_logversions) > 0 ? g:vc_logversions[0] : ""
endf

fun! vc#git#logs(argsd)
    let [meta, acargs] = [a:argsd.meta, a:argsd.cargs]
    let cargs = acargs == "" ? [] : [acargs]
    let cmd = s:logcmd(meta, cargs)
    retu s:logrtrv(cmd)
endf

fun! s:logrtrv(cmd)
    let [logentries, g:vc_logversions] = [[], []]
    let shellout = vc#utils#execshellcmd(a:cmd)
    let shellist = split(shellout, '\n')
    unlet! shellout
    try
        for idx in range(0,  len(shellist)-1)
            let curline = vc#utils#strip(shellist[idx])
            if len(curline) <= 10  | cont | en
            let contents = split(curline, ',')
            let revision = vc#utils#strip(contents[0])
            let logentry = {}
            let logentry.revision = revision
            let logentry.line = revision . ' ' . join(contents[1:], ' | ')
            call add(logentries, logentry)
            call add(g:vc_logversions, revision)
        endfor
        unlet! shellist
    catch 
        call vc#utils#dbgmsg("At s:logrtrv", v:exception)
    endtry
    retu [logentries, a:cmd]
endf
"2}}}

fun! vc#git#changes(argsd) "{{{2
    retu s:precmd(a:argsd.meta) . 'diff ' . a:argsd.revision . ' ' . a:argsd.meta.fpath
endf
"2}}}

fun! vc#git#diff_vcnoparse(argsd) "{{{2
    retu s:precmd(a:argsd.meta) . 'diff ' . a:argsd.cargs . ' ' . a:argsd.revision . ' -- ' . a:argsd.target
endf
"2}}}

fun! vc#git#diff(argsd) "{{{2
    let logargsd = {"meta": a:argsd.meta, "cargs": "-n " . g:vc_max_logs}
    call vc#git#logs(logargsd)
    unlet! logargsd
    let force = get(a:argsd, 'bang', '')
    if a:argsd.revision != "" 
        call vc#act#diffme(a:argsd.meta.repo, a:argsd.revision, a:argsd.meta.fpath, force)
    elseif len(g:vc_logversions) > 0
        let diffrevision = force != "" && len(g:vc_logversions)>=2 ? g:vc_logversions[1]: g:vc_logversions[0]
        call vc#act#diffme(a:argsd.meta.repo, diffrevision, a:argsd.meta.fpath, force)
    else
        retu vc#utils#showerr("Failed to rtrv version info")
    endif
endf
"2}}}

fun! vc#git#status(argsd) "{{{2
    let cargs = get(a:argsd, 'cargs', '')
    let cmd = s:precmd(a:argsd.meta) . "status -b --porcelain -s " . cargs . " " . a:argsd.meta.fpath 
    let [entries, cmd] = vc#utils#statussummary(cmd, a:argsd.meta.wrd)
    retu [cmd, entries]
endf
"2}}}

fun! vc#git#status_vcnoparse(argsd) "{{{2
    let cargs = get(a:argsd, 'cargs', '')
    retu s:precmd(a:argsd.meta) . "status " . cargs . " " . a:argsd.meta.fpath 
endf
"2}}}

fun! vc#git#affectedfiles(meta, revision) "{{{2
    let cmd = s:listafilescmd(a:meta, a:revision)
    retu vc#utils#statussummary(cmd, a:meta.wrd)
endf

fun! vc#git#affectedfilesacross(meta, revisionA, revisionB) 
    let cmd = s:precmd(a:meta) . "diff --name-status -r " .
                \ a:revisionA . ' ' . a:revisionB . ' ' .
                \ a:meta.fpath
    retu vc#utils#statussummary(cmd, a:meta.wrd)
endf

"2}}}

" info access {{{2
fun! vc#git#info(argsd) 
    let [result, rbranches] = ["", ""]
    try
        let result = ""
        try
            let result = result . vc#utils#execshellcmd(s:listremote(a:argsd.meta)) . "\n"
        catch|endtry

        let result = result . "Current Working Branch : " . vc#git#curbranchname(a:argsd.meta) . "\n"
        try
            let result = result . "\n" . vc#utils#execshellcmd(s:listorigins(a:argsd.meta))
        catch | endtry

        let rbranches = vc#utils#execshellcmd(s:listrbranchescmd(a:argsd.meta))
        if rbranches != ""
            let result = result . "\n  BRANCH INFO \n"
            let result = result . "\n  *********** \n"
            let result = result.rbranches
        endif
        
        let result = result . "\n  BRANCH VERBOSE INFO\n"
        let result = result . "\n  *********** \n"
        let result = result . vc#utils#execshellcmd(s:branchverbose(a:argsd.meta))
    catch
        call vc#utils#dbgmsg("vc#git#info", v:exception)
    endtry
    retu result
endf

fun! vc#git#infolog(argsd)
    let revision = get(a:argsd, "revision", "")
    let meta = a:argsd.meta
    let result = ""
    try
        let result = result . vc#utils#execshellcmd(s:listremote(meta))
        if revision != ""
            let cmd = s:precmd(meta) . 'show -s --pretty=%s ' . revision
            let result = result . vc#utils#execshellcmd(cmd)
        endif
        
        if revision
            let result = result . "Affected files : "
            let cmd = s:listafilescmd(meta, revision)
            let result = result . vc#utils#execshellcmd(cmd)
        endif
    catch
        call vc#utils#dbgmsg("vc#git#infolog", v:exception)
        "let result = v:exception
    endtry
    retu result
endf

fun! vc#git#infodiffcmds(argsd)
    let cmds = []
    call add(cmds, ["Affected Files:", s:listafilescmd(a:argsd.meta, a:argsd.revision)])
    call add(cmds, ["Revision Info:",  s:precmd(a:argsd.meta) . 'show --name-only -r ' . b:vc_revision])
    retu cmds
endf
"2}}}

" cmds callback {{{2
fun! vc#git#diffcmd(argsd) 
    let cmd = vc#git#opencmd(a:argsd)
    retu cmd
endf

fun! vc#git#opencmd(argsd)
    let arevision = get(a:argsd, 'revision', '')
    let rbranch = get(a:argsd, 'rbranch', '' )
    let meta = vc#git#meta(a:argsd.path)

    if rbranch != ""
        let cmd = s:preopencmd(meta) . rbranch . " -r " . arevision . ":" . meta.repoUrl
    elseif arevision != ""
        let cmd = s:preopencmd(meta) . " -r " . arevision . ":" . meta.repoUrl
    else
        let cmd = s:preopencmd(meta) . arevision . ":" . meta.fpath
    endif
    retu cmd
endf

fun! vc#git#blamecmd(argsd)
    let cmd = s:precmd(a:argsd.meta) . "blame HEAD -- " . a:argsd.meta.fpath
    retu cmd
endf
"2}}}

fun! vc#git#domove(argsd)  "{{{2
    try
        let [meta, topath, flist] = [a:argsd.meta, a:argsd.topath, a:argsd.flist]
        let cmd = s:precmd(meta) . "mv -v " . get(a:argsd, "cargs", "") . " ". join(flist, " ") . " " . topath
        retu [vc#passed(), cmd]
    catch 
        call vc#utils#dbgmsg("At vc#git#domove", v:exception)
    endt
    retu [vc#failed(), ""]
endf

fun! vc#git#movecmdops(argsd)
    retu [ "-k", "-n" , "--dry-run" ]
endf
"2}}}

fun! vc#git#statuscmdops(argsd) "{{{2
    retu ["--untracked-files", "--ignored", "-vcnoparse", "-uno"]
endf
"2}}}

fun! vc#git#logcmdops(argsd) "{{{2
    retu ["-n", "--reverse", "--author", "--until", "--since", "--after", "--before"]
endf
"2}}}

fun! vc#git#diffcmdops(argsd) "{{{2
    retu ["HEAD", "-vcnoparse"]
endf
"2}}}

fun! s:branchesforcmdops(argsd) "{{{2
    let lst = ["origin", "master"]
    let meta = !has_key(a:argsd, "meta") ? vc#repos#meta(".", "-git") : a:argsd.meta
    let [lnames, rnames] = vc#git#branches(meta)
    for rname in rnames
        for elem in split(rname, "/")
            if index(lst, elem) < 0
                call add(lst, elem)
            endif
        endfor
    endfor
    retu extend(lst, lnames)
endf
"2}}}

fun! vc#git#pushcmdops(argsd) "{{{2
    let cargs = ["-u", "--set-upstream", "-n", "--dry-run", "-v"]
    retu extend(cargs, s:branchesforcmdops(a:argsd))
endf
"2}}}

fun! vc#git#fetchcmdops(argsd) "{{{2
    let cargs = ["--dry-run", "-k", "-n", "-q", "-v", ]
    retu extend(cargs, s:branchesforcmdops(a:argsd))
endf
"2}}}

fun! vc#git#pullcmdops(argsd) "{{{2
    let args = ["-q", "-v", "--commit", "--no-commit", "--ff", "--no-ff",
                \ "--ff-only"]
    retu extend(args, s:branchesforcmdops(a:argsd))
endf
"2}}}

fun! vc#git#appendprevcommitmsg(argsd)   "{{{2
    let cmd = s:precmd(a:argsd.meta) . "log -n1 --pretty=%B"
    let shellout = vc#utils#execshellcmd(cmd)
    retu append(line('$'), split(shellout, "\n"))
endf
"2}}}

fun! vc#git#commitcmd(commitlog, flist, argsd) "{{{2
    let fliststr = join(a:flist, " ")
    let cargs = has_key(a:argsd, "cargs") ? a:argsd.cargs : ""
    if a:commitlog == "!"
        let cmd = s:precmd(a:argsd.meta) . "commit --allow-empty-message -m \"\" " . cargs . " " . fliststr
    else
        let cmd = s:precmd(a:argsd.meta) . "commit -F " . a:commitlog . " " . cargs . " " .fliststr
    endif
    retu cmd    
endf
"2}}}

fun! vc#git#addcmd(argsd) "{{{2
    if !exists("b:vc_meta") | retu vc#utils#showerr("Failed to rtrv meta") | en
    let cargs = has_key(a:argsd, "cargs") ? a:argsd.cargs : ""
    retu s:precmd(b:vc_meta) . "add " .cargs . " " . join(a:argsd.files, " ")
endf
"2}}}

"branches listings {{{2
fun! vc#git#lstlbranches(argsd) 
    let [adict, akey] = [a:argsd.dict, a:argsd.key]
    let meta = deepcopy(adict.meta)
    let ldict = vc#dict#new("local branches", {"meta" : meta})
    let [lnames, rnames] = vc#git#branches(meta)

    if empty(lnames) 
        call vc#dict#adderrup(ldict, "Nothing here : ", ldict.meta.cmd)
    endif

    for bname in lnames
        call vc#dict#addentries(ldict, 'menud',
            \ [vc#dict#menuitem(bname,'vc#git#lbranchlogs', bname)], 
            \ vc#gopshdlr#menuops())
    endfor

    unlet! a:argsd.dict
    let a:argsd.dict = ldict
    call vc#winj#populate(ldict)
endf

fun! vc#git#lstrbranches(argsd) 
    let [adict, akey] = [a:argsd.dict, a:argsd.key]
    let meta = deepcopy(adict.meta)
    let ldict = vc#dict#new("remote branches", {"meta" : meta})
    let [lnames, rnames] = vc#git#branches(meta)
    
    if empty(rnames) 
        call vc#dict#adderrup(ldict, "Nothing here : ", ldict.meta.cmd)
    endif
    
    for bname in rnames
        call vc#dict#addentries(ldict, 'menud',
            \ [vc#dict#menuitem(bname,'vc#git#rbranchlogs', bname)], 
            \ vc#gopshdlr#menuops())
    endfor

    unlet! a:argsd.dict
    let a:argsd.dict = ldict
    call vc#winj#populate(ldict)
endf
"2}}}

"branches log {{{2
fun! vc#git#lbranchlogs(argsd) 
    retu s:branchlogs(a:argsd, 1)
endf

fun! vc#git#rbranchlogs(argsd)
    retu s:branchlogs(a:argsd, 0)
endf

fun! s:branchlogs(argsd, islocal)
    try
        let [adict, akey] = [a:argsd.dict, a:argsd.key]
        let bname = adict.menud.contents[akey].convert
        let title = "Log " . vc#git#frmtbranchname(bname) . ' ' . adict.meta.repoUrl
        
        let cmd = s:logcmd(adict.meta, [bname,])
        let ldict = vc#dict#new("Log", {"meta" : deepcopy(adict.meta)})
        let ldict.title = title
        let ldict.meta.branch = a:islocal ? bname : ""
        let ldict.meta.rbranch = a:islocal ? "" : bname

        let [entries, ldict.meta.cmd] = s:logrtrv(cmd)
        if empty(entries)
            call vc#dict#adderrup(ldict, "Nothing here : ", ldict.meta.cmd)
        else
            call vc#dict#addentries(ldict, 'logd', entries, vc#log#logops())
        endif
        call vc#winj#populate(ldict)
    catch
        call vc#utils#dbgmsg("At vc#git#remotelogs", v:exception)
    endtry
endf
"2}}}

"branches read {{{2
fun! vc#git#branches(meta) 
    let ignpat = '^remote$\|^remotes$\|^*'
    let lnames = split(vc#utils#execshellcmd(s:listbranchescmd(a:meta)), "\n")
    let lnames = map(lnames, 'vc#utils#strip(v:val)')
    let lnames = filter(lnames, 'len(matchstr(v:val, ignpat)) == 0')

    let rnames = split(vc#utils#execshellcmd(s:listrbranchescmd(a:meta)), "\n")
    let rnames = map(rnames, 'split(vc#utils#strip(v:val))[0]')

    "filter names if in remote
    let lnames = filter(lnames, 'index(rnames, v:val) < 0')  
    retu [lnames, rnames]
endf

fun! s:localbranches(meta)
    let cmd = s:listbranchescmd(a:meta)
    let names = split(vc#utils#execshellcmd(cmd), "\n")
    let names = map(names, 'vc#utils#strip(v:val)')
    retu names
endf

fun! vc#git#curbranchname(meta)
    let name = ""
    try
        let names = s:localbranches(a:meta)
        let fltrnames = filter(names, "len(matchstr(v:val, '\^* ')) > 0")
        if len(fltrnames) == 1 
            retu fltrnames[0] 
        endif
    catch 
        call vc#utils#dbgmsg("At vc#git#curbranchname", v:exception) 
    endtry
    retu name
endf

fun! s:fmtdbranchname(meta)
    retu vc#git#frmtbranchname(vc#git#curbranchname(a:meta))
endf

fun! vc#git#frmtbranchname(name)
    retu len(a:name) > 0 ? "[" . a:name . "] " : ""
endf
"2}}}

fun! vc#git#browseentries(path, argsd)   "{{{2
    if a:argsd.meta.local 
        let a:argsd.title = s:fmtdbranchname(a:argsd.meta) . a:argsd.title
        retu call('vc#utils#lstfiles', [a:path, a:argsd.brecursive, 0])
    else
        retu []
    endif
endf
"2}}}

fun! vc#git#push(argsd)  "{{{2
    let cmd = s:pushcmd(a:argsd.meta, a:argsd.cargs)
    retu vc#utils#execshellcmduseexec(cmd, 1)
endf
"2}}}

fun! vc#git#fetch(argsd)  "{{{2
    let cmd = s:fetchcmd(a:argsd.meta, a:argsd.cargs)
    retu vc#utils#execshellcmduseexec(cmd, 1)
endf
"2}}}

fun! vc#git#pull(argsd)  "{{{2
    let cmd = s:pullcmd(a:argsd.meta, a:argsd.cargs)
    retu vc#utils#execshellcmduseexec(cmd, 1)
endf
"2}}}

fun! vc#git#revertcmd(argsd)  "{{{2
    retu s:precmd(a:argsd.meta) . 'checkout ' . a:argsd.cargs . " " . a:argsd.meta.fpath
endf
"1}}}
