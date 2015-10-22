" =============================================================================
" File:         autoload/fs.vim
" Description:  Local File System
" Author:       Juneed Ahamed
" =============================================================================

"{{{1
fun! vc#fs#meta(entity) "{{{2
    let metad = {}
    let metad.repo = "-fs"
    let metad.entity = a:entity
    let metad.fpath = a:entity == "" ? getcwd() : a:entity
    let metad.isdir = vc#utils#isdir(metad.fpath)
    let metad.local = 1
    let metad.repoUrl = ""
    let metad.wrd = getcwd()
    retu metad
endf
"2}}}

fun! vc#fs#browseinfo(argsd)  "{{{2
    let [adict, akey, aline] = [a:argsd.dict, a:argsd.key, a:argsd.line]
    let info = "Local file - not associated with repository"
    try
        if has_key(adict, 'browsed') 
            let fname = fnameescape(vc#utils#joinpath(adict.bparent, aline))
            let info = vc#fs#info(fname)
        endif
    catch | call vc#utils#dbgmsg("At vc#fs#browseinfo", v:exception) | endtry
    if info != "" | call vc#utils#showconsolemsg(info, 1) | en
    retu vc#nofltrclear() 
endf
"2}}}

fun! vc#fs#info(argsd)  "{{{2
    let info = "Local file - not associated with repository"
    try
        let fname = fnameescape(a:argsd.meta.fpath)
        let info = info . "\nParent : " . fnamemodify(fname, ":h")
        let info = info . "\nFile : " . fname
        let info = info . "\nPerms : " . getfperm(fname)
        let info = info . "\nType : " . getftype(fname)
        let info = info . "\nLast Modified : " . strftime("%c", getftime(fname))
        let info = info . "\nSize : " . getfsize(fname)
    catch | call vc#utils#dbgmsg("At vc#fs#info", v:exception) | endtry
    retu info
endf
"2}}}

fun! vc#fs#formatrevisionandfname(argsd) "{{{2
    let apath = get(a:argsd, 'path', '' )
    retu ["", apath]
endf
"2}}}

fun! vc#fs#copy(argsd) "{{{2
    retu s:do_move_copy("cp -ir", a:argsd)
endf
"2}}}

fun! vc#fs#domove(argsd) "{{{2
    retu s:do_move_copy("mv -i", a:argsd)
endf

fun! s:do_move_copy(op, argsd)
    let [topath, flist] = [a:argsd.topath, a:argsd.flist]
    let cmd =  a:op . " " . join(map(copy(flist), 'vc#utils#fnameescape(v:val)'), " ") . " " . vc#utils#fnameescape(topath)
    retu [vc#passed(), cmd]
endf
"2}}}
"1}}}
