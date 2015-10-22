"===============================================================================
" File:         autoload/vc/prompt.vim
" Description:  VC Prompt
" Author:       Juneed Ahamed
"===============================================================================
let s:fltr = ""
let s:fltrpos = 0
let s:ploop = 1
let s:sorttype = 0
let s:stopforargs = g:vc_prompt_args
let s:vc_open_revisioned = 0

fun! vc#prompt#init(cdict)
    call vc#prompt#clear()
    let s:ploop = !(g:vc_sticky_on_start && a:cdict.hasbufops)
    let s:ploop = has('gui_running') ? s:ploop : 1
endf

fun! vc#prompt#start()
    call call(s:ploop ? "vc#prompt#loop" : "vc#prompt#show", [])
endf 

fun! vc#prompt#isploop()
    retu s:ploop
endf

fun! vc#prompt#setNoLoop(...)
    let s:ploop = 0
    retu vc#noPloop()
endf

fun! vc#prompt#clear()
    let s:fltr = ""
    let s:fltrpos = 0
    retu s:fltr
endf

fun! vc#prompt#moveleft()
    if s:fltrpos > 0 | let s:fltrpos -= 1  | en
    call vc#prompt#show()
endf

fun! vc#prompt#moveright()
    if s:fltrpos < len(s:fltr) | let s:fltrpos += 1  | en
    call vc#prompt#show()
endf

fun! vc#prompt#moveleftmost()
    let s:fltrpos = 0
    call vc#prompt#show()
endf

fun! vc#prompt#moverightmost()
    let s:fltrpos = len(s:fltr)
    call vc#prompt#show()
endf

fun! vc#prompt#accept(chr)
    if len(s:fltr)<=90
        let s:fltr = strpart(s:fltr, 0, s:fltrpos) . a:chr . strpart(s:fltr, s:fltrpos)
        let s:fltrpos += 1
        call vc#winj#repopulate(s:fltr, 1)
        call vc#prompt#show()
    endif
endf

fun! vc#prompt#del()
    if s:fltrpos > 0 
        let first_ = strpart(s:fltr, 0, s:fltrpos-1)
        let last_ = strpart(s:fltr, s:fltrpos)
        let s:fltr = first_ . last_
        let s:fltrpos -= 1
        call vc#winj#repopulate(s:fltr, 0)
        call vc#prompt#show()
    endif
endf

fun! vc#prompt#str()
    retu s:fltr
endf

fun! vc#prompt#len()
    retu len(s:fltr)
endf

fun! vc#prompt#fltrpos()
    if s:fltrpos > 0
        retu s:fltr[ : s:fltrpos-1 ] . "_" . s:fltr[s:fltrpos :]
    else
        retu "_" . s:fltr[s:fltrpos :]
    endif
endf

fun! vc#prompt#sort(...)
    let s:sorttype = !s:sorttype
    call vc#winj#sort(s:fltr)
    call vc#prompt#show()
    retu vc#nofltrclear()
endf

fun! vc#prompt#sorttype()
    retu s:sorttype
endf

fun! vc#prompt#empty()
    return s:fltr == ""
endf
fun! vc#prompt#empty()
    return s:fltr == ""
endf

fun! vc#prompt#show()
    redr | exec 'echohl ' . g:vc_custom_prompt_color | echon "filter: " | echohl None
    "echon vc#prompt#fltrpos() | echon 
    if s:fltrpos > 0 | echon s:fltr[ : s:fltrpos-1 ] | en
    exec 'echohl ' . g:vc_custom_prompt_color | echon  s:fltr[s:fltrpos] | echohl None | echon s:fltr[s:fltrpos +1 :] 
endf

fun! vc#prompt#loop()
    let s:ploop = 1
    call vc#winj#stl()
    while !vc#doexit()
        try
            call vc#prompt#show()
            let nr = getchar()
            let chr = !type(nr) ? nr2char(nr) : nr
            if nr == 32 && vc#prompt#empty() | cont | en
            if chr == "?" | call vc#act#help() | cont | en
            if chr == "\<Left>" | call vc#prompt#moveleft() | cont | en
            if chr == "\<Right>" | call vc#prompt#moveright() | cont | en
            if chr == "\<Home>" | call vc#prompt#moveleftmost() | cont | en
            if chr == "\<End>" | call vc#prompt#moverightmost() | cont | en

            call vc#home()
            let [key, line] = vc#utils#extractkey(getline('.'))

            let opsd = vc#winj#ops(key)
            if len(opsd) > 0 && has_key(opsd, chr)
                try
                    let cbret = vc#prompt#cb(opsd[chr].fn, get(opsd[chr], 'args', []))
                    if cbret == vc#fltrclearandexit() | retu | en  "esc example commit
                    if cbret == vc#noPloop() 
                        redr! | call vc#prompt#setNoLoop() | call vc#winj#stl()
                        call vc#prompt#show() | retu
                    endif
                    if cbret != vc#nofltrclear() | call vc#prompt#clear() | en
                    call vc#winj#stl() | redr! | cont
                catch 
                    call vc#utils#dbgmsg("vc#prompt#loop", v:exception)
                    call vc#utils#showerr("Oops error ") | cont
                endtry
            endif

            if chr ==# "\<BS>" || chr ==# "\<Del>" 
                call vc#prompt#del()
            elseif chr == "\<Esc>"
                call vc#prepexit()
                call vc#winj#close() | break
            elseif nr >=# 0x20
                call vc#prompt#accept(chr)
            else | exec "normal!" . chr
            endif
        catch | call vc#utils#dbgmsg("vc#prompt#loop", v:exception) | endt
    endwhile
    exe 'echo ""' |  redr
    call vc#winj#close()
endf

fun! vc#prompt#cb(cbfn, optargs)
    let [key, line] = vc#utils#extractkey(getline('.'))
    let result = 0
    try
        let argsd = { 
                    \ "dict" : vc#winj#dict(),
                    \ "key"  : key,
                    \ "line" : line,
                    \ "opt"  : a:optargs,
                    \ }
        let result = call(a:cbfn, [argsd]) 
    catch 
        call vc#utils#dbgmsg("At vc#prompt#cb", v:exception)
        call vc#utils#showerr("Oops error ")
    endtry
    retu result
endf

fun! vc#prompt#toggleargsmode(...)
    let s:stopforargs = xor(s:stopforargs, 1)
    call vc#winj#stl()
endf

fun! vc#prompt#stoppingforargs()
    retu s:stopforargs
endf

fun! vc#prompt#openrevisioned()
    retu s:vc_open_revisioned 
endf

fun! vc#prompt#openrevisioneddefault()
    let s:vc_open_revisioned = 0
endf

fun! vc#prompt#toggleopenrevision(...)
    let s:vc_open_revisioned = xor(s:vc_open_revisioned, 1)
    call vc#winj#stl()
endf
