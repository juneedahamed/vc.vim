" ============================================================================
" File:         autoload/winj.vim
" Description:  window handling such as new, populate, close
" Author:       Juneed Ahamed
" =============================================================================

"autoload/winj.vim {{{1
"vars "{{{2
let s:jwinname = 'vc_window'
let s:clines = []
let s:fregex = ""
"2}}}

"win new/close handlers {{{2
fun! vc#winj#New(cdict)
    let s:fregex = ""
    call vc#prompt#clear()
    call vc#winj#close()
    noa call s:init(a:cdict)
endf

fun! s:init(cdict)
    let jwinnr = bufwinnr(s:jwinname)
    silent! exe jwinnr < 0 ? 'keepa botright 1new ' .
                \ fnameescape(s:jwinname) : jwinnr . 'wincmd w'
    call vc#syntax#build()
    call vc#bufops#dflts()
    call vc#prompt#init(a:cdict)
    try | let s:vim_tm = &tm | let &tm = 0 | catch | endt
endf

fun! vc#winj#close()
    let jwinnr = bufwinnr(s:jwinname)
    if jwinnr < 0 | retu | en
    call vc#altwinnr()
    let prevwinnr=winnr() 
    exe jwinnr . "wincmd w" | wincmd c 
    exe prevwinnr . "wincmd w" 
    if exists('s:vim_tm') | let &tm = s:vim_tm | en
    echo "" | redr 
    retu vc#passed()
endf

fun! s:resize()
    call vc#home()
    silent! exe 'resize ' . (line('$') < g:vc_window_max_size ? line('$') :
                \ g:vc_window_max_size)
    silent! exe 'normal! gg'
endf
"2}}}

"accessors {{{2
fun! vc#winj#ops(key)
    retu s:cdict.getops(a:key)
endf

fun! vc#winj#dict()
    retu s:cdict
endf

fun! vc#winj#regex()
    retu s:fregex
endf
"2}}}

"populate {{{2
fun! vc#winj#populateJWindow(cdict)
    try 
        call vc#winj#New(a:cdict)
        call vc#winj#populate(a:cdict) 
        call vc#prompt#start()
    catch 
        call vc#utils#dbgmsg("populateJWindow", v:exception)
    endt
endf

fun! vc#winj#populate(cdict)
    call vc#home()
    let s:cdict = a:cdict
    setl modifiable
    sil! exe '%d _ '
    let linenum = 0
    let s:clines = []

    try
        let [s:clines, displaylines] = s:cdict.lines()
        call s:setline(1, displaylines)
        unlet! displaylines
        call vc#bufops#map(s:cdict)
    catch 
        call vc#utils#dbgmsg("At populate", v:exception)
    endtry
   
    let linenum = line('$') < 1 ? 1 : line('$') + 1 
    if s:cdict.haserror()
        if getline('$') == "" | let linenum = 1 | en
        call s:setline(linenum, s:cdict.error.line)
    endif

    if linenum == 0 | call s:setnocontents(1) | en
    let s:fregex = ""
    call s:resize()
    call vc#syntax#highlight()
    call vc#winj#stl()
    if has_key(a:cdict, 'callback_when_populated')
        call call(a:cdict.callback_when_populated[0], a:cdict.callback_when_populated[1:])
    endif
    setl nomodifiable | redr
endf

fun! s:sort(line1, line2)
    let [k1, date1, l1] = vc#utils#extractkeydate(a:line1)
    let [k2, date2, l2] = vc#utils#extractkeydate(a:line2)
    
    let c1 = date1 == "" ? l1 : date1
    let c2 = date2 == "" ? l2 : date2

    if matchstr(c1, g:vc_info_str) != "" | retu -1 | en
    if matchstr(c2, g:vc_info_str) != ""  | retu 1 | end
    
    if matchstr(c1, g:vc_menu_start_str) != "" | retu 1 | en
    if matchstr(c2, g:vc_menu_start_str) != ""  | retu -1 | end

    if vc#prompt#sorttype()
        return c1 == c2 ? 0 : c1 > c2 ? -1 : 1
    else
        return c1 == c2 ? 0 : c1 > c2 ? 1 : -1
    endif
endf

fun! vc#winj#sort(fltr)
    try
        if line('$') == 0 | retu | endif
        call vc#home()
        let lines = getbufline(bufnr('vc_window'), 0, "$")
        let lines = sort(lines, "s:sort")
        call s:setcontents(lines)
    catch
        call vc#utils#dbgmsg("At vc#winj#sort", v:exception)
    endtry
endf

fun! vc#winj#repopulate(fltr, incr)
    try
        if len(a:fltr)>= 1 && a:incr && line('$') == 0 | retu | endif
        call vc#home()
        let [lines, s:fregex] = vc#fltr#filter(s:clines, a:fltr, g:vc_fuzzy_search_result_max)
        call s:setcontents(lines)
    catch 
        call vc#utils#dbgmsg("At repopulate", v:exception)
    endtry

    setl nomodifiable | redraws 
    redr
endf

fun! s:setcontents(lines)
    try
        setl modifiable  
	    sil! exe '%d _ ' | redr

        if len(a:lines) <= 0 
            call s:setnocontents(1)
        else
            call s:setline(1, a:lines) 
        endif

        call vc#syntax#highlight()
        call s:resize()
        call vc#winj#stl()
    catch 
        call vc#utils#dbgmsg("At s:setcontents", v:exception)
    endtry
    setl nomodifiable | redraws 
    redr
endf

fun! s:setline(start, lines)
    try | let oul = &undolevels | catch | endt
    try | set undolevels=-1 
    catch | endt
    let lines = type(a:lines) == type([]) && len(a:lines) > 0 ? filter(a:lines, 'len(v:val)>0') : a:lines
    try | call setline(a:start, lines) | catch | endt
    unlet! lines
    try | exec 'set undolevels=' . oul | catch | endt
endf

fun! s:setnocontents(linenum)
    call s:setline(a:linenum, '--ERROR--: No contents')
endf
"2}}}

"statusline update {{{2
fu! vc#winj#stl()
    try
        echo " "
        if !vc#home()[0] | retu | en
        let opsdsc = ' %#'.g:vc_custom_statusbar_ops_hl.'# ?:Help '
        let title = g:vc_custom_statusbar_title.s:cdict.title 
        let alignright = '%='
        let scnt = len(vc#select#dict()) > 0 ? 's['. len(vc#select#dict()) . ']' : ''
        let scnt = '%#' . g:vc_custom_statusbar_sel_hl . '#' . scnt
        let sticky = vc#prompt#isploop() ? "" : '%#' . g:vc_custom_sticky_hl .'#' . "STICKY "
        let argmode = !vc#prompt#stoppingforargs() ? "" : '%#' . g:vc_custom_sticky_hl .'#' . "ARGS "
        let versionmode = !vc#prompt#openrevisioned() ? "" : '%#' . g:vc_custom_sticky_hl .'#' . "VER "
        let cnt = g:vc_custom_statusbar_title . ' [' . '%L/' . len(s:clines) . ']'
        let &l:stl = title.alignright.opsdsc.sticky.argmode.versionmode.scnt.cnt
    catch
        call vc#utils#dbgmsg("At vc#winj#stl", v:exception)
    endtry
endf
"2}}}
"1}}}
