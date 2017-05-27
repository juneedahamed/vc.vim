"===============================================================================
" File:         autoload/vc/buffer.vim
" Description:  VC Buffer Files Browser
" Author:       Juneed Ahamed
"===============================================================================

"vc#buffer.vim {{{1

" ops and vars {{{2
fun! s:ops(curbufname)
   retu { 
       \ "\<Enter>": {"bop":"<enter>","fn":'vc#browse#digin', "args":[0, 1]},
       \ "\<C-q>"  : {"bop":"<c-q>", "dscr":'Ctrl-q:Quit/Close Buffer', "fn":'vc#buffer#close', "args":[a:curbufname]},
       \ "\<C-r>"  : {"bop":"<c-r>", "fn":'vc#buffer#menucb', "args":[]},
       \ "\<C-v>"  : {"bop":"<c-v>", "fn":'vc#gopshdlr#openfile', "args":['vc#act#vs']},
       \ "\<C-d>"  : {"bop":"<c-d>", "fn":'vc#gopshdlr#openfile', "args":['vc#act#diff']},
       \ "\<C-l>"  : {"bop":"<c-l>", "fn":'vc#browse#logs'},
       \ "\<C-b>"  : {"bop":"<c-b>", "fn":'vc#gopshdlr#book'},
       \ "\<C-t>"  : {"bop":"<c-t>", "fn":'vc#stack#top'},
       \ "\<C-i>"  : {"bop":"<c-i>", "fn":'vc#browse#browseinfo'},
       \ "\<C-z>"  : {"bop":"<c-z>", "fn":'vc#gopshdlr#commit'},
       \ "\<C-g>"  : {"bop":"<c-g>", "fn":'vc#gopshdlr#add'},
       \ g:vc_selkey : {"bop":g:vc_selkey_buf, "fn":'vc#gopshdlr#select'},
       \ "\<C-j>"  : {"bop":"<c-j>", "fn":'vc#browse#status'},
       \ }
endf
"2}}}

fun! vc#buffer#close(argsd) "{{{2
    let [adict, akey, aline] = [a:argsd.dict, a:argsd.key, a:argsd.line]
    let curbufname = a:argsd.opt[0]
    if has_key(adict, 'browsed') 
        try
            for [key, sdict] in items(vc#select#dict())
                let curfile = vc#utils#joinpath(adict.bparent, sdict.path)
                if curfile != curbufname 
                    call vc#buffer#delete(curfile)
                endif
            endfor

            let buffile = vc#utils#joinpath(adict.bparent, aline)
            if buffile != curbufname
                call vc#buffer#delete(buffile)
            endif
            call vc#select#clear()
            call vc#buffer#_browse('vc#winj#populate', curbufname)
        catch 
            call vc#utils#dbgmsg("At vc#buffer#close", v:exception) 
        endtry
    endif
endf

fun! vc#buffer#delete(name)
    try
        exec "bd " fnameescape(a:name)
    catch|endtry
endf
"2}}}

fun! vc#buffer#Browse() "{{{2
    call vc#init()
    call vc#buffer#_browse('vc#winj#populateJWindow', bufname('%'))
endf
"2}}}

fun! vc#buffer#menucb(...)  "{{{2
    try
        retu vc#buffer#_browse('vc#winj#populate',  bufname("%"))
    catch
        call vc#utils#dbgmsg("At vc#buffer#menucb :", v:exception)
    endtry
endf
"2}}}

fun! vc#buffer#_browse(populateCb, curbufname)  "{{{2
    let bdict = vc#dict#new("BrowseBuffer")
    try
        let bdict.meta = vc#utils#blankmeta()
        call vc#stack#push('vc#buffer#_browse', ['vc#winj#populate', a:curbufname])
   
        let files = vc#buffer#files(a:curbufname)
        if empty(files) 
            call vc#dict#adderrup(bdict, "No files", "")
        else
            call vc#dict#addbrowseentries(bdict, 'browsed', files, s:ops(a:curbufname))
        endif
        call call(a:populateCb, [bdict])
        call vc#gopshdlr#removesticky()
        unlet! bdict
    catch
        call vc#utils#dbgmsg("At vc#buffer#_browse", v:exception) 
    endtry
    retu vc#passed()
endf
"2}}}

fun! vc#buffer#files(curbufname) "{{{2
    let bfiles = []
    try 
        let bfiles = sort(filter(range(1, bufnr('$')), 'getbufvar(v:val, "&bl") && bufname(v:val) != ""'))
        let bfiles = map(bfiles, 'bufname(v:val)')
    catch 
        call vc#utils#dbgmsg("At vc#buffer#files :", v:exception)
    endtry
    retu bfiles
endf
"2}}}

