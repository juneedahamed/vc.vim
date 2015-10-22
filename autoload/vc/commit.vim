"===============================================================================
" File:         autoload/vc/commit.vim
" Description:  VC Commit ci
" Author:       Juneed Ahamed
"===============================================================================

"vc#commit.vim {{{1
fun! vc#commit#commitops(meta, cargs)  "{{{2
    let commitargs = {"meta": a:meta, "cargs":a:cargs}
    retu {
        \ "<c-z>": {"fn": "vc#commit#commit", "args": commitargs,},
        \ "<c-q>": {"fn": "vc#commit#done", "args": []}, 
        \ }
endf

fun! vc#commit#commitopsdscr(meta) 
    retu [
        \ "Ctrl-z: Commit Files",
        \ "Ctrl-q: Quit",
        \ ]
endf
"2}}}

fun! vc#commit#Commit(bang, ...) "{{{2
    try
        call vc#init()
        let arglst = copy(a:000)
        let comments = a:bang == "!"? "" : vc#argsremoveparam(arglst, "-m", 0, 1)
        let disectd = vc#argsdisectlstmultipletargets(arglst, "all")
        let [cfiles, cargs] = [disectd.targets, disectd.cargs]
        let meta = vc#repos#meta(cfiles[0], disectd.forcerepo)
        let argsd = {"files": cfiles, "meta": meta, "cargs": cargs, "comments": comments}

        let [supported, msg] = vc#repos#hasop(argsd.meta.repo, "commitcmd")
        if !supported | retu vc#utils#showerr(msg) | en
        
        let g:vc_files_to_commit = []
        call add(g:vc_files_to_commit, argsd)
        retu a:bang == "!" ? s:commitnocomments(argsd) : vc#commit#prepcommit()
    catch | retu vc#utils#showerr(v:exception) | endt
endf
"2}}}

fun! vc#commit#prepcommit() "{{{2
    if len(g:vc_files_to_commit) > 0 
        let argsd = remove(g:vc_files_to_commit, len(g:vc_files_to_commit) -1)
        if vc#repos#hasop(argsd.meta.repo, "commitcmd")[0] != vc#passed()
            call vc#utils#showerr("Commit not supported for " . argsd.meta.repo)
            return vc#commit#prepcommit()
        endif
        let [meta, cfiles, cargs, comments] = [argsd.meta, argsd.files, get(argsd, "cargs", ""),
                    \ get(argsd, "comments", "")]
        if len(cfiles) > 0
            call vc#blank#win(vc#repos#call(meta.repo, "commitops", meta, cargs))
            call vc#blank#onwrite('vc#commit#commit', {"meta":meta, 'cargs': cargs})
            let commitopsdscr = vc#repos#call(meta.repo, "commitopsdscr", meta)
            let hlines = vc#utils#commitheader(meta, cfiles, commitopsdscr)
            let result = vc#utils#writetobuffer("vc_bwindow", hlines)
            call vc#blank#appendline(comments)
            let &l:stl = vc#utils#stl("VCCommit", "")
        endif
        setlocal nomodified
    else
        setlocal nomodified
        call vc#blank#closeme()
    endif
endf
"2}}}

fun! vc#commit#done(...)  "{{{2
    call vc#commit#prepcommit()
endf
"2}}}

fun! vc#commit#commit(argd)  "{{{2
    let commitlog = ""
    try
        let [cfiles, comments] = vc#commit#parseclog()

        let docommitargs = {"files": cfiles, "comments": comments, "meta": a:argd.meta }
        if has_key(a:argd, "cargs") | let docommitargs["cargs"] = a:argd.cargs | en

        let result = len(comments) > 0 ? vc#commit#docommit(docommitargs) : 
                    \ s:confirmnocomments(a:argd, cfiles)

        if result == vc#cancel() | retu vc#cancel() | en
    catch
        call vc#utils#showerr(v:exception)
        retu vc#failed()
    finally
        if len(commitlog) > 0 | call delete(commitlog) | en
    endtry
    retu vc#commit#done()
endf
"2}}}

"utils
fun! vc#commit#parseclog() "{{{2
    let [cfiles, comments] = [[], []]

    for line in getline(1, line('$'))
        let line = vc#utils#strip(line)
        if len(line) > 0 && matchstr(line, '^VC:') == ""
            call add(comments , line) 
        elseif matchstr(line, '^VC:+') != ""
            let line = vc#utils#strip(substitute(line, '^VC:+', "", ""))
            if index(cfiles, line) < 0 | call add(cfiles, line) | en
        endif
    endfor
    retu [cfiles, comments]
endf
"2}}}

fun! vc#commit#docommit(argsd) "{{{2
    let [comments, cfiles] = [a:argsd.comments, a:argsd.files]
    let commitlog = vc#caop#commitlog()

    if filereadable(commitlog) | call delete(commitlog) | en
    call writefile(comments, commitlog)
    let cmd = vc#repos#call(a:argsd.meta.repo, 'commitcmd', commitlog, cfiles, a:argsd)
    retu vc#utils#execshellcmdinteractive(cmd)[0]
endf
"2}}}

fun! s:confirmnocomments(argd, cfiles) "{{{2
    echohl Question | echo "No comments"
    echo "Press c to commit without comments, q to abort, Any key to edit : "
    echohl None
    let choice = vc#utils#getchar()
    if choice ==? 'c' 
        let theargd = {"meta": a:argd.meta, "files": a:cfiles, "cargs": get(a:argd, "cargs", "")}
        retu s:commitnocomments(theargd)
    endif
    retu choice !=? 'q' ? vc#cancel() : vc#failed()
endf
"2}}}

fun! s:commitnocomments(argd) "{{{2
    let [meta, cfiles, cargs] = [a:argd.meta, a:argd.files, get(a:argd, "cargs", "")]
    let cmd = vc#repos#call(meta.repo, 'commitcmd', "!", cfiles, a:argd)
    retu vc#utils#execshellcmdinteractive(cmd)[0]
endf
"2}}}
"
"1}}}
