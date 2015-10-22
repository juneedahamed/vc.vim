" =============================================================================
" File:         autoload/cmpt.vim
" Description:  command line completion support
" Author:       Juneed Ahamed
" =============================================================================

"complete funs  {{{1
fun! vc#cmpt#Repos(A,L,P)
    retu vc#cmpt#filtermatch(vc#repos#repos(), a:A)
endf

fun! vc#cmpt#Revert(A,L,P)
    retu vc#cmpt#filtermatch(vc#repos#repos(), a:A)
endf

fun! vc#cmpt#Blame(arglead, cmdline, cursorpos)
    retu s:cmdargs("None", "all", 1, 0, "", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Info(arglead, cmdline, cursorpos)
    retu s:cmdargs("None", "all", 1, 0, "", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Move(arglead, cmdline, cursorpos)
    retu s:cmdargs("move.cmdops", "allmultiple", 0, 0, "", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Copy(arglead, cmdline, cursorpos)
    retu s:cmdargs("None", "allmultiple", 0, 0, "", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Status(arglead, cmdline, cursorpos)
    retu s:cmdargs("status.cmdops", "onlydirs", 1, 0, "", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Log(arglead, cmdline, cursorpos)
    retu s:cmdargs("log.cmdops", "all", 1, 0, "",  a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Diff(arglead, cmdline, cursorpos)
    retu s:cmdargs("diff.cmdops", "none", 0, 1, "", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Commit(arglead, cmdline, cursorpos)
    retu s:cmdargs("commit.cmdops", "allmultiple", 0, 0, "", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Add(arglead, cmdline, cursorpos)
    retu s:cmdargs("add.cmdops", "allmultiple", 0, 0, "", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Push(arglead, cmdline, cursorpos)
    retu s:cmdargs("push.cmdops", "none", 0, 0, "", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Pull(arglead, cmdline, cursorpos)
    retu s:cmdargs("pull.cmdops", "none", 0, 0, "", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Fetch(arglead, cmdline, cursorpos)
    retu s:cmdargs("fetch.cmdops", "none", 0, 0, "-git", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Incoming(arglead, cmdline, cursorpos)
    retu s:cmdargs("incoming.cmdops", "none", 0, 0, "-hg", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#Outgoing(arglead, cmdline, cursorpos)
    retu s:cmdargs("outgoing.cmdops", "none", 0, 0, "-hg", a:arglead, a:cmdline, a:cursorpos)
endf

fun! vc#cmpt#BrowseRepo(arglead, cmdline, cursorpos)
    let [retlst, optlst, globtype] = [[], [], "onlydirs"]
    let splits = split(a:cmdline)
    let [target, argstr] = s:argstrremovetarget(a:cmdline, globtype)

    if g:vc_autocomplete_svnurls == 1 && 
                \ vc#svn#inrepodir(vc#utils#fnameescape(getcwd())) ||
                \ vc#svn#inrepodir(a:arglead)
        call extend(retlst, s:globsvn(globtype, a:cmdline, a:arglead))
    else
        call extend(retlst, s:globpath(globtype, a:cmdline, a:arglead, ""))
    endif

    call add(retlst, "-target")
    call filter(retlst, 'index(splits, v:val) <0 ')
    retu vc#cmpt#filtermatch(retlst, a:arglead)
endf
"1}}}

" helpers {{{1
fun! s:cmdargs(cmdops, globtype, targetarg, revisionarg, forcerepo, arglead, cmdline, cursorpos)
    let [retlst, optlst] = [[], []]
    
    if a:targetarg && matchstr(a:cmdline, '\M\(^\|\s\)-target\(\s\|=\)\+\S\*') == "" 
        call add(retlst, "-target")
    endif
    
    if a:revisionarg && matchstr(a:cmdline, '\M\(^\|\s\)-revision\(\s\|=\)\+\S\*') == "" 
        call add(retlst, "-revision")
    endif
    
    let disectd = s:argsdisect(a:cmdline, a:globtype)
    if a:forcerepo != "" | let disectd.forcerepo = a:forcerepo | en
    if disectd.forcerepo == "" | call extend(retlst, vc#repos#repos()) | en

    let bufpath = ""
    try
        let bufpath = vc#utils#bufrelpath()
    catch|endtry

    if disectd.target != "" 
        let optlst = s:options(a:cmdops, disectd.forcerepo, disectd.target, a:cmdline)
        call extend(retlst, optlst)
    endif

    if a:globtype != "none" && (disectd.target == "."  || 
                \ vc#utils#isdir(disectd.target) || 
                \ disectd.target == bufpath || 
                \ !vc#utils#localFS(disectd.target)
                \ ) 
        let files = s:globpath(a:globtype, a:cmdline, a:arglead, disectd.forcerepo)
        call extend(retlst, files)
    elseif a:globtype == "allmultiple"
        let files = s:globpath(a:globtype, a:cmdline, a:arglead, disectd.forcerepo)
        call extend(retlst, files)
    endif

    retu vc#cmpt#filtermatch(retlst, a:arglead)
endf

fun! s:options(cmdops, repohint, target, cmdline)
    let optlst = []
    let cmdlinelst = split(a:cmdline)
    try
        let [argsd, target, repo, optlst] = [{}, a:target, a:repohint, []]
        if repo == ""
            let argsd.meta = vc#repos#meta(target, "")
            let repo = argsd.meta.repo
        endif
        if a:cmdops !=? "None"
            let optlst = vc#repos#call(repo, a:cmdops, argsd)
        endif
        call filter(optlst, 'index(cmdlinelst, v:val) < 0')
    catch
        "call s:logme("Exception " . v:exception)
    endtry
    retu optlst
endf

"globtype = none, all, allmultiple, onlydirs, onlyfiles
fun! s:globpath(globtype, cmdline, arglead, forcerepo)
    let [checkrepo, path, forcerepo]  = [0, expand(a:arglead), a:forcerepo]
    
    if !g:vc_autocomplete_svnurls
        retu s:globlocal(a:globtype, a:cmdline, a:arglead)
    endif

    let mpath = fnamemodify(path, ':h')
    if forcerepo == "" && index(vc#repos#repos(), "-svn") >= 0 

        if !(vc#utils#localFS(path) || vc#utils#localFS(mpath)) &&
                    \ (vc#svn#validurl(path)  || vc#svn#validurl(mpath))
            let forcerepo = "-svn"
        else
            let forcerepo = vc#svn#inrepodir(vc#utils#fnameescape(path)) ? "-svn" : forcerepo
        endif
    endif
    
    if forcerepo == "-svn" | retu s:globsvn(a:globtype, a:cmdline, a:arglead) | en

    retu s:globlocal(a:globtype, a:cmdline, a:arglead)
endf

fun! s:globlocal(globtype, cmdline, arglead)
    let [entries, arglead] = [ [], vc#utils#strip(a:arglead)]
    let path = expand(vc#utils#strip(arglead))
    let apath = vc#utils#isdir(path) ? path : fnamemodify(path, ':h') 
    let arglead = vc#utils#isdir(path) ? arglead : fnamemodify(arglead, ':h') 
    if apath != ""
        let entries = split(globpath(apath, "*"), "\n")
        let entries = map(entries, 'vc#utils#isdir(v:val) ? v:val . "/" : v:val')
        let entries = map(entries, 'vc#utils#fnameescape(v:val)')
        if a:globtype == "onlydirs"
            let entries = filter(entries, 'vc#utils#isdir(v:val)')
        endif
        if len(entries) > 0 && apath != arglead
            let entries = map(copy(entries), 'substitute(v:val, "^".apath, arglead, "")')
        endif
    endif
    retu entries
endf

fun! s:globsvn(globtype, cmdline, arglead)
    let result = []
    let dirpat = '\V/\$'
    try
        let arglead = a:arglead
        let [target, argstr] = s:argstrremoveusertarget(arglead)
        let arglead = matchstr(arglead, dirpat) == "" ? fnamemodify(a:arglead, ":h") : arglead
        call extend(result, s:globsvntop(a:cmdline, arglead))
        if vc#utils#localFS(arglead)
            call extend(result, s:globlocal(a:globtype, a:cmdline, arglead))
            retu result
        endif
        let cmd = 'svn list --non-interactive ' . arglead
        let shellout = vc#utils#execshellcmd(cmd)
        let shelloutlist = split(shellout, '\n')
        if a:globtype == "onlydirs"
            call filter(shelloutlist, 'matchstr(v:val, dirpat) != ""')
        elseif a:globtype == "onlyfiles"
            call filter(shelloutlist, 'matchstr(v:val, dirpat) == ""')
        endif
        call extend(result, map(shelloutlist, 'vc#utils#fnameescape(vc#utils#joinpath(arglead, v:val))'))
        unlet! shellout
    catch 
        "call s:logme(v:exception)
    endtry
    retu result
endf

fun! s:globsvntop(cmdline, arglead)
    let retlst = []
    let addtarget = matchstr(a:cmdline, "-target") == ""
    try
        let targetroot = vc#svn#reporoot() . "/"
        if targetroot != "" && !addtarget  | call add(retlst, targetroot) | en
        if targetroot != "" && addtarget  | call add(retlst, "-target " . targetroot) | en

        let targetcwd = vc#svn#url(vc#utils#fnameescape(getcwd())) . "/" 
        if targetcwd != "" && !addtarget | call add(retlst, targetcwd) | en
        if targetcwd != "" && addtarget | call add(retlst, "-target " . targetcwd) | en
    catch 
        "call s:logme(v:exception)
    endtry
    retu retlst
endf

fun! vc#cmpt#filtermatch(thelist, matchstr)
    "Nothing to match so no criteria for ranking return as is
    if a:matchstr == ""  | retu a:thelist | en 
    let matchme = '\V\^\(./\)\?' . fnameescape(a:matchstr)  "Donot expand
    let retlist = filter(copy(a:thelist), 'matchstr(v:val, matchme) != "" ')
    let strip = '\V\^./'
    if matchstr(a:matchstr, strip) != "./"
        retu map(retlist, 'substitute(v:val, strip, "", "")')
    endif
    retu retlist
endf

fun! s:argsdisect(argstr, globtype)
    let [forcerepo, argstr] = vc#argstrremoverepo(a:argstr)
    let [revision, argstr] = s:argstrremoverevision(argstr)
    let [target, argstr] = s:argstrremovetarget(argstr, a:globtype)
    if target == "" | let target = vc#maketarget(a:globtype) | en
    retu {"forcerepo": forcerepo, "target": target, "cargs": argstr, "revision": revision}
endf

fun! s:argstrremoverevision(argstr)
    let revision = matchstr(a:argstr, '\M\(^\|\s\)-revision\(\s\|=\)\+\S\*')
    retu [substitute(revision, '\M\(^\|\s\)-revision\(\s\|=\)\*', "", ""), 
                \ substitute(a:argstr, revision, "", "")]
endf

fun! s:argstrremoveusertarget(argstr)
    let target = matchstr(a:argstr, '\M\(^\|\s\)-target\(\s\|=\)\+\S\*')
    retu [substitute(target, '\M\(^\|\s\)-target\(\s\|=\)\*', "", ""), 
                \ substitute(a:argstr, target, "", "")]
endf

fun! s:argstrremovetarget(argstr, globtype)
    let argstr = join(map(split(a:argstr), 'expand(v:val)'))
    let [target, argstr] = s:argstrremoveusertarget(argstr)
    if target == "%" | retu [expand("%"), argstr] | en
    if target != "" | retu [target, argstr] | en

    try
        if vc#utils#localFS(argstr) | retu [argstr, ""] | en
        "remove anything between quotes ' | "
        let argstr = substitute(argstr, "[\'|\"].*[\'|\"]", "", "")
        let splits = split(argstr, " ")
        for i in range(0, len(splits))
            for j in range(len(splits)-1,i, -1)
                let target = join(splits[i : j], " ")
                if vc#utils#localFS(target)
                    retu [target, substitute(argstr, vc#utils#fnameescape(target), "", "")]
                endif
            endfor
        endfor
    catch | endtry

    let arglst = filter(split(argstr), 'vc#utils#localFS(expand(v:val))')
    let target = len(arglst) > 0 ? vc#utils#expand(arglst[0]) : ""
    if len(arglst) > 0 | let argstr = substitute(argstr, arglst[0], "", "") | en
    retu [target, argstr] 
endf

fun! s:logme(...)
    sil! exe 'redi! >>' g:vc_log_name
    echo a:000
    sil! redi END
endf
"1}}}

fun! vc#cmpt#prompt(repo, cmd, ops)  "{{{2
    let [cargs, b:cmdops] = ["", []]
    try
        if vc#prompt#stoppingforargs()
            let [result, fncb] = vc#repos#hasop(a:repo, a:ops)
            if result == vc#passed()
                redr | echohl special | echo " "
                let b:cmdops = call(fncb, [{}])
                if len(b:cmdops) <= 0 | retu "" | en
                let prompt = a:repo . " Enter arguments for " . a:cmd . " : "
                let _cargs = input(prompt, "", "customlist,vc#cmpt#promptcb")
                if len(_cargs) > 0 | retu _cargs | en
            endif
        endif
    catch
        call vc#utils#dbgmsg("vc#cmpt#prompt", v:exception) 
    finally
        echohl None
        unlet! b:cmdops
    endtry
    retu cargs
endf

fun! vc#cmpt#promptcb(arglead, cmdline, cursorpos)
    let [cargs, thearglead] = ["", ""]
    let theinputs = split(a:cmdline)
    if len(theinputs) > 0 && len(matchstr(a:cmdline, '\V\s\$')) != 1
        let thearglead = theinputs[-1]
        let theinputs = theinputs[:-2]
    endif

    let cmdops = copy(b:cmdops)
    call filter(cmdops, 'index(theinputs, v:val)<0')
    let cmdops = thearglead != "" ? vc#cmpt#filtermatch(cmdops, thearglead) : cmdops
    if len(cmdops) == 0 | retu a:cmdline | endif
   
    let theoldinput = join(theinputs, " ") . " "
    retu map(cmdops, 'theoldinput . v:val')
endf
"2}}}

fun! vc#cmpt#browsepath(warning, prompt, answer)  "{{{2
    try
        if a:warning != "" 
            echohl Error
            echo a:warning
            echohl None
        endif
        echohl Question
        echo "---------------------------------"
        echo a:prompt  
        echohl None

        let theinput = input(" ", a:answer, "customlist,vc#cmpt#promptbrowsecb")
        if len(theinput) > 0 
            retu theinput
        endif
    catch
        call vc#prompt#moveright()
        retu ""
    finally
        echohl None
    endtry
    retu a:answer
endf

fun! vc#cmpt#promptbrowsecb(arglead, cmdline, cursorpos)
    let [thearglead, cmdline] = [vc#utils#strip(a:arglead), vc#utils#strip(a:cmdline)]
    let entries = s:globlocal("all", cmdline, a:arglead)
    let entries = thearglead != "" ? vc#cmpt#filtermatch(entries, thearglead) : entries
    if len(entries) == 0 | retu cmdline | endif
    retu entries
endf
"2}}}
