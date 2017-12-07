"===============================================================================
" File:         autoload/vc/hg.vim
" Description:  Mercurial hg Commands
" Author:       Juneed Ahamed
"===============================================================================

" vars "{{{2
let s:CMD_PRE = "hg --noninteractive "
"2}}}

"Key mappings ops for hg {{{2
fun! s:precmd(meta)
    retu printf('%s --cwd %s ', s:CMD_PRE, a:meta.wrd)
endf
"2}}}

fun! vc#hg#meta(entity) "{{{2
    let fullpath = vc#utils#fnameescape(fnamemodify(a:entity, ':p'))
    let [result, wrd] = vc#utils#fetchwrd(a:entity, ".hg")
    let metad = {}
    let metad.repo = "-hg"
    let metad.entity = a:entity   "Name as given from input
    let metad.fpath = fullpath "Full path on disk
    let metad.isdir = vc#utils#isdir(fullpath) 
    let metad.local = 1
    let metad.branch = ""
    let metad.rbranch = ""
    let metad.wrd = wrd
    let metad.hgdir = vc#utils#joinpath(wrd, ".hg")
    "Path with respect to repo
    let metad.repoUrl = vc#utils#fnameescape(substitute(fullpath, wrd, '', ''))
    let b:vc_file_meta = metad
    retu metad
endf

fun! vc#hg#inrepodir(entity)
    let [result, wrd] = vc#utils#fetchwrd(a:entity, ".hg")
    retu result
endf

fun! vc#hg#member(entity)
    let [result, wrd] = vc#utils#fetchwrd(a:entity, ".hg")
    if result == vc#passed()
        let meta = vc#hg#meta(a:entity)
        let cmd = s:precmd(meta) . "status " . a:entity
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

"info access {{{2
"argsd  = { 'meta': meta}
fun! vc#hg#info(argsd)
    let result = "Summary \n"
    let cmd = s:precmd(a:argsd.meta) . "summary -v"
    let result = result . "\n" . vc#utils#execshellcmd(cmd)

    let cmd = s:precmd(a:argsd.meta) . "paths"
    let result = result . "\nPaths:\n" . vc#utils#execshellcmd(cmd)

    let cmd = s:precmd(a:argsd.meta) . "branches"
    let result = result . "\nBranches:\n" . vc#utils#execshellcmd(cmd)
    retu result
endf

fun! vc#hg#infolog(argsd)
    retu vc#hg#info(a:argsd)
endf
" 2}}}

"status {{{2
"argsd  = {'cargs': command_args, 'meta': meta }
fun! vc#hg#status(argsd)
    let cargs = get(a:argsd, 'cargs', '')
    let [incoming, outgoing, entries] = [ [], [], []]
    
    let outgoing = s:outgoing(a:argsd.meta)
    let cmd = s:precmd(a:argsd.meta) . "status " . cargs . " " . a:argsd.meta.fpath 
    let [entries, cmd] = vc#utils#statussummary(cmd, a:argsd.meta.wrd)

    let resultlst = []
    call extend(resultlst, outgoing)
    call extend(resultlst, entries)
    retu [cmd, resultlst]
endf

fun! vc#hg#statuscmdops(argsd)
    retu ["--all", "--modified", "--added", "--removed", "--deleted", "--clean", "--ignored"]
endf

fun! s:outgoing(meta)
    let statuslist = []
    try
        let cmd = s:precmd(a:meta) . "outgoing -q -l1 --template=\"{files}\""
        let shellout = vc#utils#execshellcmd(cmd)
        let pending = len(split(shellout, '\n'))
        if pending > 0
            let statusentryd = {}
            let statusentryd.modtype = "INFO"
            let statusentryd.line = g:vc_info_str ." Pending outgoing use VCPush"
            let statusentryd.fpath = "-"
            call add(statuslist, statusentryd)
        endif
    catch | endtry
    unlet! shellout
    retu statuslist
endf
"2}}}

"logs {{{2
fun! vc#hg#logtitle(argsd)
    let relpath = fnamemodify(expand(a:argsd.meta.fpath), ':.')
    retu "-hg " . s:fmtdbranchname(a:argsd.meta) . relpath
endf

"argsd  = {'cargs': command_args, 'meta': meta }
fun! vc#hg#logs(argsd)
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
            let logentry.line = revision . ' ' . join(contents[1:], '|')
            call add(logentries, logentry)
            call add(g:vc_logversions, revision)
        endfor
        unlet! shellist
    catch 
        call vc#utils#dbgmsg("At s:logrtrv", v:exception)
    endtry
    retu [logentries, a:cmd]
endf

fun! s:logcmd(meta, argslst)
    let argslst = []
    if index(a:argslst, "-l") < 0 
        call extend(argslst, ["-l", g:vc_max_logs])
    endif
    call extend(argslst, a:argslst)
    let log_template = " --template=\"{rev},{branch},{author},{date|isodate},{desc|firstline},{d}\\n \" "
    retu s:precmd(a:meta) . "log " . log_template . join(argslst, " ") . " -- " . a:meta.fpath
endf

fun! s:logcmdops()
    retu ["-d", "--date", "--rev", "-r", "-u", "-l", ]
endf

fun! vc#hg#logcmdops(argsd) 
    let cargs = s:logcmdops()
    if has_key(a:argsd, "meta")
        let branches = map(vc#hg#branches(a:argsd.meta), '"-b " . v:val . ""')
        retu extend(cargs, branches)
    else
        retu cargs
    endif
endf

fun! vc#hg#logmenu(argsd) 
    let [menus, errmsg] = [[], ""]
    call add(menus, vc#dict#menuitem("Branches", 'vc#hg#lstlbranches', ""))
    retu [menus, errmsg]
endf

fun! vc#hg#lbranchlogs(argsd) 
    retu s:branchlogs(a:argsd, 1)
endf

fun! s:branchlogs(argsd, islocal)
    try
        let [adict, akey] = [a:argsd.dict, a:argsd.key]
        let bname = adict.menud.contents[akey].convert
        let title = "Log " . vc#hg#frmtbranchname(bname) . ' ' . adict.meta.repoUrl
        
        let cmd = s:logcmd(adict.meta, [ "-b " . bname,])
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

"affected files {{{2
fun! vc#hg#affectedfiles(meta, revision)
    let cmd = s:precmd(a:meta) . "status --change " . a:revision
    retu vc#utils#statussummary(cmd, a:meta.wrd)
endf

fun! vc#hg#affectedfilesacross(meta, revisionA, revisionB) 
    let cmd = s:precmd(a:meta) . "status --rev ". a:revisionA . ':' . a:revisionB . ' ' .
                \ a:meta.fpath
    retu vc#utils#statussummary(cmd, a:meta.wrd)
endf
"2}}}

" diff {{{2
" argsd = {'bang': '', 'meta': meta, 'revision':revision}
fun! vc#hg#diff(argsd)
    let logargsd = {"meta": a:argsd.meta, "cargs": "-l " . g:vc_max_logs}
    call vc#hg#logs(logargsd)
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

fun! vc#hg#diffcmd(argsd) 
    retu vc#hg#opencmd(a:argsd)
endf

fun! vc#hg#infodiffcmds(argsd)
    retu [["Revision Info:", s:precmd(a:argsd.meta) . 'log -r' . a:argsd.revision]]
endf
"2}}}

fun! vc#hg#revertcmd(argsd)    "{{{2
    retu s:precmd(a:argsd.meta) . "revert " . a:argsd.cargs . " " . a:argsd.meta.fpath
endf
"2}}}

fun! vc#hg#commitcmd(commitlog, flist, argsd) "{{{2
    let fliststr = join(a:flist, " ")
    let cargs = has_key(a:argsd, "cargs") ? a:argsd.cargs : ""
    if a:commitlog == "!"
        let cmd = s:precmd(a:argsd.meta) . "commit -m \"No comments\" " . cargs . " " . fliststr
    else
        let cmd = s:precmd(a:argsd.meta) . "commit -l " . a:commitlog . " " . cargs . " " . fliststr
    endif
    retu cmd
endf

fun! vc#hg#commitcmdops(...)
    retu ["-d", "-u" , "-m"]
endf
" 2}}}

fun! vc#hg#addcmd(argsd) "{{{2
    if !exists("b:vc_meta") | retu vc#utils#showerr("Failed to rtrv meta") | en
    let cargs = has_key(a:argsd, "cargs") ? a:argsd.cargs : ""
    retu s:precmd(b:vc_meta) . "add " . cargs . " " . join(a:argsd.files, " ")
endf
"2}}}

fun! vc#hg#copy(argsd)  "{{{2
    try
        let [meta, topath, flist] = [a:argsd.meta, a:argsd.topath, a:argsd.flist]
        let cmd = s:precmd(meta) . "copy " . join(flist, " ") . " " . topath
        retu [vc#passed(), cmd]
    catch 
        call vc#utils#dbgmsg("At vc#hg#copy", v:exception)
    endt
    retu [vc#failed(), ""]
endf
"2}}}

fun! vc#hg#move(argsd)  "{{{2
    try
        let [meta, topath, flist] = [a:argsd.meta, a:argsd.topath, a:argsd.flist]
        let cmd = s:precmd(meta) . "move -v " . get(a:argsd, "cargs", "") . " ".  
                    \ join(flist, " ") . " " . topath
        retu [vc#passed(), cmd]
    catch 
        call vc#utils#dbgmsg("At vc#hg#move", v:exception)
    endt
    retu [vc#failed(), ""]
endf

fun! vc#hg#movecmdops(argsd)
    retu [ "--dry-run" ]
endf
"2}}}


"push {{{2
fun! vc#hg#pushcmdops(argsd)
    let cargs = ["--force", "--branch", "--rev"]
    let branches = map(vc#hg#branches(a:argsd.meta), '"-b " . v:val . ""')
    retu extend(cargs, branches)
endf

fun! vc#hg#push(argsd)
    let cmd = s:precmd(a:argsd.meta) . 'push ' . a:argsd.cargs
    retu vc#utils#execshellcmduseexec(cmd, 1)
endf
"2}}}

"pull {{{2
fun! vc#hg#pullcmdops(argsd)
    let cargs = ["--force", "--update", "--branch"]
    let branches = map(vc#hg#branches(a:argsd.meta), '"-b " . v:val . ""')
    retu extend(cargs, branches)
endf

fun! vc#hg#pull(argsd)  
    let cmd = s:precmd(a:argsd.meta) . 'pull ' . a:argsd.cargs
    retu vc#utils#execshellcmduseexec(cmd, 1)
endf
"2}}}

"incoming {{{2
fun! vc#hg#incomingcmdops(argsd)
    let cargs = ["--newest-first", "--rev", "--limit", "--no-merges"]
    retu cargs
endf

fun! vc#hg#incoming(argsd)  
    let template = " --template=\"{rev},{files}{branch},{user},{date|isodate},{desc|firstline},{d}\\n \" "
    let cmd = s:precmd(a:argsd.meta) . 'incoming -q ' . a:argsd.cargs . template
    retu s:logrtrv(cmd)
endf
"2}}}

"outgoing {{{2
fun! vc#hg#outgoingcmdops(argsd)
    let cargs = ["--newest-first", "--rev", "--limit", "--no-merges"]
    retu cargs
endf

fun! vc#hg#outgoing(argsd)  
    let template = " --template=\"{rev},{files}{branch},{desc|firstline},{d}\\n \" "
    let cmd = s:precmd(a:argsd.meta) . 'outgoing -q ' . a:argsd.cargs . template
    retu s:logrtrv(cmd)
endf
"2}}}

fun! vc#hg#opencmd(argsd) "{{{2
    let arevision = get(a:argsd, 'revision', '')
    let rbranch = get(a:argsd, 'rbranch', '' )
    let meta = vc#hg#meta(a:argsd.path)

    let precmd = s:precmd(meta) . "cat "
    if rbranch != ""
        let cmd = precmd . rbranch . " -r" . arevision . " " . meta.repoUrl
    elseif arevision != ""
        let cmd = precmd . " -r" . arevision . " " . meta.repoUrl
    else
        let cmd = precmd . arevision . " " . meta.fpath
    endif
    retu cmd
endf 
"2}}}

fun! vc#hg#blamecmd(argsd) "{{{2
    let cmd = s:precmd(a:argsd.meta) . "blame -ulqdc " . a:argsd.meta.fpath
    retu cmd
endf
"2}}}

fun! vc#hg#browseentries(path, argsd)   "{{{2
    if a:argsd.meta.local 
        let a:argsd.title = s:fmtdbranchname(a:argsd.meta) . a:argsd.title
        retu call('vc#utils#lstfiles', [a:path, a:argsd.brecursive, 0])
    else
        retu []
    endif
endf
"2}}}

"Branches "{{{2
fun! s:fmtdbranchname(meta)
    retu vc#hg#frmtbranchname(vc#hg#curbranchname(a:meta))
endf

fun! vc#hg#frmtbranchname(name)
    retu len(a:name) > 0 ? "[" . a:name . "] " : ""
endf

fun! vc#hg#curbranchname(meta)
    let name = ""
    try
        let cmd =  s:precmd(a:meta) . 'branch'
        let names = split(vc#utils#execshellcmd(cmd), "\n")
        if len(names) >= 1 
            retu names[0] 
        endif

    catch 
        call vc#utils#dbgmsg("At vc#hg#curbranchname", v:exception) 
    endtry
    retu name
endf

fun! vc#hg#lstlbranches(argsd) 
    let [adict, akey] = [a:argsd.dict, a:argsd.key]
    let meta = deepcopy(adict.meta)
    let ldict = vc#dict#new("local branches", {"meta" : meta})
    let lnames = vc#hg#branches(meta)

    if empty(lnames) 
        call vc#dict#adderrup(ldict, "Nothing here : ", ldict.meta.cmd)
    endif

    let curbranch = vc#hg#curbranchname(meta)
    for bname in lnames
        if curbranch == bname | cont | en
        call vc#dict#addentries(ldict, 'menud',
            \ [vc#dict#menuitem(bname,'vc#hg#lbranchlogs', bname)], 
            \ vc#gopshdlr#menuops())
    endfor

    unlet! a:argsd.dict
    let a:argsd.dict = ldict
    call vc#winj#populate(ldict)
endf

fun! vc#hg#branches(meta) 
    let lnames = []
    try
        let cmd = s:precmd(a:meta) . "branches"
        let lnames = split(vc#utils#execshellcmd(cmd), "\n")
        let lnames = map(lnames, 'split(vc#utils#strip(v:val))[0]')
    catch | call vc#utils#dbgmsg("vc#hg#branches", v:exception) | endtry
    retu lnames
endf
"2}}}
