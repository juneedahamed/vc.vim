"===============================================================================
" File:         autoload/vc/blank.vim
" Description:  VC Blank window used by Add, Commit, CP
" Author:       Juneed Ahamed
"===============================================================================

"vc#blank.vim {{{1
let s:bwinname = 'vc_bwindow'
let s:ops = {}

augroup VCOnWrite
augroup END

fun! vc#blank#win(cmdsdict) "{{{2
    let s:ops = {}
    call vc#winj#close()
    call vc#blank#closeme()
    noa call s:setup(a:cmdsdict)
	setlocal nomodified
endf
"2}}}

fun! s:setup(cmdsdict) "{{{2
    let jwinnr = bufwinnr(s:bwinname)
    silent! exe  jwinnr < 0 ? 'keepa botright 1new ' .
                \ fnameescape(s:bwinname) : jwinnr . 'wincmd w'
    setl nobuflisted noswapfile nowrap nonumber norelativenumber nocuc nomodeline nomore nolist wfh
	setl tw=0 bt=acwrite bh=wipe
    silent! exe 'resize ' . g:vc_window_max_size 
	au VCOnWrite BufWriteCmd <buffer> call vc#blank#callonwrite()
    exe 'nn <buffer> <silent> :wq :w<CR>'
    let idx = 0
    for [key, value] in items(a:cmdsdict)
        let idx += 1
        let s:ops[idx] = value
        exe 'nn <buffer> <silent>' key ":<c-u>call vc#blank#callback(".idx.")<CR>"
    endfor
    
    exec 'syn match VC /^VC\:.*/'
    exec 'hi link VC ' . g:vc_custom_commit_header_hl

    exe 'syn match CommitFiles /^VC\:+.*/'
    exec 'hi link CommitFiles ' . g:vc_custom_commit_files_hl

    exe 'syn match CommitFiles /^VC\:SOURCE\:.*/'
    exec 'hi link CommitFiles ' . g:vc_custom_commit_files_hl

    exe 'syn match CommitFiles /^VC\:DESTINATION\:.*/'
    exec 'hi link CommitFiles ' . g:vc_custom_commit_files_hl

    exe 'syn match Repository /^VC\: REPOSITORY \: .*/'
    exec 'hi link Repository ' . g:vc_custom_repo_header_hl
    
    exe 'syn match Wrd /^VC\: Working Root Dir \: .*/'
    exec 'hi link Wrd ' . g:vc_custom_repo_header_hl

    exe 'syn match Operations /^VC\: Operations \: .*/'
    exec 'hi link Operations ' . g:vc_custom_op_hl

    call s:noparsesetup()
endf
"2}}}

fun! s:noparsesetup()
    exec 'syn match DEL /^\-.*$/'
    exec 'hi link DEL Error'

    exec 'syn match VCADD /^+.*/'
    exec 'hi link VCADD Identifier'
    
    exec 'syn match VCNOPARSEOP /^diff.*/'
    exec 'hi link VCNOPARSEOP Title'
endf

fun! vc#blank#onwrite(callback, argsd) "{{{2
    unlet! b:onwritecallbackargsd
    unlet! b:onwritecallback
    let b:onwritecallback = a:callback
    let b:onwritecallbackargsd = a:argsd
endf
"2}}}

fun! vc#blank#callonwrite()
    try
        if exists("b:onwritecallbackargsd") && exists("b:onwritecallback")
            retu call(b:onwritecallback, [ b:onwritecallbackargsd])
        endif
    finally
        setl nomodified
    endtry
endf

fun! vc#blank#appendline(line)  "{{{2
    let line = substitute(a:line, "^[\"|\']", "", "")
    let line = substitute(line, "[\"|\']$", "", "")
    call append(line('$')-1, line)
    setlocal nomodified
endf

fun! vc#blank#callback(idx) 
    if has_key(s:ops, a:idx) 
        let cbdict = s:ops[a:idx]
        if has_key(s:ops[a:idx], "args")
            let args = s:ops[a:idx].args
            call call(cbdict.fn, [args])
        else
            call call(cbdict.fn, [{}])
        endif
    endif
    setl nomodified
endf
"2}}}

fun! vc#blank#closeme(...) "{{{2
    let jwinnr = bufwinnr(s:bwinname)
    if jwinnr > 0
        try 
            setl nomodified
            "silent! exe 'bwipeout' jwinnr
            silent! exe  jwinnr . 'wincmd w'
            silent! exe  jwinnr . 'wincmd c'
        catch | endtry 
    endif
    echo "" | redr
    retu vc#passed()
endf
"2}}}

"1}}}
