" =============================================================================
" File:         autoload/repos.vim
" Description:  repos delegator sorta, TODO have a register method to add more
"               repos
" Author:       Juneed Ahamed
" =============================================================================

"autoload/repos.vim {{{1

" mappings    {{{2
let s:maps = { 
        \ "repos": {
            \ "keys": ["-svn", "-git", "-hg", "-bzr"],
            \ },
        \ "na": {
            \ "frmtrevfname": "vc#fs#formatrevisionandfname",
            \ },
        \ "-fs": {
            \ "meta": "vc#fs#meta",
            \ "info": "vc#fs#info",
            \ "browse.info": "vc#fs#browseinfo",
            \ "browse.copycmd": "vc#fs#copy",
            \ "browse.movecmd": "vc#fs#domove",
            \ "browse.entries": "vc#svn#browseentries",
            \ "frmtrevfname": "vc#fs#formatrevisionandfname",
            \ },
        \ "-bzr": {
            \ "meta": "vc#bzr#meta",
            \ "inrepodir": "vc#bzr#inrepodir",
            \ "member": "vc#bzr#member",
            \ "status.ops": "vc#status#statusops",
            \ "status.rtrv": "vc#bzr#status",
            \ "browse.entries": "vc#bzr#browseentries",
            \ "log.ops": "vc#log#logops",
            \ "log.title": "vc#bzr#logtitle",
            \ "log.rtrv": "vc#bzr#logs",
            \ "log.cmdops": "vc#bzr#logcmdops",
            \ "log.menu": "vc#bzr#logmenu",
            \ "affectedfiles": "vc#bzr#affectedfiles",
            \ "affectedfilesAcross": "vc#bzr#affectedfilesacross",
            \ "affectedfiles.ops": "vc#git#affectedops",
            \ "addcmd": 'vc#bzr#addcmd',
            \ "addops": 'vc#add#addops',
            \ "addopsdscr": 'vc#add#addopsdscr',
            \ "add.cmdops": 'vc#bzr#addcmdops',
            \ "commitcmd": 'vc#bzr#commitcmd',
            \ "commitops": 'vc#commit#commitops',
            \ "commitopsdscr": 'vc#commit#commitopsdscr',
            \ "commit.cmdops": 'vc#bzr#commitcmdops',
            \ "diff": "vc#bzr#diff", 
            \ "diffcmd": "vc#bzr#diffcmd",
            \ "blamecmd": "vc#bzr#blamecmd",
            \ "opencmd": "vc#bzr#opencmd",
            \ "info": "vc#bzr#info", 
            \ "log.info": "vc#bzr#info",
            \ "diff.infocmds": "vc#bzr#infodiffcmds", 
            \ "browse.info": "vc#gopshdlr#info",
            \ "pull": "vc#bzr#pull",
            \ "push.cmdops": "vc#bzr#pushcmdops",
            \ "push": "vc#bzr#push",
            \ "revertcmd": "vc#bzr#revertcmd",
            \ "frmtrevfname": "vc#utils#formatrevisionandfname",
            \},
        \ "-hg": {
            \ "meta": "vc#hg#meta",
            \ "inrepodir": "vc#hg#inrepodir",
            \ "member": "vc#hg#member",
            \ "info": "vc#hg#info", 
            \ "status.ops": "vc#status#statusops",
            \ "status.rtrv": "vc#hg#status",
            \ "status.cmdops": "vc#hg#statuscmdops",
            \ "log.ops": "vc#log#logops",
            \ "log.title": "vc#hg#logtitle",
            \ "log.rtrv": "vc#hg#logs",
            \ "log.menu": "vc#hg#logmenu",
            \ "log.cmdops": "vc#hg#logcmdops",
            \ "log.info": "vc#hg#infolog",
            \ "affectedfiles": "vc#hg#affectedfiles",
            \ "affectedfilesAcross": "vc#hg#affectedfilesacross",
            \ "affectedfiles.ops": "vc#git#affectedops",
            \ "browse.entries": "vc#hg#browseentries",
            \ "browse.info": "vc#gopshdlr#info",
            \ "browse.copycmd": "vc#hg#copy",
            \ "browse.movecmd": "vc#hg#move",
            \ "move.cmdops": "vc#hg#movecmdops",
            \ "diff": "vc#hg#diff", 
            \ "diffcmd": "vc#hg#diffcmd",
            \ "diff.infocmds": "vc#hg#infodiffcmds", 
            \ "addcmd": 'vc#hg#addcmd',
            \ "addops": 'vc#add#addops',
            \ "addopsdscr": 'vc#add#addopsdscr',
            \ "commitcmd": 'vc#hg#commitcmd',
            \ "commit.cmdops": 'vc#hg#commitcmdops',
            \ "commitops": 'vc#commit#commitops',
            \ "commitopsdscr": 'vc#commit#commitopsdscr',
            \ "opencmd": "vc#hg#opencmd",
            \ "blamecmd": "vc#hg#blamecmd",
            \ "push": "vc#hg#push",
            \ "push.cmdops": "vc#hg#pushcmdops",
            \ "pull": "vc#hg#pull",
            \ "pull.cmdops": "vc#hg#pullcmdops",
            \ "incoming": "vc#hg#incoming",
            \ "incoming.cmdops": "vc#hg#incomingcmdops",
            \ "outgoing": "vc#hg#outgoing",
            \ "outgoing.cmdops": "vc#hg#outgoingcmdops",
            \ "revertcmd": "vc#hg#revertcmd",
            \ "frmtrevfname": "vc#utils#formatrevisionandfname",
            \ "frmtbranchname": "vc#hg#frmtbranchname",
            \},
        \ "-svn": {
            \ "inrepodir": "vc#svn#inrepodir",
            \ "meta": "vc#svn#meta",
            \ "member": "vc#svn#validurl",
            \ "info": "vc#svn#info", 
            \ "status.ops": "vc#status#statusops",
            \ "status.rtrv": "vc#svn#status",
            \ "status.cmdops": "vc#svn#statuscmdops",
            \ "status.vcnoparse": "vc#svn#status_vcnoparse", 
            \ "log.ops": "vc#svn#logops",
            \ "log.title": "vc#svn#logtitle",
            \ "log.rtrv": "vc#svn#logs",
            \ "log.menu": "vc#svn#logmenu",
            \ "log.cmdops": "vc#svn#logcmdops",
            \ "log.info": "vc#svn#infolog",
            \ "lcr": "vc#svn#lastchngdrev",
            \ "diff.vcnoparse": "vc#svn#diff_vcnoparse", 
            \ "diff.changes": "vc#svn#changes", 
            \ "diff": "vc#svn#diff", 
            \ "diffcmd": "vc#svn#diffcmd",
            \ "diff.cmdops": "vc#svn#diffcmdops",
            \ "diff.infocmds": "vc#svn#infodiffcmds", 
            \ "affectedfiles": "vc#svn#affectedfiles",
            \ "affectedfilesAcross": "vc#svn#affectedfilesacross",
            \ "affectedfiles.ops": "vc#svn#affectedops",
            \ "opencmd": "vc#svn#opencmd",
            \ "blamecmd": "vc#svn#blamecmd",
            \ "commitcmd": 'vc#svn#commitcmd',
            \ "commitops": 'vc#commit#commitops',
            \ "commitopsdscr": 'vc#commit#commitopsdscr',
            \ "commit.cmdops": 'vc#svn#commitcmdops',
            \ "addcmd": 'vc#svn#addcmd',
            \ "addops": 'vc#add#addops',
            \ "addopsdscr": 'vc#add#addopsdscr',
            \ "browse.info": "vc#gopshdlr#info",
            \ "browse.infolist": "vc#svn#infolist",
            \ "browse.copycmd": "vc#svn#docopy",
            \ "browse.movecmd": "vc#svn#domove",
            \ "browse.entries": "vc#svn#browseentries",
            \ "browse.checkout": "vc#svn#checkout",
            \ "revertcmd": "vc#svn#revertcmd",
            \ "frmtrevfname": "vc#utils#formatrevisionandfname",
            \ "frmtbranchname": "vc#svn#frmtbranchname",
            \ },
        \ "-git": {
            \ "meta": "vc#git#meta",
            \ "inrepodir": "vc#git#inrepodir",
            \ "member": "vc#git#member",
            \ "info": "vc#git#info", 
            \ "status.ops": "vc#status#statusops",
            \ "status.rtrv": "vc#git#status",
            \ "status.cmdops": "vc#git#statuscmdops",
            \ "status.vcnoparse": "vc#git#status_vcnoparse", 
            \ "log.ops": "vc#log#logops",
            \ "log.title": "vc#git#logtitle",
            \ "log.rtrv": "vc#git#logs",
            \ "log.menu": "vc#git#logmenu",
            \ "log.cmdops": "vc#git#logcmdops",
            \ "log.info": "vc#git#infolog",
            \ "lcr": "vc#git#lastchngdrev",
            \ "diff": "vc#git#diff", 
            \ "diff.vcnoparse": "vc#git#diff_vcnoparse", 
            \ "diff.changes": "vc#git#changes", 
            \ "diffcmd": "vc#git#diffcmd",
            \ "diff.cmdops": "vc#git#diffcmdops",
            \ "diff.infocmds": "vc#git#infodiffcmds", 
            \ "affectedfiles": "vc#git#affectedfiles",
            \ "affectedfilesAcross": "vc#git#affectedfilesacross",
            \ "affectedfiles.ops": "vc#git#affectedops",
            \ "opencmd": "vc#git#opencmd",
            \ "blamecmd": "vc#git#blamecmd",
            \ "commitcmd": 'vc#git#commitcmd',
            \ "commitops": 'vc#git#commitops',
            \ "commitopsdscr": 'vc#git#commitopsdscr',
            \ "commit.cmdops": 'vc#git#commitcmdops',
            \ "addcmd": 'vc#git#addcmd',
            \ "addops": 'vc#add#addops',
            \ "addopsdscr": 'vc#add#addopsdscr',
            \ "add.cmdops": 'vc#git#addcmdops',
            \ "browse.info": "vc#gopshdlr#info",
            \ "browse.entries": "vc#git#browseentries",
            \ "browse.movecmd": "vc#git#domove",
            \ "frmtrevfname": "vc#utils#formatrevisionandfname",
            \ "frmtbranchname": "vc#git#frmtbranchname",
            \ "push": "vc#git#push",
            \ "push.cmdops": "vc#git#pushcmdops",
            \ "fetch": "vc#git#fetch",
            \ "fetch.cmdops": "vc#git#fetchcmdops",
            \ "pull": "vc#git#pull",
            \ "pull.cmdops": "vc#git#pullcmdops",
            \ "move.cmdops": "vc#git#movecmdops",
            \ "revertcmd": "vc#git#revertcmd",
            \ }
        \}
"2}}}

fun! vc#repos#hasop(repo, op)  "{{{2
    if !has_key(s:maps, a:repo)
        retu [vc#failed(), "Unsupported repo " . a:repo]
    endif
    if !has_key(s:maps[a:repo], a:op)
        retu [vc#failed(), "Unsupported operation " . a:op . " on " . a:repo]
    endif
    retu [vc#passed(), s:maps[a:repo][a:op]]
endf
"2}}}

fun! vc#repos#meta(entity, forcerepo)  "{{{2
    try
        let repo = ""
        let forcerepo = a:forcerepo == "" ?  g:vc_default_repo : a:forcerepo
        for repokey in vc#repos#repos()
            if forcerepo ==? repokey && vc#repos#call(repokey, "inrepodir", a:entity)
                let repo = repokey
                break
            endif
        endfor
        
        if repo == "" | let repo = s:id(a:entity) | en
        let meta = call(s:maps[repo].meta, [a:entity])
        retu meta
    catch 
        call vc#utils#dbgmsg("At vc#repos#meta :", v:exception)
    endtry
    throw "Unsupported repository or operation"
endf
"2}}}

fun! vc#repos#member(path, forcerepo)  "{{{2  Returns the repo
    if a:forcerepo != "" &&
                \ vc#repos#hasop(a:forcerepo, "member")[0] == vc#passed() && 
                \ vc#repos#call(a:forcerepo, "member", a:path)
        return a:forcerepo
    endif

    for repokey in vc#repos#repos()
        if vc#repos#hasop(repokey, "member")[0] == vc#passed() && vc#repos#call(repokey, "member", a:path)
            retu repokey
        endif
    endfor
    retu "-fs"
endf
"2}}}

fun! vc#repos#call(repo, fn, ...)  "{{{2
    let [status, msg] = vc#repos#hasop(a:repo, a:fn)
    if status == vc#failed() | throw msg | en
    retu call(s:maps[a:repo][a:fn], a:000)
endf
"2}}}

fun! s:id(entity)  "{{{2
    let repo = "-fs"
    for repokey in vc#repos#repos()
        if vc#repos#call(repokey, "inrepodir", a:entity) | let repo = repokey | break | en
    endfor
    retu repo
endf

fun! vc#repos#repos()
    retu filter(copy(s:maps.repos.keys), 'index(g:vc_ignore_repos_lst, v:val) < 0' )
endf

fun! vc#repos#repopatt()
    let repos = vc#repos#repos()
    retu '\M\(^\|\s\)' . join(map(copy(repos), '"\\(" . v:val . "\\)"'), "\\|") . '\($\|\s\)'
    "pattern": '\M\(^\|\s\)\(-svn\|-git\)\($\|\s\)',
    "retu s:maps.repos.pattern
endf
"2}}
