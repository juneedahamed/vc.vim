" =============================================================================
" File:         autoload/vc.vim
" Description:  Plugin for svn, git, hg, bzr
" Author:       Juneed Ahamed
" =============================================================================

"autoload/vc.vim {{{1
"script vars {{{2
let s:endnow = 0
"2}}}

"For projects tracked by more than one repo set the preferred default repo
fun! vc#Defaultrepo(repo)  "{{{2
    if matchstr(a:repo, vc#repos#repopatt()) == "" 
        retu vc#utils#showerr("Failed, valid options are " . join(vc#repos#repos(), "|"))
    endif
    let g:vc_default_repo = a:repo
    if exists('b:vc_path') 
        unlet! b:vc_path
    endif
    call vc#utils#showconsolemsg("Default repository set to " . g:vc_default_repo, 1)
endf
"2}}}

fun! vc#Diff(bang, showerr, ...) "{{{2
    try
        call vc#init()
        let disectd = vc#argsdisectlst(a:000, "all")
        let meta = vc#repos#meta(disectd.target, disectd.forcerepo)
        if disectd.vcnoparse
            let argsd = {
                        \ "meta": meta, 
                        \ "revision": disectd.revision,
                        \ "cargs": disectd.cargs,
                        \ "target": disectd.target,
                        \ "op": "Diff",
                        \ }
            retu vc#act#handleNoParseCmd(argsd, 'diff.vcnoparse')
        endif
        if exists('b:vc_path') && vc#utils#localFS(b:vc_path)
            let target = b:vc_path
        else
            let target = vc#utils#bufrelpath()
        en
        let argsd = {"meta": meta, "bang":a:bang, "revision": disectd.revision}
        call vc#repos#call(meta.repo, 'diff', argsd)
        retu vc#passed()
    catch
        if a:showerr == 1 | call vc#utils#showerrJWindow("Diff", v:exception) | en
        retu vc#failed()
    finally
        unlet! argsd
        unlet! meta
    endtry
endf
"2}}}

fun! vc#Blame(...)   "{{{2
    try
        call vc#init()
        let disectd = vc#argsdisectlst(a:000, "all")
        let meta = vc#repos#meta(disectd.target, disectd.forcerepo)
        let argsd = {'meta':meta}
        call vc#act#blame(argsd)
    catch
        call vc#utils#showerrJWindow("Blame", v:exception)
    finally
        unlet! argsd
        unlet! meta
    endtry
endf
"2}}}

fun! vc#Info(...)  "{{{2
    try
        call vc#init()
        let disectd = vc#argsdisectlst(a:000, "all")
        let meta = vc#repos#meta(disectd.target, vc#fetchrepo(a:000))
        let argsd = {'meta':meta}
        let info = vc#repos#call(meta.repo, 'info', argsd)
        call vc#utils#showconsolemsg(info, 0)
    catch
        call vc#utils#showerrJWindow("Info", v:exception)
    finally
        unlet! argsd
        unlet! meta
    endtry
endf
"2}}}

function! vc#EnableBufferSetup(...)
    if g:vc_enable_buffers != 1 | retu | en
	augroup VCBufEnter
		au!
		au BufEnter * call vc#BuffersSetup()
	augroup END
endf

fun! vc#BuffersSetup(...) "{{{2
    let [curwinnr, jwinnr] = [winnr(), bufwinnr('vc_window')]
    if jwinnr > 0 && curwinnr == jwinnr | retu | en
	if exists('b:vc_file_meta') | retu | en
    let target = vc#utils#fnameescape(expand('<afile>'))
    call vc#repos#meta(target, "")
endf
"2}}}

fun! vc#BranchName(...) "{{{2
    try
        if g:vc_enable_buffers != 1
            call vc#BuffersSetup(a:000)
        endif
        retu b:vc_file_meta.branch
    catch | endtry
    retu "-"
endf
"2}}}

fun! vc#Revert(bang, ...)  "{{{2
    try
        call vc#init()
        let target = vc#utils#bufrelpath()
        let meta = vc#repos#meta(target, vc#fetchrepo(a:000))
        let argsd = {"meta": meta, "cargs": "" }
        let cmd = vc#repos#call(meta.repo, "revertcmd", argsd) 
        let [result, response] = vc#utils#execshellcmduseexec(cmd, 0)
        if result == vc#passed() 
            if response != "" | call vc#utils#showconsolemsg(response, 1) | en
            if a:bang == "!" | call vc#utils#refreshfile(target) | en
        else
            retu vc#utils#showerr("Failed " . response)
        endif
    catch
        call vc#utils#showerrJWindow("Revert", v:exception)
    finally
        unlet! argsd
        unlet! meta
    endtry
endf
"2}}}

fun! vc#MoveCopy(bang, op, ...)  "{{{2
    try
        call vc#init()
        let arglst = copy(a:000)
        let forcerepo = index(arglst, "-fs") >= 0 ? remove(arglst, index(arglst, "-fs")) : ""
        let dst = vc#utils#fnameescape(remove(arglst, -1))
        let disectd = vc#argsdisectlstmultipletargets(arglst, "onlyfiles")
        let [result, localop, meta ] = [vc#failed(), 0, {}]

        "Ready a filesystem op instead of VC op when forced with -fs
        if forcerepo == "-fs"
            let entries = filter(copy(disectd.targets), 'vc#utils#localFS(v:val)')
            let localop = len(entries) > 0 && len(entries) == len(disectd.targets)
            let [result, meta] = localop != 0 ? [vc#passed(), {"repo": "-fs"}] : [vc#failed(), {}]
        endif

        "Ready a VC op if not filesystem op
        if localop == 0
            let srclst = vc#utils#filesbywrd(disectd.targets, disectd.forcerepo, 0, [])
            let tolst = vc#utils#filesbywrd([dst,], disectd.forcerepo, 0, [])
            let [result, entries, meta] = vc#utils#makelistforcopyormove(srclst, tolst, a:op)
        endif

        "Execute cmds
        if result == vc#passed() && len(entries) > 0
            let theargsd = {"meta": meta, "flist": entries, "topath" : dst,
                        \"cargs":disectd.cargs}
            let opcmd =  a:op == "copy" ? "browse.copycmd" : "browse.movecmd"
            let [result, cmd] = vc#repos#call(meta.repo, opcmd, theargsd)
        
            "For move reload always, for copy on bang
            if result == vc#passed() && cmd != ""
                let [result, response] = vc#utils#execshellcmduseexec(cmd, 0)
                if result == vc#passed() && (a:op == "move" || a:bang == "!")
                    call vc#utils#refreshfileop(a:op, entries, dst)
                endif
            elseif result == vc#fltrclearandexit()
                retu
            else
                call vc#utils#showerr("Failed ")
            endif
        endif
    catch
        call vc#utils#showerrJWindow(a:op, v:exception)
    endtry
endf
"2}}}

fun! vc#PushPullFetch(vccmd, ...) "{{{2
    try
        call vc#init()
        let disectd = vc#argsdisectlst(a:000, "onlydirs")
        let meta = vc#repos#meta(disectd.target, disectd.forcerepo)
        let argsd = {"cargs": disectd.cargs, "meta":meta}
        call vc#repos#call(meta.repo, a:vccmd, argsd)
    catch
        call vc#utils#showerr("Failed " . v:exception)
    finally
        unlet! argsd
        unlet! meta
    endtry
endf
"2}}}

fun! vc#HgInOut(cmd, title, ...)   "{{{2
    try
        call vc#init()
        let disectd = vc#argsdisectlst(a:000, "onlydirs")
        let meta = vc#repos#meta(disectd.target, disectd.forcerepo)
        
        let argsd = {"cargs": disectd.cargs, "meta":meta}
        let [entries, cmd] = vc#repos#call(meta.repo, a:cmd, argsd)

        let ldict = vc#dict#new("Log", {"meta" : meta})
        let ldict.title = a:title

        if empty(entries)
            call vc#dict#adderrup(ldict, "Nothing here : ", ldict.meta.cmd)
        else
            call vc#dict#addentries(ldict, 'logd', entries, {})
        endif
    catch
        let ldict = vc#dict#new(a:title)
        call vc#dict#adderr(ldict, 'Maybe No ' . a:title, v:exception)
    finally
        unlet! argsd
        unlet! meta
    endtry
    call vc#winj#populateJWindow(ldict)
endf 
"2}}}

"init/exit {{{2
fun! vc#home() 
    let [athome, curwinnr, jwinnr] = [ 0, winnr(), bufwinnr('vc_window')]
    if jwinnr > 0 && curwinnr != jwinnr
        silent! exe jwinnr . 'wincmd w'
    endif
    let atHome = jwinnr > 0 ? 1 : 0
    retu [atHome, jwinnr]
endf

fun! vc#doexit() 
    retu s:endnow
endf

fun! vc#prepexit()
    if vc#prompt#isploop() 
        let s:endnow = 1
        call vc#stack#clear()
        call vc#select#clear()
        call vc#prompt#openrevisioneddefault()
    else
        call vc#select#clear()
    endif
    return 1
endf

fun! vc#init()
    let g:vc_logversions = []
    let g:vc_files_to_commit = []
    call vc#stack#clear()
    call vc#select#clear()
    let s:endnow = 0
endf

fun! vc#altwinnr()
    let altwin = winnr('#')
    let jwinnr = bufwinnr('vc_window')
    let curwin = winnr()
    try
        if jwinnr > 0 && altwin > 0 && curwin != altwin && jwinnr != altwin
            silent! exe  altwin . 'wincmd w'
        endif
    catch | endtry
endf
"2}}}

"result returns {{{2
fun! vc#failed()
    retu 0
endf

fun! vc#passed()
    retu 1
endf

fun! vc#nofltrclear()
    retu 2
endf

fun! vc#cancel()
    retu 3
endf

fun! vc#noPloop()
    retu 10
endf

fun! vc#fltrclearandexit()
    retu 110
endf
"2}}}

"repos {{{2
fun! vc#fetchrepo(lst)
    let flst = filter(copy(a:lst), 'matchstr(v:val, vc#repos#repopatt()) != ""')
    retu len(flst) > 0 ? flst[0] : ""
endf

fun! vc#argsdisectlstmultipletargets(arglst, globpath)
    let arglst = copy(a:arglst)
    let forcerepo = vc#argsremoveparam(arglst, vc#repos#repopatt(), 1, 0)
    let targets = map(filter(copy(arglst), 'vc#utils#localFS(v:val)'), 'vc#utils#fnameescape(v:val)')
    if len(targets) == 0 | call add(targets, vc#maketarget(a:globpath)) | endif
    call filter(arglst, '!vc#utils#localFS(v:val)')
    let cargs = vc#utils#strip(join(arglst, " "))
    retu { 
                \ "forcerepo": forcerepo, 
                \ "targets": targets,
                \ "cargs": cargs, 
                \}
endf

fun! vc#argsdisectlst(arglst, globpath)
    let arglst = copy(a:arglst)
    let vcnoparse = vc#argsremoveparam(arglst, "-vcnoparse", 0, 0)
    let forcerepo = vc#argsremoveparam(arglst, vc#repos#repopatt(), 1, 0)
    let forcerepo = forcerepo == "" && exists('b:vc_repo') ? b:vc_repo : forcerepo
    let revision = vc#argsremoveparam(arglst, "-revision", 0, 1)
    let target = vc#argsremoveparam(arglst, "-target", 0, 1)
    let arglst = filter(arglst, 'v:val != ""')
    if target == "" 
        let lasttoken = len(arglst) > 0 ? arglst[-1] : ""
        if( lasttoken != "" && vc#utils#localFS(lasttoken))
            let target = vc#utils#fnameescape(lasttoken)
            let arglst[-1] = ""
        else
            let target = vc#maketarget(a:globpath)
        endif
    else
        let target = vc#utils#fnameescape(lasttoken)
    endif
    let cargs = join(arglst, " ")

    retu { 
                \ "forcerepo": forcerepo, 
                \ "target": target,
                \ "cargs": cargs, 
                \ "revision": revision,
                \ "vcnoparse": vcnoparse != "" ? 1 : 0,
                \}
endf

fun! vc#getcargs(arglst, param, ispattern, hasvalue)
    retu vc#argsremoveparam(a:arglst, a:param, a:ispattern, a:hasvalue)
endf

fun! vc#argsremoveparam(arglst, param, ispattern, hasvalue)
    let [foundparam, foundparamvalue] = ["", ""]
    let parampatt = a:ispattern ? a:param : '\M^\s\*' . a:param . '\(\s\|=\)\*'

    for i in range(0, len(a:arglst)-1)
        if matchstr(a:arglst[i], parampatt) != ""
            let foundparam = a:arglst[i]
            if !a:hasvalue
                let foundparamvalue = foundparam
                let a:arglst[i] = ""
                return foundparamvalue
            else
                "Handle values as -target=myfile | -targetmyfile
                let remaining = substitute(foundparam, a:param . "=\*", "", "")
                if remaining != ""
                    let foundparamvalue = remaining
                    let a:arglst[i] = ""
                    return foundparamvalue
                endif

                "Handle values such as [-target=, myfile] | [target, =myfile]
                "| [target, = , myfile]
                " -m 'This is a tes'
                let [foundparamvalue, startfound] = ["", 0]
                for j in range(i+1, len(a:arglst)-1)
                    if matchstr(a:arglst[j], '\M^\s\*=\s\*$') == "=" 
                        let a:arglst[j] = ""
                        continue
                    else
                        let paramseg = startfound == 1 ? a:arglst[j] : substitute(a:arglst[j], '\V\^\s\*=\*\s\*', "", "")
                        let [a:arglst[i], a:arglst[j]] = ["", ""]
                        let foundparamvalue = vc#utils#strip(foundparamvalue . " " . paramseg)
                        if len(matchstr(paramseg, "^[\"|\']")) > 0 && startfound == 0 
                            let startfound = 1 
                            continue
                        elseif len(matchstr(paramseg, "[\"|\']$")) > 0 "end found
                            retu foundparamvalue
                        elseif startfound == 1 
                            continue
                        endif
                        return foundparamvalue
                    endif
                endfor
            endif
        endif
    endfor
    return foundparamvalue
endf

fun! vc#argstrremoverepo(argstr)
    let repo = matchstr(a:argstr, vc#repos#repopatt())
    retu [vc#utils#strip(repo), substitute(a:argstr, repo, "", "")]
endf

"globpath = onlyfiles, onlydirs, all
fun! vc#maketarget(globpath)
    let target = "."
    try
        if a:globpath != "onlydirs" && exists('b:vc_path') | retu b:vc_path | en
        if a:globpath != "onlydirs"
            retu vc#utils#bufrelpath() 
        endif
    catch |  endtry
    let target = a:globpath == "onlyfiles" && target == "." ? "" : target
    retu vc#utils#fnameescape(target)
endf
"2}}}
"1}}}
