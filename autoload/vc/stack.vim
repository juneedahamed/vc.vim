"===============================================================================
" File:         autoload/vc/stack.vim
" Description:  VC Stack
" Author:       Juneed Ahamed
"===============================================================================

"vc#stack.vim {{{1

"vars {{{2
let s:vc_stack = []
let s:vc_nav_line = ""
"2}}}

"functions {{{2
fun! vc#stack#show()
    echo s:vc_stack
    let x = input("There stack")
endf

fun! vc#stack#clear()
    let s:vc_stack = []
endf

fun! vc#stack#push(...)
    "call add(s:vc_stack, a:000)    
    "Older version of vim 7.1.138 seems to cause
    "issues with [[], []] else the upper line will do all is needed 
    let elems = []
    if a:0 >= 1 | call add(elems, a:1) | en
    if a:0 >=2 && type(a:2) == type([]) | call extend(elems, a:2) | en
    let s:vc_nav_line = getline(".")
    call add(s:vc_stack, elems)
endf

fun! vc#stack#pop(...)
    try
        let movetoline = s:vc_nav_line
        let callnow = s:vc_stack[len(s:vc_stack)-2]
        let s:vc_stack = s:vc_stack[:-3]
        call call(callnow[0], callnow[1:])
        call s:findandsetcursor(movetoline)
     catch | call vc#utils#dbgmsg("At pop", v:exception) | endt
    retu vc#passed()
endf

fun! s:findandsetcursor(movetoline)
    try
        if len(a:movetoline) > 0
            let [linenum, line] = vc#utils#extractkey(a:movetoline)
            if a:movetoline ==# getline(linenum) | call cursor(linenum, 0) | en
        endif
    catch | call vc#utils#dbgmsg("At findandsetcursor", v:exception) | endt
endf

fun! vc#stack#top(...)
    try
        if len(s:vc_stack) > 0
            let cb = s:vc_stack[0]
            let s:vc_stack = []
            call call(cb[0], cb[1:])
        else
            call vc#utils#dbgmsg("At top ", "Nothing in stack")
        endif
    catch | call vc#utils#dbgmsg("At top", v:exception) | endtry
    retu vc#passed()
endf
"2}}}
"1}}}
