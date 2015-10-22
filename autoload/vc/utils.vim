" =============================================================================
" File:         autoload/vc/utils.vim
" Description:  util functions
" Author:       Juneed Ahamed
" Credits:      strip expresion from DrAI(StackOverflow.com user)
" =============================================================================

"utils {{{1

"syntax {{{2
fun! vc#utils#getErrSyn()
    let [errstart, errend] = ['--ERROR--:', '']
    let errpatt = "/" . errstart . "/"
    let errsyntax = 'syn match VCError ' . errpatt
    retu [errstart, errend, errsyntax]
endf

fun! vc#utils#getVCSyn()
    retu 'syn match VC /^VC\:.*/'
endf
"2}}}

fun! vc#utils#stl(title, ops) "{{{
    let title = g:vc_custom_statusbar_title . a:title . ' %r'
    let alignright = '%='
    let opshl = ' %#'.g:vc_custom_statusbar_ops_hl.'# ' 
    if a:ops == ""
        retu title
    else
        let ops = opshl.a:ops
        retu title.alignright.opshl.ops
    endif
endf
"2}}}

fun! vc#utils#blankmeta() "{{{2
    let metad = {}
    let metad.entity = ""
    let metad.fpath = ""
    let metad.isdir = 0
    let metad.local = 1
    let metad.repoUrl = ""
    let metad.repo = "na"
    let metad.wrd=""
    let metad.branch = ""
    retu metad
endf
"2}}}

fun! vc#utils#keyscurbufflines() "{{{2
    let keys = []
    for i in range(1, line('$'))
        let [key, value] = vc#utils#extractkey(getline(i))
        if key != "" | call add(keys, key) | en
    endfor
    retu keys
endf
"2}}}

fun! vc#utils#extractkey(line) "{{{2
    if matchstr(a:line, g:vc_key_patt) != ""
        let tokens = split(a:line, ':')
        if len(tokens) > 1 
            retu [vc#utils#strip(tokens[0]), vc#utils#discardbinfo(join(tokens[1:], ":"))]
        endif
    elseif vc#utils#iserror(a:line)
        retu ['err', vc#utils#discardbinfo(a:line)]
    endif
    retu [line("."), vc#utils#discardbinfo(a:line)]
endf

fun! vc#utils#extractkeydate(line) 
    let date = matchstr(a:line, '\d\{2,4}-\d\d-\d\d \d\d:\d\d:\d\d')
    let [key, value] = vc#utils#extractkey(a:line)
    retu [key, date, value]
endf

fun! vc#utils#discardbinfo(line)
    let tokens = split(a:line, " -> ")
    if len(tokens) > 1
        retu vc#utils#strip(tokens[0])
    else
        retu vc#utils#strip(a:line)
    endif
endf
"2}}}

fun! vc#utils#iserror(line)
    retu matchstr(a:line, '--ERROR--') != ""
endf

fun! vc#utils#bufabspath() "{{{2
    let fileabspath = expand('%:p')
    if fileabspath ==# ''
        throw 'Error No file in buffer'
    endif
    retu vc#utils#fnameescape(fileabspath)
endf
"2}}}

fun! vc#utils#bufrelpath() "{{{2
    let target = expand('%')
    if target ==# ''
        throw 'Error No file in buffer'
    endif
    retu vc#utils#fnameescape(target)
endf
"2}}}

fun! vc#utils#fnameescape(path) "{{{2
    let path = expand(a:path)
    retu  path == "" ? a:path : fnameescape(path)
endf
"2}}}

fun! vc#utils#expand(path) "{{{2
    let path = expand(a:path)
    if has('win32') 
        let path = substitute(path, '\\', '/', 'g')
    endif
    retu  path == ""? a:path : path
endf
"2}}}

fun! vc#utils#fetchwrd(entity, repodir) "{{{2
    let fullpath = fnamemodify(vc#utils#expand(a:entity), ':p')
    let wrd = s:_fetchwrd(fullpath, a:repodir)
    if wrd != "" && vc#utils#isdir(vc#utils#joinpath(wrd, a:repodir))
        let wrd = substitute(wrd, '\v[\/]*$', '/', '')
        retu [vc#passed(), vc#utils#fnameescape(wrd)]
    endif
    retu [vc#failed(), vc#utils#fnameescape(getcwd())]
endf

fun! s:_fetchwrd(path, repodir)
    let [maxtries, path, visitedpath] = [10, a:path, ""]
    if !isdirectory(path) | let path = fnamemodify(path, ":h") | en
    while maxtries > 0 && isdirectory(path) && path != visitedpath
        if isdirectory(vc#utils#joinpath(path, a:repodir)) 
            retu path | endif
        let [visitedpath, maxtries, path] = [path, maxtries - 1, fnamemodify(path, ":h")]
    endwhile
    retu ""
endf
"2}}}

fun! vc#utils#getparent(url) "{{{2
    let url = matchstr(a:url, "/$") == '/' ? a:url[:-2] : a:url
    let url = fnamemodify(url, ":h")
    let url = url . "/"
    retu url
endf
"2}}}

fun! vc#utils#isdir(path) "{{{2
    retu isdirectory(a:path) || isdirectory(vc#utils#expand(a:path))
endf
"2}}}

fun! vc#utils#isdirdirtycheck(url) "{{{2
    "Using a slash at the end to identify if it is a directory,
    "isdirectory will not work on an SVN url, and do not want
    "to spend time parsing the command for svn
    let slash = matchstr(a:url, "/$")
    retu slash == "/" 
endf
"2}}}

fun! vc#utils#localFS(fname) "{{{2
    retu filereadable(expand(a:fname)) || vc#utils#isdir(a:fname)
endf
"2}}}

fun! vc#utils#joinpath(v1, v2) "{{{2
    let [v1, v2, sep] = [vc#utils#strip(a:v1), vc#utils#strip(a:v2) , ""]
    if v1 == "" | retu v2 | en
    if v1 != "" && v2 != "" | let sep = "/" | en
    retu substitute(v1, '[\/]\+$', '', '') . sep . substitute(v2, '^[\/]', '', '')
endf
"2}}}

fun! vc#utils#strip(input_string) "{{{2
    retu substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endf
"2}}}

fun! vc#utils#sortconvint(i1, i2) "{{{2
    retu a:i1 - a:i2
endf
"2}}}

fun! vc#utils#sortftime(f1, f2) "{{{2
    retu getftime(a:f1) - getftime(a:f2)
endf
"2}}}

fun! vc#utils#statussummary(cmd, wrd)   "{{{2
    let shellout = vc#utils#execshellcmd(a:cmd)
    let shelloutlist = split(shellout, '\n')
    unlet! shellout
    let statuslist = []
    for line in shelloutlist
        let line = vc#utils#strip(line)
        if len(line) <= 0 | cont | en
        let statusentryd = {}
        if matchstr(line, '## ' ) != ""
            let statusentryd.modtype = "INFO"
            let statusentryd.line = g:vc_info_str . " " . line
            let statusentryd.fpath = "-"
        else
            let tokens = split(line)
            let statusentryd.modtype = tokens[0]
            let statusentryd.line = line
            let path = vc#utils#parsefilefromstatus(a:wrd, tokens)
            let fullpath = vc#utils#joinpath(a:wrd, path)
            let statusentryd.fpath = path
            if !vc#utils#localFS(path) && vc#utils#localFS(fullpath) 
               let statusentryd.fpath = fullpath
            endif
        endif
        call add(statuslist, statusentryd)
    endfor
    unlet! shelloutlist
    retu [statuslist, a:cmd]
endf
"2}}}

fun! vc#utils#parsefilefromstatus(wrd, tokens)  "{{{2
    for idx in range(1, len(a:tokens)-1)
        let path = join(a:tokens[ idx :], " ")
        let path = substitute(path, "\"", '', 'g')
        let fullpath = vc#utils#joinpath(a:wrd, path)
        if vc#utils#localFS(path) || vc#utils#localFS(fullpath) 
            retu vc#utils#fnameescape(path)
        endif
    endfor
    retu vc#utils#fnameescape(a:tokens[-1])
endf 
"2}}}

"browse local filesystem {{{2
fun! vc#utils#lstfiles(path, rec, igndir)
    let cwd = getcwd()
    sil! exe 'lcd ' . a:path
    let entries = a:rec ? s:globpath(".") : s:lstnonrec(a:igndir)
    sil! exe 'lcd ' . vc#utils#fnameescape(cwd)
    retu entries
endf

fun! s:lstnonrec(igndir)
    let fileslst = split(globpath('.', "*"), '\n')
    let entries = []
    let strip_pat = '^\./' 
    for line in  fileslst
        if len(matchstr(line, g:p_ign_fpat)) != 0 | con | en
        if vc#utils#isdir(line) | let line = line . "/"  | en
        let line = substitute(line, strip_pat, "", "")
        call add(entries, vc#utils#fnameescape(line))
    endfor
    retu entries
endf

fun! s:globpath(dir)
    try 
        setl nomore
    catch | endt

    let cdir = (a:dir == "" || a:dir == ".") ? getcwd() : a:dir
    let [result, ffiles] = vc#caop#fetchandfmt("wc", cdir)
    if result && len(ffiles) > 0 | retu ffiles | en

    let [files_, tdirs, lines] = [[], [a:dir], []]
    let report = 0
    while len(files_) < g:vc_browse_max_files_cnt && len(tdirs) > 0
        let curdir = vc#utils#strip(remove(tdirs, 0))
        let fetchedcnt = len(files_)
        if fetchedcnt >= report
            call vc#utils#showconsolemsg(printf("Fetched %d, Fetching files from : %s", fetchedcnt, curdir), 0)
            let report = report + 1000
        endif
        let flist = split(globpath(curdir, "*"), "\n")
        let [tfiles, tdirs2, tlines] =  s:slicefilesanddirs(flist)

        call extend(lines, tlines)
        call extend(files_, tfiles)
        call extend(tdirs, tdirs2)
        unlet! flist tfiles tdirs2 tlines
    endwhile
    call vc#caop#cache("wc", cdir, lines)
    unlet! tdirs lines
    retu files_
endf

fun! s:slicefilesanddirs(flist)
    let [files_, dirs, lines] = [[], [], []]
    let strip_pat = '^\./' 
    for entry in a:flist
        let entry = vc#utils#fnameescape(entry)
        if len(matchstr(entry, g:p_ign_fpat)) != 0 | con | en
        let entry = substitute(entry, strip_pat, "", "")
        if vc#utils#isdir(entry)
            let entry = entry . "/"
            if g:p_ign_dirs != "" && matchstr(entry, g:p_ign_dirs) != "" | con | en
            call add(dirs, entry)
        endif
        call add(lines, entry)
        call add(files_, entry)
    endfor
    retu [files_, dirs, lines]
endf
"2}}}


fun! vc#utils#formatrevisionandfname(argsd) "{{{2
    let arevision = get(a:argsd, 'revision', '')
    let apath = get(a:argsd, 'path', '' )
    let fname = arevision == "" ? apath : arevision.'#'.vc#utils#strip(apath)
    retu [arevision, fname]
endf
"2}}}

fun! vc#utils#parsetargetandnumlogs(arglist) "{{{2
    let [target, numlogs] = ["", ""]
    try
        let repo = ""
        for thearg in a:arglist
            if len(matchstr(thearg, vc#repos#repopatt())) > 0 
                let repo = thearg
                cont
            endif
            let thearg = vc#utils#strip(thearg)
            let tnumlogs = matchstr(thearg, "^\\d\\+$")
            if tnumlogs != '' && numlogs == ""
                let numlogs = tnumlogs
                cont
            endif
            let target = thearg
        endfor
    catch 
        call vc#utils#dbgmsg("vc#utils#parsetargetandnumlogs", v:exception) 
    endt
    try
        if target == "" 
            let target = vc#utils#bufrelpath()
        en
    catch | let target = "." | endt

    if numlogs == "" | let numlogs = g:vc_max_logs | en
    retu [fnameescape(target), numlogs, repo]
endf
"2}}}

fun! vc#utils#showerrJWindow(title, exception) "{{{2
    let edict = vc#dict#new(a:title)
    call vc#dict#adderr(edict, 'Failed ', a:exception)
    call vc#winj#populateJWindow(edict)
    call edict.clear()
    unlet! edict
endf
"2}}}

fun! vc#utils#showerr(msg) "{{{2
    let errlst = split(a:msg, ":RESPONSE:")
    for errmsg in errlst
        echohl Error | echo errmsg | echohl None
        echo "----"
    endfor
    call s:finishowconsole(a:msg)
    retu vc#failed()
endf
"2}}}

fun! vc#utils#showconsolemsg(msg, wait) "{{{2
    redr | echohl special | echon a:msg | echohl None
    if a:wait | retu s:finishowconsole(a:msg) | endif
    if ! a:wait | sleep 1m | en
endf
"2}}}

fun! s:finishowconsole(msg) "{{{2
    let msg = "Press Enter/Esc to continue : "
    if g:vc_log_name !=# ''
        let msg = "Enter l to log at " . g:vc_log_name . "\n" . msg
    endif
    echohl MoreMsg | let choice = input(msg) | echohl None
    if g:vc_log_name != '' && choice == 'l'
        try
            sil! exe 'redi! >>' g:vc_log_name
            echo a:msg  | redr
            sil! redi END
            echohl MoreMsg | echo "Logged to : " . g:vc_log_name | echohl None
            let x = getchar()
        catch | endtry
    endif
endf
"2}}}

fun! vc#utils#errdict(title, emsg) "{{{2
    let edict = vc#dict#new(a:title)
    let edict.meta = vc#utils#blankmeta()
    call vc#dict#adderr(edict, a:emsg, "")
    retu edict
endf
"2}}}

fun! vc#utils#dbgmsg(title, args) "{{{2
    if g:vc_enable_debug
        echo "DBG MSG .........."
        echo a:args
        let x = input(a:title)
    endif
endf
"2}}}

fun! vc#utils#execshellcmduseexec(cmd, shouldlog)   "{{{2
    try
        echohl Title | echo "Will execute the following command"
        echohl Directory | echo a:cmd | echo "" | echohl Question 
        let choice = g:vc_donot_confirm_cmd != 1 ? input("Press y to continue, any key/enter to cancel : ") : "y"
        echohl None
        if choice ==? "y"
            echo "\nSent command waiting for response ..."
            if g:vc_log_name != "" | sil! exe 'redi! >>' g:vc_log_name | endif
            exec "!" . a:cmd
            echohl Title | echo "Press key to continue" | echohl None
            let x = getchar()
            retu [vc#passed(), ""]
        else
            retu [vc#failed(), "Aborted"]
        endif
    catch
    finally
        if g:vc_log_name != "" | sil! redi END | endif
    endtry
endf
"2}}}

fun! vc#utils#execshellcmdinteractive(cmd)   "{{{2
    echohl Title | echo "Will execute the following command"
    echohl Directory | echo a:cmd | echo "" | echohl Question
    let choice = g:vc_donot_confirm_cmd != 1 ? input("Press y to continue, any key/enter to cancel : ") : "y"
    echohl None
    if choice ==? "y"
        echo "Please wait sent command waiting for response ..."
        let response = vc#utils#execshellcmd(a:cmd)
        if g:vc_donot_confirm_cmd == 1
            let response = "Sent cmd " . a:cmd . "\n" . response
        endif
        call vc#utils#showconsolemsg(response, 1)
        retu [vc#passed(), response]
    else
        retu [vc#failed(), "Aborted"]
    endif
endf
"2}}}

fun! vc#utils#execshellcmd(cmd) "{{{2 
    let [cmd, status, shellout] = [a:cmd, vc#failed(), ""]

    if !g:vc_auth_disable && strlen(g:vc_username) > 0 && 
                \ strlen(g:vc_password) > 0 && vc#svn#iscmd(a:cmd) 
        let cmd = vc#svn#fmtauthinfo(cmd) 
    endif

    let shellout = system(cmd)
    if v:shell_error != 0 
        if !g:vc_auth_disable && vc#svn#isautherr(shellout) && vc#svn#iscmd(a:cmd)
            let [status, shellout] = vc#svn#exec_with_auth(cmd)
        else
            let status = vc#failed()
        endif
            
        if status == vc#failed() 
            throw 'FAILED CMD: ' . a:cmd . ' :RESPONSE:' . shellout
        endif
    endif
    retu shellout
endf
"2}}}

fun! vc#utils#input(title, description, prompt) "{{{2
    let inputstr = ""
    while 1
        echohl Title | echo "" | echo a:title
        echohl Directory| echo "" | echo a:description 
        echohl Question | echon a:prompt | echohl None | echon inputstr
        let chr = vc#utils#getchar()
        if chr == "\<Esc>"
            retu "\<Esc>"
        elseif chr == "\<Enter>"
            retu inputstr
        elseif chr ==# "\<BS>" || chr ==# '\<Del>'
            if len(inputstr) > 0 
                let inputstr = inputstr[:-2]
            endif
        else
            let inputstr = inputstr . chr
        endif
        redr
    endwhile
endf
"2}}}

fun! vc#utils#inputsecret(title, prompt) "{{{2
    echohl Title | echo "" | echo a:title | echohl None
    let secret = inputsecret(a:prompt)
    redr | retu secret
endf
"2}}}

fun! vc#utils#getchar() "{{{2
    let chr = getchar()
    retu !type(chr) ? nr2char(chr) : chr
endf
"2}}}

fun! vc#utils#inputchoice(msg) "{{{2
    echohl Question | let choice = input(a:msg . ": ") | echohl None
    retu choice
endf
"2}}}

fun! vc#utils#addheader(meta, thefiles, dscr) "{{{2
    let blines = []
    call add(blines, 'VC: -----------------------------------------------------------------')
    call add(blines, "VC: Following files will be Added")
    call add(blines, "VC: ")
    for thefile in a:thefiles
        call add(blines, "VC:+" . thefile)
    endfor
    call add(blines, "VC: ")
    call add(blines, "VC: The above listed files are chosen for add, You can delete/add")
    call add(blines, "VC: files instead of repeating the operation, use same syntax")
    call add(blines, "VC: Comments required to commit after adding")
    call add(blines, "VC: ")
    call add(blines, "VC: REPOSITORY : ". a:meta.repo)
    call add(blines, "VC: Working Root Dir : ". a:meta.wrd)
    call add(blines, "VC: ")
    if type(a:dscr) == type([])
        for dscr_e in a:dscr
            call add(blines, "VC: Operations : " . dscr_e)
        endfor
    else
        call add(blines, "VC: Operations : " . a:dscr)
    endif
    call add(blines, 'VC: --------Enter comments below this line for commit ---------------')
    call add(blines, '')
    let b:vc_meta = a:meta
    retu blines
endf
"2}}}

fun! vc#utils#commitheader(meta, thefiles, dscr) "{{{2
    let blines = []
    call add(blines, 'VC: -----------------------------------------------------------------')
    call add(blines, "VC: Following files will be committed")
    call add(blines, "VC: ")
    for thefile in a:thefiles
        call add(blines, "VC:+" . thefile)
    endfor
    call add(blines, "VC: ")
    call add(blines, "VC: The above listed files are chosen for commit, You can delete")
    call add(blines, "VC: files by deleting the line listing the file if not to be")
    call add(blines, "VC: commited instead of repeating the operation")
    call add(blines, "VC: Lines started with VC: will not be sent as comment")
    call add(blines, "VC: ")
    call add(blines, "VC: REPOSITORY : ". a:meta.repo)
    call add(blines, "VC: Working Root Dir : ". a:meta.wrd)
    call add(blines, "VC: ")
    if type(a:dscr) == type([])
        for dscr_e in a:dscr
            call add(blines, "VC: Operations : " . dscr_e)
        endfor
    else
        call add(blines, "VC: Operations : " . a:dscr)
    endif
    call add(blines, 'VC: ---------------Enter Comments below this line--------------------')
    call add(blines, '')
    let b:vc_meta = a:meta
    retu blines
endf
"2}}}

fun! vc#utils#copyheader(urls, dscr) "{{{2
    let blines = []
    call add(blines, 'VC: -----------------------------------------------------------------')
    call add(blines, "VC: The copy operations ends with commit, Please provide comments")
    for idx in range(0, len(a:urls) - 2)
        call add(blines, "VC:SOURCE: " . a:urls[idx])
    endfor
    call add(blines, "VC:DESTINATION: " . a:urls[len(a:urls)-1])
    call add(blines, "VC: Lines started with VC: will not be sent as comment")
    call add(blines, "VC: Supported operations : " . a:dscr)
    call add(blines, 'VC: ---------------Enter Comments below this line--------------------')
    call add(blines, '')
    retu blines
endf
"2}}}

fun! vc#utils#writetobuffer(bname, lines) "{{{2 
    let bwinnr = bufwinnr(a:bname)
    if bwinnr == -1 | retu 0 | en
    silent! exe  bwinnr . 'wincmd w'
    call setline(1, a:lines)
    exec "normal! G"
    retu vc#passed()
endf
"2}}}

fun! vc#utils#filesbywrd(sfiles, forcerepo, idrepousingmeta, ignorerepolst) "{{{2
    let resultlst = []
    let filesbyrepoandwrd = s:_filesbyrepoandwrd(a:sfiles, a:forcerepo, a:idrepousingmeta)
    for [repo, filesbywrd] in items(filesbyrepoandwrd)
        for [wrd, filerepod] in items(filesbywrd)
            if index(a:ignorerepolst, filerepod.meta.repo) >= 0 
                let msglst = ["Ignoring following files as not supported for repository : " .  filerepod.meta.repo,]
                call extend(msglst, filerepod.files)
                let errmsg = join(msglst, "\n")
                call vc#utils#showerr(errmsg)
                continue
            endif

            if len(filerepod.files) > 0
                let argsd = {"meta": filerepod.meta, "files": filerepod.files}
                call add(resultlst, argsd)
            endif
        endfor
    endfor
    retu resultlst
endf

fun! s:_filesbyrepoandwrd(files, forcerepo, idrepousingmeta)
    let filesbyrepoandwrd = {}
    for sfile in a:files
        if a:idrepousingmeta == 0 
            let repokey = vc#repos#member(sfile, a:forcerepo)
            let meta = vc#repos#call(repokey, "meta", sfile)
        else
            let meta = vc#repos#meta(sfile, a:forcerepo)
            let repokey = meta.repo
        endif

        let filesbyrepoandwrd[repokey] = has_key(filesbyrepoandwrd, repokey) ? filesbyrepoandwrd[repokey] : {}
        if has_key(filesbyrepoandwrd[repokey], meta.wrd) 
            call extend(filesbyrepoandwrd[repokey][meta.wrd].files, [sfile])
        else
            let filesbyrepoandwrd[repokey][meta.wrd] = {"files": [sfile], "meta": meta}
        endif
    endfor
    retu filesbyrepoandwrd
endf

fun! vc#utils#makelistforcopyormove(fromlst, tolst, op)
    let entries = []
    if len(a:fromlst) > 1 
        let [mulrepos, mulwrds] = [{}, {}]
        for entry in a:fromlst
            let mulrepos[entry.meta.repo] = entry.meta.wrd
            let mulwrds[entry.meta.wrd] = entry.meta.repo
        endfor
        if len(mulrepos) > 1 
            call vc#utils#showerr("Files from multiple repos " . join(keys(mulrepos), ", ") . " selected cannot " . a:op)
        elseif len(mulwrds) > 1 
            call vc#utils#showerr("Files from multiple wrds " . join(keys(mulwrds), ", ") . " selected cannot " . a:op)
        endif
        retu [vc#failed(), [], {}]
    endif

    let meta = a:fromlst[0].meta
    let [repo, wrd] = [meta.repo, meta.wrd]

    if repo != a:tolst[0].meta.repo 
        call vc#utils#showerr("Cannot " . a:op . " from " . a:fromlst[0].meta.repo .
                    \ " to " . a:tolst[0].meta.repo)
        retu [vc#failed(), [], {}]
    endif

    if wrd != a:tolst[0].meta.wrd
        call vc#utils#showerr("Cannot " . a:op . " from " . wrd . " to " . a:tolst[0].meta.wrd 
                    \ . " belongs to different repos")
        retu [vc#failed(), [], {}]
    endif

    for elem in a:fromlst
        call extend(entries, map(elem.files, 'vc#utils#fnameescape(v:val)'))
    endfor

    if index(entries, vc#utils#fnameescape(a:tolst[0].files[0])) >= 0
        call vc#utils#showerr("Cannot " . a:op . "to self")
        retu [vc#failed(), [], {}]
    endif

    return [vc#passed(), entries, meta]
endf

fun! vc#utils#refreshfileop(op, srclst, dst)
    let bufpath = ""
    try | let bufpath = vc#utils#bufabspath() | catch | endtry 
    let entries = filter(copy(a:srclst), 'vc#utils#fnameescape(fnamemodify(expand(v:val), ":p")) == bufpath')

    if len(entries) == 1 && !vc#utils#isdir(entries[0])
        let tail = fnamemodify(expand(entries[0]), ":t")
        let rdest = fnamemodify(expand(a:dst), ":.")
        let path = vc#utils#fnameescape(vc#utils#isdir(rdest) ? expand(rdest) . "/" . tail : rdest)
        if filereadable(expand(path))
            if a:op == "move"
                silent! bd
            endif
            silent! exe 'e ' path
        endif
    endif
endf

fun! vc#utils#refreshfile(filename)
    let bufpath = ""
    try | let bufpath = vc#utils#bufabspath() | catch | endtry 
    if fnamemodify(expand(a:filename), ":p") == expand(bufpath)
        if filereadable(expand(a:filename))
            silent! bd
            silent! exe 'e ' a:filename
        endif
    endif
endf
"2}}}

"constants/keys/operations {{{2
fun! vc#utils#getkeys()
   retu ['meta', 'logd', 'statusd', 'commitsd', 'browsed', 'menud', 'error']
endf

fun! vc#utils#getEntryKeys()
    retu ['logd', 'statusd', 'commitsd', 'browsed', 'flistd', 'menud', 'error']
endf

fun! vc#utils#topop()
    retu {"\<C-t>": {"bop":"<c-t>", "fn":'vc#stack#top'}}
endf

fun! vc#utils#upop()
    retu {"\<C-u>": {"bop":"<c-u>", "fn":'vc#stack#pop'}}
endf

fun! vc#utils#revisionrequiredop()
    retu {"\<F7>" :{"bop":"<F7>", 
                \ "dscr": "F7:Marks affected revisioned file when enabled",
                \ "fn":'vc#prompt#toggleopenrevision'}}
endf

fun! vc#utils#newfileop()
    retu {"\<C-n>"  : {"bop":"<c-n>", "fn":'vc#browse#newfile', "dscr": "Ctrl-n:Create new file"},}
endf
"2}}}

"descriptions {{{2
fun! vc#utils#openfiledscr(key)
    retu printf('%s:Opens selected revision file', a:key)
endf

fun! vc#utils#difffiledscr(key)
    retu printf('%s:Opens selected file/revision in diff mode', a:key)
endf

fun! vc#utils#digdescr(key)
    retu printf('%s:Open selected file, List non-recusrive for directories', a:key)
endf

fun! vc#utils#digrecdescr(key)
    retu printf('%s:List the selected directory recursively', a:key)
endf

let s:dscrd = {
            \ "\<Enter>": "Enter:Opens selected file/menu/dirs(lists dir contents)  on revsion (diff mode is done example VCLog)",
            \ "\<C-o>":   "Ctrl-o:Opens all filter/selected files",
            \ "\<C-v>":   "Ctrl-v:Vertical split the selected file",
            \ "\<C-d>":   "Ctrl-d:Opens selected file/revision in diff mode",
            \ "\<C-l>":   "Ctrl-l:Displays logs for the selected file",
            \ "\<C-i>":   "Ctrl-i:Shows VCInfo",
            \ "\<C-w>":   "Ctrl-w:Wrap!, Toggle wrap", 
            \ "\<C-y>":   "Ctrl-y:Displays the command used",
            \ "\<C-b>":   "Ctrl-b:Toggles bookmark of the selected files/dir",
            \ "\<C-e>":   "Ctrl-e:Selects all/filtered files", 
            \ "\<C-z>":   "Ctrl-z:Commit the selected file(s), brings up a new buffer with all selected files", 
            \ "\<C-g>":   "Ctrl-g:Add the selected file(s), brings up a new buffer with all selected files", 
            \ "\<C-s>":   "Ctrl-s:Toogle the sticky behavior of vc_window, sticky!",
            \ "\<C-u>":   "Ctrl-u:Go/Navigate up",
            \ "\<C-t>":   "Ctrl-t:Go/Navigate top menu/start",
            \ g:vc_selkey : g:vc_selkey_dscr . ":Select the file/line",
            \ "\<C-a>":   "Ctrl-a:Shows the SVN Info",
            \ "\<C-h>":   "Ctrl-h:Shows the committed files after the selected revision (SVN - HEAD)",
            \ "\<C-p>":   "Ctrl-p:Shows the committed files before the selected revision (SVN - PREV)",
            \ "\<C-r>":   "Ctrl-r:Refresh/Redo",
            \ "\<C-j>":   "Ctrl-j:VCStatus",
            \ "\<F4>" :   "F4:Toggle args mode",
            \ "\<F5>" :   "F5:Redraws the buffer/vc_window", 
            \ "\<F6>" :   printf("F6:logs to %s", g:vc_log_name != "" ? g:vc_log_name : "file defined at g:vc_log_name"),
            \ "\<F8>" :   "F8:Sort on date if available else first column",
            \ }

fun! vc#utils#describe(key)
        retu has_key(s:dscrd, a:key) ? s:dscrd[a:key] : ""
endf
"2}}}
"1}}}
