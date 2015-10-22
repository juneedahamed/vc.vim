"===============================================================================
" File:         autoload/vc/add.vim
" Description:  VCAdd (svn, git add) and svn ci
" Author:       Juneed Ahamed
"===============================================================================

"vc#add.vim {{{1

fun! vc#add#addops(meta, cargs)  "{{{2
    let argd = {"meta": a:meta, "cargs": a:cargs}
    retu {
        \ "<c-g>": {"fn": "vc#add#add", "args": argd},
        \ "<c-z>": {"fn": "vc#add#commit", "args": argd},
        \ "<c-q>": {"fn": "vc#add#done", "args": []},
        \ }
endf

fun! vc#add#addopsdscr(meta) 
    retu [
        \ "Ctrl-g: Add Files",
        \ "Ctrl-z: Add and Commit Files",
        \ "Ctrl-q: Quit",
        \ ]
endf
"2}}}

fun! vc#add#Add(bang, ...) "{{{2
    try
        call vc#init()
        let disectd = vc#argsdisectlstmultipletargets(a:000, "all")
        let [cfiles, cargs] = [disectd.targets, disectd.cargs]
        let meta = vc#repos#meta(cfiles[0], disectd.forcerepo)
        let argsd = {"files": cfiles, "meta": meta, "cargs": cargs }

        let [supported, msg] = vc#repos#hasop(argsd.meta.repo, "addcmd")
        if !supported | retu vc#utils#showerr(msg) | en

        let g:vc_files_to_commit = []
        call add(g:vc_files_to_commit, argsd)
        if a:bang == "!"
            let b:vc_meta = argsd.meta
            retu s:finalize(argsd)
        else
            retu vc#add#prepadd()
        endif
    catch 
        retu vc#utils#showerr(v:exception)
    endt
endf
"2}}}

fun! vc#add#prepadd() "{{{2
    if len(g:vc_files_to_commit) > 0 
        let argsd = remove(g:vc_files_to_commit, len(g:vc_files_to_commit) -1)
        let [meta, cfiles, cargs] = [argsd.meta, argsd.files, get(argsd, "cargs", "")]
        if len(cfiles) > 0
            call vc#blank#win(vc#repos#call(meta.repo, "addops", meta, cargs))
            call vc#blank#onwrite('vc#add#add', {"meta":meta, 'cargs': cargs})
            let addopsdscr = vc#repos#call(meta.repo, "addopsdscr", meta)
            let hlines = vc#utils#addheader(meta, cfiles, addopsdscr)
            let result = vc#utils#writetobuffer("vc_bwindow", hlines)
            let &l:stl = vc#utils#stl("VCAdd ", "")
        endif
        setlocal nomodified
    else
        setlocal nomodified
        call vc#blank#closeme()
    endif
endf
"2}}}

fun! vc#add#done(...)  "{{{2
    call vc#add#prepadd()
endf
"2}}}

fun! vc#add#commit(argsd) "{{{2
    try
        let [afiles, comments] = vc#commit#parseclog()
        if len(afiles) <= 0 | retu vc#utils#showerr("No files") | en

        if len(comments) <= 0
            retu vc#utils#showerr("Please provide comments for commit")
        endif

        let addargsd = {"meta": a:argsd.meta, "files": afiles, "cargs": get(a:argsd, "cargs", "")}
        let cfiles = []
        call extend(cfiles, afiles)
        if s:finalize(addargsd) == vc#passed()
            let docommitargs = {"files": cfiles, "comments": comments, "meta": a:argsd.meta,
                        \"cargs": get(a:argsd, "cargs", "") }
            call vc#commit#docommit(docommitargs)
            unlet! docommitargs
        endif
        unlet! addargsd
    catch
        call vc#utils#showerr(v:exception)
    endtry
    retu vc#add#done()
endf
"2}}}

fun! vc#add#add(argsd)  "{{{2
    try
        let [afiles, comments] = vc#commit#parseclog()
        let addargsd = {"meta": a:argsd.meta, "files": afiles, "cargs": get(a:argsd, "cargs", "")}
        call s:finalize(addargsd) 
    catch
        call vc#utils#showerr(v:exception)
    endtry
    redr!
    retu vc#add#done()
endf
"2}}}

fun! s:finalize(argsd) "{{{2
    let thefiles = a:argsd.files
    if len(thefiles) <=0 | retu vc#utils#showerr("Failed, No files") | en

    try
        let cmd = vc#repos#call(a:argsd.meta.repo, "addcmd", a:argsd)
        let [result, response ] = vc#utils#execshellcmdinteractive(cmd)
        retu result
    catch
        call vc#utils#showerr("Exception doadd " . v:exception)
        retu vc#failed()
    endtry
endf
"2}}}
"1}}}
