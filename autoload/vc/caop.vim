" =============================================================================
" File:         autoload/vc/caop.vim
" Description:  Handle all caching/persistency
" Author:       Juneed Ahamed
" =============================================================================

"Caching ops {{{1
"script vars and init {{{2
let s:bmarks_cache_name = "vcbmarks"
let s:commit_log_name = "vc_commit"
"2}}}

" cache read/write {{{2
fun! vc#caop#fetch(type, path)
    if a:type == "repo" && !g:vc_browse_repo_cache | retu [0,[]] | en
    if a:type == "wc" && !g:vc_browse_workingcopy_cache | retu [0,[]] | en

    let fname = vc#caop#fname(a:type, a:path)
    if !filereadable(fname) | retu [0, []] | en
    let lines = readfile(fname)
    retu [1, lines]
endf

fun! vc#caop#fetchandfmt(type, path)
    let [result, lines] = vc#caop#fetch(a:type, a:path)
    if !result | retu [result, lines] | en

    let rlines = []
    for line in lines
        if line == "" | con | en
        call add(rlines, line)
    endfor
    unlet! lines
    retu [1, rlines]
endf

fun! vc#caop#cache(type, path, entries)
    retu s:docache(a:type, a:path, a:entries, 0)
endf

fun! vc#caop#cacheappend(type, path, entries)
    retu s:docache(a:type, a:path, a:entries, 1)
endf

fun! s:docache(type, path, entries, append)
    if a:type == "repo" && !g:vc_browse_repo_cache | retu vc#passed() | en
    if a:type == "wc" && !g:vc_browse_workingcopy_cache | retu vc#passed() | en
    if a:type == "bm" && !g:vc_browse_bookmarks_cache | retu vc#passed() | en

    try 
        let fname = vc#caop#fname(a:type, a:path)
        "call writefile(a:entries, fname)  "Guy Leaks
        if a:append
            sil! exe 'redi! >>' fname
        else
            sil! exe 'redi! >' fname
        endif
        sil! echo join(a:entries, "\n")
        sil! redi END
        unlet! fname
        retu vc#passed()
    catch  | call vc#utils#dbgmsg("At writecache:", v:exception) | retu vc#failed()
    finally | call vc#caop#purge() | endt
endf

fun! vc#caop#iscached(type, path)
    try
        return filereadable(vc#caop#fname(a:type, a:path))
    catch | endtry
    return 0
endf
"2}}}

"bmarks {{{2
fun! vc#caop#fetchbmarks()
    if !g:vc_browse_bookmarks_cache | retu g:bmarks | en
    let fname = vc#caop#fname("bm", s:bmarks_cache_name)
    if filereadable(fname)
        let lines = readfile(fname)
        let g:bmarkssid = 1000
        let g:bmarks = {}
        for line in lines
            if line == "" | con | en
            let g:bmarkssid += 1
            let g:bmarks[line] = g:bmarkssid
        endfor
    endif
    retu g:bmarks
endf

fun! vc#caop#cachebmarks()
    retu vc#caop#cache("bm", s:bmarks_cache_name, keys(g:bmarks))
endf
"2}}}

"logs {{{2
fun! vc#caop#cachedlog(repo, path)
    let path = a:repo . a:path
    retu vc#caop#iscached("log", path)
endf

fun! vc#caop#cachelog(repo, path, entries)
    let path = a:repo . a:path
    retu vc#caop#cache("log", path, a:entries)
endf

fun! vc#caop#fetchlog(repo, path)
    let path = a:repo . a:path
    retu vc#caop#fetch("log", path)
endf
"2}}}

"helpers {{{2
fun! vc#caop#fname(type, path)
    let path = expand(a:path)
    let path = (matchstr(path, "/$") == '') ? (path . '/') : path
    let path = a:type . "_". path
    retu g:vc_cache_dir . "/" . substitute(path, "[\\:|\\/|\\.| ]", "_", "g") . "vc_cache.txt"
endf

fun! vc#caop#cls(type, path)
    try
        call s:delfile(vc#caop#fname(a:type, a:path), 1)
    catch | call vc#utils#dbgmsg("At vc#caop#cls:", v:exception) | endt
endf

fun! s:delfile(fname, forceall)
    try 
        if !a:forceall && (matchstr(a:fname, s:bmarks_cache_name) != "" ||
                    \ matchstr(a:fname, s:commit_log_name) != "" )
            retu vc#passed() "Donot delete these files unless forced
        endif

        if matchstr(a:fname, "vc_cache.txt$") != "" 
            call delete(a:fname) | retu vc#passed()
        endif
    catch | call vc#utils#dbgmsg("At delfile:", v:exception) | endt
    retu vc#passed()
endf

fun! vc#caop#purge()
    try
        if g:vc_cache_dir == "" || !vc#utils#isdir(g:vc_cache_dir) | retu | en
        let files = sort(split(globpath(g:vc_cache_dir, "*"), "\n"), 'vc#utils#sortftime')
        let fcnt = len(files)
        if fcnt > g:vc_browse_cache_max_cnt + 1
            let delfiles = files[ :fcnt - g:vc_browse_cache_max_cnt - 1]
            call map(delfiles, 's:delfile(v:val, 0)')
        endif
        unlet! files
    catch | call vc#utils#dbgmsg("At vc#caop#purge:", v:exception) | endt
endf
"2}}}

"clear cache handler ClearAll {{{2
fun! vc#caop#ClearAll()
    try 
        if g:vc_cache_dir == "" || !vc#utils#isdir(g:vc_cache_dir) | retu | en
        let files = split(globpath(g:vc_cache_dir, "*"), "\n")
        call map(files, 's:delfile(v:val, 1)')
        call vc#utils#showconsolemsg("Cleared cache", 1)
    catch | call vc#utils#dbgmsg("At vc#caop#ClearAll:", v:exception) | endt
endf
"2}}}

fun! vc#caop#commitlog() "{{{2
    retu vc#utils#isdir(g:vc_cache_dir) ? 
                \ vc#caop#fname( "", s:commit_log_name) : tempname()
endf
"2}}}
"1}}}
