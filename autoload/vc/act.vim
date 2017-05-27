" ============================================================================
" File:         autoload/vc/act.vim
" Description:  Callbacks
" Author:       Juneed Ahamed
" =============================================================================

"{{{1

"callback funs {{{2
fun! vc#act#blame(argsd)
    setlocal nowrap nofoldenable
    call vc#winj#close()

    let cmd="%!" . vc#repos#call(a:argsd.meta.repo, 'blamecmd', a:argsd)
    keepalt vnew | exec cmd

    " Strip source code from blame output
    %s/^\(\s*\S\+\s\+\S\+\) \(\S\+ \S\+\).*/\2 \1/
    nohlsearch

    " Fit blame output width
    let width=strlen(getline('.'))
    exec "setlocal winfixwidth winwidth=" . width
    exec "vertical resize " . width

    " Setup blame window
    exe 'map <buffer> <silent> <c-q>' '<esc>:diffoff!<cr>:bd!<cr>'
    let b:vc_repo = a:argsd.meta.repo
    setlocal filetype=vcblame
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nowrap nofoldenable nonumber norelativenumber nomodified readonly
    setlocal scrollbind
    wincmd p " return to previous window
    setlocal scrollbind
    syncbind
    retu vc#passed()
endf

fun! vc#act#handleNoParseCmd(argsd, fncode)
    try
        let a:argsd.cmd = vc#repos#call(a:argsd.meta.repo, a:fncode, a:argsd)
        let addops = get(a:argsd, 'addops', 0)
        let response = system(a:argsd.cmd)
        let [opsd, help] = [{}, ""]
        if addops
            let opsd = {"\<C-u>"    :{"bop":"<c-u>", "fn":'vc#stack#pop'},}
            let help = "C-u:up"
        endif
        call vc#blank#win(opsd)
        setl modifiable
        sil! exe '%d _ '
        sil! put=response
        let &l:stl = vc#utils#stl(a:argsd.op, help)
        sil! exec 1
	    setlocal nomodified | redr
        retu vc#fltrclearandexit()
    catch
        call vc#utils#showerr(v:exception)
        retu vc#failed()
    endtry
endf

fun! vc#act#diff(argsd)
    let repo = a:argsd.meta.repo
    let arevision = a:argsd.revision
    let apath = a:argsd.path
    let aforce = get(a:argsd, 'force', '')
    return vc#act#diffme(repo, arevision, apath, aforce)
endf

fun! vc#act#diffme(repo, revision, path, force)
    call s:startop()
    let islocal = 0
    if a:revision == "" && vc#utils#localFS(a:path)
        let cmd = "%!cat " . vc#utils#fnameescape(a:path)
        let fname =  vc#utils#strip(a:path)
        let islocal = 1
    else
        let argsd = {"revision" : a:revision, "path":a:path}
        let cmd = "%!". vc#repos#call(a:repo, 'diffcmd', argsd)
        if a:revision != "" 
            let fname = vc#utils#strip(a:revision). "#" . vc#utils#strip(a:path) 
        else
            let fname = vc#utils#strip(a:path) 
        endif
        let fname = substitute(fname, '\~', "", "")
    endif

    diffthis | exec 'keepalt vnew! ' vc#utils#fnameescape(fname)
    exec cmd |  diffthis
    call diffusable#diff_with_partner(winnr('#'))
    wincmd p
    call diffusable#diff_with_partner(winnr('#'))
    wincmd p
    retu s:diffsetup(a:repo, islocal, a:revision, a:path, a:force, fname, cmd)
endf

fun! s:diffsetup(repo, islocal, revision, path, force, fname, cmd)
    let filetype=&ft
    exe 'silent! com! GoVC call vc#home()'
    if has('gui_running')
        exe 'map <buffer> <silent> <c-q>' '<esc>:diffoff!<cr>:bd!<cr>:GoVC<cr>'
        let quithelp="Ctrl-q: Quit"
    else
        exe 'map <buffer> <silent> <c-x>' '<esc>:diffoff!<cr>:bd!<cr>:GoVC<cr>'
        let quithelp="Ctrl-x: Quit"
    endif

    exe 'map <buffer> <silent> <c-n>' printf("<esc>:call vc#act#diffcycle(\"%s\", 0, 'bn!')<cr>", a:force)
    exe 'map <buffer> <silent> <c-p>' printf("<esc>:call vc#act#diffcycle(\"%s\", 0, 'bp!')<cr>", a:force)
    if !a:islocal | exe "setl bt=nofile bh=wipe nobl noswf ro ft=" . filetype | en

    let opsdict = {
                \ "c-q": {"dscr": quithelp},
                \ "c-n": {"dscr": "Ctrl-n: Diff with next buffer"},
                \ "c-p": {"dscr": "Ctrl-p: Diff with previous buffer"},
                \ }

    let [newrev, olderrev] = s:newandoldrevisions(a:revision)
    if olderrev != ""
        exe 'com! -buffer VCDiffOld' printf("call vc#winj#close()|diffoff!|bd!|call vc#act#diffme('%s','%s','%s','%s')", a:repo, olderrev, a:path, a:force)
    	if has('gui_running')
			exe 'map <buffer> <silent> <c-down> <esc> :VCDiffOld<cr>'
			let opsdict["C-Down"] = {"dscr": "Ctrl-Down Arrow or VCDiffOld: Diff with revision " . olderrev}
		else
			exe 'map <buffer> <silent> <c-j> <esc> :VCDiffOld<cr>'
			let opsdict["c-j"] = {"dscr": "Ctrl-j or VCDiffOld: Diff with revision " . olderrev}
		endif
    endif
    if newrev != ""
        exe 'command! -buffer VCDiffNew' printf("call vc#winj#close()|diffoff!|bd!|call vc#act#diffme('%s','%s','%s','%s')", a:repo, newrev, a:path, a:force)
    	if has('gui_running')
			exe 'map <buffer> <silent> <c-up> <esc> :VCDiffNew<cr>'
            let opsdict["c-Up"] = {"dscr": "Ctrl-Up Arrow or VCDiffNew: Diff with revision " . newrev}
		else
			exe 'map <buffer> <silent> <c-k> <esc> :VCDiffNew<cr>'
			let opsdict["c-k"] = {"dscr": "Ctrl-k or VCDiffNew: Diff with revision " . newrev}
		endif
    endif

    if a:revision != ""
        exe 'map <buffer> <silent> <c-i>' printf("<esc>:call vc#gopshdlr#diffinfo('%s','%s','%s')<cr>", a:repo, a:revision, a:path)
        let opsdict["c-i"] = {"dscr": "Ctrl-i: Info"}
    endif

    let b:vc_cmd = a:cmd
    let b:vc_opsdict = opsdict
    let b:vc_path = a:path
    let b:vc_revision = a:revision
    let b:vc_repo = a:repo
    let b:vc_bufname = a:fname
    exe 'map <buffer> <silent> <c-h> <esc> :call vc#act#buffhelp()<cr>'
    let result = s:endop(0)
    let &l:stl = vc#utils#stl(a:fname, "Ctrl-h:Help")
    return result
endf

fun! vc#act#diffcycle(force, iteration, prev_next)
    try
        if a:iteration == 0
            sil exe "diffoff!"
            sil exe "bd!"
        elseif a:iteration >= 15
            retu
        endif
        sil exe a:prev_next
        let result = vc#Diff(a:force, 0, "")
        if result == vc#failed()
            call vc#act#diffcycle(a:force, a:iteration+1, a:prev_next)
        endif
        call vc#winj#close()
    catch | endtry
endf

fun! vc#act#efile(argsd)
    let repo = a:argsd.meta.repo
    call s:startop()

    try
        let [revision, fname] = vc#repos#call(repo, 'frmtrevfname', a:argsd)
        if revision != "" | let fname = "_".fname | en

        if filereadable(vc#utils#expand(fname)) || buflisted(vc#utils#expand(fname))
            silent! exe 'e ' vc#utils#fnameescape(fname)
            call s:grep(a:argsd)
        else
            let cmd = vc#repos#call(repo, 'opencmd', a:argsd)
            silent! exe 'e ' vc#utils#fnameescape(fname) | exe "%!" . cmd
            exe "setl bt=nofile ro"
        endif
        if has_key(a:argsd, "meta") && has_key(a:argsd, "path")
            let b:vc_argsd = a:argsd
            let b:vc_repo = a:argsd.meta.repo
            let b:vc_path = a:argsd.path
            let b:vc_bufname = fname
            if revision != "" && b:vc_path != ""
                exe 'com! -buffer VCDiffLocal' printf("diffoff!|call vc#act#diffme('%s','%s','%s','%s')", b:vc_repo, "", b:vc_path, "")
                exe 'map <buffer> <silent> <c-D> <esc> :VCDiffLocal<cr>'
                let b:vc_opsdict = {"c-D": {"dscr": "Ctrl-D or :VCDiffLocal diff with local file"}}
                exe 'map <buffer> <silent> <C-h>' '<esc>:call vc#act#buffhelp()<cr>'
            endif
        endif
    catch | call vc#utils#dbgmsg("At vc#act#efile :", v:exception) | endtry
    retu s:endop(1)
endf

fun! vc#act#newfile(argsd)
    call s:startop()
    try
        silent! exe 'e ' vc#utils#fnameescape(a:argsd.path)
        augroup VCOnWrite
        augroup END
        if has_key(a:argsd, "onwritecallback")
            let b:onwritecallbackargsd = a:argsd
            let b:onwritecallback = a:argsd.onwritecallback
            au VCOnWrite BufWritePost <buffer> call vc#blank#callonwrite()
        endif
    catch 
        call vc#utils#dbgmsg("At vc#act#newfile :", v:exception)
    endtry
    retu s:endop(1)
endf

fun! vc#act#vs(argsd)
    let repo = a:argsd.meta.repo
    call s:startop()
    let [revision, fname] = vc#repos#call(repo, 'frmtrevfname', a:argsd)
    if vc#utils#localFS(fname) || buflisted(vc#utils#expand(fname))
        silent! exe 'vsplit ' vc#utils#fnameescape(fname)
        call s:grep(a:argsd)
    else
        let cmd = vc#repos#call(repo, 'opencmd', a:argsd)
        silent! exe 'vsplit ' vc#utils#fnameescape(fname) | exe "%!" . cmd
        exe "setl bt=nofile ro"
    endif
    let b:vc_argsd = a:argsd
    retu s:endop(1)
endf

fun! s:grep(argsd)
    if has_key(a:argsd, "grep") 
        let @/ = a:argsd.grep
        silent! exe 'normal n'
    endif
endf

fun! vc#act#forceredr(...)
    redraw!
    call vc#prompt#show()
endf

fun! vc#act#logit(...)
    try
        if g:vc_log_name == "" 
            retu vc#utils#showerr("g:vc_log_name not set, see help g:vc_log_name")
        endif
        sil! exe 'redi! >>' g:vc_log_name
        echo join(getbufline(bufnr('vc_window'), 0, "$"), "\n") | redr
        sil! redi END
        echohl MoreMsg | echo "Logged to : " . g:vc_log_name 
        echo "Press any key to continue" | echohl None
        let x = getchar()
    catch 
        call vc#utils#dbgmsg("At vc#act#logit:", v:exception)
    finally
        call vc#prompt#show()
    endtry
endf

fun! vc#act#help(...)
    call vc#act#showops(vc#winj#dict().getallops())
    call vc#prompt#show()
endf

fun! vc#act#buffhelp(...)
    call vc#act#showops(b:vc_opsdict)
endf

fun! vc#act#showops(thedict)
    echohl Title
    echo " ******************* Operations ***************************** "
    echohl Function
    for [key, thedict] in items(a:thedict)
        try
            let descr = ""
            if has_key(thedict, 'dscr')
                let descr = thedict.dscr
            else
                let descr = vc#utils#describe(key)
            endif
            if descr != ""
                let splits = split(descr, ":")
                let [key, val] = [splits[0], join(splits[1:], ":")]
                echo printf("%15s: %s", key, val)
            endif
        catch 
           call vc#utils#dbgmsg("At vc#act#help:", v:exception)
       endtry
    endfor
    echohl Title
    echo " ************************************************************ "
    echohl Function | let x = input("Press enter or esc key to continue : ") | echohl None
endf

"helpers funs {{{2

fun! s:startop()
    if vc#prompt#isploop() 
        call vc#winj#close()
        retu vc#passed()
    endif
    call vc#altwinnr()
    retu vc#passed()
endf

fun! s:endop(keep)
    let [athome, jwinnr] = vc#home()
    try
        if athome && !vc#prompt#isploop()
            call vc#select#clear()
            call vc#syntax#highlight()
            call vc#winj#stl()
            setl nomodifiable | redr!
        elseif athome && vc#prompt#isploop()
            call vc#winj#close()
        endif
    catch | endtry
    retu vc#passed()
endf

fun! s:newandoldrevisions(revision) "{{{2
    let [newrev, olderrev] = ["", ""]
    try
        let idxcurrev = index(g:vc_logversions, a:revision)
        if idxcurrev != -1
            let newrev = idxcurrev > 0 ? g:vc_logversions[idxcurrev - 1] : ""
            let olderrev = idxcurrev <= len(g:vc_logversions) - 2 ? g:vc_logversions[idxcurrev + 1] : ""
        endif
    catch
        call vc#utils#dbgmsg("At s:newandoldrevisions", v:exception)
    endtry
    retu [newrev, olderrev]
endf
"2}}}
"1}}}
