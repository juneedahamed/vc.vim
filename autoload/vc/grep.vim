fun! vc#grep#do(includepattern, word)
    let [includepattern, word] = [a:includepattern, a:word]
    if includepattern == "" 
        let argslist = split(word)
        let includepattern = vc#argsremoveparam(argslist, "--include", 0, 1)
        let word = join(filter(argslist, 'v:val!=""'))
    endif

    let entries = vc#grep#match(includepattern, word)
    call vc#init()
    let bdict = vc#dict#new("VCGrep: " . word)
    let bdict.grep = word
    let bdict.meta = vc#utils#blankmeta()
    if empty(entries)
        call vc#dict#adderrup(bdict, "No match ", word)
    else
        call vc#dict#addbrowseentries(bdict, 'browsed', entries, vc#browse#ops())
    endif
    call vc#winj#populateJWindow(bdict)
endf

fun! vc#grep#match(includepattern, word)
    let entries = []
    try
        let ipat = a:includepattern == "" ? "*" : a:includepattern
        let cmd = 'grep --include=' . ipat . ' -rl ' . shellescape(a:word) . ' .'
        let x = input(cmd)
        let shellout = vc#utils#execshellcmd(cmd)
        let shelllist = split(shellout)
        for line in shelllist
            call add(entries, vc#utils#fnameescape(line))
        endfor
    catch 
    endtry
    retu entries
endf
