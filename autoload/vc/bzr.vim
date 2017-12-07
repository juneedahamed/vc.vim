"===============================================================================
" File:         autoload/vc/bzr.vim
" Description:  bzr Commands
" Author:       Juneed Ahamed
"===============================================================================

" vars "{{{2
let s:CMD_PRE = "bzr "

fun! s:precmd(meta)
    retu printf('%s ', s:CMD_PRE)
endf
"2}}}

fun! vc#bzr#meta(entity) "{{{2
    let fullpath = vc#utils#fnameescape(fnamemodify(a:entity, ':p'))
    let [result, wrd] = s:fetchwrd(a:entity)
    let metad = {}
    let metad.repo = "-bzr"
    let metad.entity = a:entity   "Name as given from input
    let metad.fpath = fullpath "Full path on disk
    let metad.isdir = vc#utils#isdir(fullpath) 
    let metad.local = 1
    let metad.branch = ""
    let metad.rbranch = ""
    let metad.wrd = wrd
    let metad.bzrdir = vc#utils#joinpath(wrd, ".bzr")
    "Path with respect to repo
    let metad.repoUrl = vc#utils#fnameescape(substitute(fullpath, wrd, '', ''))
    let b:vc_file_meta = metad
    retu metad
endf

fun! vc#bzr#inrepodir(entity)
    let [result, wrd] = s:fetchwrd(a:entity)
    retu result
endf

fun! s:fetchwrd(entity)
    let [result, wrd] = [vc#failed(), ""]
    let cmd = s:CMD_PRE . "root " . a:entity
    try
        let shellout = vc#utils#execshellcmd(cmd)
        let shelloutlist = split(shellout, '\n')
        unlet! shellout
        let wrd = shelloutlist[0]
        let result = vc#passed()
    catch | endtry
    retu [result, vc#utils#fnameescape(wrd)]
endf

fun! vc#bzr#member(entity)
    let [result, wrd] = s:fetchwrd(a:entity)
    if result == vc#passed()
        let meta = vc#bzr#meta(a:entity)
        let cmd = s:precmd(meta) . "status -S " . a:entity
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

fun! vc#bzr#diff(argsd) "{{{2
    let logargsd = {"meta": a:argsd.meta, "cargs": "-l " . g:vc_max_logs}
    call vc#bzr#logs(logargsd)
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

fun! vc#bzr#blamecmd(argsd) "{{{2
    retu s:precmd(a:argsd.meta) . "blame " . a:argsd.meta.fpath
endf
"2}}}

fun! vc#bzr#revertcmd(argsd)    "{{{2
    retu s:precmd(a:argsd.meta) . "revert " . a:argsd.cargs . " " . a:argsd.meta.fpath
endf
"2}}}

"status {{{2
fun! vc#bzr#status(argsd)
    let cargs = get(a:argsd, 'cargs', '')
    let cmd = s:precmd(a:argsd.meta) . "status -S " . cargs . " " . a:argsd.meta.fpath 
    let [entries, cmd] = vc#utils#statussummary(cmd, a:argsd.meta.wrd)
    retu [cmd, entries]
endf
"2}}}

fun! vc#bzr#copy(argsd)  "{{{2
    try
        let [meta, topath, flist] = [a:argsd.meta, a:argsd.topath, a:argsd.flist]
        let cmd = s:precmd(meta) . "copy " . join(flist, " ") . " " . topath
        retu [vc#passed(), cmd]
    catch 
        call vc#utils#dbgmsg("At vc#bzr#copy", v:exception)
    endt
    retu [vc#failed(), ""]
endf
"2}}}

fun! vc#bzr#browseentries(path, argsd)   "{{{2
    if a:argsd.meta.local 
        retu call('vc#utils#lstfiles', [a:path, a:argsd.brecursive, 0])
    endif
    retu []
endf
"2}}}

"logs {{{2
fun! vc#bzr#logtitle(argsd)
    let relpath = fnamemodify(expand(a:argsd.meta.fpath), ':.')
    retu "-bzr " . relpath
endf

fun! vc#bzr#logs(argsd)
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
            let contents = split(curline, ':')
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
    retu s:precmd(a:meta) . "log --line " . join(argslst, " ") . " " . a:meta.fpath
endf

fun! vc#bzr#logcmdops(argsd) 
    retu ["-d", "--date", "--rev", "-r", "--authors", "-l", "-b"]
endf

fun! vc#bzr#logmenu(argsd) 
    let [menus, errmsg] = [[], ""]
    call add(menus, vc#dict#menuitem("Browse", 'vc#bzr#browse', ''))
    retu [menus, errmsg]
endf
"2}}}

"affected files {{{2
fun! vc#bzr#affectedfiles(meta, revision)
    let cmd = s:precmd(a:meta) . "status -S -c " . a:revision
    retu vc#utils#statussummary(cmd, a:meta.wrd)
endf

fun! vc#bzr#affectedfilesacross(meta, revisionA, revisionB) 
    let cmd = s:precmd(a:meta) . "status -S -r ". a:revisionA . '..' . a:revisionB . ' ' .
                \ a:meta.fpath
    retu vc#utils#statussummary(cmd, a:meta.wrd)
endf
"2}}}

fun! vc#bzr#browse(key) "{{{2
    retu vc#browse#menu('vc#winj#populate')
endf
"2}}}

fun! vc#bzr#diffcmd(argsd)  "{{{2
    retu vc#bzr#opencmd(a:argsd)
endf
"2}}}

fun! vc#bzr#opencmd(argsd) "{{{2
    let arevision = get(a:argsd, 'revision', '')
    let meta = vc#bzr#meta(a:argsd.path)

    let precmd = s:precmd(meta) . "cat "
    if arevision != ""
        let cmd = precmd . " -r" . arevision . " " . meta.fpath
    else
        let cmd = precmd . " " . meta.fpath
    endif
    retu cmd
endf 
"2}}}

" commit "{{{2
fun! vc#bzr#commitcmdops(...) 
    retu ["--local", "--author", "--fixes", "-m"]
endf

fun! vc#bzr#commitcmd(commitlog, flist, argsd)
    let fliststr = join(a:flist, " ")
    let cargs = has_key(a:argsd, "cargs") ? a:argsd.cargs : ""
    if a:commitlog == "!"
        let cmd = s:precmd(a:argsd.meta) . "commit -m \"\" " . cargs . " " . fliststr
    else
        let cmd = s:precmd(a:argsd.meta) . "commit -F " . a:commitlog . " " . cargs . " " . fliststr
    endif
    retu cmd    
endf
"2}}}

" add {{{2
fun! vc#bzr#addcmdops(...) 
    retu ["--dry-run",]
endf

fun! vc#bzr#addcmd(argsd)
    if !exists("b:vc_meta") | retu vc#utils#showerr("Failed to rtrv meta") | en
    let cargs = has_key(a:argsd, "cargs") ? a:argsd.cargs : ""
    retu s:precmd(b:vc_meta) . "add " . cargs . " " . join(a:argsd.files, " ")
endf
"2}}}

"info access {{{2
fun! vc#bzr#info(argsd)
    let result = "Info \n"
    let cmd = s:precmd(a:argsd.meta) . "info -v " . a:argsd.meta.fpath
    let result = result . "\n" . vc#utils#execshellcmd(cmd)
    let result = result . "\nVersion info \n"
    let cmd = s:precmd(a:argsd.meta) . "version-info -- " . a:argsd.meta.fpath
    let result = result . "\n" . vc#utils#execshellcmd(cmd)
    retu result
endf

fun! vc#bzr#infodiffcmds(argsd)
    retu [["Revision Info:", s:precmd(a:argsd.meta) . 'log -r' . b:vc_revision]]
endf
" 2}}}

fun! vc#bzr#pull(argsd)   "{{{2
    let cmd = s:precmd(a:argsd.meta) . 'pull ' . a:argsd.cargs
    retu vc#utils#execshellcmduseexec(cmd, 1)
endf
"2}}}

"push {{{2
fun! vc#bzr#pushcmdops(argsd)
    retu [":parent",]
endf

fun! vc#bzr#push(argsd)   
    let cmd = s:precmd(a:argsd.meta) . 'push ' . a:argsd.cargs
    retu vc#utils#execshellcmduseexec(cmd, 1)
endf
"2}}}
