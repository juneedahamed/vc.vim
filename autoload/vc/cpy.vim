"===============================================================================
" File:         autoload/vc/cpy.vim
" Description:  VC Copy 
" Author:       Juneed Ahamed
"===============================================================================

"vc#blank.vim {{{1
fun! vc#cpy#ops(urllist) "ops {{{2
    retu { "<c-z>": {"fn": "vc#cpy#dorepocopy", "args": a:urllist, "dscr":"C-z:Commit"},
        \ "<c-q>": {"fn": "vc#blank#closeme", "args": [], "dscr":"C-q:Cancel"},
        \ }
endf

fun! vc#cpy#opsdscr() 
    retu join(map(values(vc#cpy#ops([])), 'v:val.dscr'), " ")
endf
"2}}}

fun! vc#cpy#repo(urllist) "callback from vc#browse#paste {{{2
    try
        if len(a:urllist) < 2 | retu vc#utils#showerr("Insufficient info") | en
        let urllist = map(a:urllist, 'substitute(v:val, "%20", " ", "g")')
        call vc#blank#win(vc#cpy#ops(urllist))
        let hlines = vc#utils#copyheader(urllist, vc#cpy#opsdscr())
        let result = vc#utils#writetobuffer("vc_bwindow", hlines)
        let &l:stl = vc#utils#stl("VC Copy Commit Log", vc#cpy#opsdscr())
        retu [vc#fltrclearandexit(), ""]
    catch 
        call vc#utils#dbgmsg("At vc#cpy#repo", v:exception)
        retu [vc#failed(), ""]
    endtry
endf
"2}}}

fun! vc#cpy#dorepocopy(...) "callback from blank win {{{2 
    try
        let [commitlog, comments] = ["", []]
        let [srcurls, desturl] = [[], ""]
        let [source_reg, dest_reg] = ["VC:SOURCE: ", "VC:DESTINATION: "]

        for line in getline(1, line('$'))
            let line = vc#utils#strip(line)
            if len(line) > 0 && matchstr(line, '^VC:') == ""
                call add(comments , line) 
            elseif matchstr(line, source_reg) != ""
                let curl = vc#utils#strip(substitute(line, source_reg, "", ""))
                if curl != "" && index(srcurls, curl) < 0
                    call add(srcurls, curl)
                else
                    call vc#utils#showerr("Duplicate src ignoring " . curl)
                endif
            elseif matchstr(line, dest_reg) != "" 
                if desturl != ""
                    retu vc#utils#showerr("Multiple destinations, Aborting")
                endif
                let curl = vc#utils#strip(substitute(line, dest_reg, "", ""))
                if curl != "" 
                    let desturl = curl
                endif
            endif
        endfor

        if len(srcurls) <= 0
            retu vc#utils#showerr("No src urls, Aborting")
        endif

        if len(desturl) <= 0
            retu vc#utils#showerr("No dest urls, Aborting")
        endif

        call add(srcurls, desturl)
        retu s:dorepocopy(comments, srcurls)
    catch
        call vc#utils#showerr("Exception during dorepocopy : " . v:exception)
    endtry
    retu
endf

fun! s:dorepocopy(comments, urls)
    if len(a:comments) <= 0 
        echohl Question | echo "No comments"
        echo "Press c to commit without comments, q to abort, Any key to edit : "
        echohl None
        let choice = vc#utils#getchar()
        if choice ==? 'c' | retu s:dosvnrepocopy("!", a:urls) | en
        retu choice ==? 'q' ? vc#blank#closeme() : vc#failed()
    else
        let commitlog = ""
        try
            let commitlog = vc#caop#commitlog()
            if filereadable(commitlog) | call delete(commitlog) | en
            call writefile(a:comments, commitlog)
            retu s:dosvnrepocopy(commitlog, a:urls)
        finally
            if len(commitlog) > 0 | call delete(commitlog) | en
        endtry
    endif
    retu vc#failed()
endf

fun! s:dosvnrepocopy(commitlog, urls)
    let [result, response] = vc#svn#copyrepo(a:commitlog, a:urls)
     if len(response) > 0
        call vc#utils#showconsolemsg(response, 1) 
    else
        call vc#utils#showconsolemsg("No output from svn", 1) 
    endif
    call vc#blank#closeme()
    retu result
endf
"2}}}
"1}}}
