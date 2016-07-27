" ============================================================================
" File:         autoload/vc/syntax.vim
" Description:  Syntax and highlights for vc_window
" Author:       Juneed Ahamed
" =============================================================================

" syntax build and hl {{{1

fun! vc#syntax#build() "{{{2
    setl nobuflisted
    setl noswapfile nowrap nonumber norelativenumber cul nocuc nomodeline nomore nospell nolist wfh
	setl fdc=0 fdl=99 tw=0 bt=nofile bh=unload

    silent! exe 'resize ' . g:vc_window_max_size 

    let [estart, eend, errsyntax] = vc#utils#getErrSyn()
    exec errsyntax 

    let menupatt = "/" . g:vc_menu_start_str . "\.\*/"
    let infopatt = "/" . g:vc_info_str . "\.\*/"

    exec 'syn match VCHide ' . '/^\s*\d\+\:/'
    exec 'syn match VCMenu ' . menupatt
    exec 'syn match VCInfo ' . infopatt
    exec 'syn match VCRev /\(^\s*\d\+:\)\@<=\([a-z0-9]\)\+\s\ze/'
    exec 'syn match VCDate /\d\{2,4}-\d\d-\d\d \(\d\d:\d\d:\d\d\)* [-+]*\(\d\{4}\)*\( (.*)\)*/'
    
    exec 'syn match VCBrowseInfoListSep / -> \| | \|||/'

    exec 'syn match VCStatusMod /\(^\s*\d\+:\)\@<=\s*\([AM]\)\+\s\ze/'
    exec 'syn match VCStatusNA /\(^\s*\d\+:\)\@<=\([\?DRCU]\)\+\s\ze/'

    exec 'hi VCHide guifg=bg'
    exec 'hi link VCMenu ' . g:vc_custom_menu_color
    exec 'hi link VCInfo ' . g:vc_custom_info_color
    exec 'hi link VCError ' . g:vc_custom_error_color
    exec 'hi link VCRev ' . g:vc_custom_rev_color
    exec 'hi link VCDate ' . g:vc_custom_date_color
    exec 'hi link VCBrowseInfoListSep ' . g:vc_custom_binfolistsep_color

    exec 'hi link VCStatusMod ' . g:vc_custom_st_modified_hl
    exec 'hi link VCStatusNA ' . g:vc_custom_st_na_hl

    "exe "highlight SignColumn guibg=black"
	setl bt=nofile bh=unload
    abc <buffer>
endf
"2}}}

"highlight {{{2
fun! vc#syntax#highlight()
     try
        call vc#home()
        call clearmatches()

        let regex = vc#winj#regex()
        if regex != "" 
            let ignchars = "[\\(\\)\\<\\>\\{\\}\\\]"
            let regex = substitute(regex, ignchars, "", "g")
            try 
                call matchadd(g:vc_custom_fuzzy_match_hl, '\v\c' . regex)
            catch 
                call vc#utils#dbgmsg("At highlight matchadd", v:exception)
            endtry
        endif

        if len(vc#select#dict()) && !g:vc_signs
            let patt = join(map(copy(keys(vc#select#dict())),
                        \ '"\\<" . v:val . ": " . ""' ), "\\|")
            let patt = "/\\(" . patt . "\\)/"
            exec 'match ' . s:vchl . ' ' . patt
        endif

        call vc#select#resign(vc#winj#dict())

    catch 
        call vc#utils#dbgmsg("At highlight", v:exception)
    endtry
endf

fun! s:dohicurline()
    try
        let key = matchstr(getline('.'), g:vc_key_patt)
        if key != "" | call matchadd('Directory', '\v\c^' . key) | en
    catch 
        call vc#utils#dbgmsg("At dohicurline", v:exception) 
    endtry
endf
"2}}}
"1}}}
