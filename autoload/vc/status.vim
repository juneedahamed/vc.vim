"===============================================================================
" File:         autoload/vc/status.vim
" Description:  VC Status
" Author:       Juneed Ahamed
"===============================================================================

"vc#status {{{1
fun! vc#status#statusops()   "{{{2
   return {
       \ "\<Enter>"  :{"bop":"<enter>", "fn":'vc#gopshdlr#openfile', "args":['vc#act#efile']},
       \ "\<C-o>"    :{"bop":"<c-o>", "fn":'vc#gopshdlr#openfltrdfiles', "args":['vc#act#efile']},
       \ "\<C-d>"    :{"bop":"<c-d>", "fn":'vc#gopshdlr#openfile', "args":['vc#act#diff']},
       \ "\<C-i>"    :{"bop":"<c-i>", "fn":'vc#gopshdlr#info'},
       \ "\<C-w>"    :{"bop":"<c-w>", "fn":'vc#gopshdlr#togglewrap'},
       \ "\<C-y>"    :{"bop":"<c-y>", "fn":'vc#gopshdlr#cmd'},
       \ "\<C-b>"    :{"bop":"<c-b>", "fn":'vc#gopshdlr#book'},
       \ "\<C-z>"    :{"bop":"<c-z>", "fn":'vc#gopshdlr#commit'},
       \ "\<C-g>"    :{"bop":"<c-g>", "fn":'vc#gopshdlr#add'},
       \ "\<C-t>"    :{"bop":"<c-t>", "fn":'vc#stack#top'},
       \ "\<C-u>"    :{"bop":"<c-u>", "fn":'vc#stack#pop'},
       \ "\<C-l>"    :{"bop":"<c-l>", "fn":'vc#status#logs'},
       \ g:vc_selkey :{"bop":g:vc_selkey_buf, "fn":'vc#gopshdlr#select'},
       \ }
endf
"2}}}

fun! vc#status#Status(...)   "{{{2
    try
        call vc#init()
        let disectd = vc#argsdisectlst(a:000, "onlydirs")
        let meta = vc#repos#meta(disectd.target, disectd.forcerepo)
        let argsd = {'meta':meta, 'cargs' : disectd.cargs }
        if disectd.vcnoparse
            let argsd = {
                        \ "meta": meta, 
                        \ "revision": disectd.revision,
                        \ "cargs": disectd.cargs,
                        \ "target": disectd.target,
                        \ "op": "Status",
                        \ }
            retu vc#act#handleNoParseCmd(argsd, 'status.vcnoparse')
        endif
        call vc#status#_status('vc#winj#populateJWindow', argsd)
    catch
        call vc#utils#dbgmsg("Exception at vc#status#Status", v:exception)
        let sdict = vc#dict#new("Status :")
        call vc#dict#adderrtop(sdict, 'Failed ', v:exception)
    endtry
endf

fun! vc#status#_status(populatecb, argsd)
    let title = get(a:argsd.meta, 'fpath', ".") == "\." ? getcwd() : get(a:argsd.meta, "fpath")
    let sdict = vc#dict#new("Status: " . title)
    let sdict.meta = a:argsd.meta
    let [cmd, entries] = vc#repos#call(sdict.meta.repo, 'status.rtrv', a:argsd)

    if empty(entries)
        call vc#dict#adderrup(sdict, 'No Modified files ..', '' )
    else
        let ops = vc#repos#call(sdict.meta.repo, 'status.ops')
        call vc#dict#addentries(sdict, 'statusd', entries, ops)
        let sdict.meta.cmd = cmd
        call vc#stack#push('vc#status#_status', [a:populatecb, a:argsd])
    endif
    call call(a:populatecb, [sdict])
    retu vc#passed()
endf
"2}}}

fun! vc#status#logs(argsd)   "{{{2
    try
        let [adict, akey] = [a:argsd.dict, a:argsd.key]
        if has_key(adict.statusd.contents, akey)
            if adict.statusd.contents[akey].modtype == "INFO" | cont | endif
            let path = adict.statusd.contents[akey].fpath
            call vc#log#logs("", path, "vc_stop_for_args", 'vc#winj#populate', 0, adict.meta.repo)
        endif
    catch 
        call vc#utils#showerr("Failed, Exception")
    endtry
    retu vc#passed()
endf
"2}}}

"1}}}

