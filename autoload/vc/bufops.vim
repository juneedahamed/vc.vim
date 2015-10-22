" ============================================================================
" File:         autoload/vc/bufops
" Description:  Buffer mapping/operations for vc_window
" Author:       Juneed Ahamed
" =============================================================================

"Buffer Mappings {{{1
fun! vc#bufops#dflts() "{{{2
    autocmd VimResized vc_window call s:fakekeys()
    autocmd BufEnter vc_window call s:fakekeys()

    exe 'nn <buffer> <silent> <esc>'  ':<c-u>cal vc#winj#close()'.'<cr>'
    exe 'nn <buffer> <silent> <c-s>'  ':<c-u>cal vc#prompt#loop()'.'<cr>'

    for x in range(65, 90) + range(97, 122)
        let tc = nr2char(x)
        exe 'nn <buffer> <silent> ' . tc  ':<c-u>call ' . 'vc#prompt#accept("' . tc. '")' . '<cr>'
    endfor

    for x in range(0, 9)
        exe 'nn <buffer> <silent> ' . x  ':<c-u>call ' . 'vc#prompt#accept("' . x. '")' . '<cr>'
    endfor

    for x in [":", "/", "_", "-", "~", "#", "$", "=", "."]
        exe 'nn <buffer> <silent> ' . x  ':<c-u>call ' . 'vc#prompt#accept("' . x. '")' . '<cr>'
    endfor

    for x in ['(', ')', '\', '*', '+', '[', ']', '{', '}', '&', '@', '`', '?']
        exe 'nn <buffer> <silent> ' . x  ':<c-u>call ' . 'vc#prompt#show()' . '<cr>'
    endfor

    for x in ['<Down>']
        exe 'nn <buffer> <silent> ' . x ':normal! j <cr> :<c-u>call vc#prompt#show()<cr>'
    endfor

    for x in ['<Up>']
        exe 'nn <buffer> <silent> ' . x ':normal! k <cr> :<c-u>call vc#prompt#show()<cr>'
    endfor

    for x in ['<bs>', '<del>']
        exe 'nn <buffer> <silent> ' . x  ':<c-u>call ' . 'vc#prompt#del()' . '<cr>'
    endfor

    exe 'nn <buffer> <silent> <left>' ':<c-u>call ' . 'vc#prompt#moveleft()' . '<cr>'
    exe 'nn <buffer> <silent> <right>' ':<c-u>call ' . 'vc#prompt#moveright()' . '<cr>'
    exe 'nn <buffer> <silent> <home>' ':<c-u>call ' . 'vc#prompt#moveleftmost()' . '<cr>'
    exe 'nn <buffer> <silent> <end>' ':<c-u>call ' . 'vc#prompt#moverightmost()' . '<cr>'
    exe 'nn <buffer> <silent> <tab>' ':<c-u>call ' . 'vc#prompt#show()' . '<cr>'
    exe 'nn <buffer> <silent> <F4> :<c-u>call ' . 'vc#prompt#toggleargsmode()' . '<cr>'
    exe 'nn <buffer> <silent> <F5> :<c-u>call ' . 'vc#act#forceredr()' . '<cr>'
    exe 'nn <buffer> <silent> <F6> :<c-u>call ' . 'vc#act#logit()' . '<cr>'
    exe 'nn <buffer> <silent> <F8> :<c-u>call ' . 'vc#prompt#sort()' . '<cr>'
    exe 'nn <buffer> <silent> ?  :<c-u>call ' . 'vc#act#help()' . '<cr>'
endf
"2}}}

fun! vc#bufops#map(cdict) "{{{2
    let s:cdict = a:cdict
    let s:curbufmaps = {}

    call s:unmap()
    let idx = 1
    for [ign, tdict] in items(s:cdict.getallops())
        if has_key(tdict, "bop")
            exe 'nn <buffer> <silent> ' . tdict.bop printf(":<c-u>call vc#bufops#op(%d)<cr>", idx)
            let s:curbufmaps[idx] = [ign, tdict.bop]
            let idx = idx + 1
        endif
    endfor
endf
"2}}}

fun! vc#bufops#op(...) "{{{2
    try
        let [key, line] = vc#utils#extractkey(getline('.'))
        let opsd = s:cdict.getops(key)
        let chr = s:curbufmaps[a:000[0]][0]
        if len(opsd) > 0 && has_key(opsd, chr)
            let cbret = vc#prompt#cb(opsd[chr].fn, get(opsd[chr], 'args', []))
            if cbret == vc#fltrclearandexit() | call vc#winj#close() | retu | en  "Feed esc example commit
            if cbret != vc#nofltrclear() | call vc#prompt#clear() | en
            call vc#winj#stl() 
            call call(s:cdict.hasbufops ? "vc#prompt#show" : "vc#prompt#loop", [])
        endif
    catch 
        call vc#utils#showerr("oops error " . v:exception)
    endtry
endf
"2}}}

fun! s:fakekeys() "{{{2
    "let the getchar get a break with a key that is not handled
    if !vc#prompt#isploop() | retu vc#prompt#show() | en
    call feedkeys("\<Left>")
    call vc#winj#stl()
    redr
endf
"2}}}

fun! s:unmap() "{{{2
    for [key, tlist] in items(s:curbufmaps)
        try 
            exe 'nunmap <buffer> <silent> ' . tlist[1]
        catch 
            call vc#utils#dbgHld("unmap", v:exception)
        endtry
    endfor
    let s:curbufmaps = {}
endf
"2}}}
"1}}}
