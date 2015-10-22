"===============================================================================
" File:         autoload/vc/mylist.vim
" Description:  VC MyList Browser
" Author:       Juneed Ahamed
"===============================================================================

"vc#mylist.vim {{{1

fun! vc#mylist#Browse() "{{{2
    call vc#init()
    call vc#mylist#_browse('vc#winj#populateJWindow')
endf
"2}}}

fun! vc#mylist#menucb(...)  "{{{2
    retu vc#mylist#_browse('vc#winj#populate')
endf
"2}}}

fun! vc#mylist#_browse(populateCb) " {{{2
    if len(g:p_browse_mylist) == 0 
        let edict = vc#utils#errdict("BrowseMyList", 
                    \ "Please set g:vc_browse_mylist " .
                    \ "at .vimrc see :help g:vc_browse_mylist")
        call call(a:populateCb, [edict]) | unlet! edict | retu 1
    endif
    
    let bdict = vc#dict#new("MyList")
    try
        let bdict.meta = vc#utils#blankmeta()
        call vc#stack#push('vc#mylist#_browse', ['vc#winj#populate'])
        if empty(g:p_browse_mylist)
            call vc#dict#adderrup(bdict, "No files", "")
        else
            let ops = vc#browse#ops()
            call remove(ops, "\<C-u>")
            call vc#dict#addbrowseentries(bdict, 'browsed', g:p_browse_mylist, ops)
        endif
        call call(a:populateCb, [bdict])
        unlet! bdict
    catch | call vc#utils#dbgmsg("At vc#mylist#_browse", v:exception) 
    endtry
    retu vc#passed()
endf
"2}}} 
"1}}}
