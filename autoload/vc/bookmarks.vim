"===============================================================================
" File:         autoload/vc/bookmarks.vim
" Description:  VC Bookmarks Browser
" Author:       Juneed Ahamed
"===============================================================================

"vc#bookmarks.vim {{{1

" ops and vars {{{2
fun! s:ops()
   retu { 
       \ "\<Enter>": {"bop":"<enter>", "fn":'vc#browse#digin', "args":[0, 1]},
       \ g:vc_ctrlenterkey : {"bop":g:vc_ctrlenterkey_buf, "dscr":vc#utils#digrecdescr(g:vc_ctrlenterkey_dscr), "fn":'vc#browse#digin', "args":[1]},
       \ "\<C-u>"  : {"bop":"<c-u>", "fn":'vc#browse#digout'},
       \ "\<C-r>"  : {"bop":"<c-r>", "fn":'vc#bookmarks#menucb', "args":[]},
       \ "\<C-o>"  : {"bop":"<c-o>", "fn":'vc#gopshdlr#openfltrdfiles', "args":['vc#act#efile']},
       \ "\<C-v>"  : {"bop":"<c-v>", "fn":'vc#gopshdlr#openfile', "args":['vc#act#vs']},
       \ "\<C-d>"  : {"bop":"<c-d>", "fn":'vc#gopshdlr#openfile', "args":['vc#act#diff']},
       \ "\<C-l>"  : {"bop":"<c-l>", "fn":'vc#browse#logs'},
       \ "\<C-b>"  : {"bop":"<c-b>", "fn":'vc#gopshdlr#book'},
       \ "\<C-t>"  : {"bop":"<c-t>", "fn":'vc#stack#top'},
       \ "\<C-i>"  : {"bop":"<c-i>", "fn":'vc#browse#browseinfo'},
       \ "\<C-z>"  : {"bop":"<c-z>", "fn":'vc#gopshdlr#commit'},
       \ "\<C-g>"  : {"bop":"<c-g>", "fn":'vc#gopshdlr#add'},
       \ g:vc_selkey : {"bop":g:vc_selkey_buf, "fn":'vc#gopshdlr#select'},
       \ }
endf
"2}}}

call vc#caop#fetchbmarks()

fun! vc#bookmarks#Browse() "{{{2
    call vc#init()
    call vc#bookmarks#_browse('vc#winj#populateJWindow')
endf
"2}}}

fun! vc#bookmarks#menucb(...)  "{{{2
    retu vc#bookmarks#_browse('vc#winj#populate')
endf
"2}}}

fun! vc#bookmarks#_browse(populateCb)  "{{{2
    try
        let bdict = vc#dict#new("Bookmarks")
        let bdict.meta = vc#utils#blankmeta()
        let entries = vc#select#booked()
        call vc#stack#push('vc#bookmarks#_browse', ['vc#winj#populate'])
        if empty(entries)
            call vc#dict#adderrtop(bdict, "No Book Marked files", "")
        else
            call vc#dict#addbrowseentries(bdict, 'browsed', entries, s:ops())
        endif
        unlet! entries
        call call(a:populateCb, [bdict])
        unlet! bdict
    catch | call vc#utils#dbgmsg("At vc#bookmarks#_browse", v:exception)
    endtry
    retu vc#passed()
endf
"2}}}
